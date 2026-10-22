# Changelog

All notable changes to the Earnie CLI. The release workflow publishes this
file to `scanoss/earnie-cli` and uses the section of the released version as
its release notes.

## [Unreleased]

## [0.4.0] - 2026-10-22

### Added

- `earnie model scan <file>` uploads one AI model file (weights such as
  `.safetensors`, `.gguf` or `.onnx`, or a Hugging Face snapshot as `.tar`,
  `.tar.gz` or `.tgz`) to the Project and waits for its AI provenance result,
  listing each finding with its status, component, confidence and license. The
  file is sent in 16 MiB windows, and scanning the same file again after an
  interruption resumes from the bytes the server already holds. `--no-wait`
  returns once the upload is sealed, and `--timeout` bounds the wait. It exits 0
  when the model was identified or not matched, 3 with `model_scan_failed` when
  its scan failed, and 8 with `model_too_large` when the file exceeds the
  deployment's model size cap (larger models cannot be scanned yet). `--json`
  prints the report in a new `model` member of the envelope. It needs an API key
  scoped to the `ai` scanner with `scans:read` and `scans:write`. The generated
  Go client `pkg/earnieclient` gains the model upload and read operations.
- The notification kinds `earnie notifications rules create --kind` accepts now
  include `cra_deadline`, the security reminder that a CRA reporting stage is
  near, at or past its due time. It is a security kind, so it cannot be turned
  off and `earnie notifications health` counts a rule for it as a security
  route.
- `earnie integrations list [--provider github|gitlab]` lists the GitHub and
  GitLab connections with their recorded health, the permissions each is missing
  (with the level needed) and the provider page where an admin grants them.
  `earnie integrations verify <connection-id>` asks the provider again, records
  its answer as the connection's health and exits 9 when the connection is
  degraded or disconnected; when the provider cannot be reached it fails and the
  recorded health is kept. Both need an API key with `integrations:read` and
  change no setting. `earnie integrations connect <github|gitlab>` prints the
  Settings > Integrations link where a person signed in to Earnie connects the
  provider; it makes no request, because an API key cannot connect a provider.
  `--json` prints the report. The commands need a server that serves
  `POST /v1/integrations/connections/{connection_id}:verify`.
- `earnie doctor` checks the SCANOSS API key before it reads the integrations
  status: the server calls the SCANOSS API once with its configured key, and the
  SCANOSS API key entry then says whether the key works, was refused, is rate
  limited or out of quota, or could not be checked because the SCANOSS API was
  unreachable. A refused key shows up as a disconnected integration with a link
  to get a key, so the command exits 9. A server that does not have the check
  yet, or a key that may not run it, still gets the status as before. The
  command needs a server that serves `POST /v1/integrations/scanoss-api-key:test`
  to run the check.

- `earnie doctor` shows one status for every integration the server knows
  (source-code connections, single sign-on, notification channels, the SCANOSS
  API key and API keys), each with a link to fix it when it is degraded or
  disconnected, and runs the checks of `earnie mcp doctor` after it. It reads
  what the server already recorded and changes nothing. It exits 9 when an
  integration is degraded or disconnected or an MCP check fails; an integration
  that was never configured is not a problem. A key without `integrations:read`
  still gets the MCP checks and the output says the integrations were not
  checked. An integration whose settings the caller may not read (single
  sign-on needs `sso:read`, notification channels `organization:read`, API keys
  `apikeys:read:all`) is left out. `--json` prints `{ok, integrations, mcp}`. The command needs a
  server that serves `GET /v1/integrations/status`.

- `earnie notifications test <channel>` sends a real test message through a saved
  notification channel and reports how it ended. `<channel>` is a channel id or the
  exact name of a channel; a name is looked up in the channel list, so a key that
  tests by id needs only `notifications:write`. The output names the channel, the
  outcome and the message that says what to fix, plus the address an email test went
  to. It exits 0 when the message was sent and exits 3 with
  `notification_test_failed` and the failure reason when it was not. It never
  repeats a test on its own, because the message is real. A key without
  `notifications:write` exits 5, and an unknown channel exits 8 with
  `channel_not_found`. No flag takes a secret: a secret is set by a person in the
  web app. The JSON output gains an optional `notification_test` member with the
  channel, outcome, reason, message and recipient. It needs a server that has the
  channel test endpoint and a key with `notifications:write`.

