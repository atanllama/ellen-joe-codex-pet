#!/bin/sh
set -eu
test_dir=$(CDPATH= cd -P "$(dirname "$0")" && pwd)
temp_root=$(mktemp -d "${TMPDIR:-/tmp}/ellen-installer-test.XXXXXX")
trap 'rm -rf "$temp_root"' EXIT HUP INT TERM
fixture="$temp_root/repo"
home="$temp_root/codex home"
mkdir -p "$fixture/scripts" "$fixture/pet/ellen-joe-pixel"
cp "$test_dir/../scripts/install.sh" "$test_dir/../scripts/uninstall.sh" "$fixture/scripts/"
cp "$test_dir/../scripts/manifest_contract.py" "$fixture/scripts/"
cp "$test_dir/../release-assets.json" "$fixture/"
manifest="$fixture/pet/ellen-joe-pixel/pet.json"
sheet="$fixture/pet/ellen-joe-pixel/spritesheet.webp"
canonical_manifest='{"id":"ellen-joe-pixel","displayName":"Ellen Joe Pixel","description":"A sleepy full-body Ellen Joe fan-art Codex Pet.","spriteVersionNumber":2,"spritesheetPath":"spritesheet.webp"}'
valid_manifest='{ "metadata": { "id": "nested first", "id": "nested last", "spriteVersionNumber": 20, "spritesheetPath": "other.webp" }, "extra": true, "displayName": "Ellen Joe Pixel", "description": "A sleepy full-body Ellen Joe fan-art Codex Pet.", "spritesheetPath" : "spritesheet.webp", "spriteVersionNumber" : 2, "id" : "ellen-joe-pixel" }'
printf '%s\r\n' "$valid_manifest" > "$manifest"
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
assert_no_install_locks() {
    lock_path="$1/pets/.ellen-joe-pixel.install.lock"
    [ ! -e "$lock_path" ] || fail_test "install lock leaked: $lock_path"
    [ ! -L "$lock_path" ] || fail_test "dangling install lock leaked: $lock_path"
    if command -v cmd.exe >/dev/null 2>&1 && command -v cygpath >/dev/null 2>&1; then
        lock_query=$(cmd.exe /c fsutil reparsepoint query "$(cygpath -w "$lock_path")" 2>&1 || :)
        if printf '%s\n' "$lock_query" | grep -q 'Reparse Tag Value'; then
            fail_test "reparse install lock leaked: $lock_path"
        fi
    fi
}
assert_installed_bytes() {
    expected_hash=C6F4ED31F670E00CDA1B596F35372B3B60BA5A6CB94DBD6E049B2E1950FC15E6
    if command -v sha256sum >/dev/null 2>&1; then
        actual_hash=$(sha256sum "$1/pets/ellen-joe-pixel/spritesheet.webp" | awk '{print toupper($1)}')
    else
        actual_hash=$(shasum -a 256 "$1/pets/ellen-joe-pixel/spritesheet.webp" | awk '{print toupper($1)}')
    fi
    [ "$actual_hash" = "$expected_hash" ] || fail_test 'installed spritesheet bytes changed'
    cmp -s "$manifest" "$1/pets/ellen-joe-pixel/pet.json" || fail_test 'installed manifest bytes changed'
}
single_backup() {
    backup=
    for candidate in "$1/pet-backups"/ellen-joe-pixel.backup.*; do
        [ -d "$candidate" ] || continue
        [ -z "$backup" ] || fail_test "multiple backups under $1"
        backup=$candidate
    done
    [ -n "$backup" ] || fail_test "backup missing under $1"
    for candidate in "$1/pets"/ellen-joe-pixel.backup.*; do
        [ ! -e "$candidate" ] || fail_test "backup leaked into pets: $candidate"
    done
    printf '%s\n' "$backup"
}

