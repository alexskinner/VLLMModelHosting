#!/bin/bash
set -e

echo "=== vLLM Server - OPTIMISED FOR HIGH THROUGHPUT ==="
echo "==================================================="

# Set defaults
MODEL="${MODEL:-Qwen/Qwen3-4B-Instruct-2507}"
SERVED_NAME="${SERVED_NAME:-$(basename $MODEL | tr '[:upper:]' '[:lower:]' | sed 's/-instruct.*//')}"

# Generate API key if not provided
if [ -z "$VLLM_API_KEY" ]; then
    export VLLM_API_KEY=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 48)
    echo "⚠ Generated API Key: $VLLM_API_KEY"
else
    echo "✓ Using provided API key"
fi

# Handle HF token
if [ -n "$HUGGING_FACE_HUB_TOKEN" ] && [ -z "$HF_TOKEN" ]; then
    export HF_TOKEN="$HUGGING_FACE_HUB_TOKEN"
    echo "✓ HuggingFace token set"
elif [ -n "$HF_TOKEN" ]; then
    echo "✓ HuggingFace token set"
fi

echo ""
echo "Model: $MODEL"
echo "Served as: $SERVED_NAME"
echo "Context window: 64K tokens"
echo "Max concurrent sequences: 64"
echo "CUDAGraph: ENABLED"
echo ""
echo "Starting optimised vLLM server..."

# Start vLLM with all optimisations
exec python3 -m vllm.entrypoints.openai.api_server \
  --model "$MODEL" \
  --host 0.0.0.0 \
  --port 8000 \
  --served-model-name "$SERVED_NAME" \
  --max-model-len 65536 \
  --max-num-seqs 64 \
  --gpu-memory-utilization 0.95 \
  --kv-cache-dtype auto \
  --enable-prefix-caching \
  --enable-chunked-prefill \
  --api-key "$VLLM_API_KEY"
