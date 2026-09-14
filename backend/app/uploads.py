from __future__ import annotations

from dataclasses import dataclass
from hashlib import sha256
from pathlib import Path


UPLOAD_DIR = Path(__file__).resolve().parents[1] / "data" / "uploads"
MAX_UPLOAD_BYTES = 6 * 1024 * 1024
ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp"}


@dataclass(frozen=True)
class StoredUpload:
    sha256: str
    size_bytes: int
    content_type: str
    path: Path


class UploadError(Exception):
    pass


def store_image_upload(
    *,
    content: bytes,
    filename: str,
    content_type: str,
    upload_dir: Path = UPLOAD_DIR,
) -> StoredUpload:
    if content_type not in ALLOWED_CONTENT_TYPES:
        raise UploadError("Only JPEG, PNG, and WebP images are supported.")
    if not content:
        raise UploadError("Image upload is empty.")
    if len(content) > MAX_UPLOAD_BYTES:
        raise UploadError("Image upload is larger than 6 MB.")
    if not _matches_image_signature(content, content_type):
        raise UploadError("Image bytes do not match the declared image type.")

    digest = sha256(content).hexdigest()
    suffix = Path(filename).suffix.lower()
    if suffix not in {".jpg", ".jpeg", ".png", ".webp"}:
        suffix = {
            "image/jpeg": ".jpg",
            "image/png": ".png",
            "image/webp": ".webp",
        }[content_type]

    upload_dir.mkdir(parents=True, exist_ok=True)
    path = upload_dir / f"{digest[:16]}{suffix}"
    path.write_bytes(content)
    return StoredUpload(
        sha256=digest,
        size_bytes=len(content),
        content_type=content_type,
        path=path,
    )


def _matches_image_signature(content: bytes, content_type: str) -> bool:
    if content_type == "image/png":
        return content.startswith(b"\x89PNG\r\n\x1a\n")
    if content_type == "image/jpeg":
        return content.startswith(b"\xff\xd8\xff")
    if content_type == "image/webp":
        return len(content) >= 12 and content[:4] == b"RIFF" and content[8:12] == b"WEBP"
    return False