# RED-before-GREEN regression: version 20 was accepted by substring matching.
new_test_home "$home"
printf '%s\n' '{"id":"ellen-joe-pixel","spriteVersionNumber":20,"spritesheetPath":"spritesheet.webp"}' > "$manifest"
assert_code 3 sh "$fixture/scripts/install.sh" --codex-home "$home"
assert_sentinel "$home"
printf '%s\n' '{"id":"ellen-joe-pixel",' > "$manifest"
assert_code 3 sh "$fixture/scripts/install.sh" --codex-home "$home"
assert_sentinel "$home"
printf '%s\n' '[]' > "$manifest"
assert_code 3 sh "$fixture/scripts/install.sh" --codex-home "$home"
assert_sentinel "$home"
printf '%s\n' '{"id":"ellen-joe-pixel","displayName":"Ellen Joe Pixel","description":"A sleepy full-body Ellen Joe fan-art Codex Pet.","spriteVersionNumber":2,"spriteVersionNumber":20,"spritesheetPath":"spritesheet.webp"}' > "$manifest"
assert_code 3 sh "$fixture/scripts/install.sh" --codex-home "$home"
assert_sentinel "$home"
printf '%s\n' '{"id":"ellen-joe-pixel","id":"not-ellen","spriteVersionNumber":2,"spritesheetPath":"spritesheet.webp"}' > "$manifest"
assert_code 3 sh "$fixture/scripts/install.sh" --codex-home "$home"
assert_sentinel "$home"
printf '%s\n' "$canonical_manifest" > "$manifest"
cd "$fixture"

assert_code 3 sh "$fixture/scripts/install.sh" --unknown
assert_sentinel "$home"
assert_code 3 sh "$fixture/scripts/install.sh" --codex-home
assert_sentinel "$home"
assert_code 3 sh "$fixture/scripts/install.sh" --codex-home ''
assert_sentinel "$home"
assert_code 3 sh "$fixture/scripts/install.sh" --codex-home --force
assert_sentinel "$home"
test ! -e "$fixture/--force"
assert_code 3 sh "$fixture/scripts/uninstall.sh" --unknown
assert_sentinel "$home"
assert_code 3 sh "$fixture/scripts/uninstall.sh" --codex-home
assert_sentinel "$home"
assert_code 3 sh "$fixture/scripts/uninstall.sh" --codex-home ''
assert_sentinel "$home"
assert_code 3 sh "$fixture/scripts/uninstall.sh" --codex-home --force
assert_sentinel "$home"
test ! -e "$fixture/--force"
assert_code 3 env -u HOME -u CODEX_HOME sh "$fixture/scripts/install.sh"
assert_sentinel "$home"
assert_code 3 env -u HOME -u CODEX_HOME sh "$fixture/scripts/uninstall.sh"
assert_sentinel "$home"

sed -e 's/command -v python3/command -v python3-not-installed/g' -e 's/command -v python/command -v python-not-installed/g' "$fixture/scripts/install.sh" > "$fixture/scripts/install-no-python.sh"
assert_code 3 sh "$fixture/scripts/install-no-python.sh" --codex-home "$home"
assert_sentinel "$home"
printf '%s\r\n' "$valid_manifest" > "$manifest"
assert_code 3 sh "$fixture/scripts/install.sh" --codex-home "$home"
assert_sentinel "$home"
[ ! -e "$home/pets/ellen-joe-pixel" ] || fail_test 'invalid atlas was installed'
cp "$test_dir/../pet/ellen-joe-pixel/spritesheet.webp" "$sheet"

# Resolve through a real root child; macOS symlinks /tmp to /private/tmp.
root_alias=/usr/..
assert_code 3 sh "$fixture/scripts/install.sh" --codex-home "$root_alias"
assert_sentinel "$home"
assert_code 3 sh "$fixture/scripts/uninstall.sh" --codex-home "$root_alias"
assert_sentinel "$home"
assert_code 3 sh "$fixture/scripts/install.sh" --codex-home //
assert_sentinel "$home"
assert_code 3 sh "$fixture/scripts/uninstall.sh" --codex-home //
assert_sentinel "$home"
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
        assert_code 3 sh "$fixture/scripts/install.sh" --codex-home /c
        assert_sentinel "$home"
        assert_code 3 sh "$fixture/scripts/uninstall.sh" --codex-home /c
        assert_sentinel "$home"
        ;;
