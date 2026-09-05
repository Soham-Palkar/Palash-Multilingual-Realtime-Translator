PALASH Multilingual Realtime Translator

Developer Setup Guide

This guide is for team members setting up the PALASH project on their own PC.

The commands below do not depend on any specific developer's username,
OneDrive path, or local folder.

1. Requirements

Each developer needs:

Windows 10/11

WSL2

Ubuntu on WSL2

NVIDIA GPU with working WSL CUDA support for the current AI inference setup

Git

Python 3.10/3.11

Internet connection for first-time package/model downloads

Physical microphone

Speakers/headphones

The current voice pipeline uses Windows for physical microphone/audio
handling and WSL2 for AI inference.

2. Install Git

Install Git for Windows:

https://git-scm.com/download/win

Verify:

git --version

3. Clone the Project

Choose any folder you want.

Example:

cd Desktop
git clone <REPOSITORY_URL>
cd Palash-Multilingual-Realtime-Translator

Check:

git status

4. Create a Git Branch

Do not work directly on main.

Create your own branch:

git checkout -b feature/<your-name>

Example:

git checkout -b feature/rahul-voice-testing

5. Windows Python Environment

Check Python:

python --version

Create the environment:

python -m venv .venv

Activate:

.venv\Scripts\activate

Verify:

python --version

6. Install Windows Dependencies

Install the packages required for microphone/audio handling:

pip install numpy
pip install sounddevice
pip install soundfile
pip install pyaudio

If the repository contains a requirements.txt, install it as well:

pip install -r requirements.txt

7. Test Windows Audio Devices

Run:

python -c "import sounddevice as sd; print(sd.query_devices())"

You should see your physical microphone and an output device.

For example:

Microphone
Headphones
Speakers

The exact device numbers will be different on every PC.

Do not copy another developer's device number.

8. Install WSL2

Open PowerShell as Administrator:

wsl --install

Restart the PC if Windows asks you to.

After restarting:

wsl --status

Check installed distributions:

wsl --list --verbose

Ubuntu should be installed and using WSL2.

If necessary:

wsl --set-default-version 2

9. Open WSL2

wsl

Update Ubuntu:

sudo apt update
sudo apt upgrade -y

Install basic tools:

sudo apt install -y git build-essential python3 python3-venv python3-pip ffmpeg

10. Access the Project from WSL

The Windows drives are available under /mnt.

If the project was cloned to the Windows Desktop, find it using:

cd /mnt/c/Users/$USER/Desktop/Palash-Multilingual-Realtime-Translator

If your Windows username/path differs, use the actual location of your
project. Do not copy another developer's absolute path.

You can also locate the project manually:

ls /mnt/c/Users

11. Create WSL Python Environment

From the project directory:

python3 -m venv .venv-wsl

Activate:

source .venv-wsl/bin/activate

Verify:

python --version

12. Install PyTorch

The project requires a CUDA-enabled PyTorch installation for the current
WSL inference setup.

Install the PyTorch version specified by the project's dependency files.

Then verify:

python -c "import torch; print('PyTorch:', torch.__version__); print('CUDA available:', torch.cuda.is_available()); print('GPU:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'N/A')"

Expected:

CUDA available: True

If CUDA is False, do not continue with performance testing until the
WSL/NVIDIA setup is fixed.

13. Verify NVIDIA GPU from WSL

Run:

nvidia-smi

A working setup should display the NVIDIA GPU.

If nvidia-smi does not work, check the NVIDIA driver and WSL CUDA setup
before running the AI pipeline.

14. Install NeMo / IndicConformer Dependencies

The current Hindi ASR uses AI4Bharat IndicConformer:

ai4bharat/indicconformer_stt_hi_hybrid_rnnt_large

The repository's NeMo setup should be installed according to the version
used by the project.

Verify:

python -c "import nemo; print('NeMo import OK')"

If the project already contains the required NeMo setup, use that setup
instead of installing an unrelated latest version.

15. Hugging Face Login

Some AI4Bharat models may require accepting their Hugging Face terms before
they can be downloaded.

Install the Hugging Face CLI if required:

pip install huggingface_hub

Login:

hf auth login

Paste your Hugging Face access token when requested.

Do not commit the token to GitHub.

16. IndicTrans2

Current translation model:

ai4bharat/indictrans2-indic-indic-dist-320M

Language codes:

Hindi   = hin_Deva
Santali = sat_Olck

The model is downloaded automatically from Hugging Face when required by
the translation module.

Test:

python -c "from translation.translator import Translator; t=Translator(); print(t.translate('नमस्ते बच्चों', 'hin_Deva', 'sat_Olck'))"

A Santali translation should be returned.

17. Indic Parler-TTS

Current TTS model:

ai4bharat/indic-parler-tts

Current project support:

Hindi
Santali

Install the TTS package if it is not already included in the project's
requirements:

pip install parler-tts

Verify:

python -c "import parler_tts; print('Parler-TTS import OK')"

The first TTS run may take a long time because the model needs to be
downloaded and loaded.

18. Test Santali TTS

From WSL:

python -c "from voice.indic_parler_tts import IndicParlerTTSBackend; t=IndicParlerTTSBackend(); x=t.synthesize('ᱦᱮᱞᱳ', 'sat_Olck'); print('WAV bytes:', len(x) if x else None)"

