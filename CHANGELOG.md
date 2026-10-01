# Changelog

All notable changes to the Earnie CLI. The release workflow publishes this
file to `scanoss/earnie-cli` and uses the section of the released version as
its release notes.

## [Unreleased]

## [0.2.3] - 2026-10-01

### Added

- `earnie scan path` and `earnie scan diff` send the GitHub Actions or GitLab
  CI pipeline they run in, and a GitHub Action and a GitLab CI template run
  them. A pipeline the CLI cannot read now fails with exit 8.
- The generated findings list parameters carry an optional `scan_only` filter,
  which narrows a pull request scan's findings to the ones it introduced. No
  CLI command sends it yet, so no CLI release is required.
- The generated scans models include the upload limits the api reports from
  `GET /v1/scans/upload-limits`. No CLI command reads them yet, so no CLI
  release is required.

### Changed

- A server error (5xx) no longer carries the server's internal error text.
  The CLI prints a fixed message with the request ID instead, for example
  `Internal Server Error. Quote request ID <id> when you report this.`, and
  the cause is in the API log under that ID. The error `code` is unchanged.
  Three errors keep a fixed hint instead: a repository that could not be
  fetched, a scanner worker that is not running, and models that are not
  available on the deployment.
  No CLI release is required: the CLI already prints the message it gets.
- The generated project models accept an optional `connection_id` on
  repository import and connect, so two hosts can each bind a repository at
  the same path. Resolving a project by `--repository` answers
  `ambiguous_project` when that path is bound on two hosts; select the project
  instead. Existing CLI requests remain compatible; no CLI release is required.

### Fixed

- `earnie scan staged` and `earnie scan diff` with nothing to check exit 0 and
  say so. They print `nothing to check:` and the reason on standard error, and
  under `--format json` they print one document whose `gate` is `none` and
  whose `wait.outcome` is `nothing_to_check`. An empty diff used to exit 8 with
  `source_unavailable`, and an empty staged scan printed nothing at all. No
  request reaches the API in either case.
- A scan that did not select a scanner, such as an OSS-only scan on a project
  with an AI policy attached, no longer reports the gate as `error` with
  `missing_evidence`. A policy that reads only a scanner the scan left out
  reports the new verdict `not_applicable` and does not decide the gate, so
  `earnie scan` and `earnie verdict` exit on the policies that did apply. A
  scanner the scan selected that fails still exits 3. The fix is on the
  server, and the CLI passes the verdict through unchanged, so no CLI release
  is required.

## [0.2.2] - 2026-09-30

### Added

- The generated project models include the bulk import of a connection's
  repositories. No CLI command uses them yet, so no CLI release is required.

- Model inventory responses include source-discovered model findings alongside
  uploaded assets, with optional current triage state/version and matched model
  license. Scan file listings include model paths without counting them as OSS
  matches. Existing CLI requests remain compatible; no CLI release is required
  for these server-side projections.

- The generated API models accept a per-scan Git LFS model-download choice
  for Git submissions, repository import/connect, and reruns. Existing CLI
  requests remain compatible; no CLI release is required for the server fix.

- The generated `Project` model carries the bound repository's provider and
  connection. No CLI command reads them yet, so no CLI release is required.

- The generated client models for findings and component rows carry an
  optional `remediation` assessment. No CLI command renders it yet, so the
  CLI does not need a new release for it.

### Changed

- Trusted default-head scans retain their results for pull-request baseline
  inheritance without being labelled as push events. Historical scans without
  retained results still fall back to full scanning. No CLI release is required.

- Server-side crypto normalization preserves malformed padding-as-mode evidence
  without exposing it as a cipher mode; policy fields now offer JCA PKCS1Padding.
  No CLI binary release is required.

- Project posture now includes the first completed full default-head repository
  scan, without requiring a later push. This is a server-side correction;
  existing CLI requests remain compatible and no new CLI release is required.

- The container image builds from Go 1.25.14 and Alpine 3.22 base images
  pinned by digest, so a rebuild of the same release uses the same bases.
- `earnie export --bom-format spdx` with the crypto or ai section writes an
  SPDX file whose document comment counts the cryptographic assets and AI
  models it leaves out. SPDX 2.3 cannot describe them; export CycloneDX to
  get them. The server makes this change, so it needs no new CLI.
- A policy that reads a vulnerability's CWE classification is reported as not
  evaluated, with `cwe` as the missing enrichment, instead of passed. The
  server receives no CWE data yet, so the pass meant nothing. Missing
  evidence fails the gate, for a `warn` policy too. `earnie scan` exits
  with `evaluation_error`, `earnie mcp review` shows `Gate: error`, and the
  pre-commit hook reports the Self-check as failed, which blocks the commit
  when the hook is fail-closed. Detach the policy from the Project to clear
  it. Every CLI version behaves this way, because the server decides it.

