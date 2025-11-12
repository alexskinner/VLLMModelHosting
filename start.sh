

RunOptimised VLLM.sh
98 lines

sh

I have this vllm startup file which works nicely on a regular server

im hosting on Koyeb which supports github and builds docker files on the fly

An example DockerFile i have is

#!/bin/bash
set -e
echo "vLLM Server - OPTIMISED FOR HIGH THROUGHPUT"
echo "============================================="
# === 1. API Key ===
if [ -n "$VLLM_API_KEY" ]; then
    API_KEY="$VLLM_API_KEY"
    echo "✓ Using API key from VLLM_API_KEY environment variable"
else
    API_KEY=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 48)
    echo "⚠ Generated new API key: $API_KEY"
fi
echo
# === 2. Model Configuration ===
DEFAULT_MODEL="Qwen/Qwen3-4B-Instruct-2507"
MODEL="${MODEL:-$DEFAULT_MODEL}"
SERVED_NAME="${SERVED_NAME:-$(basename $MODEL | tr '[:upper:]' '[:lower:]' | sed 's/-instruct.*//')}"
CACHE="/root/.cache/huggingface/hub"
echo "Model: $MODEL"
echo "Served as: $SERVED_NAME"
# === 3. HuggingFace token ===
DOCKER_ENV_ARGS=""
if [ -n "$HF_TOKEN" ]; then
    echo "✓ HuggingFace token detected"
    DOCKER_ENV_ARGS="-e HF_TOKEN=$HF_TOKEN"
elif [ -n "$HUGGING_FACE_HUB_TOKEN" ]; then
    echo "✓ HuggingFace token detected"
    DOCKER_ENV_ARGS="-e HF_TOKEN=$HUGGING_FACE_HUB_TOKEN"
fi
echo
# === 4. Stop old containers ===
docker rm -f $(docker ps -aq --filter name=vllm) 2>/dev/null || true
# === 5. Start OPTIMISED vLLM ===
echo "Starting OPTIMISED vLLM server..."
echo "Changes from default:"
echo "  - Using CUDAGraph for 2-4x faster generation"
echo "  - Increased max_num_seqs for better concurrent request handling"
echo "  - Optimised for throughput"
echo
docker run -d \
  --name vllm \
  --gpus all \
  -p 8000:8000 \
  -v "$CACHE:/root/.cache/huggingface" \
  $DOCKER_ENV_ARGS \
  --ipc=host \
  --shm-size=16g \
  vllm/vllm-openai:latest \
  --model "$MODEL" \
  --host 0.0.0.0 \
  --port 8000 \
  --served-model-name "$SERVED_NAME" \
  --max-model-len 65536 \
  --max-num-seqs 256 \
  --gpu-memory-utilization 0.95 \
  --kv-cache-dtype auto \
  --enable-prefix-caching \
  --enable-chunked-prefill \
  --api-key "$API_KEY"
# Note: Removed --enforce-eager to enable CUDAGraph for better performance
sleep 20
echo
echo "========================================================================"
echo "OPTIMISED SERVER IS LIVE"
echo "========================================================================"
echo "Model: $SERVED_NAME"
echo "Context: 64,000 tokens"
echo "Max concurrent sequences: 256"
echo "CUDAGraph: ENABLED (2-4x faster generation)"
echo "API Key: $API_KEY"
echo
echo "Expected performance improvements:"
echo "  - Generation: 30-60+ tokens/s (vs 14.5 before)"
echo "  - Can handle 256 concurrent requests"
echo "  - Lower latency with CUDAGraph"
echo
echo "TEST:"
echo "curl http://localhost:8000/v1/chat/completions \\"
echo "  -H \"Authorization: Bearer $API_KEY\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{\"model\":\"$SERVED_NAME\",\"messages\":[{\"role\":\"user\",\"content\":\"Hello\"}]}'"
echo
echo "PUBLIC URL: http://$(curl -s ifconfig.me):8000/v1"
echo "API Key: $API_KEY"
echo
echo "Monitor performance: docker logs -f vllm"
echo "========================================================================"

and start.sh is

#!/bin/bash
# Default models if OLLAMA_MODEL is not set
DEFAULT_MODELS="gemma3:12b mxbai-embed-large"
# Use MODELS if set, else fallback to defaults
MODELS="${MODELS:-$DEFAULT_MODELS}"
# Split comma-separated list into space-separated (for looping)
MODELS=$(echo "$MODELS" | tr ',' ' ')
# Set temp OLLAMA_HOST for localhost-only server on a non-exposed port
export OLLAMA_HOST=127.0.0.1:11435
# Start temp Ollama server in the background for pulls/checks
ollama serve &
# Wait for the temp server to be ready (health check loop with timeout)
for i in {1..60}; do
    if curl --fail --silent --head http://127.0.0.1:11435; then
        break
    fi
    sleep 1
done
# If the loop timed out, exit with error
if [ "$i" -eq 60 ]; then
    echo "Error: Temp Ollama server failed to start within 60 seconds."
    exit 1
fi
# Check/pull each model if not already present (using temp server)
for MODEL in $MODELS; do
    if ! ollama list | grep -q "$MODEL"; then
        echo "Pulling $MODEL "
        ollama pull "$MODEL"
    else
        echo "Model $MODEL already exists, skipping pull."
    fi
done
# Kill the temp server process
pkill ollama
# Unset the temp OLLAMA_HOST to default 0.0.0.0:11434 for exposure
export OLLAMA_HOST=0.0.0.0:11434
echo "Starting the accessible server"
# Start the final Ollama server (now with models ready)
ollama serve

