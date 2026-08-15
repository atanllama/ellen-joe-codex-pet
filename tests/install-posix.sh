#!/bin/sh
set -eu
test_dir=$(CDPATH= cd -P "$(dirname "$0")" && pwd)
temp_root=$(mktemp -d "${TMPDIR:-/tmp}/ellen-installer-test.XXXXXX")
trap 'rm -rf "$temp_root"' EXIT HUP INT TERM
fixture="$temp_root/repo"
home="$temp_root/codex home"
mkdir -p "$fixture/scripts" "$fixture/pet/ellen-joe-pixel" "$home/pets/sentinel"
cp "$test_dir/../scripts/install.sh" "$test_dir/../scripts/uninstall.sh" "$fixture/scripts/"
printf '%s\n' '{"id":"sentinel"}' > "$home/pets/sentinel/pet.json"
printf '%s\n' '{"id":"ellen-joe-pixel","displayName":"Ellen Joe Pixel","description":"fixture","spriteVersionNumber":2,"spritesheetPath":"spritesheet.webp"}' > "$fixture/pet/ellen-joe-pixel/pet.json"
printf '\001\002\003' > "$fixture/pet/ellen-joe-pixel/spritesheet.webp"
sh "$fixture/scripts/install.sh" --codex-home "$home"
test -f "$home/pets/ellen-joe-pixel/pet.json"
test -f "$home/pets/ellen-joe-pixel/spritesheet.webp"
set +e
sh "$fixture/scripts/install.sh" --codex-home "$home" >/dev/null 2>&1
code=$?
set -e
test "$code" -eq 2
printf '%s\n' old > "$home/pets/ellen-joe-pixel/marker.txt"
sh "$fixture/scripts/install.sh" --codex-home "$home" --force
backup=$(find "$home/pets" -maxdepth 1 -type d -name 'ellen-joe-pixel.backup.*' -print)
test -n "$backup" && test -f "$backup/marker.txt"
sh "$fixture/scripts/uninstall.sh" --codex-home "$home"
test ! -e "$home/pets/ellen-joe-pixel"
set +e
sh "$fixture/scripts/uninstall.sh" --codex-home "$home" >/dev/null 2>&1
code=$?
set -e
test "$code" -eq 2
test "$(cat "$home/pets/sentinel/pet.json")" = '{"id":"sentinel"}'
printf '%s\n' 'OK: POSIX installer isolation and rollback contract'
