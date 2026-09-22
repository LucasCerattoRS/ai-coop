#!/usr/bin/env bash
# Exercita hooks versionados em um repositorio descartavel. Sem framework.
set -uo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PASS=0; FAIL=0
ok() { printf 'ok   %s\n' "$1"; PASS=$((PASS + 1)); }
bad() { printf 'FAIL %s\n' "$1" >&2; FAIL=$((FAIL + 1)); }
check() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }

for file in .githooks/pre-merge-commit .githooks/pre-push .githooks/reference-transaction scripts/install-hooks.sh; do
  check "$file existe" "[[ -x $ROOT/$file ]]"
done

if (( FAIL )); then
  printf '%s passaram, %s falharam\n' "$PASS" "$FAIL"
  exit 1
fi

SB=$(mktemp -d); trap 'rm -rf "$SB"' EXIT
R="$SB/repo"; REMOTE="$SB/remote.git"
git init -q -b main "$R"
git -C "$R" config user.name test
git -C "$R" config user.email test@example.invalid
printf base > "$R/base"
git -C "$R" add base && git -C "$R" commit -qm base
git init -q --bare "$REMOTE"
git -C "$R" remote add origin "$REMOTE"
git -C "$R" push -q origin main
mkdir "$R/.githooks" "$R/scripts"
cp "$ROOT"/.githooks/* "$R/.githooks/"
cp "$ROOT/scripts/install-hooks.sh" "$R/scripts/"
( cd "$R" && bash scripts/install-hooks.sh >/dev/null )
check "hooksPath instalado" "[[ \$(git -C $R config --get core.hooksPath) == $R/.githooks ]]"

git -C "$R" switch -q -c topic
printf topic > "$R/topic"
git -C "$R" add topic && git -C "$R" commit -qm topic
git -C "$R" switch -q main
check "merge com commit recusado" "! git -C $R merge --no-ff topic >/dev/null 2>&1"
AI_COOP_HUMAN=1 git -C "$R" merge --abort
check "merge com commit liberado para humano" "AI_COOP_HUMAN=1 git -C $R merge --no-ff topic >/dev/null"

git -C "$R" switch -q -c fast-forward
printf ff > "$R/ff"
git -C "$R" add ff && git -C "$R" commit -qm ff
git -C "$R" switch -q main
check "fast-forward em main recusado" "! git -C $R merge fast-forward >/dev/null 2>&1"
check "fast-forward em main liberado para humano" "AI_COOP_HUMAN=1 git -C $R merge fast-forward >/dev/null"

git -C "$R" switch -q -c push-branch
printf push > "$R/push"
git -C "$R" add push && git -C "$R" commit -qm push
check "push recusado" "! git -C $R push origin HEAD:refs/heads/push-branch >/dev/null 2>&1"
check "push liberado para humano" "AI_COOP_HUMAN=1 git -C $R push origin HEAD:refs/heads/push-branch >/dev/null"

printf '%s passaram, %s falharam\n' "$PASS" "$FAIL"
(( FAIL == 0 ))
