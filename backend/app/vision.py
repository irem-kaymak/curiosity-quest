from __future__ import annotations

from io import BytesIO
from dataclasses import dataclass

from app.domain import Domain


@dataclass(frozen=True)
class VisualLabel:
    name: str
    confidence: float


@dataclass(frozen=True)
class VisionResult:
    provider: str
    status: str
    labels: list[VisualLabel]
    error: str = ""

    def prompt_hint(self) -> str:
        if not self.labels:
            return f"Visual labels unavailable from {self.provider}: {self.status}."
        label_text = ", ".join(
            f"{label.name} ({label.confidence:.0f}%)" for label in self.labels[:10]
        )
        return f"Visual labels from {self.provider}: {label_text}."


def detect_visual_labels(image_bytes: bytes) -> VisionResult:
    try:
        import boto3  # type: ignore

        rekognition_bytes, conversion_note = normalize_for_rekognition(image_bytes)
        client = boto3.client("rekognition")
        response = client.detect_labels(
            Image={"Bytes": rekognition_bytes},
            MaxLabels=12,
            MinConfidence=55,
            Features=["GENERAL_LABELS"],
        )
        labels = [
            VisualLabel(str(item.get("Name", "")), float(item.get("Confidence", 0)))
            for item in response.get("Labels", [])
            if item.get("Name")
        ]
        return VisionResult("aws_rekognition", conversion_note or "ok", labels)
    except Exception as exc:
        return VisionResult(
            "aws_rekognition",
            "unavailable",
            [],
            f"{type(exc).__name__}: {str(exc)[:180]}",
        )


def sniff_image_format(image_bytes: bytes) -> str:
    if image_bytes.startswith(b"\xff\xd8\xff"):
        return "jpeg"
    if image_bytes.startswith(b"\x89PNG\r\n\x1a\n"):
        return "png"
    if image_bytes.startswith(b"GIF87a") or image_bytes.startswith(b"GIF89a"):
        return "gif"
    if image_bytes[:4] == b"RIFF" and image_bytes[8:12] == b"WEBP":
        return "webp"
    return "unknown"


def normalize_for_rekognition(image_bytes: bytes) -> tuple[bytes, str]:
    image_format = sniff_image_format(image_bytes)
    if image_format in {"jpeg", "png"}:
        return image_bytes, "ok"
    try:
        from PIL import Image  # type: ignore

        with Image.open(BytesIO(image_bytes)) as image:
            output = BytesIO()
            image.convert("RGB").save(output, format="JPEG", quality=92)
            return output.getvalue(), f"converted_{image_format}_to_jpeg"
    except Exception as exc:
        raise ValueError(
            f"unsupported image format for Rekognition ({image_format}); "
            f"install Pillow with WebP/HEIC support or upload JPEG/PNG. {type(exc).__name__}"
        ) from exc


def infer_domain_from_labels(labels: list[VisualLabel]) -> Domain:
    text = " ".join(label.name.lower() for label in labels)
    if any(
        word in text
        for word in [
            "squirrel",
            "animal",
            "mammal",
            "wildlife",
            "rodent",
            "bird",
            "insect",
            "plant",
            "leaf",
            "tree",
            "flower",
            "acorn",
            "mushroom",
            "nature",
        ]
    ):
        return Domain.NATURE
    if any(
        word in text
        for word in ["food", "dish", "meal", "fruit", "vegetable", "menu", "restaurant"]
    ):
        return Domain.DINING
    if any(
        word in text
        for word in ["building", "architecture", "monument", "fountain", "statue", "temple"]
    ):
        return Domain.HERITAGE
    return Domain.GENERAL


def infer_risk_terms_from_labels(labels: list[VisualLabel]) -> list[str]:
    text = " ".join(label.name.lower() for label in labels)
    risks: list[str] = []
    for term in ["knife", "weapon", "fire", "flame", "smoke", "blood", "gun"]:
        if term in text:
            risks.append(term)
    return risks


def best_subject_label(labels: list[VisualLabel]) -> str:
    preferred = [
        "squirrel",
        "rabbit",
        "horse",
        "pony",
        "cat",
        "dog",
        "bird",
        "butterfly",
        "bee",
        "daisy",
        "chamomile",
        "sunflower",
        "rose",
        "tulip",
        "oak",
        "acorn",
        "mushroom",
        "knife",
        "blade",
        "food",
    ]
    by_name = {label.name.lower(): label for label in labels}
    for name in preferred:
        if name in by_name:
            return by_name[name].name
    ignored = {
        "animal",
        "mammal",
        "rodent",
        "wildlife",
        "nature",
        "outdoors",
        "plant",
        "flower",
        "food",
        "weapon",
        "cutlery",
    }
    for label in sorted(labels, key=lambda item: item.confidence, reverse=True):
        if label.name.lower() not in ignored:
            return label.name
    return labels[0].name if labels else ""


def curiosity_fact_and_question(subject: str, domain: Domain) -> tuple[str, str]:
    name = subject.lower()
    if "squirrel" in name:
        return (
            "Squirrels often eat nuts, seeds, fruits, fungi, and sometimes small insects.",
            "Do you know why squirrels bury some of their food?"
        )
    if "rabbit" in name:
        return (
            "Rabbits often have soft fur, long ears, and strong back legs for hopping.",
            "What color do you notice on the rabbit's fur?"
        )
    if "horse" in name or "pony" in name:
        return (
            "Horses are large mammals with hooves, a mane, a tail, and strong legs for running.",
            "What color do you notice on the horse, and what clue besides color can you spot?"
        )
    if "bird" in name:
        return (
            "Birds use feathers, beaks, and body shape as helpful clues.",
            "What clue do you notice first: color, beak shape, or wing pattern?"
        )
    if "cat" in name or "dog" in name:
        return (
            "Fur color, body shape, and behavior can be useful clues.",
            "What detail should Curio check next?"
        )
    if "acorn" in name or "oak" in name:
        return (
            "Those look like acorns, which grow on oak trees and can become new oak trees.",
            "Can you spot the cap on the acorn and the shape of the oak leaf?"
        )
    if any(term in name for term in ["leaf", "tree", "plant", "flower"]):
        return (
            "Plants use sunlight, water, and air to make their own food.",
            "What do you notice first: the leaf shape, the color, or the stem?"
        )
    if domain == Domain.DINING:
        return (
            "A photo can show visible ingredients, but it cannot prove hidden allergens or how food was prepared.",
            "Which part can we verify with an adult: the menu, the label, or the staff answer?"
        )
    if domain == Domain.NATURE and name not in {"animal", "mammal", "nature", "wildlife"}:
        return (
            f"{subject.title()} can be explored by comparing body shape, color, movement, and where it was seen.",
            f"What clue do you notice first on the {name}: color, shape, movement, or where it is?"
        )
    return (
        "A good explorer compares the first clue with one more observation before deciding.",
        "What is one detail you notice that Curio should check next?"
    )
