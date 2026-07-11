# Antigravity CLI & IDE Pack For Edge

## Overview

This Cribl Edge pack collects local telemetry from Google Antigravity developer tools and forwards it to a Cribl Stream
worker group for indexing, analysis, and search.

Default-enabled coverage is limited to Antigravity paths documented by Google docs or codelabs:

- **Antigravity CLI (`agy`)** - settings, keybindings, MCP config, plugin manifests/hooks, import manifest, and agent
  brain markdown under `~/.gemini/antigravity-cli/`.
- **Shared Antigravity configuration** - global MCP config under `~/.gemini/config/mcp_config.json`.
- **Global rules** - Gemini/Antigravity global rules under `~/.gemini/GEMINI.md`.

Candidate app, IDE, runtime log, history, annotation, and code-tracker monitors remain available but are disabled by
default because the current Google documentation does not publish those paths as default local collection contracts.

Legacy Gemini CLI sources remain in the pack for compatibility but are disabled by default. Google announced that
consumer Gemini CLI and Gemini Code Assist IDE extension request serving ends on **2026-06-18** for free, Pro, and Ultra
users, while enterprise/API-key access can remain available. See Google's transition announcement:
<https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/>.

## Architecture

```text
Antigravity CLI (agy) ──writes──> ~/.gemini/antigravity-cli/{settings.json,keybindings.json,mcp_config.json,brain}
        |                                                  |
        |                                       Cribl Edge file monitors
        v                                                  |
Antigravity IDE ───────writes──> ~/.gemini/antigravity-ide/{brain,annotations,code_tracker,daemon}
        |                                                  |
        v                                                  |
Shared config ─────────writes──> ~/.gemini/config/mcp_config.json and ~/.gemini/GEMINI.md
        |                                                  |
        └────────────────────────────────────── Cribl HTTP output
                                                           |
                                                 Cribl Stream worker group
```

## Data Sources

### Antigravity CLI

Antigravity CLI is the terminal-first `agy` interface. It writes its active local state under
`~/.gemini/antigravity-cli/`.

Collected by default:

- **Settings** - `~/.gemini/antigravity-cli/settings.json`
- **Keybindings** - `~/.gemini/antigravity-cli/keybindings.json`
- **MCP config** - `~/.gemini/antigravity-cli/mcp_config.json`
- **Plugin metadata** - `plugins/<plugin>/plugin.json`, `plugins/<plugin>/mcp_config.json`,
  `plugins/<plugin>/hooks.json`, and `import_manifest.json`
- **Agent brain markdown** - `~/.gemini/antigravity-cli/brain/**/*.md`

Available but disabled by default:

- `~/.gemini/antigravity-cli/**/*.log`
- `~/.gemini/antigravity-cli/history.jsonl`
- `~/.gemini/antigravity-cli/annotations/*.pbtxt`
- `conversations/*.db`, `*.db-wal`, and `*.db-shm`
- `implicit/*.pb`
- uploaded media and executable helper binaries

### Antigravity IDE

The Google docs identify Antigravity IDE as a separate surface, but they do not currently publish default local filesystem
contracts for IDE logs, brain, annotation, code-tracker, or daemon state.

Available but disabled by default:

- **Agent brain** - `~/.gemini/antigravity-ide/brain/**/*.md` and `*.metadata.json`
- **Annotations** - `~/.gemini/antigravity-ide/annotations/*.pbtxt`
- **Code tracker** - `~/.gemini/antigravity-ide/code_tracker/**/*` text/source snapshots
- **Daemon/runtime logs** - `~/.gemini/antigravity-ide/**/*.log`
- **Config identity** - `mcp_config.json` and `installation_id`

### Antigravity Desktop App And Shared State

The desktop app writes VS Code-style application logs and user settings under
`~/Library/Application Support/Antigravity/`, app logs under `~/Library/Logs/Antigravity/`, and shared agent state under
`~/.gemini/antigravity/` and `~/.gemini/config/`.

