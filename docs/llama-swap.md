# llama-swap

[llama-swap](https://github.com/mostlygeek/llama-swap) puts one OpenAI-compatible endpoint in front of several model servers.
When a request names a model, llama-swap starts the server for that model and stops the one that was running.
Here it switches between:

- **GGUF models** with llama.cpp built from source (see [llama-cpp.md](llama-cpp.md)).
- **Safetensors models** with eugr's [spark-vllm-docker](https://github.com/eugr/spark-vllm-docker) recipes, which run vLLM in a container.

Only one model runs at a time, so the 128 GB of unified memory is available to the model that is loaded.

## Files

| Path in this repository | Purpose |
|---|---|
| `llama-swap/config.yaml` | Models and how to start them |
| `llama-swap/llama-swap.service` | systemd user service |
| `scripts/llama-swap-install.sh` | Install or upgrade the llama-swap binary |

## Install

From the root of this repository:

```bash
scripts/llama-swap-install.sh                 # latest release into ~/.local/bin, checksum verified
mkdir -p ~/.config/llama-swap
ln -s "$PWD/llama-swap/config.yaml" ~/.config/llama-swap/config.yaml
systemctl --user link "$PWD/llama-swap/llama-swap.service"
systemctl --user enable --now llama-swap
```

A user service only runs while you are logged in, unless lingering is on for your account:

```bash
loginctl show-user "$USER" -p Linger         # Linger=yes means it keeps running
sudo loginctl enable-linger "$USER"           # if it says no
```

For vLLM models, build the spark-vllm-docker image once:

```bash
python3 ~/data/github/eugr/spark-vllm-docker/run-recipe.py <recipe> --build-only
```

## Use

llama-swap listens on `http://127.0.0.1:9292`.

```bash
curl -s localhost:9292/v1/models                       # configured models
curl -s localhost:9292/running                         # model running now
curl -s localhost:9292/v1/chat/completions -H "Content-Type: application/json" \
  -d '{"model": "llama3-8b", "messages": [{"role": "user", "content": "Hello"}]}'
curl -s -X POST localhost:9292/api/models/unload       # stop the running model, free the memory
```

llama-swap also has a web interface at `http://127.0.0.1:9292/ui`, with the logs and the running model.

### Switching times

Measured on 2026-11-22 with llama-swap v275, from the request to the first answer:

| Switch | Time |
|---|---|
| Nothing loaded → Llama 3 8B (llama.cpp, from the external SSD) | 4.5 s |
| Nothing loaded → Nemotron 3 Nano (vLLM), first start after building the image | 132 s |
| Nemotron 3 Nano → Llama 3 8B, including stopping the vLLM container | 15 s |
| Llama 3 8B → Nemotron 3 Nano, later start | 60 s |
| `systemctl --user stop llama-swap` with Nemotron 3 Nano loaded | 11 s |

The later vLLM start is faster, probably because vLLM reuses its compile cache in `~/.cache/vllm`.

## Manage the service

```bash
systemctl --user status llama-swap
journalctl --user -u llama-swap -f                     # logs
systemctl --user restart llama-swap                    # after a llama-swap upgrade
systemctl --user stop llama-swap                       # stop serving, for example during evaluations
```

The service runs with `--watch-config`, so changes to `config.yaml` apply without a restart.

## Add a model

**GGUF model:** put the file under `/mnt/ai-data/models` (see [models.md](models.md)) and add an entry like `llama3-8b` in `config.yaml`.

**vLLM model:** pick a recipe from `spark-vllm-docker/recipes`, download its model with `models get`, and add an entry like `nemotron-nano`:

- `cmd` runs the recipe with `--solo`, a fixed `--name` and `--port ${PORT}`.
- `cmdStop` stops the container by that name.
- `useModelName` is the Hugging Face repo ID, because vLLM only answers to that name.

## Serving other machines

The service only listens on `127.0.0.1`. To reach it from other machines, override the address:

```bash
systemctl --user edit llama-swap
# [Service]
# Environment=LLAMA_SWAP_LISTEN=0.0.0.0:9292
```

llama-swap then answers anyone who can reach the port. Set `apiKeys` in `config.yaml` before doing this, and only do it on a trusted network.
