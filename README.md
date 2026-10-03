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

## Run in a pipeline

In GitHub Actions, check out the code and run the action; the job fails when
the gate blocks:

```yaml
- uses: actions/checkout@v4
  with:
    ref: ${{ github.event.pull_request.head.sha || github.sha }}
- uses: scanoss/earnie-cli@vX.Y.Z
  with:
    api-key: ${{ secrets.EARNIE_API_KEY }}
    api-url: https://earnie.example.com
```

In GitLab CI, set `EARNIE_API_KEY` (masked) and `EARNIE_API_URL` as CI/CD
variables and include the template; on a self-managed GitLab also set
`EARNIE_PROJECT`:

```yaml
include:
  - remote: https://raw.githubusercontent.com/scanoss/earnie-cli/vX.Y.Z/gitlab/earnie-scan.yml
```

The CLI reads the pull or merge request from the pipeline. Both accept `args`
for `earnie scan`.

## Exit codes

| Exit | Meaning |
| --- | --- |
| 0 | Success, or gate `pass`, `warn` or `none` |
| 1 | Gate `block` |
| 2 | Gate `require` (approval needed) |
| 3 | Scan, review, evaluation or gate failed, or an unclassified failure |
| 4 | Authentication failed |
| 5 | Authorization failed |
| 6 | Network failure |
| 7 | Timeout |
| 8 | Usage or configuration error, including a missing or conflicting flag |
| 9 | `earnie mcp doctor` or `earnie mcp setup --check` found a problem |
| 130 | Interrupted |

`earnie scan`, `earnie verdict` and `earnie mcp review` exit from the gate with
0, 1 or 2. Set `EARNIE_SKIP_REVIEW` to `1`, `true`, `yes` or `on` to skip
`earnie mcp review` and the review hooks; `0`, `false`, `no` or an empty value
does not skip. Coding-agent hook adapters never exit 2 on their own errors,
because Claude Code and Cursor read a hook's exit 2 as "block".

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
