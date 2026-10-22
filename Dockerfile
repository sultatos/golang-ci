ARG GO_VERSION=1.27.1
FROM debian:trixie-20261020-slim

ARG GO_VERSION
ARG TARGETARCH
ARG GOLANGCI_LINT_VERSION=v2.14.0
ARG GOSEC_VERSION=v2.29.0
ARG GOVULNCHECK_VERSION=v1.8.0
ARG SQLC_VERSION=v1.31.1
ARG BUF_VERSION=v1.72.0
ARG PROTOC_GEN_GO_VERSION=v1.36.11
ARG PROTOC_GEN_GO_GRPC_VERSION=v1.5.1
ARG OAPI_CODEGEN_VERSION=v2.8.0

LABEL org.opencontainers.image.source="https://github.com/sultatos/golang-ci" \
      org.opencontainers.image.version.go="${GO_VERSION}" \
      golang-ci.golangci-lint="${GOLANGCI_LINT_VERSION}" \
      golang-ci.gosec="${GOSEC_VERSION}" \
      golang-ci.govulncheck="${GOVULNCHECK_VERSION}" \
      golang-ci.sqlc="${SQLC_VERSION}" \
      golang-ci.buf="${BUF_VERSION}" \
      golang-ci.protoc-gen-go="${PROTOC_GEN_GO_VERSION}" \
      golang-ci.protoc-gen-go-grpc="${PROTOC_GEN_GO_GRPC_VERSION}" \
      golang-ci.oapi-codegen="${OAPI_CODEGEN_VERSION}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends gcc libc6-dev make git curl ca-certificates file \
    && rm -rf /var/lib/apt/lists/*

# Go toolchain from the official tarball, verified against the checksum Go publishes for that file.
RUN set -eu; \
    tarball="go${GO_VERSION}.linux-${TARGETARCH}.tar.gz"; \
    cd /tmp; \
    curl -fsSLO "https://go.dev/dl/${tarball}"; \
    echo "$(curl -fsSL "https://dl.google.com/go/${tarball}.sha256")  ${tarball}" | sha256sum -c -; \
    tar -xzf "${tarball}" -C /usr/local; \
    rm -f "${tarball}"

ENV GOPATH=/go PATH=/go/bin:/usr/local/go/bin:$PATH GOTOOLCHAIN=local
RUN mkdir -p /go/bin /go/src && chmod -R 1777 /go
WORKDIR /go

# golangci-lint ships release binaries; the tarball is verified against the published checksum file.
RUN set -eu; \
    v="${GOLANGCI_LINT_VERSION#v}"; \
    base="https://github.com/golangci/golangci-lint/releases/download/${GOLANGCI_LINT_VERSION}"; \
    tarball="golangci-lint-${v}-linux-${TARGETARCH}.tar.gz"; \
    cd /tmp; \
    curl -fsSLO "${base}/${tarball}"; \
    curl -fsSLO "${base}/golangci-lint-${v}-checksums.txt"; \
    grep " ${tarball}\$" "golangci-lint-${v}-checksums.txt" | sha256sum -c -; \
    tar -xzf "${tarball}" --strip-components=1 -C /usr/local/bin "golangci-lint-${v}-linux-${TARGETARCH}/golangci-lint"; \
    rm -f /tmp/golangci-lint-*

RUN GOBIN=/usr/local/bin go install "github.com/securego/gosec/v2/cmd/gosec@${GOSEC_VERSION}" \
    && GOBIN=/usr/local/bin go install "golang.org/x/vuln/cmd/govulncheck@${GOVULNCHECK_VERSION}" \
    && GOBIN=/usr/local/bin go install "github.com/sqlc-dev/sqlc/cmd/sqlc@${SQLC_VERSION}" \
    && GOBIN=/usr/local/bin go install "github.com/bufbuild/buf/cmd/buf@${BUF_VERSION}" \
    && GOBIN=/usr/local/bin go install "google.golang.org/protobuf/cmd/protoc-gen-go@${PROTOC_GEN_GO_VERSION}" \
    && GOBIN=/usr/local/bin go install "google.golang.org/grpc/cmd/protoc-gen-go-grpc@${PROTOC_GEN_GO_GRPC_VERSION}" \
    && GOBIN=/usr/local/bin go install "github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen@${OAPI_CODEGEN_VERSION}" \
    && go clean -modcache -cache \
    && rm -rf /root/.cache/* /go/bin/*
