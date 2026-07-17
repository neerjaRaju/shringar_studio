"""Pluggable image-generation providers (zero-cost by default)."""
from __future__ import annotations

import abc
import time
import urllib.parse

import requests

SIZE_BY_ORIENTATION = {
    "square": lambda edge: (edge, edge),
    "portrait": lambda edge: (int(edge * 2 / 3), edge),
    "landscape": lambda edge: (edge, int(edge * 2 / 3)),
}


class ImageProvider(abc.ABC):
    name: str = "abstract"

    def __init__(self, timeout: int = 120, retries: int = 3, backoff: int = 10) -> None:
        self.timeout = timeout
        self.retries = retries
        self.backoff = backoff

    @abc.abstractmethod
    def _fetch(self, prompt: str, width: int, height: int, seed: int) -> bytes: ...

    def generate(self, prompt: str, width: int, height: int, seed: int) -> bytes:
        last_err: Exception | None = None
        for attempt in range(self.retries):
            try:
                data = self._fetch(prompt, width, height, seed)
                if len(data) < 2048:
                    raise ValueError("response too small to be an image")
                return data
            except Exception as err:  # noqa: BLE001
                last_err = err
                time.sleep(self.backoff * (attempt + 1))
        raise RuntimeError(f"{self.name}: generation failed after {self.retries} attempts: {last_err}")


class PollinationsProvider(ImageProvider):
    """Free, keyless image generation — https://pollinations.ai"""

    name = "pollinations"
    BASE = "https://image.pollinations.ai/prompt/"

    def _fetch(self, prompt: str, width: int, height: int, seed: int) -> bytes:
        url = self.BASE + urllib.parse.quote(prompt[:1500])
        params = {"width": width, "height": height, "seed": seed, "nologo": "true", "model": "flux"}
        resp = requests.get(url, params=params, timeout=self.timeout)
        resp.raise_for_status()
        if not resp.headers.get("Content-Type", "").startswith("image/"):
            raise ValueError(f"unexpected content type {resp.headers.get('Content-Type')}")
        return resp.content


class HuggingFaceProvider(ImageProvider):
    """Free-tier HF Inference API. Requires HF_TOKEN env / GitHub secret."""

    name = "huggingface"
    MODEL = "black-forest-labs/FLUX.1-schnell"

    def __init__(self, token: str, **kw) -> None:
        super().__init__(**kw)
        self.token = token

    def _fetch(self, prompt: str, width: int, height: int, seed: int) -> bytes:
        resp = requests.post(
            f"https://api-inference.huggingface.co/models/{self.MODEL}",
            headers={"Authorization": f"Bearer {self.token}"},
            json={"inputs": prompt, "parameters": {"width": width, "height": height, "seed": seed}},
            timeout=self.timeout,
        )
        resp.raise_for_status()
        return resp.content


def get_provider(name: str, *, timeout: int = 120, retries: int = 3, backoff: int = 10) -> ImageProvider:
    import os

    kw = {"timeout": timeout, "retries": retries, "backoff": backoff}
    if name == "pollinations":
        return PollinationsProvider(**kw)
    if name == "huggingface":
        token = os.environ.get("HF_TOKEN", "")
        if not token:
            raise EnvironmentError("HF_TOKEN environment variable is required for huggingface provider")
        return HuggingFaceProvider(token, **kw)
    raise ValueError(f"unknown provider: {name}")
