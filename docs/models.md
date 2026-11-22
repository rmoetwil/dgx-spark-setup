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

To switch caches with `hfuse` (see below), also add this line to `~/.bashrc`:

```bash
command -v models >/dev/null && eval "$(models shell-init)"
```

## Commands

```bash
models ls                                  # every model on both disks
models where <repo>                        # internal or external
models get <repo> [--internal|--external]  # hf download into the active cache, or the one given
models run <repo> -- <command...>          # run <command> with HF_HOME set to the cache holding <repo>
eval "$(models env <repo>)"                # set HF_HOME in the current shell to the cache holding <repo>
models mv <repo> internal|external         # move to the other cache: copy, verify, then delete
hfuse [internal|external]                  # switch HF_HOME in the current shell; no argument shows the active cache
```

## Switching the cache for other tools

Tools such as `hf`, vLLM and spark-vllm-docker do not know the `models` script; they only read `HF_HOME`.
`hfuse` switches `HF_HOME` in the current shell, so those tools follow:

```bash
hfuse external                 # HF_HOME=/mnt/ai-data/huggingface
hf cache ls                    # now lists the external cache
hfuse internal                 # unsets HF_HOME, back to ~/.cache/huggingface
```

While the external cache is active, the prompt starts with `[hf:ext]`.
The switch only lasts for that shell, so watch the prompt before downloading.
For a single command, a one-off is safer, because nothing stays switched:

```bash
HF_HOME=/mnt/ai-data/huggingface hf cache ls
```

`hfuse` is a shell function, because a script cannot change the environment of the shell that started it.
It runs `models use`, which prints the `export` or `unset` line.

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

## Deleting models

Newer `hf` versions keep large files in a store shared by all models, `hub/blobs/<xx>/<sha256>`, and link to them from the model folder.
Deleting a model folder with `rm -rf` leaves those shared files behind, so delete through `hf` instead:

```bash
hf cache rm model/<repo>       # add HF_HOME=/mnt/ai-data/huggingface for the external cache
hf cache prune                 # remove leftovers, such as shared files no model uses
```

## Moving models

Stop anything that uses the model before `models mv`.
Containers download as root, so `models mv` refuses models with root-owned files.
Take ownership of the cache once to fix that:

```bash
sudo chown -R $USER: ~/.cache/huggingface
```