Collected by default:

- **Shared MCP config** - `~/.gemini/config/mcp_config.json`
- **Global rules** - `~/.gemini/GEMINI.md`

Available but disabled by default:

- **Application logs** - `~/Library/Application Support/Antigravity/logs/**/*.log`
- **macOS Library logs** - `~/Library/Logs/Antigravity/*.log`
- **Application config** - app/user settings and cached configuration JSON
- **Shared brain** - `~/.gemini/antigravity/brain/**/*.md` and `*.metadata.json`
- **Shared annotations** - `~/.gemini/antigravity/annotations/*.pbtxt`
- **Shared code tracker** - `~/.gemini/antigravity/code_tracker/**/*` text/source snapshots
- **Shared runtime logs** - `~/.gemini/antigravity/**/*.log`
- **Shared state/config** - root text protobuf state, MCP config, and installation identity

Workspace rules can also exist under each project's `.agent/rules/` directory. This pack does not collect those by
default because there is no single global workspace root to monitor safely.

Common app log names include `main.log`, `auth.log`, `telemetry.log`, `cloudcode.log`, `rendererPerf.log`,
`sharedprocess.log`, `terminal.log`, `artifacts.log`, `ptyhost.log`, `remoteTunnelService.log`, `renderer.log`,
`network.log`, `textModelChanges.log`, `views.log`, `tasks.log`, `language_server.log`, and extension-host logs.

### Legacy Gemini CLI

Legacy Gemini CLI inputs remain available but disabled by default:

- `~/.gemini/tmp/**/chats/session-*.json`
- `~/.gemini/tmp/**/chats/session-*.jsonl`
- `~/.gemini/tmp/**/logs.json`
- `~/.gemini/settings.json`
- `~/.gemini/projects.json`
- OTLP gRPC receiver on `127.0.0.1:4317`

Enable these inputs only when you still have a supported Gemini CLI deployment to monitor.

## OpenTelemetry

Antigravity-specific custom OTel handling is not added in this pack. Cribl already has a built-in OpenTelemetry source,
and no current Antigravity CLI/IDE documentation requires a nonstandard OTLP receiver or payload path.

The legacy Gemini CLI OTLP input remains present but disabled by default. Gemini CLI's documented telemetry settings use
standard OTLP fields such as `GEMINI_TELEMETRY_ENABLED`, `GEMINI_TELEMETRY_OTLP_ENDPOINT`,
`GEMINI_TELEMETRY_OTLP_PROTOCOL`, and `GEMINI_TELEMETRY_OUTFILE`. See:
<https://google-gemini.github.io/gemini-cli/docs/cli/telemetry.html>.

## Data Contract

Events leave this pack tagged with a `datatype` metadata field. Downstream Cribl Stream routes or destinations can map
these datatypes to indexes, sourcetypes, datasets, or storage paths.

