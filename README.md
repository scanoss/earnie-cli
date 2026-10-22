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
When `cosign` is on your `PATH`, it also verifies the signature of the checksum
list against the release's `checksums.txt.bundle` and stops if the signature is
bad. Without `cosign` it prints that signature verification was skipped, with
the command to run it yourself (see "Verify a downloaded archive").

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
    fetch-depth: 0
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

Both run `earnie scan ci`. In a pull or merge request pipeline it scans the
changes against the base the pipeline names; in any other pipeline it scans the
whole tree. `--base <ref>` replaces the base. The diff needs the base commit in
the clone, so check out with `fetch-depth: 0`; the GitLab template sets
`GIT_DEPTH: 0` itself. A shallow clone without the base exits 8 with
`shallow_clone` and names the setting. Outside a CI `earnie scan ci` exits 8;
use `earnie scan path` or `earnie scan diff --base <ref>` there. Both accept
`args` for `earnie scan`.

## Scan a model file

```sh
earnie model scan ./model.safetensors --project my-project
```

`earnie model scan` uploads one model file to the Project and waits for its AI
provenance result. It takes weights (`.safetensors`, `.gguf`, `.onnx`, `.bin`,
`.pt`, `.h5` and other framework formats) or a Hugging Face snapshot archived
as `.tar`, `.tar.gz` or `.tgz`. The output lists the model's status and one line
per finding with its status, component, confidence and license. Run the same
command again after an interrupted upload and it resumes from the bytes the
server already holds. `--no-wait` returns once the upload is sealed, and
`--timeout <duration>` bounds the wait; the scan keeps running on the server.

The API key needs `scans:write` and `scans:read` and must include the `ai`
scanner. Exit codes:

| Exit | Meaning |
| --- | --- |
| 0 | The scan finished, whether or not the model matched a known one |
| 3 | The model scan failed (`model_scan_failed`) |
| 5 | The key or organization does not have the `ai` scanner |
| 7 | The wait timed out |
| 8 | Not a model file, a directory or empty file, or larger than the deployment's model size cap (`model_too_large`) |

Models above the cap cannot be scanned yet.

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