esac

write_root_classifier() {
    source_script=$1
    classifier_script=$2
    {
        printf '%s\n' '#!/bin/sh'
        sed -n '/^is_filesystem_root()/,/^}/p' "$source_script"
        printf '%s\n' 'if is_filesystem_root "$2"; then actual=root; else actual=nonroot; fi'
        printf '%s\n' '[ "$actual" = "$1" ]'
    } > "$classifier_script"
}
write_root_classifier "$fixture/scripts/install.sh" "$fixture/install-root-classifier.sh"
write_root_classifier "$fixture/scripts/uninstall.sh" "$fixture/uninstall-root-classifier.sh"
for classifier in "$fixture/install-root-classifier.sh" "$fixture/uninstall-root-classifier.sh"; do
    assert_code 0 sh "$classifier" root /
    assert_code 0 sh "$classifier" root //
    assert_code 0 sh "$classifier" root //server/share
    assert_code 0 sh "$classifier" root //server/share/
    assert_code 0 sh "$classifier" nonroot //server/share/codex-home
    case "$(uname -s)" in
        MINGW*|MSYS*|CYGWIN*)
            assert_code 0 sh "$classifier" root /c
            assert_code 0 sh "$classifier" root /c/
            assert_code 0 sh "$classifier" root C:
            assert_code 0 sh "$classifier" root C:/
            ;;
    esac
done

linked_home="$temp_root/linked home"
outside="$temp_root/outside"
new_test_home "$outside"
mkdir -p "$linked_home"

linked_codex_home="$temp_root/linked codex home"
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
        command -v pwsh >/dev/null 2>&1 || fail_test 'pwsh is required to create the Windows Junction fixture'
        LINKED_HOME="$linked_codex_home" OUTSIDE_HOME="$outside" pwsh -NoProfile -Command 'New-Item -ItemType Junction -Path $env:LINKED_HOME -Target $env:OUTSIDE_HOME | Out-Null'
        ;;
    *) ln -s "$outside" "$linked_codex_home" ;;
esac
assert_code 3 sh "$fixture/scripts/install.sh" --codex-home "$linked_codex_home"
assert_sentinel "$outside"
[ ! -e "$outside/pets/ellen-joe-pixel" ] || fail_test 'symlinked Codex home escaped selected home'
assert_code 3 sh "$fixture/scripts/uninstall.sh" --codex-home "$linked_codex_home"
assert_sentinel "$outside"

case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
        command -v pwsh >/dev/null 2>&1 || fail_test 'pwsh is required to create the Windows Junction fixture'
        LINKED_PETS="$linked_home/pets" OUTSIDE_PETS="$outside/pets" pwsh -NoProfile -Command 'New-Item -ItemType Junction -Path $env:LINKED_PETS -Target $env:OUTSIDE_PETS | Out-Null'
        ;;
    *) ln -s "$outside/pets" "$linked_home/pets" ;;
esac
assert_code 3 sh "$fixture/scripts/install.sh" --codex-home "$linked_home"
assert_sentinel "$outside"
assert_code 3 sh "$fixture/scripts/uninstall.sh" --codex-home "$linked_home"
assert_sentinel "$outside"
[ ! -e "$outside/pets/ellen-joe-pixel" ] || fail_test 'linked pets parent escaped Codex home'
assert_sentinel "$outside"

file_home="$temp_root/file target home"
new_test_home "$file_home"
printf '%s\n' 'not a pet directory' > "$file_home/pets/ellen-joe-pixel"
assert_code 3 sh "$fixture/scripts/install.sh" --codex-home "$file_home" --force
assert_sentinel "$file_home"
assert_code 3 sh "$fixture/scripts/uninstall.sh" --codex-home "$file_home"
assert_sentinel "$file_home"

