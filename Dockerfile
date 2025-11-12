FROM vllm/vllm-openai:latest

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Create cache directory
RUN mkdir -p /root/.cache/huggingface/hub

# Copy startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Expose vLLM port
EXPOSE 8000

# Set working directory
WORKDIR /root

# Use our startup script as the entrypoint
ENTRYPOINT ["/bin/bash", "/start.sh"]
