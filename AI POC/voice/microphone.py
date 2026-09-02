import pyaudio
import time
from typing import List, Dict, Optional

class Microphone:
    """
    Abstration for a physical microphone using PyAudio.
    Supports selecting an external or built-in microphone, opening a stream, and capturing PCM frames.
    """
    def __init__(self, rate: int = 16000, channels: int = 1, chunk_size: int = 1024):
        self.rate = rate
        self.channels = channels
        self.chunk_size = chunk_size
        self.format = pyaudio.paInt16
        self.p = pyaudio.PyAudio()
        self.stream = None
        self.selected_device_id = None

    def list_audio_inputs(self) -> List[Dict[str, any]]:
        """Enumerates available microphone input devices."""
        inputs = []
        info = self.p.get_host_api_info_by_index(0)
        numdevices = info.get('deviceCount')
        
        for i in range(numdevices):
            dev_info = self.p.get_device_info_by_host_api_device_index(0, i)
            if dev_info.get('maxInputChannels') > 0:
                inputs.append({
                    "id": i,
                    "name": dev_info.get('name'),
                    "channels": dev_info.get('maxInputChannels'),
                    "sample_rate": int(dev_info.get('defaultSampleRate'))
                })
        return inputs

    def select_audio_input(self, device_id: Optional[int] = None):
        """Selects the audio input device. Uses default if None."""
        if device_id is not None:
            self.selected_device_id = device_id
        else:
            inputs = self.list_audio_inputs()
            if not inputs:
                raise RuntimeError("No microphone input devices found.")
            # Prefer external mics (often have USB or external in name), otherwise default to first
            external = [d for d in inputs if 'USB' in d['name'] or 'External' in d['name']]
            self.selected_device_id = external[0]['id'] if external else inputs[0]['id']
            
        dev_info = self.p.get_device_info_by_host_api_device_index(0, self.selected_device_id)
        print(f"Selected Microphone: {dev_info.get('name')} (ID: {self.selected_device_id})")

    def start(self):
        """Opens the microphone stream and starts recording."""
        if self.selected_device_id is None:
            self.select_audio_input()
            
        try:
            self.stream = self.p.open(
                format=self.format,
                channels=self.channels,
                rate=self.rate,
                input=True,
                input_device_index=self.selected_device_id,
                frames_per_buffer=self.chunk_size
            )
            print("Microphone stream started.")
        except Exception as e:
            raise RuntimeError(f"Failed to initialize microphone: {e}")

    def read_chunk(self) -> bytes:
        """Reads a chunk of PCM audio from the microphone."""
        if not self.stream or not self.stream.is_active():
            raise RuntimeError("Microphone stream is not active.")
        # exception_on_overflow=False prevents crashes if we don't read fast enough
        return self.stream.read(self.chunk_size, exception_on_overflow=False)

    def stop(self):
        """Cleanly stops and releases the microphone stream."""
        if self.stream:
            self.stream.stop_stream()
            self.stream.close()
            self.stream = None
            print("Microphone stream stopped.")
            
    def close(self):
        """Terminates the PyAudio instance."""
        self.stop()
        self.p.terminate()

    def __del__(self):
        self.close()