locked_home="$temp_root/locked home"
new_test_home "$locked_home"
lock_path="$locked_home/pets/.ellen-joe-pixel.install.lock"
mkdir "$lock_path"
assert_code 4 sh "$fixture/scripts/install.sh" --codex-home "$locked_home"
assert_sentinel "$locked_home"
test -d "$lock_path"
rmdir "$lock_path"
sh "$fixture/scripts/install.sh" --codex-home "$locked_home"
assert_sentinel "$locked_home"
assert_no_install_locks "$locked_home"
mkdir "$lock_path"
assert_code 4 sh "$fixture/scripts/uninstall.sh" --codex-home "$locked_home"
test -d "$locked_home/pets/ellen-joe-pixel"
test -d "$lock_path"
rmdir "$lock_path"
assert_code 0 sh "$fixture/scripts/uninstall.sh" --codex-home "$locked_home"
assert_no_install_locks "$locked_home"

sh "$fixture/scripts/install.sh" --codex-home "$home"
assert_sentinel "$home"
test -f "$home/pets/ellen-joe-pixel/pet.json"
test -f "$home/pets/ellen-joe-pixel/spritesheet.webp"
assert_code 2 sh "$fixture/scripts/install.sh" --codex-home "$home"
assert_sentinel "$home"
printf '%s\n' old > "$home/pets/ellen-joe-pixel/marker.txt"
sh "$fixture/scripts/install.sh" --codex-home "$home" --force
assert_sentinel "$home"
test -f "$home/pets/ellen-joe-pixel/pet.json"
test -f "$home/pets/ellen-joe-pixel/spritesheet.webp"
assert_installed_bytes "$home"
backup=$(single_backup "$home")
test -f "$backup/marker.txt"
printf '%s\n' new > "$home/pets/ellen-joe-pixel/marker.txt"
sh "$fixture/scripts/install.sh" --codex-home "$home" --force
assert_sentinel "$home"
assert_no_install_locks "$home"
backup_count=0
saw_old=0
saw_new=0
for candidate in "$home/pet-backups"/ellen-joe-pixel.backup.*; do
    [ -d "$candidate" ] || continue
    backup_count=$((backup_count + 1))
    case "$(cat "$candidate/marker.txt")" in
        old) saw_old=1 ;;
        new) saw_new=1 ;;
    esac
done
[ "$backup_count" -eq 2 ] || fail_test 'backup names were not unique'
[ "$saw_old" -eq 1 ] && [ "$saw_new" -eq 1 ] || fail_test 'unique backups did not preserve both prior targets'
assert_installed_bytes "$home"
sh "$fixture/scripts/uninstall.sh" --codex-home "$home"
assert_sentinel "$home"
test ! -e "$home/pets/ellen-joe-pixel"
test -f "$backup/marker.txt"
assert_code 2 sh "$fixture/scripts/uninstall.sh" --codex-home "$home"
assert_sentinel "$home"

rollback_home="$temp_root/rollback home"
new_test_home "$rollback_home"
# Match the installer's physical path when macOS TMPDIR is symlinked.
rollback_home=$(CDPATH= cd -P "$rollback_home" && pwd -P)
rollback_pets="$rollback_home/pets"
rollback_backup_dir="$rollback_home/pet-backups"
sh "$fixture/scripts/install.sh" --codex-home "$rollback_home"
assert_sentinel "$rollback_home"
printf '%s\n' 'prior target' > "$rollback_pets/ellen-joe-pixel/marker.txt"
rollback_installer="$fixture/scripts/install-rollback.sh"
sed '/^rename_directory() {/a\
    if [ "${ELLEN_TEST_FAIL_FINAL_MOVE-}" = 1 ]; then\
        case "$1" in */.ellen-joe-pixel.stage.*) return 1 ;; esac\
    fi\
    if [ "${ELLEN_TEST_FAIL_ROLLBACK-}" = 1 ]; then\
        case "$1" in */pet-backups/ellen-joe-pixel.backup.*) return 1 ;; esac\
    fi' "$fixture/scripts/install.sh" > "$rollback_installer"
