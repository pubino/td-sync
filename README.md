# Tiny Data Sync

Tiny Data Sync schedules recurring `rsync` synchronizations through Slurm.

The script ingests `.env` configuration profiles and produces self-resubmitting batch jobs that keep pairs of directories in sync on a predictable cadence.

## Features

- Auto-discovers configuration profiles from `$HOME/.config/td-sync.d` or `$TD_CONFIG_DIR`.
- Generates per-profile Slurm job scripts that execute `rsync`, log results, send notifications, and requeue themselves with `--begin=+TD_SUBMIT_INTERVAL`.
- Creates and rotates log files under `$PWD/logs` or `$TD_LOG_DIR` with optional retention via `TD_LOG_RETENTION_DAYS`.
- Provides mock `sbatch`, `mail`, and `sendmail` utilities for isolated testing via `TD_TEST_MODE`.
- Ships a Docker test environment with `bats-core` for unit tests.

## Quick Start

```bash
# Run tests inside the provided Docker container
make test
```

To exercise the script locally without Docker:

```bash
export TD_TEST_MODE=1
./bin/td-sync --help
```

## Configuration Profiles

Each profile is a simple `.env` file. Required keys:

- `TD_SRC` – source path for `rsync`.
- `TD_DEST` – destination path for `rsync`.
- `TD_SUBMIT_INTERVAL` – Slurm delay (seconds or strings like `7days`).
- `TD_SLURM_ACCOUNT` – Slurm account (defaults to the profile filename when omitted).

Optional keys:

- `TD_NOTIFY` – comma-separated email recipients.
- `TD_DRY_RUN` – `1` or `true` for `rsync --dry-run`.
- `TD_SLURM_RUNTIME` – job runtime (`HH:MM:SS`, defaults to `01:00:00`).

## Test Mode

Setting `TD_TEST_MODE` to `1` or `true` prepends `mocks/bin` to `PATH`, replacing `sbatch`, `mail`, and `sendmail` with test doubles. Use this when running unit tests or developing on a system without Slurm or a mail transfer agent.

## Log Retention

If `TD_LOG_RETENTION_DAYS` is set, Tiny Data Sync purges logs older than the configured number of days using `find -mtime` each time the script runs.

## Docker Image

The Dockerfile under `docker/` uses Debian Bookworm, respects the host architecture via `TARGETPLATFORM`, installs `bats-core`, and defaults to executing the Bats test suite.

## Example Usage

Below is a representative profile and command sequence for a project that mirrors data from a scratch volume to a long-term storage area every week:

1. Create a profile such as `~/ .config/td-sync.d/data-sync.env` containing:

	```env
	TD_SRC=/scratch/project/data/
	TD_DEST=/archive/project/data/
	TD_SUBMIT_INTERVAL=7days
	TD_SLURM_ACCOUNT=research
	TD_NOTIFY=user@example.edu
	TD_DRY_RUN=1
	TD_SLURM_RUNTIME=02:00:00
	```

2. Export any optional runtime variables, then execute the scheduler:

	```bash
	export TD_LOG_RETENTION_DAYS=7
	td-sync/bin/td-sync
	```

3. Tiny Data Sync will submit a Slurm job that performs an `rsync --dry-run`, writes a log under `logs/`, emails a short summary to the specified recipient, and requeues itself to run again after seven days. Switching `TD_DRY_RUN` to `0` promotes the synchronization from a preview to a real transfer.
