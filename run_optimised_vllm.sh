# Use this on Digital Ocean Inference ready droplets instead of their run_model.sh which doesn't work

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