chmod +x "$rollback_installer"
assert_code 4 env ELLEN_TEST_FAIL_FINAL_MOVE=1 sh "$rollback_installer" --codex-home "$rollback_home" --force
assert_sentinel "$rollback_home"
test -f "$rollback_pets/ellen-joe-pixel/marker.txt"
assert_no_stages "$rollback_home"
assert_no_install_locks "$rollback_home"
assert_code 5 env ELLEN_TEST_FAIL_FINAL_MOVE=1 ELLEN_TEST_FAIL_ROLLBACK=1 sh "$rollback_installer" --codex-home "$rollback_home" --force
assert_sentinel "$rollback_home"
test ! -e "$rollback_pets/ellen-joe-pixel"
backup=$(single_backup "$rollback_home")
test -f "$backup/marker.txt"
assert_no_stages "$rollback_home"
assert_no_install_locks "$rollback_home"

appeared_installer="$fixture/scripts/install-appeared.sh"
sed '/^if ! rename_directory /i\
if [ "${ELLEN_TEST_CREATE_TARGET_BEFORE_FINAL_MOVE-}" = 1 ]; then\
    mkdir "$target"\
    printf "%s\\n" appeared > "$target/marker.txt"\
fi' "$fixture/scripts/install.sh" > "$appeared_installer"
chmod +x "$appeared_installer"
appeared_home="$temp_root/appeared target home"
new_test_home "$appeared_home"
assert_code 4 env ELLEN_TEST_CREATE_TARGET_BEFORE_FINAL_MOVE=1 sh "$appeared_installer" --codex-home "$appeared_home"
test -f "$appeared_home/pets/ellen-joe-pixel/marker.txt"
test ! -e "$appeared_home/pets/ellen-joe-pixel/pet.json"
for candidate in "$appeared_home/pet-backups"/ellen-joe-pixel.backup.*; do
    [ ! -e "$candidate" ] || fail_test 'target appearance created an unexpected backup'
done
assert_no_install_locks "$appeared_home"
assert_no_stages "$appeared_home"

cleanup_failure_installer="$fixture/scripts/install-cleanup-failure.sh"
sed '/^acquire_install_lock$/a\
mkdir "$install_lock/held"\
fail 3 "Injected cleanup failure."' "$fixture/scripts/install.sh" > "$cleanup_failure_installer"
chmod +x "$cleanup_failure_installer"
cleanup_failure_home="$temp_root/cleanup failure home"
new_test_home "$cleanup_failure_home"
cleanup_failure_lock="$cleanup_failure_home/pets/.ellen-joe-pixel.install.lock"
assert_code 5 sh "$cleanup_failure_installer" --codex-home "$cleanup_failure_home"
test -d "$cleanup_failure_lock/held"
test ! -e "$cleanup_failure_home/pets/ellen-joe-pixel"
assert_sentinel "$cleanup_failure_home"
rm -rf "$cleanup_failure_lock"
assert_no_install_locks "$cleanup_failure_home"
assert_no_stages "$cleanup_failure_home"

cleanup_failure_uninstaller="$fixture/scripts/uninstall-cleanup-failure.sh"
sed '/^acquire_uninstall_lock$/a\
mkdir "$install_lock/held"\
fail 3 "Injected uninstall cleanup failure."' "$fixture/scripts/uninstall.sh" > "$cleanup_failure_uninstaller"
chmod +x "$cleanup_failure_uninstaller"
uninstall_cleanup_home="$temp_root/uninstall cleanup failure home"
new_test_home "$uninstall_cleanup_home"
uninstall_cleanup_lock="$uninstall_cleanup_home/pets/.ellen-joe-pixel.install.lock"
assert_code 5 sh "$cleanup_failure_uninstaller" --codex-home "$uninstall_cleanup_home"
test -d "$uninstall_cleanup_lock/held"
assert_sentinel "$uninstall_cleanup_home"
rm -rf "$uninstall_cleanup_lock"
assert_no_install_locks "$uninstall_cleanup_home"
printf '%s\n' 'OK: POSIX installer isolation and safety contract'
