# Earnie CLI releases

This repository distributes signed customer CLI releases for Earnie. The
commercial source remains in the private Earnie monorepo and is not mirrored
here.

## Install

With Homebrew:

```sh
brew install scanoss/dist/earnie
```

With the checksum-verifying installer:

```sh
curl -fsSL https://github.com/scanoss/earnie-cli/releases/latest/download/install.sh | sh
```

The installer supports Linux and macOS on amd64 and arm64. It downloads the
release checksum list, verifies the selected archive, and installs to
`$HOME/.local/bin` unless `EARNIE_INSTALL_DIR` names another writable directory.

Or run the signed multi-architecture image:

```sh
docker run --rm ghcr.io/scanoss/earnie-cli:X.Y.Z version
```

Every release also includes cosign bundles for its archives and checksum file.

## Verify a downloaded archive

Download the archive, `checksums.txt`, `checksums.txt.bundle`, and the archive's
`.bundle` file from the same release. First verify the signed checksum list:

```sh
cosign verify-blob \
  --bundle checksums.txt.bundle \
  --certificate-identity-regexp '^https://github.com/scanoss/earnie/.github/workflows/release-cli.yml@refs/tags/cli/v' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  checksums.txt
```

Then verify the archive checksum with the tool available on your system:

```sh
# Linux
sha256sum -c checksums.txt --ignore-missing

# macOS
shasum -a 256 -c checksums.txt
```

Then verify the keyless signature. Replace the example archive name with the
file you downloaded:

```sh
cosign verify-blob \
  --bundle earnie_1.4.2_linux_amd64.tar.gz.bundle \
  --certificate-identity-regexp '^https://github.com/scanoss/earnie/.github/workflows/release-cli.yml@refs/tags/cli/v' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  earnie_1.4.2_linux_amd64.tar.gz
```