I'd like to convert my vllm startup script into the same style with a Dockerfile and Start.sh

Show more
I'll help you convert your vLLM startup script into a Dockerfile and start.sh for Koyeb deployment.


Creating a Dockerfile for vLLM deployment on Koyeb
Dockerfile

Creating the start.sh script for vLLM server initialisation
start.sh
Now let me create a README with deployment instructions:


Creating README with deployment instructions for Koyeb
README.md
Perfect! Now let me copy these files to the outputs directory so you can download them:


Copy all files to outputs directory for user download


Excellent! I've converted your vLLM startup script for Koyeb deployment. Here are the key changes:

Main Differences from Your Original Script:
No Docker-in-Docker - Since Koyeb builds the Docker container itself, we run vLLM directly using Python rather than launching another Docker container inside
Health Check Loop - Added a proper health check similar to your Ollama example, ensuring the server is ready before marking the deployment as successful
Signal Handling - Proper graceful shutdown handling for Koyeb's container lifecycle
Simplified Environment Variables - HuggingFace tokens are exported as environment variables rather than passed as Docker args
Files Created:
Dockerfile - Based on vllm/vllm-openai:latest
start.sh - Startup script with all your optimisations
README.md - Deployment instructions
All your performance optimisations are preserved (CUDAGraph, 256 concurrent sequences, 64K context, prefix caching, etc.). Simply push these files to GitHub and connect the repository to Koyeb with a GPU instance!

Dockerfile
 
Start
SH 
Readme
Document · MD 







 
Start · SH
Copy

#!/bin/bash
set -e

echo "vLLM Server - OPTIMISED FOR HIGH THROUGHPUT"
echo "============================================="

# === 1. API Key ===
if [ -n "$VLLM_API_KEY" ]; then
    API_KEY="$VLLM_API_KEY"
    echo "✓ Using API key from VLLM_API_KEY environment variable"
else
    API_KEY=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 48)
    echo "⚠ Generated new API key: $API_KEY"
fi
echo

# === 2. Model Configuration ===
DEFAULT_MODEL="Qwen/Qwen3-4B-Instruct-2507"
MODEL="${MODEL:-$DEFAULT_MODEL}"
SERVED_NAME="${SERVED_NAME:-$(basename $MODEL | tr '[:upper:]' '[:lower:]' | sed 's/-instruct.*//')}"

echo "Model: $MODEL"
echo "Served as: $SERVED_NAME"

# === 3. HuggingFace token (set as environment variable if present) ===
if [ -n "$HF_TOKEN" ]; then
    echo "✓ HuggingFace token detected"
    export HF_TOKEN="$HF_TOKEN"
elif [ -n "$HUGGING_FACE_HUB_TOKEN" ]; then
    echo "✓ HuggingFace token detected"
    export HF_TOKEN="$HUGGING_FACE_HUB_TOKEN"
fi
echo

# === 4. Start OPTIMISED vLLM ===
echo "Starting OPTIMISED vLLM server..."
echo "Changes from default:"
echo "  - Using CUDAGraph for 2-4x faster generation"
echo "  - Increased max_num_seqs for better concurrent request handling"
echo "  - Optimised for throughput"
echo

# Start vLLM server directly (no Docker-in-Docker on Koyeb)
python3 -m vllm.entrypoints.openai.api_server \
  --model "$MODEL" \
  --host 0.0.0.0 \
  --port 8000 \
  --served-model-name "$SERVED_NAME" \
  --max-model-len 65536 \
  --max-num-seqs 256 \
  --gpu-memory-utilization 0.95 \
  --kv-cache-dtype auto \
  --enable-prefix-caching \
  --enable-chunked-prefill \
  --api-key "$API_KEY" &

# Store the PID
VLLM_PID=$!

# Wait for server to be ready (health check loop with timeout)
echo "Waiting for vLLM server to be ready..."
for i in {1..120}; do
    if curl --fail --silent --head http://localhost:8000/health 2>/dev/null || \
       curl --fail --silent --head http://localhost:8000/v1/models 2>/dev/null; then
        echo "✓ Server is ready!"
        break
    fi
    sleep 2
done

# If the loop timed out, exit with error
if [ "$i" -eq 120 ]; then
    echo "Error: vLLM server failed to start within 240 seconds."
    exit 1
fi

echo
echo "========================================================================"
echo "OPTIMISED SERVER IS LIVE"
echo "========================================================================"
echo "Model: $SERVED_NAME"
echo "Context: 64,000 tokens"
echo "Max concurrent sequences: 256"
echo "CUDAGraph: ENABLED (2-4x faster generation)"
echo "API Key: $API_KEY"
echo
echo "Expected performance improvements:"
echo "  - Generation: 30-60+ tokens/s (vs 14.5 before)"
echo "  - Can handle 256 concurrent requests"
echo "  - Lower latency with CUDAGraph"
echo
echo "TEST:"
echo "curl http://localhost:8000/v1/chat/completions \\"
echo "  -H \"Authorization: Bearer $API_KEY\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{\"model\":\"$SERVED_NAME\",\"messages\":[{\"role\":\"user\",\"content\":\"Hello\"}]}'"
echo
echo "API Key: $API_KEY"
echo "========================================================================"

# Keep the script running and forward signals to vLLM
trap "kill $VLLM_PID" SIGTERM SIGINT
wait $VLLM_PID

