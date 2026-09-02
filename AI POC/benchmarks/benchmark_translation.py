import os
import sys
import json
import statistics
import time

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from translation.translator import Translator

def run_benchmark():
    print("================================================")
    print("PALASH TRANSLATION BENCHMARK")
    print("================================================\n")
    
    print("Initializing translation engine...")
    start_init = time.time()
    
    phrase_bank_path = os.path.join(os.path.dirname(__file__), '..', 'data', 'verified_phrase_bank.json')
    translator = Translator(phrase_bank_path=phrase_bank_path)
    
    init_time_ms = int((time.time() - start_init) * 1000)
    print(f"Engine initialization time: {init_time_ms} ms\n")
    
    # Load dataset
    test_set_path = os.path.join(os.path.dirname(__file__), '..', 'data', 'classroom_test_set.json')
    try:
        with open(test_set_path, "r", encoding="utf-8") as f:
            dataset = json.load(f)
    except Exception as e:
        print(f"Failed to load dataset from {test_set_path}: {e}")
        return

    # Extract just the sentences for Neural MT benchmark (avoid verified cache for pure speed test)
    # We will modify the texts slightly so they don't match the phrase bank, ensuring we benchmark the model.
    sentences = [entry["hindi"] + " " for entry in dataset]
    
    if not sentences:
        print("No sentences found in dataset.")
        return

    print("Direction:\nHindi → Santali\n")
    print(f"Sentences:\n{len(sentences)}\n")
    
    latencies = []
    successes = 0
    failures = 0
    
    # Warmup
    print("Running warmup pass...")
    translator.translate("यह एक परीक्षण है।", "hin_Deva", "sat_Olck")
    
    print("Running benchmark...\n")
    for sentence in sentences:
        result = translator.translate(sentence, "hin_Deva", "sat_Olck")
        if result["success"]:
            latencies.append(result["latency_ms"])
            successes += 1
        else:
            failures += 1

    if not latencies:
        print("All translations failed.")
        return

    avg_latency = statistics.mean(latencies)
    latencies.sort()
    
    def percentile(data, percent):
        k = (len(data) - 1) * percent
        f = int(k)
        c = int(k) + 1
        if f == c:
            return data[f]
        d0 = data[f] * (c - k)
        d1 = data[c] * (k - f)
        return d0 + d1

    p50 = percentile(latencies, 0.5)
    p95 = percentile(latencies, 0.95)
    p99 = percentile(latencies, 0.99)
    max_latency = max(latencies)

    print(f"Average:\n{avg_latency:.2f} ms\n")
    print(f"P50:\n{p50:.2f} ms\n")
    print(f"P95:\n{p95:.2f} ms\n")
    print(f"P99:\n{p99:.2f} ms\n")
    print(f"Maximum:\n{max_latency:.2f} ms\n")
    print(f"Success:\n{successes}/{len(sentences)}\n")
    
    print("================================================")
    
    # Save the output to a text file for reference
    results_path = os.path.join(os.path.dirname(__file__), 'benchmark_results.txt')
    with open(results_path, 'w', encoding='utf-8') as f:
        f.write("PALASH TRANSLATION BENCHMARK\n")
        f.write("Direction: Hindi -> Santali\n")
        f.write(f"Sentences: {len(sentences)}\n")
        f.write(f"Average: {avg_latency:.2f} ms\n")
        f.write(f"P50: {p50:.2f} ms\n")
        f.write(f"P95: {p95:.2f} ms\n")
        f.write(f"P99: {p99:.2f} ms\n")
        f.write(f"Maximum: {max_latency:.2f} ms\n")
        f.write(f"Success: {successes}/{len(sentences)}\n")

if __name__ == "__main__":
    run_benchmark()
