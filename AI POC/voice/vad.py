import audioop
import time
from enum import Enum, auto

class VADState(Enum):
    IDLE = auto()
    SPEECH_DETECTED = auto()
    RECORDING = auto()
    END_OF_SPEECH = auto()

class VoiceActivityDetector:
    """
    Energy-based Voice Activity Detection.
    Detects speech start and end, managing state transitions based on configurable thresholds.
    """
    def __init__(self, 
                 energy_threshold: int = 500,
                 min_speech_ms: int = 500,
                 min_silence_ms: int = 700):
        self.energy_threshold = energy_threshold
        self.min_speech_ms = min_speech_ms
        self.min_silence_ms = min_silence_ms
        
        self.state = VADState.IDLE
        self.speech_start_time = 0.0
        self.silence_start_time = 0.0

    def process(self, chunk: bytes) -> VADState:
        """
        Processes a PCM audio chunk and updates the VAD state.
        
        Returns:
            VADState: The new state of the VAD after processing the chunk.
        """
        # audioop is used to calculate RMS energy
        rms = audioop.rms(chunk, 2)
        is_speech = rms > self.energy_threshold
        current_time = time.time()

        if self.state == VADState.IDLE:
            if is_speech:
                self.state = VADState.SPEECH_DETECTED
                self.speech_start_time = current_time
                self.silence_start_time = 0.0

        elif self.state == VADState.SPEECH_DETECTED:
            # Check if speech has lasted long enough to be considered recording
            duration = (current_time - self.speech_start_time) * 1000
            if is_speech:
                if duration >= self.min_speech_ms:
                    self.state = VADState.RECORDING
            else:
                # False alarm
                self.state = VADState.IDLE

        elif self.state == VADState.RECORDING:
            if not is_speech:
                if self.silence_start_time == 0.0:
                    self.silence_start_time = current_time
                else:
                    silence_duration = (current_time - self.silence_start_time) * 1000
                    if silence_duration >= self.min_silence_ms:
                        self.state = VADState.END_OF_SPEECH
            else:
                self.silence_start_time = 0.0

        elif self.state == VADState.END_OF_SPEECH:
            # Once END_OF_SPEECH is triggered, reset to IDLE immediately on next loop
            self.state = VADState.IDLE
            if is_speech:
                self.state = VADState.SPEECH_DETECTED
                self.speech_start_time = current_time

        return self.state

    def reset(self):
        """Resets the VAD to IDLE state."""
        self.state = VADState.IDLE
        self.speech_start_time = 0.0
        self.silence_start_time = 0.0