- `earnie notifications channels list|create|update|delete` sets up notification
  channels from a terminal or an agent. A channel is a channel id or an exact name.
  `channels create` takes `--kind`, `--name`, `--enabled`, the `--email-*` settings
  and `--webhook-url`. `channels update` sends only the flags you pass. No flag takes
  a secret: a channel that needs one is saved disabled, and the output says so and
  prints the web link `<server>/settings/notifications?channel=<id>` where a person
  enters it. Reads need `organization:read` and changes `notifications:write`. A
  missing scope exits 5 naming it, an unknown channel exits 8, and writes are never
  repeated on their own. An API key cannot change where a stored secret is sent:
  `channels update` that moves it exits 5 with `secret_requires_member`. The JSON output gains the optional `notification_channels`,
  `notification_channel` and `notification_deleted` members. It needs a server that
  serves the notification channel routes of the REST API.

- `earnie notifications rules list|create|delete` and `earnie notifications health`
  finish the setup. `rules create --class <class> [--kind <kind>]... --channel
  <channel>` routes a class of notification to a channel, and `rules delete
  <rule-id>` removes a rule. `health` says whether the server holds the
  notifications key and whether security notifications have a route outside the
  inbox. Reads need `organization:read` and changes `notifications:write`. An
  unknown rule exits 8. The JSON output gains the optional `notification_rules`,
  `notification_rule` and `notification_health` members.

- The bulk-resolve response model gains an optional `needs_decision` count,
  present only on an `introduced_via` dry run: how many of the selected findings
  a policy flags. Nothing the CLI sends or prints changes.

- `earnie scan retry <scan-id> --producer crypto|ai` runs a failed scanner again
  on a scan that completed without it. The scan and the findings of the scanners
  that finished stay as they are; when the new attempt succeeds, that scanner's
  findings and the scan's gate update. Asking again while an attempt is in
  flight opens no second one. Without `--wait` it exits 0 once the attempt is
  accepted; with `--wait` (and `--timeout`) it waits for the attempt to end and
  exits like `earnie scan wait`, or exits 3 with `producer_retry_failed` and the
  failure code when the attempt fails again. A scanner that cannot be retried
  exits 8 with the server's code, such as `producer_not_failed` or
  `scan_superseded`. The JSON output gains an optional `retry` member with the
  producer, whether this call opened the attempt, its outcome and every
  attempt. It needs a server that has the retry endpoint and a key with
  `scans:write`.

- A scan read now says whether a failed scanner can be retried: each failed
  scanner in a scan's `producers` carries `retry_refusal` when a retry would be
  refused (`scan_not_retryable`, `producer_not_retryable` or `scan_superseded`),
  and carries none when a person who can run scans may retry it.

- `earnie scan ci` scans what the pipeline checks. In a GitHub pull request or
  GitLab merge request pipeline it diffs against the base the pipeline names;
  in any other pipeline it scans the whole tree; outside a CI it exits 8 with
  `ci_not_detected`. `--base <ref>` replaces the base. A shallow clone without
  the base exits 8 with `shallow_clone` and names `fetch-depth: 0` or
  `GIT_DEPTH: 0`.

- Each policy approval in the JSON output of `earnie policy violations` and
  `earnie policy show` now carries `different_approver_required`: whether the
  organization setting "Require a different approver" was on when the approval
  was decided. It is `false` for a pending request and for every decision made
  before the setting existed.
- The generated `earnieclient` models gain fields the CLI does not read, so its
  behaviour is unchanged: `inventory` on the AI usage rollup, and `inventory`,
  `files_inventory` and `findings_inventory` on the review file queue, and
  `needs_decision` on a finding, for AI usage findings that need no decision.
- The generated `earnieclient` models gain `roots` and `dev` on dependency
  evidence: the root manifests whose lockfile graph holds the package, and
  whether the project needs it only to develop it. A package only a lockfile
  names carries no declarations. The CLI does not read `roots` or `dev`, so its
  behaviour is unchanged. `dependency_count` in a scan or project summary now
  counts the packages of the lockfile graph when the scan has one.
