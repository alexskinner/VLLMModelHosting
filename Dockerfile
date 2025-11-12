FROM vllm/vllm-openai:latest

# Install curl for health checks and public IP detection
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

# Run the startup script
CMD ["/start.sh"]