| Input                          | Datatype                       | Default  |
| ------------------------------ | ------------------------------ | -------- |
| `antigravity-app-logs`         | `antigravity-app-logs`         | Disabled |
| `antigravity-library-logs`     | `antigravity-library-logs`     | Disabled |
| `antigravity-app-config`       | `antigravity-app-config`       | Disabled |
| `antigravity-brain`            | `antigravity-brain`            | Disabled |
| `antigravity-annotations`      | `antigravity-annotations`      | Disabled |
| `antigravity-code-tracker`     | `antigravity-code-tracker`     | Disabled |
| `antigravity-runtime-logs`     | `antigravity-runtime-logs`     | Disabled |
| `antigravity-state`            | `antigravity-state`            | Disabled |
| `antigravity-shared-config`    | `antigravity-shared-config`    | Enabled  |
| `antigravity-global-rules`     | `antigravity-global-rules`     | Enabled  |
| `antigravity-cli-logs`         | `antigravity-cli-logs`         | Disabled |
| `antigravity-cli-history`      | `antigravity-cli-history`      | Disabled |
| `antigravity-cli-config`       | `antigravity-cli-config`       | Enabled  |
| `antigravity-cli-brain`        | `antigravity-cli-brain`        | Enabled  |
| `antigravity-cli-annotations`  | `antigravity-cli-annotations`  | Disabled |
| `antigravity-ide-logs`         | `antigravity-ide-logs`         | Disabled |
| `antigravity-ide-config`       | `antigravity-ide-config`       | Disabled |
| `antigravity-ide-brain`        | `antigravity-ide-brain`        | Disabled |
| `antigravity-ide-annotations`  | `antigravity-ide-annotations`  | Disabled |
| `antigravity-ide-code-tracker` | `antigravity-ide-code-tracker` | Disabled |
| `gemini-cli-sessions`          | `gemini-cli-session`           | Disabled |
| `gemini-cli-logs`              | `gemini-cli-logs`              | Disabled |
| `gemini-cli-settings`          | `gemini-cli-settings`          | Disabled |
| `gemini-cli-projects`          | `gemini-cli-projects`          | Disabled |
| `gemini-cli-otel`              | `gemini-cli-otel`              | Disabled |

## Requirements

- Cribl Edge 4.13.0+
- Antigravity CLI installed for the local user when collecting CLI sources
- Antigravity desktop app or IDE installed when enabling candidate app/IDE sources
- Supported default paths: macOS user-home layout
- Filesystem permissions for the Cribl Edge process to read `~/.gemini/`,
  `~/Library/Application Support/Antigravity/`, and `~/Library/Logs/Antigravity/`

## Setup

### Set `GEMINI_HOME`

All file monitors resolve paths from `$GEMINI_HOME`. Set it to the home directory of the user running Antigravity:

```bash
export GEMINI_HOME=/Users/<user>
```

Restart Cribl Edge after setting the variable.

### Grant Filesystem Permissions

If Edge runs as the same user that owns the Antigravity files, no extra permissions are normally required. If Edge runs as
a different user on macOS, grant read/list/search access:

```bash
chmod +a "cribl allow read,readattr,readextattr,readsecurity,list,search" /Users/<user>/.gemini
chmod -R +a "cribl allow read,readattr,readextattr,readsecurity,list,search" /Users/<user>/.gemini/
chmod +a "cribl allow read,readattr,readextattr,readsecurity,list,search" "/Users/<user>/Library/Application Support/Antigravity"
chmod -R +a "cribl allow read,readattr,readextattr,readsecurity,list,search" "/Users/<user>/Library/Application Support/Antigravity/"
chmod +a "cribl allow read,readattr,readextattr,readsecurity,list,search" "/Users/<user>/Library/Logs/Antigravity"
chmod -R +a "cribl allow read,readattr,readextattr,readsecurity,list,search" "/Users/<user>/Library/Logs/Antigravity/"
```

### Verify Source Files

```bash
find /Users/<user>/.gemini/antigravity-cli -name "settings.json" -o -name "keybindings.json" -o -name "mcp_config.json" -o -name "import_manifest.json" -o -name "*.md" | head
find /Users/<user>/.gemini/config -name "mcp_config.json" | head
test -f /Users/<user>/.gemini/GEMINI.md && echo "global rules found"
```

## Pack Components

### File Monitor Inputs

All file monitors set `metadata.datatype` for downstream routing.

