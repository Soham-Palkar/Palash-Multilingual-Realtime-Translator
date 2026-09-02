"""
PALASH Translation Model Optimization Benchmark

Investigates PyTorch FP32, Dynamic INT8 quantization, CTranslate2, and ONNX export.
Records disk size, RAM, latency, and output quality for each backend.

IMPORTANT: Not all backends may succeed. Failed experiments are documented.
"""
import os
import sys
import json
import time
import statistics
import traceback

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

import torch
from transformers import AutoModelForSeq2SeqLM, AutoTokenizer
from IndicTransToolkit.processor import IndicProcessor

MODEL_NAME = "ai4bharat/indictrans2-indic-indic-dist-320M"
SRC_LANG = "hin_Deva"
TGT_LANG = "sat_Olck"

TEST_SENTENCES = [
    "बच्चों, इन फलों को गिनो।",
    "अपनी किताब खोलो।",
    "बैठ जाओ।",
    "ध्यान से सुनो।",
    "अपना नाम बताओ।",
]


def get_process_ram_mb():
    """Returns current process RSS in MB."""
    try:
        import psutil
        process = psutil.Process(os.getpid())
        return round(process.memory_info().rss / (1024 * 1024), 2)
    except ImportError:
        return "TBD (install psutil)"


def translate_pytorch(model, tokenizer, ip, sentences, src_lang, tgt_lang, device):
    """Translates using the standard PyTorch model."""
    batch = ip.preprocess_batch(sentences, src_lang=src_lang, tgt_lang=tgt_lang)
    inputs = tokenizer(batch, truncation=True, padding="longest",
                       return_tensors="pt", return_attention_mask=True).to(device)
    with torch.no_grad():
        generated = model.generate(**inputs, use_cache=True, min_length=0,
                                   max_length=256, num_beams=5, num_return_sequences=1)
    translations = tokenizer.batch_decode(generated, skip_special_tokens=True,
                                          clean_up_tokenization_spaces=True)
    return ip.postprocess_batch(translations, lang=tgt_lang)


