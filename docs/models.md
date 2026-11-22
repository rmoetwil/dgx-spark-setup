# Model storage

Models are spread over two disks.
The script `scripts/models` finds, downloads, runs and moves them.

## Layout

| Disk | Path | Holds |
|---|---|---|
| internal NVMe | `~/.cache/huggingface` | HF cache with the main models, fastest loading |
| external SSD | `/mnt/ai-data/huggingface` | HF cache with less-used and experimental models |
| external SSD | `/mnt/ai-data/models` | GGUFs as plain folders, also the LM Studio models folder |

The rule: safetensors models go in one of the two HF caches; GGUFs go in `/mnt/ai-data/models`.
Do not use `hf download --local-dir` for safetensors models anymore.

`HF_HOME` selects the cache.
Without it, `hf`, vLLM and spark-vllm-docker use the internal cache.
llama.cpp and LM Studio find GGUFs by path, not through `HF_HOME`.

## External SSD

The SSD is formatted ext4 and mounted at `/mnt/ai-data` through `/etc/fstab`, with `nofail` so the machine still boots without it.
`scripts/format-ai-ssd.sh` did the formatting and the fstab entry; it erases the disk, so only run it on a new disk.

## Install the script

Link the script into `~/.local/bin` once, from the root of this repository:

```bash
ln -s "$PWD/scripts/models" ~/.local/bin/models
```

## Commands

```bash
models ls                             # every model on both disks
models where <repo>                   # internal or external
models get <repo> [--external]        # hf download into the internal (default) or external cache
models run <repo> -- <command...>     # run <command> with HF_HOME set to the cache holding <repo>
eval "$(models env <repo>)"           # set HF_HOME in the current shell
models mv <repo> internal|external    # move to the other cache: copy, verify, then delete
```

`<repo>` is a Hugging Face repo ID, such as `Qwen/Qwen3-Coder-Next-FP8`.
In `models ls`, type `hf` means the model is in an HF cache and type `local` means it is a plain folder.

## Examples

```bash
# Download a less-used model to the SSD and serve it with a spark-vllm-docker recipe
models get nvidia/NVIDIA-Nemotron-3-Nano-30B-A3B-NVFP4 --external
models run nvidia/NVIDIA-Nemotron-3-Nano-30B-A3B-NVFP4 -- ./run-recipe.py nemotron-3-nano-nvfp4
```

Extra arguments after the repo ID go to `hf download`.

GGUFs are not managed by `models`.
Download only the file you need, because a GGUF repo usually holds every quantization:

```bash
hf download ggml-org/gpt-oss-20b-GGUF gpt-oss-20b-MXFP4.gguf \
  --local-dir /mnt/ai-data/models/ggml-org/gpt-oss-20b-GGUF
llama-server -m /mnt/ai-data/models/ggml-org/gpt-oss-20b-GGUF/gpt-oss-20b-MXFP4.gguf
```

## Moving models

Stop anything that uses the model before `models mv`.
Containers download as root, so `models mv` refuses models with root-owned files.
Take ownership of the cache once to fix that:

```bash
sudo chown -R $USER: ~/.cache/huggingface
```
