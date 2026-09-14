from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

from app.uploads import UploadError, store_image_upload


PNG_BYTES = b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDRdemo"


class UploadsTest(unittest.TestCase):
    def test_store_image_upload_hashes_and_writes_file(self):
        with TemporaryDirectory() as tmp:
            stored = store_image_upload(
                content=PNG_BYTES,
                filename="sample.png",
                content_type="image/png",
                upload_dir=Path(tmp),
            )
            self.assertEqual(stored.size_bytes, len(PNG_BYTES))
            self.assertEqual(stored.content_type, "image/png")
            self.assertTrue(stored.path.exists())
            self.assertEqual(stored.path.suffix, ".png")

    def test_rejects_unsupported_upload_type(self):
        with self.assertRaises(UploadError):
            store_image_upload(
                content=b"not-an-image",
                filename="sample.txt",
                content_type="text/plain",
            )

    def test_rejects_mismatched_image_signature(self):
        with self.assertRaises(UploadError):
            store_image_upload(
                content=b"not-really-a-png",
                filename="sample.png",
                content_type="image/png",
            )


if __name__ == "__main__":
    unittest.main()