| Input                          | Path                                           | Filter                                     | Recursive | Default  |
| ------------------------------ | ---------------------------------------------- | ------------------------------------------ | --------- | -------- |
| `antigravity-app-logs`         | `Library/Application Support/Antigravity/logs` | `*.log`                                    | Yes       | Disabled |
| `antigravity-library-logs`     | `Library/Logs/Antigravity`                     | `*.log`                                    | Yes       | Disabled |
| `antigravity-app-config`       | `Library/Application Support/Antigravity`      | app/user/config JSON                       | Yes       | Disabled |
| `antigravity-brain`            | `.gemini/antigravity/brain`                    | `*.md`, `*.metadata.json`                  | Yes       | Disabled |
| `antigravity-annotations`      | `.gemini/antigravity/annotations`              | `*.pbtxt`                                  | No        | Disabled |
| `antigravity-code-tracker`     | `.gemini/antigravity/code_tracker`             | text/source snapshots                      | Yes       | Disabled |
| `antigravity-runtime-logs`     | `.gemini/antigravity`                          | `*.log`                                    | Yes       | Disabled |
| `antigravity-state`            | `.gemini/antigravity`                          | root `.pbtxt`, MCP config, installation ID | No        | Disabled |
| `antigravity-shared-config`    | `.gemini/config`                               | `mcp_config.json`                          | Yes       | Enabled  |
| `antigravity-global-rules`     | `.gemini`                                      | `GEMINI.md`                                | No        | Enabled  |
| `antigravity-cli-logs`         | `.gemini/antigravity-cli`                      | `*.log`                                    | Yes       | Disabled |
| `antigravity-cli-history`      | `.gemini/antigravity-cli`                      | `history.jsonl`                            | No        | Disabled |
| `antigravity-cli-config`       | `.gemini/antigravity-cli`                      | settings, keybindings, MCP, plugin JSON    | Yes       | Enabled  |
| `antigravity-cli-brain`        | `.gemini/antigravity-cli/brain`                | `*.md`                                     | Yes       | Enabled  |
| `antigravity-cli-annotations`  | `.gemini/antigravity-cli/annotations`          | `*.pbtxt`                                  | No        | Disabled |
| `antigravity-ide-logs`         | `.gemini/antigravity-ide`                      | `*.log`                                    | Yes       | Disabled |
| `antigravity-ide-config`       | `.gemini/antigravity-ide`                      | MCP config, installation ID                | No        | Disabled |
| `antigravity-ide-brain`        | `.gemini/antigravity-ide/brain`                | `*.md`, `*.metadata.json`                  | Yes       | Disabled |
| `antigravity-ide-annotations`  | `.gemini/antigravity-ide/annotations`          | `*.pbtxt`                                  | No        | Disabled |
| `antigravity-ide-code-tracker` | `.gemini/antigravity-ide/code_tracker`         | text/source snapshots                      | Yes       | Disabled |
| `gemini-cli-*`                 | `.gemini` and `.gemini/tmp`                    | legacy Gemini CLI files                    | Mixed     | Disabled |

### Binary Stores Not Collected

The following files are intentionally not monitored by default:

- `~/.gemini/antigravity-cli/conversations/*.db`
- `~/.gemini/antigravity-cli/conversations/*.db-wal`
- `~/.gemini/antigravity-cli/conversations/*.db-shm`
- `~/.gemini/antigravity-cli/implicit/*.pb`
- `~/.gemini/antigravity/conversations/*.db`
- `~/.gemini/antigravity/conversations/*.db-wal`
- `~/.gemini/antigravity/conversations/*.db-shm`
- `~/.gemini/antigravity/conversations/*.pb`
- `~/.gemini/antigravity/implicit/*.pb`
- `~/.gemini/antigravity-ide/conversations/*.pb`
- `~/.gemini/antigravity-ide/implicit/*.pb`
- `~/Library/Application Support/Antigravity/shared_proto_db/*`
- `~/Library/Application Support/Antigravity/Session Storage/*`
- executable helpers, uploaded media, and cache blobs

These stores can contain high-volume binary data and are better handled with a purpose-built parser or a downstream
forensics workflow instead of generic file tailing.

### OTLP Input

| Input             | Type          | Host        | Port | Protocol | TLS      | Default  |
| ----------------- | ------------- | ----------- | ---- | -------- | -------- | -------- |
| `gemini-cli-otel` | OpenTelemetry | `127.0.0.1` | 4317 | gRPC     | Disabled | Disabled |

