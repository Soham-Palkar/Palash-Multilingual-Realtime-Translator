import unittest
import sys
import os

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from voice.asr_interface import DummyASRBackend
from voice.tts_interface import DummyTTSBackend
from voice.voice_pipeline import VoicePipeline


class TestVoicePipeline(unittest.TestCase):

    def test_pipeline_direction_selection(self):
        pipeline = VoicePipeline(
            source_language="hin_Deva",
            target_language="sat_Olck",
            asr_engine=DummyASRBackend(),
            tts_engine=DummyTTSBackend()
        )
        self.assertEqual(pipeline.source_language, "hin_Deva")
        self.assertEqual(pipeline.target_language, "sat_Olck")

    def test_santali_asr_capability_error(self):
        pipeline = VoicePipeline(
            source_language="hin_Deva",
            target_language="sat_Olck",
            asr_engine=DummyASRBackend(),
            tts_engine=DummyTTSBackend()
        )
        # DummyASRBackend supports hin_Deva but not sat_Olck for ASR
        with self.assertRaises(NotImplementedError) as ctx:
            pipeline.set_direction("sat_Olck", "hin_Deva")

        self.assertIn("Santali ASR pending model integration", str(ctx.exception))


if __name__ == "__main__":
    unittest.main()
