ARG VIPERSERVER_REF=v-2026-08-13-0738
ARG IMAGE_VERSION=dev

FROM golang:1.26-alpine AS shim-builder
ARG VIPERSERVER_REF
ARG IMAGE_VERSION
WORKDIR /shim
COPY shim/go.mod shim/main.go ./
RUN CGO_ENABLED=0 go build \
        -ldflags="-s -w -X main.imageVersion=${IMAGE_VERSION} -X main.viperserverRef=${VIPERSERVER_REF}" \
        -o /shim/dildo-docker-shim .

FROM eclipse-temurin:17-jre-noble AS base

ARG VIPERSERVER_REF

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/home/dilduser \
    Z3_EXE="/usr/local/bin/z3"

# Install curl for the release download, purged after use
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Download pinned Z3 solver binary
ARG Z3_VERSION=4.16.0
RUN curl -fsSL -o /tmp/z3.zip \
        "https://github.com/Z3Prover/z3/releases/download/z3-${Z3_VERSION}/z3-${Z3_VERSION}-x64-glibc-2.39.zip" \
    && unzip -q /tmp/z3.zip -d /tmp/z3 \
    && find /tmp/z3 -name z3 -type f -exec cp {} /usr/local/bin/z3 \; \
    && chmod +x /usr/local/bin/z3 \
    && rm -rf /tmp/z3 /tmp/z3.zip

# Download pinned ViperServer release jar
RUN curl -fsSL -o /opt/viperserver.jar \
        "https://github.com/viperproject/viperserver/releases/download/${VIPERSERVER_REF}/viperserver.jar"

COPY --from=shim-builder /shim/dildo-docker-shim /usr/local/bin/dildo-docker-shim

# Set up non-root user and workspace
RUN useradd -m dilduser && \
    mkdir -p /code && \
    chown -R dilduser:dilduser /code /opt/viperserver.jar /home/dilduser

COPY --chown=dilduser:dilduser entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /code
USER dilduser

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["--help"]