- The generated `earnieclient` models gain the GitLab import hook plan
  (`hooks` on the bulk import preview, `hook_scope` on the bulk import request
  and batch, and per-repository hook results on the batch). The CLI does not
  read them, so its behaviour is unchanged.
- The generated `earnieclient` models gain the `inventory` component state and
  its `state` filter value, for a component whose declared dependencies need no
  decision. The CLI does not read them, so its behaviour is unchanged.

- The model finding status gains `declared`: a repository the knowledge base
  knows whose files were not matched. `earnie` reports it as a model status that
  is not identified. The generated `earnieclient` models gain the matching
  `declared` count and `ModelDeclaredDetail`.
- A Model gains `source` (`upload` or `huggingface`) and `source_ref`, its
  `weights` gain `none` for a Model that was never uploaded, and the server gains
  `POST /v1/projects/{projectId}/models/huggingface`, which adds a Model by its
  Hugging Face id. The generated `earnieclient` models carry them. No CLI command
  uses them, so its behaviour is unchanged.
- A declared model finding gains the reason `gated`: Hugging Face hides the file
  hashes of a gated repository, so none could be looked up. The generated
  `earnieclient` models carry it. The CLI does not read it.
- A scan read of a single scan now carries `degraded`, true when the scan
  completed but one of its scanners failed, and `producers`, the outcome and
  attempts of each scanner. The generated `earnieclient` models gain both
  fields, plus `ScanProducerResult` and `ScanProducerAttempt`. The CLI does not
  read them, so its behaviour is unchanged.

- Each version in a component of `GET /v1/findings/components` now carries its
  own `total_count` and `decided_count`, its own `vulnerabilities` and a
  `canonical_purl`, and the generated `earnieclient` models gain those fields on
  `ComponentVersionRef`. The component's counts are still the sums of its
  versions. The CLI does not read them, so its behaviour is unchanged.

### Changed

- `earnie export` no longer lists dev dependencies (test runners, build tools and the
  packages only they pull in, as the lockfile marks them) in the CycloneDX or SPDX document.
  The server now leaves them out unless the snapshot is generated with
  `include_dev_dependencies`; the CLI has no flag for it yet, so a CLI export always omits them.
  A package your code matched in the tree stays. This needs no CLI release: the change is in the server.
- The SBOM that `earnie export` downloads now carries the dependency graph
  Earnie stored for the scan: CycloneDX `dependencies` and per-manifest
  `compositions`, SPDX `DEPENDS_ON` relationships. The change is on the server,
  so it needs no new CLI release; snapshots made before it keep their old
  statement that the graph was not assessed.

- The GitHub Action and the GitLab template now run `earnie scan ci` by
  default instead of `earnie scan path .`, so a pull or merge request scans only
  its changes. Check out with `fetch-depth: 0` in GitHub Actions; the GitLab
  template sets `GIT_DEPTH: 0`. Set `args: path .` to keep the old scan.

- On macOS and Windows the CLI now honours `SSL_CERT_FILE` and `SSL_CERT_DIR`
  over the system keychain. Unset them, or set
  `GODEBUG=x509sslcertoverrideplatform=0`, to keep using the keychain.
- The macOS builds now need macOS 13 Ventura or later.
- Dependency updates: `charm.land/bubbletea/v2` 2.1.0, `golang.org/x/mod`
  0.42.0, `golang.org/x/sys` 0.49.0 and `golang.org/x/term` 0.47.0. No
  behaviour change is expected.

### Security

- The CLI is built with Go 1.27.3 instead of 1.25.8, picking up the standard
  library security fixes since, including `crypto/tls`, `crypto/x509` and
  `net/http`. 1.27.3 fixes GO-2026-6809 in `crypto/x509`. Building the CLI from
  source now needs Go 1.27.

## [0.3.1] - 2026-10-07

### Added

- `install.sh` verifies the cosign signature of `checksums.txt` against the
  release's `checksums.txt.bundle` when `cosign` is on your `PATH`, and refuses
  to install when the signature is bad. Without `cosign` it prints one line
  saying signature verification was skipped, with the exact `cosign
  verify-blob` command to run. The SHA-256 check stays.
