# Earnie CLI

Install and run the Earnie customer CLI on macOS, Linux, or Windows. This
repository contains release artifacts, the checksum-verifying installer, and
verification guidance. It does not contain the Earnie monorepo source or source
archives.

## Install

### Homebrew

```sh
brew install scanoss/dist/earnie
```

### Installer for macOS and Linux

```sh
curl -fsSL https://github.com/scanoss/earnie-cli/releases/latest/download/install.sh | sh
```

The installer supports amd64 and arm64, verifies the downloaded archive against
the release SHA-256 list, and writes to `$HOME/.local/bin`. It never invokes
`sudo`. To choose another writable directory:

```sh
curl -fsSL https://github.com/scanoss/earnie-cli/releases/latest/download/install.sh \
  | EARNIE_INSTALL_DIR="$HOME/bin" sh
```

### Manual download

Download the archive for your operating system and architecture from
[Releases](https://github.com/scanoss/earnie-cli/releases). Windows releases are
provided as amd64 `.zip` files. Linux and macOS releases are `.tar.gz` files for
amd64 and arm64.

## Start using Earnie

Confirm the installed build, authenticate to your Earnie tenant, and scan a
repository:

```sh
earnie version
earnie auth login --api-url https://your-earnie.example
earnie scan path .
```

`earnie version` always prints the CLI version and source commit. When an API
URL is configured, it also reports the tenant API version and compatibility
requirements.

## Verify release signatures

Each release includes `checksums.txt`, a keyless cosign bundle for that checksum
file, and one cosign bundle per archive. Install
[cosign](https://docs.sigstore.dev/cosign/system_config/installation/) before
verification.

Download an archive and its `.bundle`, plus `checksums.txt` and
`checksums.txt.bundle`, from the same release. First verify that the checksum
list was signed by the Earnie CLI release workflow:

```sh
cosign verify-blob \
  --bundle checksums.txt.bundle \
  --certificate-identity-regexp '^https://github.com/scanoss/earnie/.github/workflows/release-cli.yml@refs/tags/cli/v' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  checksums.txt
```

Set the downloaded archive name and verify its checksum:

```sh
archive=earnie_1.4.2_linux_amd64.tar.gz

# Linux
grep "  ${archive}$" checksums.txt | sha256sum -c -

# macOS
grep "  ${archive}$" checksums.txt | shasum -a 256 -c -
```

Finally, verify the archive's keyless signature:

```sh
cosign verify-blob \
  --bundle "${archive}.bundle" \
  --certificate-identity-regexp '^https://github.com/scanoss/earnie/.github/workflows/release-cli.yml@refs/tags/cli/v' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  "$archive"
```

## Run the container

The signed multi-architecture image supports linux/amd64 and linux/arm64. Pin a
release version for reproducible automation:

```sh
docker run --rm ghcr.io/scanoss/earnie-cli:X.Y.Z version
```

To scan the current directory, pass tenant configuration at runtime rather than
baking credentials into an image:

```sh
docker run --rm \
  -e EARNIE_API_URL \
  -e EARNIE_API_KEY \
  -v "$PWD:/workspace" \
  -w /workspace \
  ghcr.io/scanoss/earnie-cli:X.Y.Z scan path .
```

Container images are signed by the same GitHub Actions workflow as the release
archives. Use the immutable image digest from the release workflow when
verifying or pinning a production deployment.

## Update behavior

Earnie may print a best-effort update notice on standard error after a
successful command. It never downloads or installs an update automatically.
Upgrade with Homebrew or rerun the installer when you choose.

Disable the network check for one command or for automation:

```sh
earnie --no-update-check version
export EARNIE_NO_UPDATE_CHECK=1
```

The update check never changes the command result or exit code.

## Troubleshooting

### `earnie` is not found after installation

Add the default install directory to your shell path:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

### The install directory is not writable

Choose a directory owned by your user with `EARNIE_INSTALL_DIR`. The installer
does not elevate privileges or silently use `sudo`.

### The installer reports an unsupported platform

Use a manual release archive. The installer supports Linux and macOS on amd64
and arm64; Windows uses the amd64 zip release.

### The CLI asks for an API URL

Run `earnie auth login --api-url https://your-earnie.example`, or set
`EARNIE_API_URL` for automation. Keep API keys in your secret manager and pass
them at runtime.

### Verification fails

Confirm the archive, its bundle, `checksums.txt`, and `checksums.txt.bundle` all
came from the same release. Do not install an archive whose checksum or cosign
verification fails.
