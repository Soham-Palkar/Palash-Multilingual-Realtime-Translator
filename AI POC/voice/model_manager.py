"""
PALASH Model Manager & Offline Readiness Inspection Layer

Centralized configuration and local model manager for:
- Hindi ASR (ai4bharat/indicconformer_stt_hi_hybrid_rnnt_large)
- Translation (ai4bharat/indictrans2-indic-indic-dist-320M)
- Santali TTS (ai4bharat/indic-parler-tts)
- Hindi TTS (ai4bharat/indic-parler-tts)
- Santali ASR (Pending official model integration)
"""

import os
from pathlib import Path
from typing import Dict, Any, Optional

MODELS_CONFIG: Dict[str, Dict[str, Any]] = {
    "ASR_HINDI": {
        "name": "ai4bharat/indicconformer_stt_hi_hybrid_rnnt_large",
        "language": "hin_Deva",
        "type": "asr",
        "framework": "nemo",
        "required": True,
    },
    "TRANSLATOR": {
        "name": "ai4bharat/indictrans2-indic-indic-dist-320M",
        "language": "hin_Deva <-> sat_Olck",
        "type": "translation",
        "framework": "transformers",
        "required": True,
    },
    "TTS_SANTALI": {
        "name": "ai4bharat/indic-parler-tts",
        "language": "sat_Olck",
        "type": "tts",
        "framework": "parler_tts",
        "required": True,
    },
    "TTS_HINDI": {
        "name": "ai4bharat/indic-parler-tts",
        "language": "hin_Deva",
        "type": "tts",
        "framework": "parler_tts",
        "required": False,
    },
    "ASR_SANTALI": {
        "name": "ai4bharat/indicconformer_stt_sat_large",
        "language": "sat_Olck",
        "type": "asr",
        "framework": "nemo",
        "required": False,
        "status": "PENDING",
    },
}


class ModelManager:
    """
    Manages model configuration, local cache checks, offline enforcement,
    and device selection for PALASH voice translation pipeline.
    """

    def __init__(self, offline_mode: bool = True):
        self.offline_mode = offline_mode
        self.models_config = MODELS_CONFIG

    def check_offline_readiness(self) -> Dict[str, Any]:
        """
        Verify if required models exist in local cache or local storage.
        Prints status reports and returns summary dict.
        """
        status_report = {}
        all_required_present = True

        cache_dir = os.environ.get(
            "HF_HOME",
            os.path.expanduser("~/.cache/huggingface")
        )

        print("[OFFLINE CHECK] Inspecting local model availability...")
        print(f"[OFFLINE CHECK] Cache root: {cache_dir}")

        for model_key, meta in MODELS_CONFIG.items():
            model_name = meta["name"]
            is_required = meta.get("required", False)
            status = meta.get("status", "AVAILABLE")

            if status == "PENDING":
                print(f"  - {model_key} ({model_name}): [PENDING MODEL INTEGRATION]")
                status_report[model_key] = {
                    "available": False,
                    "status": "PENDING",
                    "required": is_required
                }
                continue

            # Check for local presence in HuggingFace cache
            clean_repo = model_name.replace("/", "--")
            repo_cache = Path(cache_dir) / "hub" / f"models--{clean_repo}"
            exists = repo_cache.exists() or Path(model_name).exists()

            if exists:
                print(f"  - {model_key} ({model_name}): [OFFLINE READY]")
                status_report[model_key] = {
                    "available": True,
                    "status": "OFFLINE_READY",
                    "required": is_required
                }
            else:
                if is_required:
                    all_required_present = False
                    print(f"  - {model_key} ({model_name}): [MISSING - REQUIRED]")
                else:
                    print(f"  - {model_key} ({model_name}): [MISSING - OPTIONAL]")

                status_report[model_key] = {
                    "available": False,
                    "status": "MISSING",
                    "required": is_required
                }

        if all_required_present:
            print("[OFFLINE] Models available locally. Runtime mode enabled.")
        else:
            print("[MODEL MISSING] Required local model files are missing. Run setup/download first.")

        return {
            "ready": all_required_present,
            "offline_mode": True,
            "report": status_report
        }

    @staticmethod
    def get_model_info(model_key: str) -> Optional[Dict[str, Any]]:
        """Get metadata for a specified model key."""
        return MODELS_CONFIG.get(model_key)


if __name__ == "__main__":
    manager = ModelManager()
    manager.check_offline_readiness()
