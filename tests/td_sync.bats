#!/usr/bin/env bats

setup() {
  PROJECT_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"
  export PROJECT_ROOT
  export TD_HOME="$PROJECT_ROOT"
  export TD_TEST_MODE=1
  export PATH="$PROJECT_ROOT/bin:$PATH"
  export TD_MOCK_OUTPUT="$BATS_TEST_TMPDIR/mock.log"
  export HOME="$BATS_TEST_TMPDIR/home"
  unset TD_CONFIG_DIR
  unset TD_LOG_DIR
  unset TD_LOG_RETENTION_DAYS
  mkdir -p "$HOME"
  rm -f "$TD_MOCK_OUTPUT"
}

teardown() {
  rm -f "$TD_MOCK_OUTPUT"
}

@test "shows help text" {
  run "$PROJECT_ROOT/bin/td-sync" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Tiny Data Sync"* ]]
  [[ "$output" == *"TD_TEST_MODE"* ]]
}

@test "initial run creates default config dir and reports absence" {
  unset TD_CONFIG_DIR
  run "$PROJECT_ROOT/bin/td-sync"
  [ "$status" -eq 0 ]
  [[ -d "$HOME/.config/td-sync.d" ]]
  [[ "$output" == *"No configuration profiles found"* ]]
}

@test "invalid profile fails with helpful error" {
  config_dir="$BATS_TEST_TMPDIR/config"
  mkdir -p "$config_dir"
  cat >"$config_dir/invalid.env" <<'EOF'
TD_SRC=/tmp/source
TD_SUBMIT_INTERVAL=3600
EOF
  export TD_CONFIG_DIR="$config_dir"
  run "$PROJECT_ROOT/bin/td-sync"
  [ "$status" -ne 0 ]
  [[ "$output" == *"TD_DEST is required"* ]]
}

@test "valid profile writes job script and submits via sbatch" {
  config_dir="$BATS_TEST_TMPDIR/config-valid"
  log_dir="$BATS_TEST_TMPDIR/logs"
  mkdir -p "$config_dir" "$log_dir"
  cat >"$config_dir/sample.env" <<'EOF'
TD_SRC=/data/src
TD_DEST=/data/dest
TD_SUBMIT_INTERVAL=3600
TD_SLURM_ACCOUNT=research
TD_NOTIFY=ops@example.com
TD_DRY_RUN=1
TD_SLURM_RUNTIME=02:30:00
EOF
  export TD_CONFIG_DIR="$config_dir"
  export TD_LOG_DIR="$log_dir"
  run "$PROJECT_ROOT/bin/td-sync"
  [ "$status" -eq 0 ]
  [[ -f "$PROJECT_ROOT/jobs/sample.job.sh" ]]
  job_script_contents="$(cat "$PROJECT_ROOT/jobs/sample.job.sh")"
  [[ "$job_script_contents" == *"TD_NOTIFY=ops@example.com"* ]]
  [[ "$job_script_contents" == *"TD_DRY_RUN=1"* ]]
  mock_log="$(cat "$TD_MOCK_OUTPUT")"
  [[ "$mock_log" == *"--account=research"* ]]
  [[ "$mock_log" == *"--time=02:30:00"* ]]
}

@test "log retention purges stale files" {
  config_dir="$BATS_TEST_TMPDIR/config-retain"
  mkdir -p "$config_dir"
  cat >"$config_dir/keep.env" <<'EOF'
TD_SRC=/data/src
TD_DEST=/data/dest
TD_SUBMIT_INTERVAL=7days
EOF
  export TD_CONFIG_DIR="$config_dir"
  export TD_LOG_DIR="$BATS_TEST_TMPDIR/logs-retain"
  mkdir -p "$TD_LOG_DIR"
  old_log="$TD_LOG_DIR/old.log"
  touch -d '3 days ago' "$old_log"
  export TD_LOG_RETENTION_DAYS=1
  run "$PROJECT_ROOT/bin/td-sync"
  [ "$status" -eq 0 ]
  [[ ! -e "$old_log" ]]
}