This is retained only for legacy Gemini CLI deployments.

### Output: `default`

- Type: Cribl HTTP
- Compression: gzip
- Concurrency: 5

## Troubleshooting

### No events flowing

1. Verify `$GEMINI_HOME` points to the owning user's home directory.
2. Check that the file monitor discovered files in Cribl Edge logs.
3. Verify the route is not disabled in the Cribl UI.
4. Confirm the output destination is reachable.

### No default Antigravity CLI files found

1. Run `agy` at least once.
2. Check `ls ~/.gemini/antigravity-cli/`.
3. Check
   `find ~/.gemini/antigravity-cli -name "settings.json" -o -name "keybindings.json" -o -name "mcp_config.json" -o -name "*.md" | head`.

### No Antigravity IDE or desktop app candidate files found

1. Launch Antigravity at least once.
2. Check `ls ~/.gemini/antigravity-ide/` and `ls ~/.gemini/antigravity/`.
3. Check `find ~/Library/Application\ Support/Antigravity/logs -name "*.log" | head`.
4. Check `find ~/Library/Logs/Antigravity -name "*.log" | head`.
5. Enable the relevant candidate input before expecting these files to flow.

### No legacy Gemini CLI data

Legacy Gemini inputs are disabled by default in this release. Enable the relevant `gemini-cli-*` source only if the host
still runs a supported Gemini CLI deployment.

### Stale file tracking

Cribl Edge tracks file state in its kvstore. If you need to re-ingest files from the beginning, stop the worker, clear the
relevant kvstore directories, and restart.

- macOS: `/opt/cribl/state/kvstore/default/file_gemini-cli-*/` and `/opt/cribl/state/kvstore/default/file_antigravity-*/`

## Release Notes

- **0.3.0** - 2026-06-12
  - Default-enabled coverage now targets only Google-documented Antigravity filesystem paths.
  - Added Antigravity CLI config, plugin metadata, and brain markdown inputs.
  - Added shared MCP config collection for `.gemini/config/mcp_config.json`.
  - Added Antigravity global rules collection for `.gemini/GEMINI.md`.
  - Added Antigravity app, IDE, runtime log, history, annotation, and code-tracker candidate inputs as disabled by
    default where Google docs do not publish local default path contracts.
  - Disabled legacy Gemini CLI file and OTLP inputs by default.
  - Documented binary SQLite/protobuf stores as intentionally not collected.
- **0.2.3** - 2026-06-10
  - Added Data Contract section and OTLP port allocation notes.
  - Added `.jsonl` Gemini CLI session matching.
  - Normalized `package.json` metadata and README formatting.
- **0.2.2** - 2026-03-11
  - Enabled `tailOnly: true` and `checkFileModTime: true` on file inputs.
  - Increased intervals for the largest recursive inputs.
- **0.2.1** - 2026-03-10
  - Fixed FileMonitor filename patterns for Cribl 4.16.x behavior.
- **0.2.0** - 2026-03-06
  - Added OTLP gRPC receiver for Gemini CLI telemetry.
- **0.1.0** - 2026-03-07
  - Initial release with Gemini CLI and Antigravity IDE file monitors.

## Authors

- Andrew Hendrix - <Andrewh@VisiCoreTech.com>
- Jacob Evans - <jevans@VisiCoreTech.com>

To contact us, please email <CriblPacks@VisiCoreTech.com>.

## Contributing to the Pack

To contribute to this Pack, or to report any issues or enhancement requests, please connect with **VisiCore Tech** on
[Cribl Community Slack](https://cribl-community.slack.com) or email us at: <CriblPacks@visicoretech.com>.

## License

This Pack uses the following license: [`Apache 2.0`](https://github.com/criblio/appscope/blob/master/LICENSE)