- The generated `earnieclient` models gain fields the CLI does not read, so its
  behaviour is unchanged: `advisory_gate` on the scan publication block
  (whether a blocking verdict can stop the change request's merge);
  `project_count` on a bulk import batch, with an optional `batch` filter on the
  estate reads `projects:posture` and `crypto/posture`; `projects_updating` on
  the estate crypto posture, `updating` and `as_of` on each of its projects,
  and `weak_crypto_updating` and `weak_crypto_as_of` on the project posture
  row, for numbers still being recalculated.

### Changed

- The findings of a scan, which the scan commands read, now include crypto,
  dependency and AI findings on files the OSS scan skips by default (HTML,
  Markdown, YAML). Before, they were left out of the count. No CLI change is
  needed to get this; the server returns them.
- `earnie scan staged` run by hand now records its run as a `CLI self-check`
  instead of `Pre-commit hook`. Only the installed hook (`--format hook`)
  reports the pre-commit producer. Every other `earnie scan` run now declares
  the `cli` producer, so a raw REST call with an API key reads `API` while the
  CLI still reads `CLI`. Scans from CLI 0.3.0 and earlier keep the `CLI` label:
  the server treats an API-key submission that declares no producer and names
  its archive exactly `cli` as a CLI scan. Any other undeclared API-key
  submission reads `API`.
- The compatibility check that starts every command, including `earnie scan
  wait`, now retries network errors and 5xx answers with the polling budget (8
  attempts, 1 second doubling to a 30 second cap) instead of failing at once
  during an outage. An incompatible CLI or a 4xx answer still fails at once.
  The `earnie scan` and `earnie scan wait` help names the budget.
- Self-checks and scans from `earnie scan` are named after the branch and
  short commit (`feat/payments@4f9c2a1`), or the first file and how many more,
  instead of `cli`.
- `earnie export` documents now name the project they describe. The CycloneDX
  root component carries the project name, a slug-based `bom-ref` and the
  scan's commit as its version (omitted for an uploaded archive), and the SPDX
  document is titled after the project instead of `earnie-project`. The server
  generates the document, so no CLI update is needed.
- CycloneDX documents carry a `compositions` entry with aggregate `unknown`,
  stating that the dependency graph is not included, and an SPDX document's
  `documentNamespace` is unique per snapshot. The CLI downloads these
  documents as they are.
- The snapshot format enum gains `report-html`, `report-csv`, `report-xlsx`
  and `report-pdf`. Older CLIs list such artifacts without error.
- The `earnieclient` models change in ways the CLI does not read, so its
  behaviour is unchanged. The project posture row has `scan_in_progress`, true
  while the project has a scan that has not finished, and `high_cves`, which
  counts critical plus high CVEs the way the project dashboard does. The
  posture gate gains the value `require` (a project with findings awaiting
  approval) and the attention condition `approval_required`; the attention
  condition constants are now prefixed `AttentionCondition`. `weak_crypto` on
  the posture row is the same number as the project's crypto card (dependency
  crypto in a dismissed dependency no longer counts, and a project scanned
  clean reports 0 instead of null). `review_coverage` on an SBOM snapshot is
  the share of the scan's findings that need a decision and have one, the same
  figure as the Review header, and `component_count` is the components included
  in the snapshot. The project summary model no longer has `crypto` or
  `last_crypto_scan_at`; they are on the new project crypto summary model. The
  bulk-resolve and bulk-resolve preview descriptions now say they select open
  or reopened findings.
- Dependency updates: `bubbletea` 2.0.9, `huh` 2.0.3, `go-toml` 2.4.3,
  `go-keyring` 0.2.8 and `oapi-codegen/runtime` 1.7.0.

## [0.3.0] - 2026-10-03

### Added

- `earnie mcp setup` (and `--hooks`) now installs a session-start hook for
  Claude Code, Cursor and Codex that refreshes the Earnie policy block in
  `AGENTS.md`, `CLAUDE.md` or `.cursor/rules/earnie.mdc`. It replaces only what
  lies between the `<!-- earnie:policies:start ... -->` and
  `<!-- earnie:policies:end -->` markers, does nothing when the server's set
  revision equals the block's, never creates a block setup did not write, and
  never fails a session: an unreachable server adds at most about three
  seconds, and a timeout or a missing key leaves the file untouched and logs
  to stderr. Claude Code and Codex run it on `startup` and `resume` only;
  Cursor has no matcher. Edits made inside the managed block are overwritten
  the next time the revision changes, and edits to the markers themselves stop
  the refresh. `earnie mcp doctor` reports hooks that predate it
  (`policy_refresh` in `--json`), and `earnie mcp uninstall` removes it with
  the other hooks. Rerun `earnie mcp setup --hooks` to add it to an existing
  checkout.

