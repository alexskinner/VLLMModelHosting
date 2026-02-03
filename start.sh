#!/bin/bash
set -e

echo "=== vLLM Server - OPTIMISED FOR HIGH THROUGHPUT ==="
echo "==================================================="

# Set defaults
MODEL="${MODEL:-Qwen/Qwen3-4B-Instruct-2507}"
SERVED_NAME="${SERVED_NAME:-$(basename $MODEL | tr '[:upper:]' '[:lower:]' | sed 's/-instruct.*//')}"
HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8000}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-65536}"
MAX_NUM_SEQS="${MAX_NUM_SEQS:-64}"
GPU_MEMORY_UTILIZATION="${GPU_MEMORY_UTILIZATION:-0.95}"
KV_CACHE_DTYPE="${KV_CACHE_DTYPE:-auto}"
ENABLE_PREFIX_CACHING="${ENABLE_PREFIX_CACHING:-true}"
ENABLE_CHUNKED_PREFILL="${ENABLE_CHUNKED_PREFILL:-true}"

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
echo "Context window: $(($MAX_MODEL_LEN / 1024))K tokens"
echo "Max concurrent sequences: $MAX_NUM_SEQS"
echo "GPU Memory Utilization: $GPU_MEMORY_UTILIZATION"
echo "Prefix Caching: $ENABLE_PREFIX_CACHING"
echo "Chunked Prefill: $ENABLE_CHUNKED_PREFILL"
echo "KV Cache Dtype: $KV_CACHE_DTYPE"
echo ""
echo "Starting optimised vLLM server..."

# Build vLLM command with conditional flags
VLLM_CMD="python3 -m vllm.entrypoints.openai.api_server \
  --model $MODEL \
  --host $HOST \
  --port $PORT \
  --served-model-name $SERVED_NAME \
  --max-model-len $MAX_MODEL_LEN \
  --max-num-seqs $MAX_NUM_SEQS \
  --gpu-memory-utilization $GPU_MEMORY_UTILIZATION \
  --kv-cache-dtype $KV_CACHE_DTYPE"

# Add optional flags
if [ "$ENABLE_PREFIX_CACHING" = "true" ]; then
    VLLM_CMD="$VLLM_CMD --enable-prefix-caching"
fi

if [ "$ENABLE_CHUNKED_PREFILL" = "true" ]; then
    VLLM_CMD="$VLLM_CMD --enable-chunked-prefill"
fi

VLLM_CMD="$VLLM_CMD --api-key $VLLM_API_KEY"

# Start vLLM with all optimisations
exec $VLLM_CMD
