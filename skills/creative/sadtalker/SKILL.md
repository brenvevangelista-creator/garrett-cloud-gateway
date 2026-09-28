---
name: sadtalker
description: >
  Use when generating avatar videos from photo + audio.
---

# SadTalker — Local Avatar Video Generator

## Overview
Generate HeyGen-style talking head videos from a single photo + audio file, 100% offline on Apple Silicon.

## Location
`~/projects/SadTalker/`

## Quick Usage
```bash
cd ~/projects/SadTalker
source venv/bin/activate
python3 inference.py --driven_audio <audio.wav> --source_image <photo.jpg> --result_dir results --size 256 --preprocess crop
```

Or use the wrapper:
```bash
./generate-avatar.sh <photo> <audio> [output_dir] [--still]
```

## Key Flags
- `--still` — minimal head movement, faster generation
- `--size 256` — standard quality (512 = higher but slower)
- `--preprocess crop` — auto-crop face (or `full` for full body)
- `--enhancer gfpgan` — face enhancement (slower but sharper)
- `--cpu` — force CPU (default auto-detects MPS on Mac)

## Performance (Apple M5 Pro, 24GB)
- Face Renderer: ~13s per frame
- 256 size, crop mode: ~20 min for a typical 10-second video
- 256 size, crop, --still: ~15 min (less head motion = fewer frames)

## Dependencies
- Python 3.10 venv at `venv/`
- PyTorch 2.14.0 with MPS backend
- Model checkpoints in `checkpoints/` (~1.7GB)
- GFPGAN enhancer weights in `gfpgan/weights/` (~700MB)

## Known Fixes Applied
- `basicsr/data/degradations.py` — patched `functional_tensor` import for torchvision 0.29+
- `setuptools<81` — for `pkg_resources` compatibility

## Output
- Videos saved to `results/<timestamp>/` as MP4
- Each run creates a timestamped subdirectory

## Pitfalls
- No `--device mps` flag; MPS is auto-detected on Apple Silicon
- First run is slower (model loading); subsequent runs are faster
- For HeyGen-style professional results, use high-quality source photos (front-facing, good lighting)
- `--still` flag is recommended for business/marketing content (less uncanny valley)

## Full Pipeline
1. Generate audio with Coqui TTS or Fish Audio
2. Run SadTalker with photo + generated audio
3. Output: MP4 avatar video with lip sync

## License
MIT — fully open source, no watermarks, commercial use OK