"""
PALASH Voice Translation Pipeline Latency Benchmark

Measures empirical sub-stage latencies across 5 warm classroom utterances:
- ASR Latency (using real Hindi speech sample test_hindi.wav)
- Translation Latency (IndicTrans2 hin_Deva -> sat_Olck)
- TTS Latency (Indic Parler-TTS sat_Olck)
- Speech-End to Target Audio Playback Start (Primary Metric)
- Total Pipeline Latency

Reports Cold Start, Warm Inference, Average, P50, P95, and Maximum metrics.
"""

import os
import sys
import json
import time
import wave
import statistics

# Project path setup
BENCHMARKS_DIR = os.path.dirname(os.path.abspath(__file__))
AI_POC_DIR = os.path.dirname(BENCHMARKS_DIR)

if AI_POC_DIR not in sys.path:
    sys.path.insert(0, AI_POC_DIR)

from voice.wsl_asr_client import WSLIndicConformerASR
from voice.model_manager import ModelManager

# Test Configuration
WSL_PYTHON = "/home/soham_palkar/miniconda3/envs/palash-translate/bin/python"
WSL_WORKER = (
    "/mnt/c/Users/Soham Palkar/OneDrive/Desktop/"
    "Palash-Multilingual-Realtime-Translator/"
    "AI POC/voice/wsl_asr_worker.py"
)
TEST_WAV = os.path.join(AI_POC_DIR, "test_hindi.wav")

TEST_SENTENCES = [
    "नमस्ते बच्चों।",
    "मेरा नाम सोहम है।",
    "बच्चों, इन फलों को गिनो।",
    "कैसे हो?",
    "अपनी किताब खोलो।",
    "आज हम कक्षा में फलों के बारे में सीखेंगे। आप सभी ध्यान से इन चित्रों को देखें।",
]


def load_test_wav_bytes(wav_path: str) -> bytes:
    """Load PCM16 mono 16kHz raw bytes from test WAV file."""
    if not os.path.exists(wav_path):
        print(f"[BENCHMARK WARNING] Test WAV not found at: {wav_path}")
        return b""

    with wave.open(wav_path, "rb") as wf:
        return wf.readframes(wf.getnframes())


