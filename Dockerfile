# Use NVIDIA CUDA runtime base for compatibility with RTX 4000 (Ada)
FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04

# Install system deps and Python
RUN apt-get update && apt-get install -y python3.10 python3-pip git && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install vLLM from PyPI
RUN pip install --no-cache-dir -U pip && \
    pip install --no-cache-dir vllm

# Set default values as environment variables (can be overridden at runtime)
ENV model=google/gemma-3-12b-it
ENV dtype=float8_e4m3
ENV gpu_memory_utilization=0.9
ENV max_model_len=8192

# Set working directory
WORKDIR /app

# Expose OpenAI-compatible port
EXPOSE 8000

# Run vLLM serve with PyTorch backend (parameters from environment variables)
# Optimizations: dtype from ENV (FP8 equivalent), gpu-memory-util from ENV, max-model-len from ENV
CMD ["python3", "-m", "vllm.entrypoints.openai.api_server", \
     "--model", "${model}", \
     "--host", "0.0.0.0", \
     "--port", "8000", \
     "--dtype", "${dtype}", \
     "--gpu-memory-utilization", "${gpu_memory_utilization}", \
     "--max-model-len", "${max_model_len}"]
