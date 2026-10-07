#!/bin/sh
set -eu

release_base_url="${EARNIE_RELEASE_BASE_URL:-https://github.com/scanoss/earnie-cli/releases}"
version="${EARNIE_VERSION:-}"
install_dir="${EARNIE_INSTALL_DIR:-${HOME}/.local/bin}"
os_name="${EARNIE_INSTALL_OS:-$(uname -s)}"
arch_name="${EARNIE_INSTALL_ARCH:-$(uname -m)}"

if [ -z "$version" ]; then
  version="$(curl -fsSL "${release_base_url}/latest/download/version.txt")"
fi
version="$(printf '%s' "$version" | tr -d '\r\n')"
if ! printf '%s' "$version" | grep -Eq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'; then
  echo "Invalid Earnie CLI version: $version" >&2
  exit 2
fi

case "$(printf '%s' "$os_name" | tr '[:upper:]' '[:lower:]')" in
  linux) os_name="linux" ;;
  darwin) os_name="darwin" ;;
  *) echo "Unsupported operating system: $os_name" >&2; exit 2 ;;
esac

case "$arch_name" in
  x86_64|amd64) arch_name="amd64" ;;
  aarch64|arm64) arch_name="arm64" ;;
  *) echo "Unsupported architecture: $arch_name" >&2; exit 2 ;;
esac

archive="earnie_${version}_${os_name}_${arch_name}.tar.gz"
if [ -n "${EARNIE_RELEASE_BASE_URL:-}" ]; then
  download_base="${release_base_url}"
else
  download_base="${release_base_url}/download/v${version}"
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
curl -fsSL "${download_base}/${archive}" -o "${tmp}/${archive}"
curl -fsSL "${download_base}/checksums.txt" -o "${tmp}/checksums.txt"

cosign_identity='^https://github\.com/scanoss/earnie/\.github/workflows/release-cli\.yml@refs/tags/cli/v'
cosign_issuer='https://token.actions.githubusercontent.com'
if command -v cosign >/dev/null 2>&1; then
  if ! curl -fsSL "${download_base}/checksums.txt.bundle" -o "${tmp}/checksums.txt.bundle"; then
    echo "Could not download checksums.txt.bundle to verify the release signature" >&2
    exit 1
  fi
  if ! cosign verify-blob \
    --bundle "${tmp}/checksums.txt.bundle" \
    --certificate-identity-regexp "$cosign_identity" \
    --certificate-oidc-issuer "$cosign_issuer" \
    "${tmp}/checksums.txt" >/dev/null 2>&1; then
    echo "checksums.txt signature verification failed (an older cosign may need upgrading to read this bundle)" >&2
    exit 1
  fi
  echo "Verified the cosign signature of checksums.txt"
else
  echo "Signature verification skipped: cosign not found. To verify, download checksums.txt and checksums.txt.bundle from the release and run: cosign verify-blob --bundle checksums.txt.bundle --certificate-identity-regexp '${cosign_identity}' --certificate-oidc-issuer ${cosign_issuer} checksums.txt"
fi

expected="$(awk -v name="$archive" '$2 == name { print $1 }' "${tmp}/checksums.txt")"
if [ -z "$expected" ]; then
  echo "No checksum found for ${archive}" >&2
  exit 1
fi
if command -v sha256sum >/dev/null 2>&1; then
  actual="$(sha256sum "${tmp}/${archive}" | awk '{print $1}')"
elif command -v shasum >/dev/null 2>&1; then
  actual="$(shasum -a 256 "${tmp}/${archive}" | awk '{print $1}')"
else
  echo "A SHA-256 checksum tool is required" >&2
  exit 1
fi
if [ "$actual" != "$expected" ]; then
  echo "Archive checksum verification failed" >&2
  exit 1
fi

tar -xzf "${tmp}/${archive}" -C "$tmp" earnie
if ! mkdir -p "$install_dir" || [ ! -w "$install_dir" ]; then
  echo "Install directory is not writable: ${install_dir}" >&2
  echo "Choose a writable directory with EARNIE_INSTALL_DIR." >&2
  exit 1
fi
install -m 0755 "${tmp}/earnie" "${install_dir}/earnie"
echo "Installed Earnie CLI ${version} at ${install_dir}/earnie"
