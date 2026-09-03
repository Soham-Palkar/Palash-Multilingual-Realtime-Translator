import audioop
import time
from collections import deque
from enum import Enum, auto


class VADState(Enum):
    IDLE = auto()
    SPEECH_DETECTED = auto()
    RECORDING = auto()
    END_OF_SPEECH = auto()


class VoiceActivityDetector:
    """
    Real-time energy-based VAD.

    Designed for:
        16 kHz
        mono
        PCM16

    Features:
    - Noise filtering
    - Pre-roll
    - Speech confirmation
    - Silence timeout
    - Minimum utterance duration
    - Hysteresis between speech/silence thresholds
    """

    def __init__(
        self,
        energy_threshold: int = 800,
        silence_threshold: int = 500,
        min_speech_ms: int = 300,
        min_silence_ms: int = 900,
        min_utterance_ms: int = 500,
        preroll_ms: int = 300,
        sample_rate: int = 16000,
        chunk_size: int = 1024,
    ):

        self.energy_threshold = energy_threshold
        self.silence_threshold = silence_threshold

        self.min_speech_ms = min_speech_ms
        self.min_silence_ms = min_silence_ms
        self.min_utterance_ms = min_utterance_ms

        self.sample_rate = sample_rate
        self.chunk_size = chunk_size

        self.state = VADState.IDLE

        self.speech_start_time = 0.0
        self.silence_start_time = 0.0

        # -------------------------------------------------
        # PRE-ROLL
        # -------------------------------------------------

        chunk_duration_ms = (
            chunk_size / sample_rate
        ) * 1000

        self.preroll_chunks = max(
            1,
            int(preroll_ms / chunk_duration_ms)
        )

        self._preroll_buffer = deque(
            maxlen=self.preroll_chunks
        )

        # -------------------------------------------------
        # CURRENT UTTERANCE
        # -------------------------------------------------

        self._speech_audio = bytearray()

    # =====================================================
    # PROCESS AUDIO
    # =====================================================

    def process(self, chunk: bytes) -> VADState:

        if not chunk:
            return self.state

        # Keep recent audio for pre-roll.
        self._preroll_buffer.append(chunk)

        # PCM16 RMS energy.
        rms = audioop.rms(chunk, 2)

        current_time = time.monotonic()

        # -------------------------------------------------
        # IDLE
        # -------------------------------------------------

        if self.state == VADState.IDLE:

            if rms >= self.energy_threshold:

                self.state = VADState.SPEECH_DETECTED

                self.speech_start_time = current_time
                self.silence_start_time = 0.0

                self._speech_audio = bytearray()

                # Include audio just before detection.
                for previous_chunk in self._preroll_buffer:
                    self._speech_audio.extend(
                        previous_chunk
                    )

        # -------------------------------------------------
        # SPEECH DETECTED
        # -------------------------------------------------

        elif self.state == VADState.SPEECH_DETECTED:

            if rms >= self.energy_threshold:

                self._speech_audio.extend(chunk)

                speech_duration = (
                    current_time
                    - self.speech_start_time
                ) * 1000

                if speech_duration >= self.min_speech_ms:

                    self.state = VADState.RECORDING

            else:

                # Speech did not continue long enough.
                self.state = VADState.IDLE

                self.speech_start_time = 0.0
                self.silence_start_time = 0.0

                self._speech_audio.clear()

        # -------------------------------------------------
        # RECORDING
        # -------------------------------------------------

        elif self.state == VADState.RECORDING:

            self._speech_audio.extend(chunk)

            # Use lower threshold while recording.
            # This prevents normal speech pauses from
            # immediately ending the utterance.
            if rms < self.silence_threshold:

                if self.silence_start_time == 0.0:

                    self.silence_start_time = current_time

                else:

                    silence_duration = (
                        current_time
                        - self.silence_start_time
                    ) * 1000

                    utterance_duration = (
                        current_time
                        - self.speech_start_time
                    ) * 1000

                    if (
                        silence_duration >=
                        self.min_silence_ms
                        and
                        utterance_duration >=
                        self.min_utterance_ms
                    ):

                        self.state = (
                            VADState.END_OF_SPEECH
                        )

            else:

                # Speech resumed.
                self.silence_start_time = 0.0

        # -------------------------------------------------
        # END OF SPEECH
        # -------------------------------------------------

        elif self.state == VADState.END_OF_SPEECH:

            # Keep this state until the application
            # retrieves the utterance and calls reset().
            pass

        return self.state

    # =====================================================
    # GET COMPLETE UTTERANCE
    # =====================================================

    def get_speech_audio(self) -> bytes:

        return bytes(
            self._speech_audio
        )

    # =====================================================
    # RESET
    # =====================================================

    def reset(self):

        self.state = VADState.IDLE

        self.speech_start_time = 0.0
        self.silence_start_time = 0.0

        self._speech_audio.clear()

        self._preroll_buffer.clear()