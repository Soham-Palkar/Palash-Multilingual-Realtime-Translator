import threading

class AudioBuffer:
    """
    A thread-safe streaming audio buffer.
    Accumulates PCM frames and provides duration calculation and chunk retrieval.
    """
    def __init__(self, sample_rate: int = 16000, sample_width: int = 2, channels: int = 1):
        self.sample_rate = sample_rate
        self.sample_width = sample_width
        self.channels = channels
        self.buffer = bytearray()
        self.lock = threading.Lock()

    def append(self, data: bytes):
        """Appends new PCM audio frames to the buffer."""
        with self.lock:
            self.buffer.extend(data)

    def read_all(self) -> bytes:
        """Reads and consumes all available audio in the buffer."""
        with self.lock:
            data = bytes(self.buffer)
            self.buffer.clear()
            return data

    def clear(self):
        """Clears the buffer."""
        with self.lock:
            self.buffer.clear()

    def get_duration_ms(self) -> float:
        """Calculates the duration of the current buffer in milliseconds."""
        with self.lock:
            total_bytes = len(self.buffer)
            bytes_per_second = self.sample_rate * self.sample_width * self.channels
            return (total_bytes / bytes_per_second) * 1000.0

    def __len__(self):
        """Returns the length of the buffer in bytes."""
        with self.lock:
            return len(self.buffer)