If successful, the command should return a non-zero WAV byte count.

19. Test the Physical Microphone

The microphone must be a real physical microphone.

List devices:

python -c "import sounddevice as sd; print(sd.query_devices())"

Run the project's microphone test if available:

python voice/microphone.py

If the repository has a dedicated microphone/VAD test script, use that
script instead.

20. Start the WSL Worker

Open Terminal 1.

wsl

Inside WSL:

cd /path/to/Palash-Multilingual-Realtime-Translator
source .venv-wsl/bin/activate
python wsl_asr_worker.py

Wait for:

[WORKER] Ready

Keep this terminal open.

21. Start the Windows Realtime Pipeline

Open Terminal 2 — PowerShell.

Go to the project:

cd path\to\Palash-Multilingual-Realtime-Translator

Activate:

.venv\Scripts\activate

Run the project's realtime pipeline:

python <REALTIME_PIPELINE_FILE>.py

Replace <REALTIME_PIPELINE_FILE>.py with the actual filename in the
repository.

Expected:

[PIPELINE] Ready. Listening on physical microphone...

Speak Hindi into the microphone.

Expected:

Hindi Speech
    ↓
VAD
    ↓
IndicConformer ASR
    ↓
Hindi Text
    ↓
IndicTrans2
    ↓
Santali Text
    ↓
Indic Parler-TTS
    ↓
Santali Audio

22. Important: Do Not Use Another Developer's Paths

Never copy paths such as:

C:\Users\Someone\...

or:

/mnt/c/Users/Someone/...

Each developer's Windows username and project location will be different.

Use:

Get-Location

in PowerShell and:

pwd

in WSL to find your own project path.

23. Important: Do Not Commit AI Models

Do NOT commit:

*.nemo
*.safetensors
*.bin
*.ckpt
*.wav
model caches
Hugging Face cache
.venv
.venv-wsl
.env

Models should be downloaded locally.

Check before committing:

git status

24. Debug TTS WAV

Enable debug WAV:

$env:PALASH_TTS_DEBUG_WAV="1"

The WSL worker saves:

/tmp/palash_santali_tts.wav

Copy it to your Windows Desktop if required:

cp /tmp/palash_santali_tts.wav /mnt/c/Users/<YOUR_WINDOWS_USERNAME>/Desktop/palash_santali_tts.wav

Play it using your own output device.

List your devices:

python -c "import sounddevice as sd; print(sd.query_devices())"

Do not assume device 4 exists on another PC.

25. Troubleshooting

Python command not found

Check:

python --version

and:

python3 --version

Use the correct command for the environment.

CUDA is False

Run:

nvidia-smi

Then:

python -c "import torch; print(torch.cuda.is_available())"

The current AI inference setup requires working CUDA for the expected
performance.

Microphone not detected

Run:

python -c "import sounddevice as sd; print(sd.query_devices())"

Check Windows microphone permissions and make sure the physical microphone
is connected.

WSL worker does not start

Check:

python --version
python -c "import torch; print(torch.cuda.is_available())"
python -c "import nemo; print('NeMo OK')"

Then run:

python wsl_asr_worker.py

Read the first error instead of repeatedly restarting the complete pipeline.

TTS produces grrrrr / noise

Save the generated WAV and play the WAV directly.

If the saved WAV itself contains noise, the problem is in TTS generation.

If the saved WAV contains clear speech but the live speaker output is wrong,
the problem is in the audio-output path.

VAD does not stop

The VAD should transition:

IDLE
 ↓
SPEECH_DETECTED
 ↓
RECORDING
 ↓
END_OF_SPEECH
 ↓
PROCESSING
 ↓
IDLE

After the speaker stops, silence should cause the current utterance to end.

Do not solve a VAD problem by modifying ASR or TTS.

26. Git Workflow for Team Members

Get the latest changes:

git checkout main
git pull origin main

Create your branch:

git checkout -b feature/<your-name>

Work on your assigned files.

Check changes:

git status

Add:

git add .

Commit:

git commit -m "feat: <short description>"

Push:

git push -u origin feature/<your-name>

Create a Pull Request on GitHub.

27. Before Pull Request

Run:

git status

Make sure you did not add:

Model weights

API tokens

.env files

Virtual environments

Generated audio

Personal absolute paths

Temporary files

28. Quick Start — Existing Setup

If the machine is already configured:

Terminal 1 — WSL

cd /path/to/Palash-Multilingual-Realtime-Translator
source .venv-wsl/bin/activate
python wsl_asr_worker.py

Wait:

[WORKER] Ready

Terminal 2 — Windows

cd path\to\Palash-Multilingual-Realtime-Translator
.venv\Scripts\activate
python <REALTIME_PIPELINE_FILE>.py

Then:

Speak Hindi
    ↓
Stop speaking
    ↓
VAD detects end of speech
    ↓
Hindi ASR
    ↓
Hindi → Santali
    ↓
Santali TTS
    ↓
Speaker

29. Current Development Limitations

The current Windows + WSL2 setup is for development and prototype testing.

It is not yet the final Android architecture.

Still requiring validation:

Android ASR inference

Android translation inference

Android Santali TTS inference

Low-end Android memory usage

Offline model packaging

End-to-end latency target

Santali → Hindi reverse voice pipeline