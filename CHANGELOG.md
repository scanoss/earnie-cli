# Changelog

All notable changes to the Earnie CLI. The release workflow publishes this
file to `scanoss/earnie-cli` and uses the section of the released version as
its release notes.

## [Unreleased]

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
