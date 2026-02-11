# Open WebUI with Ollama

Setting up Open WebUI with Ollama is easy.
Start by following this [documentation](https://build.nvidia.com/spark/open-webui/overview)

After setup make the following changes to be able to use Ollama externally.
- Expose the Ollama port to your host machine.
- Make sure Ollama accepts external connections.
- (optionally) Set Auth to none in the Open WebUI `admin->settings->connections` Manage Ollama API Connections.

Modified NVidia Sync script:
```
#!/usr/bin/env bash
set -euo pipefail

NAME="open-webui"
IMAGE="ghcr.io/open-webui/open-webui:ollama"

cleanup() {
  echo "Signal received; stopping ${NAME}..."
  docker stop "${NAME}" >/dev/null 2>&1 || true
  exit 0
}
trap cleanup INT TERM HUP QUIT EXIT

# Ensure Docker CLI and daemon are available
if ! docker info >/dev/null 2>&1; then
  echo "Error: Docker daemon not reachable." >&2
  exit 1
fi

# Already running?
if [ -n "$(docker ps -q --filter "name=^${NAME}$" --filter "status=running")" ]; then
  echo "Container ${NAME} is already running."
else
  # Exists but stopped? Start it.
  if [ -n "$(docker ps -aq --filter "name=^${NAME}$")" ]; then
    echo "Starting existing container ${NAME}..."
    docker start "${NAME}" >/dev/null
  else
    # Not present: create and start it.
    echo "Creating and starting ${NAME}..."
    docker run -d -p 12000:8080 -p 11434:11434 --gpus=all \
      -o OLLAMA_HOST=0.0.0.0
      -v open-webui:/app/backend/data \
      -v open-webui-ollama:/root/.ollama \
      --name "${NAME}" "${IMAGE}" >/dev/null
  fi
fi

echo "Running. Press Ctrl+C to stop ${NAME}."
# Keep the script alive until a signal arrives
while :; do sleep 86400; done
```