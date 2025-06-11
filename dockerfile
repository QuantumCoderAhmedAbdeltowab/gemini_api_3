# ─────────────────────────────────────────────────────────────────────────────
# Stage 1: build all wheels & native libs
# ─────────────────────────────────────────────────────────────────────────────
FROM python:3.10-slim AS builder
WORKDIR /app

# Install system deps needed for faiss, torch, etc.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential \
      libopenblas-dev \
      git \
 && rm -rf /var/lib/apt/lists/*

# Copy only requirements, install with no-cache
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ─────────────────────────────────────────────────────────────────────────────
# Stage 2: runtime image
# ─────────────────────────────────────────────────────────────────────────────
FROM python:3.10-slim
WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /usr/local/lib/python3.10/site-packages \
                  /usr/local/lib/python3.10/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy your code
COPY . .

# Clean up any model caches that snuck in
RUN rm -rf /root/.cache/huggingface \
           /root/.cache/torch \
           /root/.cache/pypoetry \
           /root/.cache/pip

# Expose and set entrypoint
ENV PORT=8000
EXPOSE ${PORT}
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
