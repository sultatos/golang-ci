#!/bin/sh
# Fails if a tool is missing or resolves outside its expected directory, or if a cache path ships non-empty.
set -u
fail=0

check() {
	bin=$1
	dir=$2
	shift 2
	path=$(command -v "$bin" 2>/dev/null || true)
	if [ "$path" != "$dir/$bin" ]; then
		echo "FAIL $bin: found '${path:-nothing}', want $dir/$bin" >&2
		fail=1
		return
	fi
	if ! out=$("$@" 2>&1); then
		echo "FAIL $bin: version command failed: $out" >&2
		fail=1
		return
	fi
	echo "ok   $bin: $(echo "$out" | head -n 1)"
}

check go /usr/local/go/bin go version
check gofmt /usr/local/go/bin gofmt -l /usr/local/go/src/errors
check golangci-lint /usr/local/bin golangci-lint version
check gosec /usr/local/bin gosec -version
check govulncheck /usr/local/bin govulncheck -version
check sqlc /usr/local/bin sqlc version
check buf /usr/local/bin buf --version
check protoc-gen-go /usr/local/bin protoc-gen-go --version
check protoc-gen-go-grpc /usr/local/bin protoc-gen-go-grpc --version
check oapi-codegen /usr/local/bin oapi-codegen -version
check file /usr/bin file --version

for d in /go/pkg/mod /root/.cache/go-build /root/.cache/golangci-lint /go/bin; do
	if [ -d "$d" ] && [ -n "$(ls -A "$d")" ]; then
		echo "FAIL $d is not empty" >&2
		fail=1
	fi
done

exit "$fail"
