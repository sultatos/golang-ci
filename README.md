# golang-ci

Go CI image: the Go toolchain plus the linters, scanners and code generators a Go pipeline needs,
pinned in one image so pipelines stop installing tools on every run.

```
ghcr.io/sultatos/golang-ci:<vX.Y.Z>
```

Multi-arch (`linux/amd64`, `linux/arm64`), public, no credentials needed to pull.

## Contents

Base `debian:trixie-<date>-slim` with the official Go tarball (sha256-verified; `GOPATH=/go`,
`HOME=/root`, `GOTOOLCHAIN=local`), `gcc`, `libc6-dev`, `make`, `git`, `curl`, `ca-certificates`, plus,
in `/usr/local/bin`:

| Tool | ARG |
|---|---|
| golangci-lint (release binary, sha256-verified) | `GOLANGCI_LINT_VERSION` |
| gosec | `GOSEC_VERSION` |
| govulncheck | `GOVULNCHECK_VERSION` |
| sqlc | `SQLC_VERSION` |
| buf | `BUF_VERSION` |
| protoc-gen-go | `PROTOC_GEN_GO_VERSION` |
| protoc-gen-go-grpc | `PROTOC_GEN_GO_GRPC_VERSION` |
| oapi-codegen | `OAPI_CODEGEN_VERSION` |
| file | apt |

The image carries no docker CLI or buildx.

The Dockerfile `ARG` defaults are the single source of truth for versions; `docker inspect` shows
them as `golang-ci.*` labels. The module and build caches (`/go/pkg/mod`, `/root/.cache/go-build`,
`/root/.cache/golangci-lint`) and `/go/bin` ship empty, so CI caches keyed on those paths work
unchanged.

## Using it

GitHub Actions:

```yaml
jobs:
  test:
    runs-on: ubuntu-24.04
    container: ghcr.io/sultatos/golang-ci:v1.1.0
```

Bitbucket Pipelines:

```yaml
image: ghcr.io/sultatos/golang-ci:v1.1.0
```

## Build and check locally

```bash
docker build -t golang-ci:local .
docker run --rm -v "$PWD/scripts:/s:ro" golang-ci:local sh /s/smoke.sh
```

## Bumping a tool or Go

1. Edit the `ARG` default in `Dockerfile`.
2. Open a PR; CI builds and smoke-tests both architectures. Merge it.
3. Tag `vX.Y.Z` on `main`; the workflow publishes `ghcr.io/sultatos/golang-ci:vX.Y.Z`. Tags are
   immutable: an existing tag is skipped, never overwritten.
4. Point consumers at the new tag.

Rollback: point consumers back at the previous tag.
