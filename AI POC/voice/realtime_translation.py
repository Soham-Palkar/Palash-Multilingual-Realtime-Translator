from datasets.features import translation
import sys
import os
import time


# ---------------------------------------------------------
# PROJECT PATH
# ---------------------------------------------------------

VOICE_DIR = os.path.dirname(os.path.abspath(__file__))
AI_POC_DIR = os.path.dirname(VOICE_DIR)

if AI_POC_DIR not in sys.path:
    sys.path.insert(0, AI_POC_DIR)


# ---------------------------------------------------------
# PALASH COMPONENTS
# ---------------------------------------------------------

from voice.microphone import Microphone
from voice.vad import VoiceActivityDetector, VADState
from voice.wsl_asr_client import WSLIndicConformerASR


# ---------------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------------

SAMPLE_RATE = 16000
CHANNELS = 1
CHUNK_SIZE = 1024

# Verified working microphone
MIC_DEVICE_ID = 1

# WSL Python environment
WSL_PYTHON = (
    "/home/soham_palkar/miniconda3/"
    "envs/palash-translate/bin/python"
)

# WSL ASR worker
WSL_WORKER = (
    "/mnt/c/Users/Soham Palkar/"
    "OneDrive/Desktop/"
    "Palash-Multilingual-Realtime-Translator/"
    "AI POC/voice/wsl_asr_worker.py"
)


# ---------------------------------------------------------
# MAIN
# ---------------------------------------------------------

