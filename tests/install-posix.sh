#!/bin/sh
set -eu
test_dir=$(CDPATH= cd -P "$(dirname "$0")" && pwd)
temp_root=$(mktemp -d "${TMPDIR:-/tmp}/ellen-installer-test.XXXXXX")
trap 'rm -rf "$temp_root"' EXIT HUP INT TERM
fixture="$temp_root/repo"
home="$temp_root/codex home"
mkdir -p "$fixture/scripts" "$fixture/pet/ellen-joe-pixel"
cp "$test_dir/../scripts/install.sh" "$test_dir/../scripts/uninstall.sh" "$fixture/scripts/"
manifest="$fixture/pet/ellen-joe-pixel/pet.json"
sheet="$fixture/pet/ellen-joe-pixel/spritesheet.webp"
valid_manifest='{"id":"ellen-joe-pixel","displayName":"Ellen Joe Pixel","description":"A sleepy full-body Ellen Joe fan-art Codex Pet.","spriteVersionNumber":2,"spritesheetPath":"spritesheet.webp"}'
printf '%s\n' "$valid_manifest" > "$manifest"
printf '\001\002\003' > "$sheet"

fail_test() { printf '%s\n' "$*" >&2; exit 1; }
assert_code() {
    expected=$1
    shift
    set +e
    output=$("$@" 2>&1)
    actual=$?
    set -e
    [ "$actual" -eq "$expected" ] || fail_test "expected exit $expected, got $actual: $*\n$output"
}
new_test_home() {
    mkdir -p "$1/pets/sentinel"
    printf '%s\n' '{"id":"sentinel"}' > "$1/pets/sentinel/pet.json"
}
assert_sentinel() {
    [ "$(cat "$1/pets/sentinel/pet.json")" = '{"id":"sentinel"}' ] || fail_test "sentinel changed under $1"
}
assert_no_stages() {
    for candidate in "$1/pets"/.ellen-joe-pixel.stage.*; do
        [ ! -e "$candidate" ] || fail_test "staging directory leaked: $candidate"
    done
}
single_backup() {
    backup=
    for candidate in "$1/pets"/ellen-joe-pixel.backup.*; do
        [ -d "$candidate" ] || continue
        [ -z "$backup" ] || fail_test "multiple backups under $1"
        backup=$candidate
    done
    [ -n "$backup" ] || fail_test "backup missing under $1"
    printf '%s\n' "$backup"
}

# RED-before-GREEN regression: version 20 was accepted by substring matching.
new_test_home "$home"
printf '%s\n' '{"id":"ellen-joe-pixel","spriteVersionNumber":20,"spritesheetPath":"spritesheet.webp"}' > "$manifest"
assert_code 3 sh "$fixture/scripts/install.sh" --codex-home "$home"
printf '%s\n' '{"id":"ellen-joe-pixel",' > "$manifest"
assert_code 3 sh "$fixture/scripts/install.sh" --codex-home "$home"
printf '%s\n' '{"id":"ellen-joe-pixel","displayName":"Ellen Joe Pixel","description":"A sleepy full-body Ellen Joe fan-art Codex Pet.","spriteVersionNumber":2,"spriteVersionNumber":20,"spritesheetPath":"spritesheet.webp"}' > "$manifest"
assert_code 3 sh "$fixture/scripts/install.sh" --codex-home "$home"
printf '%s\n' "$valid_manifest" > "$manifest"

assert_code 3 sh "$fixture/scripts/install.sh" --unknown
assert_code 3 sh "$fixture/scripts/install.sh" --codex-home
assert_code 3 sh "$fixture/scripts/install.sh" --codex-home ''
assert_code 3 sh "$fixture/scripts/uninstall.sh" --unknown
assert_code 3 sh "$fixture/scripts/uninstall.sh" --codex-home
assert_code 3 sh "$fixture/scripts/uninstall.sh" --codex-home ''
assert_code 3 env -u HOME -u CODEX_HOME sh "$fixture/scripts/install.sh"
assert_code 3 env -u HOME -u CODEX_HOME sh "$fixture/scripts/uninstall.sh"

root_alias=/tmp/..
assert_code 3 sh "$fixture/scripts/install.sh" --codex-home "$root_alias"
assert_code 3 sh "$fixture/scripts/uninstall.sh" --codex-home "$root_alias"