def benchmark_backend(name, translate_fn, sentences, warmup=2, runs=5):
    """Runs a translate function multiple times and records latency stats."""
    print(f"\n--- {name} ---")
    
    # Warmup
    for _ in range(warmup):
        try:
            translate_fn(sentences[:1])
        except Exception:
            pass
    
    latencies = []
    outputs = []
    for i in range(runs):
        t0 = time.time()
        try:
            result = translate_fn(sentences)
            latencies.append((time.time() - t0) * 1000)
            if i == 0:
                outputs = result
        except Exception as e:
            print(f"  Run {i+1} FAILED: {e}")
    
    if not latencies:
        return {"status": "FAILED", "outputs": []}
    
    latencies.sort()
    stats = {
        "status": "OK",
        "runs": len(latencies),
        "avg_ms": round(statistics.mean(latencies), 2),
        "p50_ms": round(latencies[len(latencies) // 2], 2),
        "p95_ms": round(latencies[int(len(latencies) * 0.95)], 2) if len(latencies) >= 5 else "N/A",
        "max_ms": round(max(latencies), 2),
        "ram_mb": get_process_ram_mb(),
        "outputs": outputs,
    }
    for k, v in stats.items():
        if k != "outputs":
            print(f"  {k}: {v}")
    return stats


def run_optimization_benchmark():
    print("=" * 60)
    print("PALASH MODEL OPTIMIZATION BENCHMARK")
    print("=" * 60)

    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"Device: {device}\n")

    results = {}

    # =============================================
    # 1. PyTorch FP32 Baseline
    # =============================================
    print("Loading PyTorch FP32 model...")
    ram_before = get_process_ram_mb()
    tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME, trust_remote_code=True)
    model_fp32 = AutoModelForSeq2SeqLM.from_pretrained(MODEL_NAME, trust_remote_code=True)
    model_fp32 = model_fp32.to(device)
    model_fp32.eval()
    ip = IndicProcessor(inference=True)
    ram_after = get_process_ram_mb()
    print(f"RAM before load: {ram_before} MB")
    print(f"RAM after load: {ram_after} MB")

    def pytorch_fp32_fn(sents):
        return translate_pytorch(model_fp32, tokenizer, ip, sents, SRC_LANG, TGT_LANG, device)

    results["pytorch_fp32"] = benchmark_backend("PyTorch FP32", pytorch_fp32_fn, TEST_SENTENCES)

    baseline_outputs = results["pytorch_fp32"].get("outputs", [])

    # =============================================
    # 2. PyTorch Dynamic INT8 Quantization (CPU)
    # =============================================
    print("\n\nAttempting PyTorch Dynamic INT8 Quantization...")
    try:
        model_int8 = AutoModelForSeq2SeqLM.from_pretrained(MODEL_NAME, trust_remote_code=True)
        model_int8.eval()
        model_int8 = torch.quantization.quantize_dynamic(
            model_int8, {torch.nn.Linear}, dtype=torch.qint8
        )
        ram_int8 = get_process_ram_mb()
        print(f"RAM after INT8 load: {ram_int8} MB")

        def pytorch_int8_fn(sents):
            return translate_pytorch(model_int8, tokenizer, ip, sents, SRC_LANG, TGT_LANG, "cpu")

        results["pytorch_int8"] = benchmark_backend("PyTorch INT8 (CPU)", pytorch_int8_fn, TEST_SENTENCES)
    except Exception as e:
        print(f"  INT8 quantization FAILED: {e}")
        traceback.print_exc()
        results["pytorch_int8"] = {"status": "FAILED", "error": str(e)}

    # =============================================
    # 3. CTranslate2 Conversion
    # =============================================
    print("\n\nAttempting CTranslate2 conversion...")
    try:
        import ctranslate2
        ct2_output_dir = os.path.join(os.path.dirname(__file__), '..', 'models', 'ct2_indictrans2')
        
        if not os.path.exists(ct2_output_dir):
            from ctranslate2.converters import TransformersConverter
            converter = TransformersConverter(MODEL_NAME)
            converter.convert(ct2_output_dir, quantization="float32")
            print(f"  Converted to CTranslate2 at: {ct2_output_dir}")
        else:
            print(f"  Using existing CTranslate2 model at: {ct2_output_dir}")

        ct2_translator = ctranslate2.Translator(ct2_output_dir, device="cpu")
        ram_ct2 = get_process_ram_mb()
        print(f"  RAM after CTranslate2 load: {ram_ct2} MB")

        def ct2_fn(sents):
            batch = ip.preprocess_batch(sents, src_lang=SRC_LANG, tgt_lang=TGT_LANG)
            tokenized = [tokenizer.tokenize(s) for s in batch]
            ct2_results = ct2_translator.translate_batch(tokenized)
            decoded = [tokenizer.convert_tokens_to_string(r.hypotheses[0]) for r in ct2_results]
            return ip.postprocess_batch(decoded, lang=TGT_LANG)

        results["ctranslate2_fp32"] = benchmark_backend("CTranslate2 FP32", ct2_fn, TEST_SENTENCES)

    except ImportError:
        print("  CTranslate2 not installed. Install with 'pip install ctranslate2'.")
        results["ctranslate2_fp32"] = {"status": "FAILED", "error": "ctranslate2 not installed"}
    except Exception as e:
        print(f"  CTranslate2 conversion/inference FAILED: {e}")
        traceback.print_exc()
        results["ctranslate2_fp32"] = {"status": "FAILED", "error": str(e)}

    # =============================================
    # 4. ONNX Export
    # =============================================
    print("\n\nAttempting ONNX export...")
    try:
        from optimum.onnxruntime import ORTModelForSeq2SeqLM
        onnx_output_dir = os.path.join(os.path.dirname(__file__), '..', 'models', 'onnx_indictrans2')

        if not os.path.exists(onnx_output_dir):
            onnx_model = ORTModelForSeq2SeqLM.from_pretrained(MODEL_NAME, export=True,
                                                               trust_remote_code=True)
            onnx_model.save_pretrained(onnx_output_dir)
            onnx_tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME, trust_remote_code=True)
            onnx_tokenizer.save_pretrained(onnx_output_dir)
            print(f"  Exported to ONNX at: {onnx_output_dir}")
        else:
            onnx_model = ORTModelForSeq2SeqLM.from_pretrained(onnx_output_dir)
            print(f"  Using existing ONNX model at: {onnx_output_dir}")

        ram_onnx = get_process_ram_mb()
        print(f"  RAM after ONNX load: {ram_onnx} MB")

        def onnx_fn(sents):
            batch = ip.preprocess_batch(sents, src_lang=SRC_LANG, tgt_lang=TGT_LANG)
            inputs = tokenizer(batch, truncation=True, padding="longest",
                               return_tensors="pt", return_attention_mask=True)
            generated = onnx_model.generate(**inputs, min_length=0, max_length=256,
                                            num_beams=5, num_return_sequences=1)
            translations = tokenizer.batch_decode(generated, skip_special_tokens=True,
                                                  clean_up_tokenization_spaces=True)
            return ip.postprocess_batch(translations, lang=TGT_LANG)

        results["onnx_fp32"] = benchmark_backend("ONNX FP32", onnx_fn, TEST_SENTENCES)

    except ImportError:
        print("  optimum/onnxruntime not installed. Install with 'pip install optimum[onnxruntime]'.")
        results["onnx_fp32"] = {"status": "FAILED", "error": "optimum not installed"}
    except Exception as e:
        print(f"  ONNX export/inference FAILED: {e}")
        traceback.print_exc()
        results["onnx_fp32"] = {"status": "FAILED", "error": str(e)}

    # =============================================
    # Quality Comparison
    # =============================================
    print("\n\n" + "=" * 60)
    print("QUALITY COMPARISON")
    print("=" * 60)

    if baseline_outputs:
        for backend_name, data in results.items():
            outputs = data.get("outputs", [])
            if not outputs:
                print(f"\n{backend_name}: No outputs to compare.")
                continue
            print(f"\n{backend_name}:")
            for i, (baseline, optimized) in enumerate(zip(baseline_outputs, outputs)):
                match = "EXACT MATCH" if baseline == optimized else "DIFFERS"
                print(f"  [{i}] Baseline: {baseline}")
                print(f"       Optimized: {optimized}")
                print(f"       -> {match}")

    # =============================================
    # Summary Table
    # =============================================
    print("\n\n" + "=" * 60)
    print("SUMMARY TABLE")
    print("=" * 60)
    print(f"{'Backend':<25} {'Status':<10} {'Avg (ms)':<12} {'P50 (ms)':<12} {'RAM (MB)':<12}")
    print("-" * 71)
    for name, data in results.items():
        status = data.get("status", "?")
        avg = data.get("avg_ms", "N/A")
        p50 = data.get("p50_ms", "N/A")
        ram = data.get("ram_mb", "N/A")
        print(f"{name:<25} {status:<10} {str(avg):<12} {str(p50):<12} {str(ram):<12}")

    # Save results
    results_path = os.path.join(os.path.dirname(__file__), 'optimization_results.json')
    serializable = {}
    for k, v in results.items():
        entry = {kk: vv for kk, vv in v.items() if kk != "outputs"}
        serializable[k] = entry
    with open(results_path, 'w', encoding='utf-8') as f:
        json.dump(serializable, f, indent=2, ensure_ascii=False)
    print(f"\nResults saved to: {results_path}")


if __name__ == "__main__":
    run_optimization_benchmark()