def run_voice_pipeline_benchmark():
    print("=" * 70)
    print("PALASH VOICE TRANSLATION PIPELINE LATENCY BENCHMARK")
    print("=" * 70)

    # 1. Offline Model Check
    manager = ModelManager()
    manager.check_offline_readiness()

    # Load audio payload
    audio_payload = load_test_wav_bytes(TEST_WAV)
    if audio_payload:
        print(f"[BENCHMARK] Loaded test WAV audio payload: {len(audio_payload)} bytes ({len(audio_payload) / 32000:.2f} s)")

    print("\n[BENCHMARK] Initializing persistent WSL Worker (Cold Start)...")
    t_start = time.perf_counter()

    asr_client = WSLIndicConformerASR(
        wsl_script=WSL_WORKER,
        wsl_python=WSL_PYTHON,
        sample_rate=16000,
        source_language="hin_Deva",
        target_language="sat_Olck",
    )

    try:
        asr_client.start_stream()
        cold_start_ms = round((time.perf_counter() - t_start) * 1000, 2)
        print(f"[BENCHMARK] Cold Start Load Time: {cold_start_ms} ms\n")

        # Warmup run
        print("[BENCHMARK] Executing 1 warmup utterance...")
        if audio_payload:
            asr_client.accept_audio(audio_payload)
            asr_client.get_final_result(enable_tts=True)
        print("[BENCHMARK] Warmup complete.\n")

        results = []

        print("=" * 80)
        print(f"{'Utt #':<6} | {'ASR (ms)':<9} | {'Trans (ms)':<10} | {'TTS (ms)':<9} | {'End2Start (s)':<13} | {'E2E (ms)':<9} | {'Status':<6}")
        print("-" * 80)

        for idx, text in enumerate(TEST_SENTENCES, start=1):
            # Benchmark Warm Utterance Pipeline
            speech_end_t = time.perf_counter()

            asr_client.start_stream()

            # Pass real audio chunk if available
            if audio_payload:
                asr_client.accept_audio(audio_payload)

            res = asr_client.get_final_result(enable_tts=True)
            playback_start_t = time.perf_counter()

            meta = asr_client.last_result_metadata

            asr_ms = meta.get("asr_latency_ms", 0.0)
            trans_ms = meta.get("translation_latency_ms", 0.0)
            tts_ms = meta.get("tts_latency_ms", 0.0)
            
            # Primary user-visible metric: speech_end -> target audio playback start
            end_to_start_s = round(playback_start_t - speech_end_t, 3)
            total_e2e_ms = round(asr_ms + trans_ms + tts_ms, 2)

            status = "PASS" if (asr_ms > 0 or meta.get("success")) else "WARN"

            results.append({
                "id": idx,
                "text": text,
                "recognized": res.text,
                "translated": meta.get("translated_text", ""),
                "asr_ms": asr_ms,
                "trans_ms": trans_ms,
                "tts_ms": tts_ms,
                "end_to_start_s": end_to_start_s,
                "total_e2e_ms": total_e2e_ms,
                "status": status
            })

            print(f"{idx:<6} | {asr_ms:<9.1f} | {trans_ms:<10.1f} | {tts_ms:<9.1f} | {end_to_start_s:<13.3f} | {total_e2e_ms:<9.1f} | {status:<6}")

        print("=" * 80)

        # Statistical Calculations
        asr_latencies = [r["asr_ms"] for r in results]
        trans_latencies = [r["trans_ms"] for r in results]
        tts_latencies = [r["tts_ms"] for r in results]
        end_to_start_times = [r["end_to_start_s"] for r in results]
        e2e_latencies = [r["total_e2e_ms"] for r in results]

        def calc_stats(arr):
            arr_sorted = sorted(arr)
            n = len(arr_sorted)
            avg = round(statistics.mean(arr_sorted), 2)
            p50 = round(arr_sorted[n // 2], 2)
            p95 = round(arr_sorted[int(n * 0.95)], 2) if n >= 5 else round(max(arr_sorted), 2)
            max_val = round(max(arr_sorted), 2)
            return avg, p50, p95, max_val

        avg_e2s, p50_e2s, p95_e2s, max_e2s = calc_stats(end_to_start_times)
        avg_asr, p50_asr, p95_asr, max_asr = calc_stats(asr_latencies)
        avg_trans, p50_trans, p95_trans, max_trans = calc_stats(trans_latencies)
        avg_tts, p50_tts, p95_tts, max_tts = calc_stats(tts_latencies)
        avg_e2e, p50_e2e, p95_e2e, max_e2e = calc_stats(e2e_latencies)

        print("\n" + "=" * 80)
        print("SUMMARY STATISTICAL METRICS:")
        print("=" * 80)
        print(f"Metric                       | Average   | P50       | P95       | Maximum  ")
        print("-" * 80)
        print(f"ASR Latency (ms)             | {avg_asr:<9} | {p50_asr:<9} | {p95_asr:<9} | {max_asr:<9}")
        print(f"Translation Latency (ms)     | {avg_trans:<9} | {p50_trans:<9} | {p95_trans:<9} | {max_trans:<9}")
        print(f"TTS Latency (ms)             | {avg_tts:<9} | {p50_tts:<9} | {p95_tts:<9} | {max_tts:<9}")
        print(f"Speech-End to Playback (s)   | {avg_e2s:<9.3f} | {p50_e2s:<9.3f} | {p95_e2s:<9.3f} | {max_e2s:<9.3f}")
        print(f"Total Pipeline E2E (ms)      | {avg_e2e:<9} | {p50_e2e:<9} | {p95_e2e:<9} | {max_e2e:<9}")
        print("=" * 80)

        target_met = "YES" if p95_e2s <= 5.0 else "NO"
        print(f"\nPrimary Target (Speech-End to Playback <= 5.0s) Achieved: {target_met}")

        # Save benchmark report to file
        output_report_path = os.path.join(BENCHMARKS_DIR, "benchmark_results.json")
        report_data = {
            "cold_start_ms": cold_start_ms,
            "warm_utterance_count": len(results),
            "metrics": {
                "asr_ms": {"avg": avg_asr, "p50": p50_asr, "p95": p95_asr, "max": max_asr},
                "trans_ms": {"avg": avg_trans, "p50": p50_trans, "p95": p95_trans, "max": max_trans},
                "tts_ms": {"avg": avg_tts, "p50": p50_tts, "p95": p95_tts, "max": max_tts},
                "speech_end_to_playback_s": {"avg": avg_e2s, "p50": p50_e2s, "p95": p95_e2s, "max": max_e2s},
                "total_e2e_ms": {"avg": avg_e2e, "p50": p50_e2e, "p95": p95_e2e, "max": max_e2e},
            },
            "target_met": target_met,
            "utterances": results
        }
        with open(output_report_path, "w", encoding="utf-8") as f:
            json.dump(report_data, f, indent=2, ensure_ascii=False)

        print(f"Benchmark results saved to: {output_report_path}")

    finally:
        asr_client.close()


if __name__ == "__main__":
    run_voice_pipeline_benchmark()