linked_home="$temp_root/linked home"
outside="$temp_root/outside"
new_test_home "$outside"
mkdir -p "$linked_home"
if command -v pwsh >/dev/null 2>&1; then
    LINKED_PETS="$linked_home/pets" OUTSIDE_PETS="$outside/pets" pwsh -NoProfile -Command 'New-Item -ItemType Junction -Path $env:LINKED_PETS -Target $env:OUTSIDE_PETS | Out-Null'
else
    ln -s "$outside/pets" "$linked_home/pets"
fi
assert_code 3 sh "$fixture/scripts/install.sh" --codex-home "$linked_home"
assert_code 3 sh "$fixture/scripts/uninstall.sh" --codex-home "$linked_home"
[ ! -e "$outside/pets/ellen-joe-pixel" ] || fail_test 'linked pets parent escaped Codex home'
assert_sentinel "$outside"

file_home="$temp_root/file target home"
new_test_home "$file_home"
printf '%s\n' 'not a pet directory' > "$file_home/pets/ellen-joe-pixel"
assert_code 3 sh "$fixture/scripts/install.sh" --codex-home "$file_home" --force
assert_code 3 sh "$fixture/scripts/uninstall.sh" --codex-home "$file_home"
assert_sentinel "$file_home"

sh "$fixture/scripts/install.sh" --codex-home "$home"
test -f "$home/pets/ellen-joe-pixel/pet.json"
test -f "$home/pets/ellen-joe-pixel/spritesheet.webp"
assert_sentinel "$home"
assert_code 2 sh "$fixture/scripts/install.sh" --codex-home "$home"
assert_sentinel "$home"
printf '%s\n' old > "$home/pets/ellen-joe-pixel/marker.txt"
sh "$fixture/scripts/install.sh" --codex-home "$home" --force
backup=$(single_backup "$home")
test -f "$backup/marker.txt"
assert_sentinel "$home"
sh "$fixture/scripts/uninstall.sh" --codex-home "$home"
test ! -e "$home/pets/ellen-joe-pixel"
assert_sentinel "$home"
assert_code 2 sh "$fixture/scripts/uninstall.sh" --codex-home "$home"
assert_sentinel "$home"

rollback_home="$temp_root/rollback home"
new_test_home "$rollback_home"
rollback_pets="$rollback_home/pets"
sh "$fixture/scripts/install.sh" --codex-home "$rollback_home"
printf '%s\n' 'prior target' > "$rollback_pets/ellen-joe-pixel/marker.txt"
real_mv=$(command -v mv)
mkdir -p "$fixture/bin"
cat > "$fixture/bin/mv" <<EOF
#!/bin/sh
if [ "\${ELLEN_TEST_FAIL_FINAL_MOVE-}" = 1 ]; then
    case "\$1" in "$rollback_pets"/.ellen-joe-pixel.stage.*) exit 1 ;; esac
fi
if [ "\${ELLEN_TEST_FAIL_ROLLBACK-}" = 1 ]; then
    case "\$1" in "$rollback_pets"/ellen-joe-pixel.backup.*) exit 1 ;; esac
fi
exec "\$ELLEN_REAL_MV" "\$@"
EOF
chmod +x "$fixture/bin/mv"
assert_code 4 env PATH="$fixture/bin:$PATH" ELLEN_REAL_MV="$real_mv" ELLEN_TEST_FAIL_FINAL_MOVE=1 sh "$fixture/scripts/install.sh" --codex-home "$rollback_home" --force
test -f "$rollback_pets/ellen-joe-pixel/marker.txt"
assert_no_stages "$rollback_home"
assert_sentinel "$rollback_home"
assert_code 5 env PATH="$fixture/bin:$PATH" ELLEN_REAL_MV="$real_mv" ELLEN_TEST_FAIL_FINAL_MOVE=1 ELLEN_TEST_FAIL_ROLLBACK=1 sh "$fixture/scripts/install.sh" --codex-home "$rollback_home" --force
test ! -e "$rollback_pets/ellen-joe-pixel"
backup=$(single_backup "$rollback_home")
test -f "$backup/marker.txt"
assert_no_stages "$rollback_home"
assert_sentinel "$rollback_home"
printf '%s\n' 'OK: POSIX installer isolation and safety contract'
