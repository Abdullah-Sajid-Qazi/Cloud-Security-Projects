# Intentionally insecure Dockerfile for CI/CD pipeline demo
# These issues should be caught by Trivy container scanning

# ISSUE 1: Using outdated base image with known CVEs
FROM python:3.8-slim

# ISSUE 2: Running as root (no USER instruction)

# ISSUE 3: Installing unnecessary packages increases attack surface
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# ISSUE 4: Using pip install without pinned versions
RUN pip install --no-cache-dir \
    flask==2.0.1 \
    requests==2.25.0 \
    pyyaml==5.3.1 \
    jinja2==3.0.1

WORKDIR /app

COPY app.py .

# ISSUE 5: Exposing a port without TLS
EXPOSE 5000

CMD ["python3", "app.py"]
