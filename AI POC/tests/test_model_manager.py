import unittest
import sys
import os

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from voice.model_manager import ModelManager, MODELS_CONFIG


class TestModelManager(unittest.TestCase):

    def test_model_manager_config(self):
        manager = ModelManager()
        self.assertIn("ASR_HINDI", manager.models_config)
        self.assertIn("TRANSLATOR", manager.models_config)
        self.assertIn("TTS_SANTALI", manager.models_config)
        self.assertIn("ASR_SANTALI", manager.models_config)

    def test_santali_asr_pending_status(self):
        info = ModelManager.get_model_info("ASR_SANTALI")
        self.assertIsNotNone(info)
        self.assertEqual(info.get("status"), "PENDING")

    def test_check_offline_readiness_structure(self):
        manager = ModelManager()
        readiness = manager.check_offline_readiness()
        self.assertIn("ready", readiness)
        self.assertIn("report", readiness)
        self.assertTrue(readiness["offline_mode"])


if __name__ == "__main__":
    unittest.main()
