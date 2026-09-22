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
mkdir -p "$tmp/outside/tasks" "$tmp/outside/schemas"
printf '{}\n' >"$tmp/outside/schemas/task.schema.json"
mv "$tmp/repo/.ai" "$tmp/real-ai"
ln -s "$tmp/outside" "$tmp/repo/.ai"
check 4 "$tmp/repo"
rm "$tmp/repo/.ai"; mv "$tmp/real-ai" "$tmp/repo/.ai"
mv "$tmp/repo/.ai/tasks" "$tmp/real-tasks"
ln -s "$tmp/outside/tasks" "$tmp/repo/.ai/tasks"
check 4 "$tmp/repo"
rm "$tmp/repo/.ai/tasks"; mv "$tmp/real-tasks" "$tmp/repo/.ai/tasks"
mv "$tmp/repo/.ai/schemas" "$tmp/real-schemas"
ln -s "$tmp/outside/schemas" "$tmp/repo/.ai/schemas"
check 4 "$tmp/repo"
rm "$tmp/repo/.ai/schemas"; mv "$tmp/real-schemas" "$tmp/repo/.ai/schemas"
mkdir -p "$tmp/repo/subdir"
check 0 "$tmp/repo/subdir"
check 2 "$tmp/repo" unexpected-argument

mkdir "$tmp/no-git"
ln -s "$(command -v bash)" "$tmp/no-git/bash"
PATH="$tmp/no-git" check 1 "$tmp/repo"

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