def main():

    print("=" * 70)
    print("PALASH REAL-TIME VOICE TRANSLATION")
    print("=" * 70)

    microphone = None
    asr = None

    try:

        # =================================================
        # MICROPHONE
        # =================================================

        microphone = Microphone(
            rate=SAMPLE_RATE,
            channels=CHANNELS,
            chunk_size=CHUNK_SIZE
        )

        microphone.select_audio_input(
            device_id=MIC_DEVICE_ID
        )

        # =================================================
        # VAD
        # =================================================

        vad = VoiceActivityDetector(
            energy_threshold=800,
            silence_threshold=500,
            min_speech_ms=300,
            min_silence_ms=900,
            min_utterance_ms=500,
            preroll_ms=300,
            sample_rate=SAMPLE_RATE,
            chunk_size=CHUNK_SIZE
        )

        # =================================================
        # WSL ASR + TRANSLATION
        # =================================================

        asr = WSLIndicConformerASR(
            wsl_script=WSL_WORKER,
            wsl_python=WSL_PYTHON,
            sample_rate=SAMPLE_RATE
        )

        # =================================================
        # START MICROPHONE
        # =================================================

        microphone.start()

        # Start persistent WSL worker.
        # IndicConformer + Translator load only once.
        asr.start_stream()

        print()
        print("=" * 70)
        print("PALASH IS READY")
        print("=" * 70)
        print()
        print("Speak Hindi into the microphone.")
        print("Speak one sentence and then pause.")
        print("Press Ctrl+C to stop.")
        print()
        print("Listening...")

        # =================================================
        # SPEECH STATE
        # =================================================

        speech_active = False

        # =================================================
        # MAIN AUDIO LOOP
        # =================================================

        while True:

            # ---------------------------------------------
            # Read REAL microphone audio
            # ---------------------------------------------

            chunk = microphone.read_chunk()

            if not chunk:
                continue

            # ---------------------------------------------
            # VAD
            # ---------------------------------------------

            vad_start = time.time()

            state = vad.process(chunk)

            vad_ms = (
                time.time() - vad_start
            ) * 1000

            # =================================================
            # SPEECH DETECTED
            # =================================================

            if state == VADState.SPEECH_DETECTED:

                # Print ONLY once when speech starts.
                if not speech_active:

                    speech_active = True

                    print()
                    print(
                        "[VAD] Speech detected..."
                    )

            # =================================================
            # RECORDING
            # =================================================

            elif state == VADState.RECORDING:

                # VAD is already collecting the audio.
                #
                # DO NOT call:
                #     asr.accept_audio(chunk)
                #
                # here.
                #
                # The complete utterance will be obtained
                # from vad.get_speech_audio() after silence.

                pass

            # =================================================
            # END OF SPEECH
            # =================================================

            elif state == VADState.END_OF_SPEECH:

                speech_active = False

                print(
                    "[VAD] Speech ended."
                )

                # -----------------------------------------
                # Get COMPLETE utterance
                # -----------------------------------------

                speech_audio = (
                    vad.get_speech_audio()
                )

                if not speech_audio:

                    print(
                        "[VAD] No audio captured."
                    )

                    vad.reset()

                    print(
                        "Listening..."
                    )

                    continue

                print(
                    f"[VAD] Captured "
                    f"{len(speech_audio)} bytes"
                )

                # -----------------------------------------
                # ASR
                # -----------------------------------------

                print(
                    "[ASR] Processing..."
                )

                asr_start = time.time()

                # Start a fresh ASR utterance.
                asr.start_stream()

                # Send complete audio only once.
                asr.accept_audio(
                    speech_audio
                )

                # IndicConformer inference
                result = (
                    asr.get_final_result()
                )

                asr_ms = (
                    time.time() - asr_start
                ) * 1000

                recognized_text = (
                    result.text.strip()
                )

                # =================================================
                # ASR RESULT
                # =================================================

                if not recognized_text:

                    print()
                    print(
                        "[ASR] No speech recognized."
                    )

                else:

                    print()
                    print(
                        f"[Hindi] "
                        f"{recognized_text}"
                    )

                    # ---------------------------------------------
                    # TRANSLATION
                    # ---------------------------------------------

                    translation = (
                        asr.last_translation
                    )

                    if translation:

                        if translation.get(
                            "success",
                            False
                        ):

                            print(f"[Hindi] {result.text}")
                            print(f"[Santali] {translation.get('translated_text', '')}")
                            print(f"[Translation source] {translation.get('translation_source', '')}")
                            print(f"[Translation latency] {translation.get('translation_latency_ms', 0)} ms")

                    else:

                        print(
                            "[Translation] "
                            "No translation result."
                        )

                    # ---------------------------------------------
                    # LATENCY
                    # ---------------------------------------------

                    print(
                        f"[VAD latency] "
                        f"{vad_ms:.2f} ms"
                    )

                    print(
                        f"[ASR + Translation latency] "
                        f"{asr_ms:.0f} ms"
                    )

                # ---------------------------------------------
                # RESET
                # ---------------------------------------------

                asr.stop_stream()

                vad.reset()

                speech_active = False

                print()
                print(
                    "Listening..."
                )

    # =====================================================
    # CTRL+C
    # =====================================================

    except KeyboardInterrupt:

        print()
        print(
            "[Pipeline] Ctrl+C received."
        )

        print(
            "[Pipeline] Stopping..."
        )

    # =====================================================
    # ERROR
    # =====================================================

    except Exception as e:

        print()
        print(
            "[Pipeline] ERROR:"
        )

        print(
            f"{type(e).__name__}: {e}"
        )

    # =====================================================
    # CLEANUP
    # =====================================================

    finally:

        print(
            "[Pipeline] Cleaning up..."
        )

        # ---------------------------------------------
        # Stop ASR worker
        # ---------------------------------------------

        if asr is not None:

            try:

                asr.close()

            except Exception as e:

                print(
                    f"[ASR] Cleanup warning: {e}"
                )

        # ---------------------------------------------
        # Stop microphone
        # ---------------------------------------------

        if microphone is not None:

            try:

                microphone.stop()

            except Exception as e:

                print(
                    f"[Microphone] Stop warning: {e}"
                )

            try:

                microphone.close()

            except Exception as e:

                print(
                    f"[Microphone] Cleanup warning: {e}"
                )

        print(
            "[Pipeline] Stopped."
        )


# ---------------------------------------------------------
# ENTRY POINT
# ---------------------------------------------------------

if __name__ == "__main__":
    main()