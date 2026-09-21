#!/usr/bin/env bash
set -euo pipefail

doctor="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/ai-coop-doctor.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

check() {
  local expected="$1" dir="$2" actual
  shift 2
  if (cd "$dir" && "$doctor" "$@") >"$tmp/output" 2>&1; then
    actual=0
  else
    actual=$?
  fi
  if [[ "$actual" -ne "$expected" ]]; then
    printf 'expected exit %s, got %s for %s\n' "$expected" "$actual" "$dir" >&2
    cat "$tmp/output" >&2
    exit 1
  fi
}

check 3 "$tmp"
git init -q "$tmp/repo"
check 4 "$tmp/repo"
mkdir -p "$tmp/repo/.ai/tasks" "$tmp/repo/.ai/schemas"
check 4 "$tmp/repo"
printf '{}\n' >"$tmp/repo/.ai/schemas/task.schema.json"
check 0 "$tmp/repo"
mkdir -p "$tmp/repo/subdir"
check 0 "$tmp/repo/subdir"
check 2 "$tmp/repo" unexpected-argument

mkdir "$tmp/bin"
real_git="$(command -v git)"
cat >"$tmp/bin/git" <<'SH'
#!/usr/bin/env bash
if [[ "$*" == 'worktree list --porcelain' ]]; then
  exit 73
fi
exec "$REAL_GIT" "$@"
SH
chmod +x "$tmp/bin/git"
REAL_GIT="$real_git" PATH="$tmp/bin:$PATH" check 1 "$tmp/repo"

printf 'doctor exit codes: 0, 1, 2, 3, 4 verified\n'
