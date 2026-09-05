import sys
import time
import io
import wave
import os
from typing import Optional, Dict

import torch
import numpy as np

from voice.tts_interface import TTSEngine


def _log(message: str):
    """
    TTS diagnostics go to stderr.
    stdout must remain clean for WSL JSON IPC.
    """
    print(message, file=sys.stderr, flush=True)


MODEL_NAME = "ai4bharat/indic-parler-tts"


# ============================================================================
# VOICE DESCRIPTIONS
# ============================================================================

VOICE_DESCRIPTIONS: Dict[str, str] = {
    "sat_Olck": (
        "Arjun speaks Santali language clearly and naturally, "
        "with a warm and steady pace suitable for a classroom. "
        "The speech is in Santali using Ol Chiki script pronunciation."
    ),

    "sat": (
        "Arjun speaks Santali language clearly and naturally, "
        "with a warm and steady pace suitable for a classroom. "
        "The speech is in Santali using Ol Chiki script pronunciation."
    ),

    "hin_Deva": (
        "Sunita speaks Hindi language clearly and naturally, "
        "with a warm classroom-friendly speaking style and moderate speaking speed."
    ),

    "hi": (
        "Sunita speaks Hindi language clearly and naturally, "
        "with a warm classroom-friendly speaking style and moderate speaking speed."
    ),
}


# ============================================================================
# LANGUAGE ALIASES
# ============================================================================

LANG_ALIASES: Dict[str, str] = {
    "hin_Deva": "hi",
    "hi": "hi",
    "sat_Olck": "sat",
    "sat": "sat",
}