- A Self-check whose upload stopped, for example when a hook timed out or
  was interrupted, reads `failed` once the server cancels it after an hour
  idle. It read `running` until it was purged 30 days later, and a
  `status=failed` listing never found it. This is a server-side correction;
  no CLI release is required for it.

### Fixed

- `earnie scan staged` and the pre-commit hook run the Self-check again.
  Since 0.2.0 they waited for the upload through the Scan read, which never
  serves a Self-check. The hook reported "scan status returned HTTP 404" and
  allowed every commit without checking it. They now wait on the ingest
  cursor. Install this release to get the fix: the server did not change.
- `earnie scan path`, `scan staged` and `scan diff` skip symlinks,
  submodules and special files such as sockets instead of refusing the whole
  source, so repositories like kubernetes and django scan, and a pre-commit
  hook no longer skips its Self-check on a commit that touches a symlink. A
  link is never followed: its target inside the tree is scanned at its own
  path, and nothing outside the scanned path is read. A file replaced by a
  link counts as deleted. A scan path that is itself a symlink is still
  refused.
- An error names its cause in the text output, the JSON `message` and the
  pre-commit hook notice. `collect the source set [source_unavailable]` now
  says which file failed and why, and `check server compatibility` says why
  the server could not be reached. A flag error no longer repeats itself.
- `earnie scan staged --format hook --scanners <list>` runs the scanners it
  names. The hook accepted `--scanners` and ran every scanner the
  organization enabled. The hook `earnie hook install` writes passes no
  `--scanners`, so it is unchanged. Customers get this fix from a new CLI
  release.
- The pre-commit hook and `earnie scan staged` report the files their
  Self-check reviewed and the scanners it did not run. They showed
  `Files: 0 submitted, 0 included` and no `Scanners not run` line, and
  `scan staged --json` reported `files_total: 0`. A policy whose scanner did
  not run on such a Self-check is reported as not evaluated instead of
  passing with no findings to read, as it already was for `earnie mcp review`.
  The server makes this change, so it needs no new CLI.
- A pre-commit hook or `earnie scan staged` Self-check completes on a
  deployment that cannot run a scanner the organization enabled. It runs the
  scanners the deployment has and reports the missing one as unavailable, as
  `earnie mcp review` does. It failed with `the Self-check failed: requested
  scanner is not configured`, so a fail-closed hook blocked every commit.
  `--scanners` naming a scanner the deployment cannot run is refused with
  `module_disabled`. The server makes this change, so it needs no new CLI.

## [0.2.1] - 2026-09-26

### Added

- `earnie mcp review`, the coding-agent hooks and the pre-commit hook name
  every scanner a Self-check did not run, with the reason. A Self-check now
  also runs AI provenance.
- `earnie mcp doctor` says, for each scanner domain, whether your key sees
  it and why not: the organization has not enabled it, or the key is not
  scoped to it.
- `earnie scan path|staged|diff --scanners oss,crypto,ai` chooses the
  scanners. Without it the server runs every scanner your organization
  enabled that your key may use.
- A model file finding reports its identification (status, model, match
  method and confidence) in JSON output and in `--details`.
- `earnie export --include oss,crypto,ai --bom-format cyclonedx|spdx
  --output FILE` downloads a bill of materials for the Project: crypto alone
  is a CBOM, ai alone an AIBOM. It reuses the scan's snapshot with the same
  sections when there is one.

### Changed

- A request refused because the organization has not enabled a scanner, or
  because the API key is not scoped to it, says which of the two it is and
  what to do.
- `earnie policy violations` reads every page of a policy's violations. The
  server now returns them in pages, and 0.1.1 shows only the first one.
- `earnie scan` waits until the server has prepared the scan before it
  uploads files.
- A repository with a `gitlab.com` remote resolves to its Earnie project.

### Fixed

- `earnie mcp setup` accepts the file modes Windows reports for existing
  agent configuration files.
- The release installs the GitHub CLI it needs, so it publishes from the
  self-hosted runners.

## [0.2.0] - 2026-09-26

- Release tag that never published; use 0.2.1.

## [0.1.1] - 2026-09-11

### Fixed

- The release keeps its `cli/v` tag prefix, so the first public release
  publishes.

## [0.1.0] - 2026-09-10

- First release tag. It never published; use 0.1.1.