- `earnie export --fresh` always generates a new SBOM snapshot.

- The generated triage models carry new optional crypto evidence fields: per
  call-chain frame `library` (module, version, purl), `entry_resolution` and
  `entry_declared_type`; per chain `dependency_path` and `root_kind`; the
  `call_paths_total` / `call_paths_kept` route counts; the `route_evidence`
  tier (`direct`, `dispatch`, `name_only`) and `no_callers_only` flag;
  `dependency_provenance` (the dependency's `direct` or `transitive`
  relationship and declared path, each step marked `without_source` when it
  was scanned without source); and the `unresolved_dispatch` and
  `dependency_without_source` unknown reasons. No CLI command renders them yet.

### Changed

- **Behaviour change for CI scripts:** `earnie mcp doctor` and
  `earnie mcp setup --check` now exit 9, not 2, when they find a problem. 2 is
  the gate Require code. A script that treated doctor's exit 2 as "problems
  found" must test for 9. Exit 0 (healthy) is unchanged.

- **Behaviour change for CI scripts:** `earnie mcp review` now exits from the
  review's gate like `scan` and `verdict`: 1 for Block, 2 for Require, 0 for
  Pass, Warn and None, and 3 (fail closed) when the review did not complete,
  for example because it is still running, or its gate is an error or unknown.
  It used to exit 0 whatever the gate said, so a CI step could not fail on a
  blocked review.

- `earnie export` no longer generates a new SBOM snapshot on every run. It
  downloads the scan's latest snapshot that has the requested `--bom-format`
  and the sections you named with `--include`, or, without `--include`, the
  default sections the server reports for your key and plan, so a crypto-only
  or AI-only snapshot is never returned in place of the default export. It
  generates one only when none matches, when the server does not report its
  default sections, or when the project's review state changed since the
  latest snapshot (stale), saying so on stderr; `--quiet` silences the note.

- Server: crypto findings in a project whose dependencies do not resolve (no
  lockfile or build file) now read `reachable` or `unreachable` instead of
  `unknown`, because the scan traces the project's own source. A policy on
  reachable crypto can therefore start to fire on such a project, and
  `earnie scan` reports it.

### Fixed

- `EARNIE_SKIP_REVIEW` is read as a boolean. `1`, `true`, `yes` and `on` skip the
  review; `0`, `false`, `no` and an empty value no longer do. Any non-empty
  value used to skip, so `EARNIE_SKIP_REVIEW=0` silently disabled the review.

- Usage errors now exit 8, as documented, instead of 3: `earnie mcp review`
  without exactly one selector, `earnie scan diff` without `--base`, an unknown
  or duplicate `--client`, `--global` with `--project`, `--check` with
  `--dry-run`, `--hooks` and `--no-hooks` together, a missing API URL in
  `mcp setup` and `mcp doctor`, and unreadable `mcp hook` input or a missing
  `--client`. Hook adapters stay clear of exit 2, which Claude Code and Cursor
  read as "block", so their input errors cannot block an agent.

- `earnie export` on a project whose latest scan finished before SBOM evidence
  was kept now fails with the error code `scan_evidence_unavailable` and a
  message telling you to run a new scan. The server used to answer HTTP 500,
  which the CLI reported as a retryable `api_unavailable`, so a retry could
  never succeed.

- Server: SBOM documents from `earnie export` and the `earnie_export_bom` tool
  keep the licence the scan detected next to a concluded one: a `declared`
  entry beside the `concluded` one in CycloneDX, and `licenseDeclared` in SPDX
  (it read `NOASSERTION`).

- Server: SBOM documents name Earnie and the server build as the generating
  tool (`earnie` and its version). They named the SBOM library (`scanoss`,
  version `dev`).

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
