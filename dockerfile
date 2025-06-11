# ─── Stage 1: build dependencies ─────────────────────────────────────────────
FROM python:3.10-slim AS builder
WORKDIR /app

# Install system deps for faiss + PyTorch
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential \
      libopenblas-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy only requirements, install w/o cache
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ─── Stage 2: runtime ───────────────────────────────────────────────────────
FROM python:3.10-slim
WORKDIR /app

# Copy only the installed packages
COPY --from=builder /usr/local/lib/python3.10/site-packages \
                  /usr/local/lib/python3.10/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy your application files (no .cache, thanks to .dockerignore)
COPY main.py context.txt phishaware_sheet.csv .

# Expose port & run
ENV PORT=8000
EXPOSE ${PORT}
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