class IndicParlerTTSBackend(TTSEngine):
    """
    Offline AI4Bharat Indic Parler-TTS backend.

    Supported:
        Hindi   -> hin_Deva / hi
        Santali -> sat_Olck / sat

    Architecture:

        WSL CUDA
            |
            | Parler-TTS
            v
        WAV bytes
            |
            v
        Windows playback

    Important:
        Indic Parler-TTS uses two different tokenizers:

        1. Prompt tokenizer
           -> actual speech text

        2. Description tokenizer
           -> speaker/voice description
    """

    def __init__(
        self,
        device: Optional[str] = None,
        lazy_load: bool = False,
        use_half_precision: bool = True,
    ):
        self.device = device or (
            "cuda:0"
            if torch.cuda.is_available()
            else "cpu"
        )

        self.model_name = MODEL_NAME

        self.model = None

        # Tokenizer for actual target-language text.
        self.tokenizer = None

        # Tokenizer for voice description.
        self.description_tokenizer = None

        self.load_time_ms = 0.0
        self.last_latency_ms = 0.0

        self._is_loaded = False
        self.use_half_precision = use_half_precision

        # ---------------------------------------------------------------
        # Precision
        # ---------------------------------------------------------------

        if (
            "cuda" in str(self.device)
            and self.use_half_precision
        ):
            try:
                if torch.cuda.is_bf16_supported():
                    self.dtype = torch.bfloat16
                else:
                    self.dtype = torch.float16
            except Exception:
                self.dtype = torch.float16
        else:
            self.dtype = torch.float32

        if not lazy_load:
            self.load_model()

    # ===================================================================
    # MODEL LOADING
    # ===================================================================

    def load_model(self):
        """Load model and both tokenizers exactly once."""

        if self._is_loaded:
            return

        _log(
            f"[TTS] Loading Indic Parler-TTS "
            f"({MODEL_NAME})..."
        )

        _log(
            f"[TTS] Device: {self.device} | "
            f"Precision: {self.dtype}"
        )

        start = time.perf_counter()

        try:
            from parler_tts import (
                ParlerTTSForConditionalGeneration
            )
            from transformers import AutoTokenizer

            # -----------------------------------------------------------
            # Model
            # -----------------------------------------------------------

            self.model = (
                ParlerTTSForConditionalGeneration.from_pretrained(
                    MODEL_NAME,
                    torch_dtype=self.dtype,
                    attn_implementation="eager",
                )
                .to(self.device)
            )

            self.model.eval()

            # -----------------------------------------------------------
            # Prompt tokenizer
            #
            # Used for the actual speech text.
            # -----------------------------------------------------------

            self.tokenizer = (
                AutoTokenizer.from_pretrained(
                    MODEL_NAME
                )
            )

            # -----------------------------------------------------------
            # Description tokenizer
            #
            # IMPORTANT:
            # This must NOT use the Parler prompt tokenizer.
            # -----------------------------------------------------------

            description_tokenizer_name = (
                self.model.config.text_encoder._name_or_path
            )

            _log(
                "[TTS] Description tokenizer: "
                f"{description_tokenizer_name}"
            )

            self.description_tokenizer = (
                AutoTokenizer.from_pretrained(
                    description_tokenizer_name
                )
            )

            # -----------------------------------------------------------
            # Ready
            # -----------------------------------------------------------

            self.load_time_ms = round(
                (
                    time.perf_counter() - start
                ) * 1000,
                2,
            )

            self._is_loaded = True

            sample_rate = int(
                getattr(
                    self.model.config,
                    "sampling_rate",
                    44100,
                )
            )

            _log(
                "[TTS] Ready "
                f"(Load time: {self.load_time_ms} ms | "
                f"Sample rate: {sample_rate} Hz)"
            )

        except ImportError as e:

            _log(
                f"[TTS ERROR] Missing package: {e}"
            )

            raise

        except Exception as e:

            _log(
                f"[TTS ERROR] Model loading failed: {e}"
            )

            raise

    # ===================================================================
    # LANGUAGE SUPPORT
    # ===================================================================

    def is_language_supported(
        self,
        language: str,
    ) -> bool:

        normalized = LANG_ALIASES.get(
            language,
            language,
        )

        return normalized in (
            "sat",
            "hi",
        )

    def get_voice_description(
        self,
        language: str,
    ) -> str:

        if language in VOICE_DESCRIPTIONS:
            return VOICE_DESCRIPTIONS[language]

        normalized = LANG_ALIASES.get(
            language,
            language,
        )

        return VOICE_DESCRIPTIONS.get(
            normalized,
            VOICE_DESCRIPTIONS["sat_Olck"],
        )

    # ===================================================================
    # GENERATION LENGTH
    # ===================================================================

    def _calculate_max_tokens(
        self,
        text: str,
        language: str = "sat_Olck",
    ) -> int:
        """
        Calculate a generation safety limit.

        Keep this moderate because unnecessarily large values
        increase generation latency.
        """

        text_len = len(
            text.strip()
        )

        normalized = LANG_ALIASES.get(
            language,
            language,
        )

        if normalized == "sat":

            return max(
                256,
                min(
                    1024,
                    text_len * 12,
                ),
            )

        return max(
            192,
            min(
                768,
                text_len * 10,
            ),
        )

    # ===================================================================
    # AUDIO PREPARATION
    # ===================================================================

    def _prepare_audio(
        self,
        generation,
    ) -> np.ndarray:
        """
        Convert Parler output into a mono float32 waveform.

        The generated waveform observed in testing was extremely quiet:

            peak ~= 0.022
            RMS  ~= 0.0016

        Therefore controlled peak normalization is applied.

        Target peak:
            0.89

        Maximum gain:
            50x

        Final safety limit:
            +/-0.95
        """

        # ---------------------------------------------------------------
        # Tensor -> float32
        # ---------------------------------------------------------------

        audio_tensor = generation.squeeze()

        if audio_tensor.dtype != torch.float32:
            audio_tensor = audio_tensor.float()

        # ---------------------------------------------------------------
        # GPU -> CPU -> NumPy
        # ---------------------------------------------------------------

        audio_array = (
            audio_tensor
            .detach()
            .cpu()
            .numpy()
            .astype(np.float32)
        )

        audio_array = np.asarray(
            audio_array,
            dtype=np.float32,
        ).squeeze()

        # ---------------------------------------------------------------
        # Make sure mono/1D
        # ---------------------------------------------------------------

        if audio_array.ndim != 1:
            audio_array = audio_array.reshape(-1)

        # ---------------------------------------------------------------
        # Validate
        # ---------------------------------------------------------------

        if audio_array.size == 0:
            raise ValueError(
                "Parler-TTS returned empty audio."
            )

        if not np.all(
            np.isfinite(audio_array)
        ):
            raise ValueError(
                "Parler-TTS returned NaN/Inf audio."
            )

        # ---------------------------------------------------------------
        # Original levels
        # ---------------------------------------------------------------

        original_peak = float(
            np.max(
                np.abs(audio_array)
            )
        )

        original_rms = float(
            np.sqrt(
                np.mean(
                    np.square(audio_array)
                )
            )
        )

        _log(
            "[TTS RAW] "
            f"shape={audio_array.shape} "
            f"dtype={audio_array.dtype} "
            f"min={np.min(audio_array):.8f} "
            f"max={np.max(audio_array):.8f} "
            f"mean={np.mean(audio_array):.8f}"
        )

        _log(
            "[TTS RAW LEVEL] "
            f"peak={original_peak:.8f} "
            f"rms={original_rms:.8f}"
        )

        # ---------------------------------------------------------------
        # Detect actual silence
        # ---------------------------------------------------------------

        if original_peak <= 1e-8:
            raise ValueError(
                "Parler-TTS generated silent audio."
            )

        # ---------------------------------------------------------------
        # Controlled normalization
        # ---------------------------------------------------------------

        target_peak = 0.89

        gain = (
            target_peak
            / original_peak
        )

        # Safety limit.
        max_gain = 50.0

        gain = min(
            gain,
            max_gain,
        )

        audio_array *= gain

        _log(
            "[TTS NORMALIZE] "
            f"gain={gain:.2f}x "
            f"original_peak={original_peak:.8f}"
        )

        # ---------------------------------------------------------------
        # Final safety clipping
        # ---------------------------------------------------------------

        audio_array = np.clip(
            audio_array,
            -0.95,
            0.95,
        )

        # ---------------------------------------------------------------
        # Final levels
        # ---------------------------------------------------------------

        final_peak = float(
            np.max(
                np.abs(audio_array)
            )
        )

        final_rms = float(
            np.sqrt(
                np.mean(
                    np.square(audio_array)
                )
            )
        )

        _log(
            "[TTS FINAL LEVEL] "
            f"peak={final_peak:.6f} "
            f"rms={final_rms:.6f}"
        )

        return audio_array

    # ===================================================================
    # WAV ENCODING
    # ===================================================================

    def _encode_wav(
        self,
        audio_array: np.ndarray,
        sample_rate: int,
    ) -> bytes:
        """
        Encode waveform as standard PCM16 WAV.

        Uses Python's built-in wave module.
        No soundfile dependency is required.
        """

        audio_array = np.asarray(
            audio_array,
            dtype=np.float32,
        ).reshape(-1)

        audio_array = np.clip(
            audio_array,
            -0.95,
            0.95,
        )

        # Float32 -> PCM16
        pcm16 = (
            audio_array * 32767.0
        ).astype(
            np.int16
        )

        wav_io = io.BytesIO()

        with wave.open(
            wav_io,
            "wb",
        ) as wf:

            wf.setnchannels(1)
            wf.setsampwidth(2)
            wf.setframerate(sample_rate)

            wf.writeframes(
                pcm16.tobytes()
            )

        wav_bytes = wav_io.getvalue()

        if not wav_bytes.startswith(
            b"RIFF"
        ):
            raise RuntimeError(
                "Generated WAV has invalid RIFF header."
            )

        return wav_bytes

    # ===================================================================
    # SYNTHESIS
    # ===================================================================

    def synthesize(
        self,
        text: str,
        language: str = "sat_Olck",
    ) -> Optional[bytes]:
        """
        Generate target-language speech as WAV bytes.
        """

        # ---------------------------------------------------------------
        # Load model if required
        # ---------------------------------------------------------------

        if not self._is_loaded:

            try:
                self.load_model()

            except Exception as e:

                _log(
                    f"[TTS ERROR] "
                    f"Model load failed: {e}"
                )

                return None

        # ---------------------------------------------------------------
        # Validate text
        # ---------------------------------------------------------------

        if not text or not text.strip():

            _log(
                "[TTS WARNING] "
                "Empty text rejected."
            )

            return None

        text = text.strip()

        # ---------------------------------------------------------------
        # Validate language
        # ---------------------------------------------------------------

        if not self.is_language_supported(
            language
        ):

            _log(
                f"[TTS ERROR] "
                f"Language '{language}' "
                f"not supported."
            )

            return None

        description = (
            self.get_voice_description(
                language
            )
        )

        _log(
            f"[TTS] Language: {language}"
        )

        _log(
            f"[TTS] Text: {text}"
        )

        start_time = time.perf_counter()

        try:

            # -----------------------------------------------------------
            # DESCRIPTION TOKENIZER
            #
            # This is the critical correction.
            # -----------------------------------------------------------

            description_inputs = (
                self.description_tokenizer(
                    description,
                    return_tensors="pt",
                ).to(self.device)
            )

            # -----------------------------------------------------------
            # PROMPT TOKENIZER
            #
            # Actual speech text.
            # -----------------------------------------------------------

            prompt_inputs = (
                self.tokenizer(
                    text,
                    return_tensors="pt",
                ).to(self.device)
            )

            # -----------------------------------------------------------
            # Generation length
            # -----------------------------------------------------------

            max_tokens = (
                self._calculate_max_tokens(
                    text,
                    language,
                )
            )

            _log(
                f"[TTS] max_new_tokens={max_tokens}"
            )

            # -----------------------------------------------------------
            # Generate with raw-waveform quality check + retry
            #
            # Parler can occasionally produce an extremely weak waveform
            # for some Santali prompts when using deterministic decoding.
            # Never amplify such a waveform. Reject it and retry once with
            # sampled decoding.
            # -----------------------------------------------------------

            generation = None

            generation_attempts = [
                {
                    "name": "deterministic",
                    "do_sample": False,
                },
                {
                    "name": "sampled_retry",
                    "do_sample": True,
                    "temperature": 0.8,
                    "top_k": 50,
                    "top_p": 0.95,
                },
            ]

            for attempt_index, attempt_config in enumerate(
                generation_attempts,
                start=1,
            ):
                attempt_name = attempt_config.pop("name")

                _log(
                    "[TTS GENERATION] "
                    f"Attempt {attempt_index}/"
                    f"{len(generation_attempts)} "
                    f"({attempt_name})"
                )

                with torch.inference_mode():

                    generation = self.model.generate(
                        input_ids=(
                            description_inputs.input_ids
                        ),
                        attention_mask=(
                            description_inputs.attention_mask
                        ),

                        prompt_input_ids=(
                            prompt_inputs.input_ids
                        ),
                        prompt_attention_mask=(
                            prompt_inputs.input_ids.new_ones(
                                prompt_inputs.input_ids.shape
                            )
                        ) if prompt_inputs.attention_mask is None else (
                            prompt_inputs.attention_mask
                        ),

                        max_new_tokens=max_tokens,

                        use_cache=True,

                        **attempt_config,
                    )

                _log(
                    "[TTS GENERATION] "
                    f"type={type(generation).__name__} "
                    f"shape={getattr(generation, 'shape', None)} "
                    f"dtype={getattr(generation, 'dtype', None)}"
                )

                # -------------------------------------------------------
                # Inspect RAW audio before any normalization.
                # -------------------------------------------------------

                raw_tensor = generation.squeeze()

                if raw_tensor.dtype != torch.float32:
                    raw_tensor = raw_tensor.float()

                raw_audio = (
                    raw_tensor
                    .detach()
                    .cpu()
                    .numpy()
                    .astype(np.float32)
                )

                raw_audio = np.asarray(
                    raw_audio,
                    dtype=np.float32,
                ).squeeze()

                if raw_audio.ndim != 1:
                    raw_audio = raw_audio.reshape(-1)

                if raw_audio.size == 0:
                    raw_peak = 0.0
                    raw_rms = 0.0
                    valid_audio = False
                else:
                    raw_peak = float(
                        np.max(np.abs(raw_audio))
                    )

                    raw_rms = float(
                        np.sqrt(
                            np.mean(
                                np.square(raw_audio)
                            )
                        )
                    )

                    valid_audio = bool(
                        np.all(
                            np.isfinite(raw_audio)
                        )
                    )

                _log(
                    "[TTS QUALITY] "
                    f"attempt={attempt_index} "
                    f"peak={raw_peak:.8f} "
                    f"rms={raw_rms:.8f} "
                    f"finite={valid_audio}"
                )

                # A healthy generation observed in testing has substantially
                # higher energy. The previous broken generations were around
                # peak=0.0077 / RMS=0.0003. Do not normalize those.
                healthy = (
                    valid_audio
                    and raw_audio.size > 0
                    and raw_peak >= 0.02
                    and raw_rms >= 0.005
                )

                if healthy:
                    _log(
                        "[TTS QUALITY] "
                        f"Attempt {attempt_index} ACCEPTED"
                    )
                    break

                _log(
                    "[TTS QUALITY] "
                    f"Attempt {attempt_index} REJECTED: "
                    "waveform is empty, invalid, or too weak."
                )

                generation = None

                # Release the rejected generation before retrying.
                if "cuda" in str(self.device):
                    torch.cuda.empty_cache()

            # -----------------------------------------------------------
            # No usable waveform after all attempts
            # -----------------------------------------------------------

            if generation is None:
                raise RuntimeError(
                    "Parler-TTS failed to generate a healthy waveform "
                    "after all retry attempts."
                )

            # -----------------------------------------------------------
            # CUDA synchronization
            # -----------------------------------------------------------

            if "cuda" in str(
                self.device
            ):

                torch.cuda.synchronize(
                    self.device
                )

            # -----------------------------------------------------------
            # Prepare waveform
            # -----------------------------------------------------------

            audio_array = (
                self._prepare_audio(
                    generation
                )
            )

            # -----------------------------------------------------------
            # Native sample rate
            # -----------------------------------------------------------

            sample_rate = int(
                getattr(
                    self.model.config,
                    "sampling_rate",
                    44100,
                )
            )

            # -----------------------------------------------------------
            # Encode WAV
            # -----------------------------------------------------------

            wav_bytes = self._encode_wav(
                audio_array,
                sample_rate,
            )

            # ---------------------------------------------------------------
            # DEBUG: SAVE EXACT GENERATED WAV
            # ---------------------------------------------------------------
            # This is intentionally after WAV encoding. The saved file is
            # exactly the same byte sequence returned to the playback layer.
            #
            # Disable with:
            #   PALASH_TTS_DEBUG_WAV=0
            #
            # Change path with:
            #   PALASH_TTS_DEBUG_WAV_PATH=/some/path/file.wav
            # ---------------------------------------------------------------

            if os.environ.get("PALASH_TTS_DEBUG_WAV", "1") == "1":
                debug_wav_path = os.environ.get(
                    "PALASH_TTS_DEBUG_WAV_PATH",
                    "/tmp/palash_santali_tts.wav",
                )

                try:
                    with open(debug_wav_path, "wb") as debug_file:
                        debug_file.write(wav_bytes)

                    _log(
                        "[TTS DEBUG] WAV saved: "
                        f"{debug_wav_path} "
                        f"({len(wav_bytes)} bytes)"
                    )

                except Exception as debug_error:
                    _log(
                        "[TTS DEBUG] WAV save failed: "
                        f"{debug_error}"
                    )


            # -----------------------------------------------------------
            # Duration
            # -----------------------------------------------------------

            duration_ms = round(
                (
                    len(audio_array)
                    / sample_rate
                ) * 1000,
                2,
            )

            # -----------------------------------------------------------
            # TTS latency
            # -----------------------------------------------------------

            self.last_latency_ms = round(
                (
                    time.perf_counter()
                    - start_time
                ) * 1000,
                2,
            )

            # -----------------------------------------------------------
            # Final diagnostics
            # -----------------------------------------------------------

            peak = float(
                np.max(
                    np.abs(audio_array)
                )
            )

            rms = float(
                np.sqrt(
                    np.mean(
                        np.square(audio_array)
                    )
                )
            )

            _log(
                "[TTS] Synthesis successful "
                f"({len(text)} chars -> "
                f"{len(wav_bytes)} WAV bytes | "
                f"Sample Rate: {sample_rate} Hz | "
                f"Duration: {duration_ms} ms | "
                f"Peak: {peak:.6f} | "
                f"RMS: {rms:.6f} | "
                f"Latency: {self.last_latency_ms} ms)"
            )

            return wav_bytes

        except Exception as e:

            _log(
                f"[TTS ERROR] "
                f"Inference exception: {e}"
            )

            self.last_latency_ms = 0.0

            return None