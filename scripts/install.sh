#!/bin/sh
set -u
fail() { code=$1; shift; printf '%s\n' "$*" >&2; exit "$code"; }
is_filesystem_root() {
    case "$1" in /|// ) return 0 ;; esac
    case "$1" in
        //*)
            unc_path=${1#//}
            unc_path=${unc_path%/}
            case "$unc_path" in
                */*)
                    unc_server=${unc_path%%/*}
                    unc_share=${unc_path#*/}
                    if [ -n "$unc_server" ] && [ -n "$unc_share" ] && [ "$unc_share" = "${unc_share#*/}" ]; then
                        return 0
                    fi
                    ;;
            esac
            ;;
    esac
    case "$(uname -s)" in
        MINGW*|MSYS*|CYGWIN*)
            case "$1" in /[A-Za-z]|/[A-Za-z]/|[A-Za-z]:|[A-Za-z]:/) return 0 ;; esac
            ;;
    esac
    return 1
}
is_link_or_reparse() {
    [ -L "$1" ] && return 0
    if command -v cmd.exe >/dev/null 2>&1 && command -v cygpath >/dev/null 2>&1; then
        reparse_query=$(cmd.exe /c fsutil reparsepoint query "$(cygpath -w "$1")" 2>&1 || :)
        printf '%s\n' "$reparse_query" | grep -q 'Reparse Tag Value' && return 0
    fi
    return 1
}
canonical_home() {
    [ -n "$1" ] || fail 3 'Invalid Codex home.'
    is_link_or_reparse "$1" && fail 3 'Refusing a symbolic-link or reparse-point Codex home.'
    if [ -d "$1" ]; then
        result=$(CDPATH= cd -P "$1" && pwd -P) || fail 3 'Cannot resolve Codex home.'
    elif [ -e "$1" ]; then
        fail 3 'Refusing a non-directory Codex home.'
    else
        parent=$(dirname "$1")
        leaf=$(basename "$1")
        [ -d "$parent" ] || fail 4 'Cannot create Codex home.'
        resolved_parent=$(CDPATH= cd -P "$parent" && pwd -P) || fail 3 'Cannot resolve Codex home.'
        case "$leaf" in
            .|..) result=$(CDPATH= cd -P "$resolved_parent/$leaf" && pwd -P) || fail 3 'Cannot resolve Codex home.' ;;
            *) mkdir "$resolved_parent/$leaf" || fail 4 'Cannot create Codex home.'; result="$resolved_parent/$leaf" ;;
        esac
    fi
    is_filesystem_root "$result" && fail 3 'Codex home cannot be a filesystem root.'
    printf '%s\n' "$result"
}
cleanup_stage() {
    [ -n "$stage" ] || return 0
    case "$stage" in "$pets_dir"/.ellen-joe-pixel.stage.*) ;; *) return 1 ;; esac
    [ ! -e "$stage" ] || { rm -rf "$stage" && [ ! -e "$stage" ]; }
}
cleanup_transaction() {
    transaction_cleanup_ok=1
    cleanup_stage || transaction_cleanup_ok=0
    if [ "${lock_held:-0}" -eq 1 ]; then
        if rmdir "$install_lock"; then
            lock_held=0
        else
            transaction_cleanup_ok=0
        fi
    fi
    [ "$transaction_cleanup_ok" -eq 1 ]
}
cleanup_on_exit() {
    exit_code=$?
    trap '' HUP INT TERM
    trap - EXIT
    if cleanup_transaction; then
        exit "$exit_code"
    fi
    exit 5
}
cleanup_on_signal() {
    trap '' HUP INT TERM
    cleanup_transaction || :
    trap - EXIT HUP INT TERM
    exit 5
}
acquire_install_lock() {
    trap '' HUP INT TERM
    if mkdir "$install_lock" 2>/dev/null; then
        lock_held=1
        trap 'cleanup_on_signal' HUP INT TERM
        return 0
    fi
    trap 'cleanup_on_signal' HUP INT TERM
    fail 4 "Cannot acquire install lock: $install_lock"
}
rename_directory() {
    rename_source=$1
    rename_destination=$2
    "$python_cmd" - "$rename_source" "$rename_destination" <<'PY'
import os
import stat
import sys

source, destination = sys.argv[1:]


def reject(message):
    print(message, file=sys.stderr)
    raise SystemExit(1)


try:
    source_info = os.lstat(source)
except OSError as error:
    reject(f"cannot inspect source directory: {error}")
if stat.S_ISLNK(source_info.st_mode) or not stat.S_ISDIR(source_info.st_mode):
    reject("source is not a real directory")
for parent in (os.path.dirname(source), os.path.dirname(destination)):
    try:
        parent_info = os.lstat(parent)
    except OSError as error:
        reject(f"cannot inspect destination parent: {error}")
    if stat.S_ISLNK(parent_info.st_mode):
        reject("destination parent is a symbolic link")
try:
    os.lstat(destination)
except FileNotFoundError:
    pass
except OSError as error:
    reject(f"cannot inspect destination: {error}")
else:
    reject("destination already exists")
try:
    os.rename(source, destination)
except OSError as error:
    reject(f"directory rename failed: {error}")
PY
}
new_backup_path() {
    [ -n "$backup_dir" ] || return 1
    backup_attempt=0
    while [ "$backup_attempt" -lt 16 ]; do
        backup_token=$("$python_cmd" -c 'import secrets; print(secrets.token_hex(16))') || return 1
        backup_candidate="$backup_dir/ellen-joe-pixel.backup.$backup_token"
        if [ ! -e "$backup_candidate" ] && [ ! -L "$backup_candidate" ] && ! is_link_or_reparse "$backup_candidate"; then
            printf '%s\n' "$backup_candidate"
            return 0
        fi
        backup_attempt=$((backup_attempt + 1))
    done
    return 1
}
finish_failed_install() {
    failure_message=$1
    trap '' HUP INT TERM
    rollback_ok=1
    if [ -n "$backup" ]; then
        if [ -e "$backup" ] && [ ! -e "$target" ] && ! is_link_or_reparse "$target"; then
            rename_directory "$backup" "$target" || rollback_ok=0
        else
            rollback_ok=0
        fi
    fi
    cleanup_ok=1
    cleanup_transaction || cleanup_ok=0
    stage=
    trap - EXIT HUP INT TERM
    if [ "$cleanup_ok" -eq 1 ] && [ "$rollback_ok" -eq 1 ]; then
        fail 4 "Install failed; prior target restored when present: $failure_message"
    fi
    fail 5 "Install failed and rollback or cleanup failed: $failure_message"
}
resolve_backup_directory() {
    backup_candidate="$1/pet-backups"
    if is_link_or_reparse "$backup_candidate" || [ -n "$(readlink "$backup_candidate" 2>/dev/null || :)" ]; then
        fail 3 'Refusing a symbolic-link or reparse-point pet-backups directory.'
    elif [ -e "$backup_candidate" ]; then
        [ -d "$backup_candidate" ] || fail 3 'Refusing a non-directory pet-backups path.'
    else
        mkdir "$backup_candidate" || fail 4 'Cannot create pet-backups directory.'
    fi
    backup_result=$(CDPATH= cd -P "$backup_candidate" && pwd -P) || fail 4 'Cannot resolve pet-backups directory.'
    [ "$backup_result" = "$backup_candidate" ] || fail 3 'Pet-backups directory escapes Codex home.'
    printf '%s\n' "$backup_result"
}

if [ -n "${CODEX_HOME-}" ]; then
    codex_home=$CODEX_HOME
elif [ -n "${HOME-}" ]; then
    codex_home="$HOME/.codex"
else
    codex_home=
fi
force=0
home_specified=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --codex-home)
            [ "$#" -ge 2 ] && [ "$home_specified" -eq 0 ] && [ -n "$2" ] || fail 3 'Invalid --codex-home value.'
            case "$2" in -*) fail 3 'Invalid --codex-home value.' ;; esac
            codex_home=$2
            home_specified=1
            shift 2
            ;;
        --force) [ "$force" -eq 0 ] || fail 3 'Duplicate --force argument.'; force=1; shift ;;
        *) fail 3 "Unknown argument: $1" ;;
    esac
done
[ -n "$codex_home" ] || fail 3 'Invalid Codex home.'

script_dir=$(CDPATH= cd -P "$(dirname "$0")" && pwd) || fail 3 'Cannot resolve script directory.'
repo_root=$(CDPATH= cd -P "$script_dir/.." && pwd) || fail 3 'Cannot resolve repository root.'
source_dir="$repo_root/pet/ellen-joe-pixel"
[ -f "$source_dir/pet.json" ] && [ -f "$source_dir/spritesheet.webp" ] || fail 3 'Invalid source: package files are missing.'
# Python 3 is used only for strict JSON manifest validation. Prefer the usual
# python3 command and accept python only when it identifies as Python 3. The
# approved WebP hash below carries the already-validated v2 pixel contract
# without adding a Pillow runtime dependency to release installs.
if command -v python3 >/dev/null 2>&1 && python3 -c 'import sys; raise SystemExit(sys.version_info[0] != 3)' >/dev/null 2>&1; then
    python_cmd=python3
elif command -v python >/dev/null 2>&1 && python -c 'import sys; raise SystemExit(sys.version_info[0] != 3)' >/dev/null 2>&1; then
    python_cmd=python
else
    fail 3 'Invalid source: Python 3 is required to validate pet.json.'
fi
"$python_cmd" - "$source_dir/pet.json" <<'PY'
import json
import sys

required = {"id", "spriteVersionNumber", "spritesheetPath"}


def top_level_keys(source):
    decoder = json.JSONDecoder()

    def skip_whitespace(index):
        while index < len(source) and source[index] in " \t\r\n":
            index += 1
        return index

    index = skip_whitespace(0)
    if index == len(source) or source[index] != "{":
        raise ValueError("manifest must be an object")
    index += 1
    keys = []
    while True:
        index = skip_whitespace(index)
        if index >= len(source):
            raise ValueError("unterminated object")
        if source[index] == "}":
            return keys
        key, index = decoder.raw_decode(source, index)
        if not isinstance(key, str):
            raise ValueError("object key is not a string")
        keys.append(key)
        index = skip_whitespace(index)
        if index >= len(source) or source[index] != ":":
            raise ValueError("missing object colon")
        _, index = decoder.raw_decode(source, skip_whitespace(index + 1))
        index = skip_whitespace(index)
        if index < len(source) and source[index] == "}":
            return keys
        if index >= len(source) or source[index] != ",":
            raise ValueError("missing object comma")
        index += 1


try:
    with open(sys.argv[1], "r", encoding="utf-8", newline=None) as handle:
        source = handle.read()
    manifest = json.loads(source)
    if type(manifest) is not dict:
        raise ValueError("manifest must be an object")
    keys = top_level_keys(source)
    if any(keys.count(key) > 1 for key in required):
        raise ValueError("duplicate required top-level key")
    if manifest.get("id") != "ellen-joe-pixel":
        raise ValueError("invalid id")
    if manifest.get("displayName") != "Ellen Joe Pixel":
        raise ValueError("invalid display name")
    if not isinstance(manifest.get("description"), str) or not manifest["description"].strip():
        raise ValueError("invalid description")
    if type(manifest.get("spriteVersionNumber")) is not int or manifest["spriteVersionNumber"] != 2:
        raise ValueError("invalid sprite version")
    if manifest.get("spritesheetPath") != "spritesheet.webp":
        raise ValueError("invalid spritesheet path")
except (OSError, ValueError, json.JSONDecodeError, TypeError) as error:
    print(f"Invalid source: manifest contract mismatch ({error}).", file=sys.stderr)
    sys.exit(1)
PY
[ "$?" -eq 0 ] || fail 3 'Invalid source: manifest contract mismatch.'

expected_spritesheet_sha256=C6F4ED31F670E00CDA1B596F35372B3B60BA5A6CB94DBD6E049B2E1950FC15E6
if command -v sha256sum >/dev/null 2>&1; then
    actual_spritesheet_sha256=$(sha256sum "$source_dir/spritesheet.webp" | awk '{print $1}') || fail 3 'Invalid source: cannot hash spritesheet.webp.'
elif command -v shasum >/dev/null 2>&1; then
    actual_spritesheet_sha256=$(shasum -a 256 "$source_dir/spritesheet.webp" | awk '{print $1}') || fail 3 'Invalid source: cannot hash spritesheet.webp.'
else
    fail 3 'Invalid source: sha256sum or shasum is required to verify spritesheet.webp.'
fi
[ "$(printf '%s' "$actual_spritesheet_sha256" | tr '[:lower:]' '[:upper:]')" = "$expected_spritesheet_sha256" ] || fail 3 'Invalid source: spritesheet.webp does not match the approved v2 atlas.'

codex_home=$(canonical_home "$codex_home") || exit $?
pets_candidate="$codex_home/pets"
if is_link_or_reparse "$pets_candidate" || [ -n "$(readlink "$pets_candidate" 2>/dev/null || :)" ]; then
    fail 3 'Refusing a symbolic-link pets directory.'
elif [ -e "$pets_candidate" ]; then
    [ -d "$pets_candidate" ] || fail 3 'Refusing a non-directory pets path.'
else
    mkdir "$pets_candidate" || fail 4 'Cannot create pets directory.'
fi
pets_dir=$(CDPATH= cd -P "$pets_candidate" && pwd -P) || fail 4 'Cannot resolve pets directory.'
[ "$pets_dir" = "$pets_candidate" ] || fail 3 'Pets directory escapes Codex home.'
target="$pets_dir/ellen-joe-pixel"
install_lock="$pets_dir/.ellen-joe-pixel.install.lock"
backup_dir=
stage=
backup=
lock_held=0
trap 'cleanup_on_exit' EXIT
trap 'cleanup_on_signal' HUP INT TERM
acquire_install_lock
if is_link_or_reparse "$target"; then
    fail 3 'Refusing a symbolic-link target.'
elif [ -e "$target" ]; then
    [ -d "$target" ] || fail 3 'Refusing a non-directory target.'
    [ "$force" -eq 1 ] || fail 2 "Target already exists: $target"
    backup_dir=$(resolve_backup_directory "$codex_home") || exit $?
fi

stage=$(mktemp -d "$pets_dir/.ellen-joe-pixel.stage.XXXXXX") || fail 4 'Cannot create staging directory.'
cp "$source_dir/pet.json" "$source_dir/spritesheet.webp" "$stage/" || finish_failed_install 'Cannot stage package files.'
if is_link_or_reparse "$target"; then
    fail 3 'Refusing a symbolic-link target.'
elif [ -e "$target" ]; then
    [ -d "$target" ] || fail 3 'Refusing a non-directory target.'
    if [ -z "$backup_dir" ]; then
        backup_dir=$(resolve_backup_directory "$codex_home") || exit $?
    fi
    backup_candidate=$(new_backup_path) || finish_failed_install 'Cannot allocate a unique backup path.'
    [ -n "$backup_candidate" ] || finish_failed_install 'Cannot allocate a unique backup path.'
    rename_directory "$target" "$backup_candidate" || finish_failed_install 'Cannot create backup.'
    backup=$backup_candidate
fi
if ! rename_directory "$stage" "$target"; then
    finish_failed_install 'Final move failed.'
fi
stage=
trap '' HUP INT TERM
if ! cleanup_transaction; then
    trap - EXIT HUP INT TERM
    fail 5 'Install succeeded but cleanup failed.'
fi
trap - EXIT HUP INT TERM
printf 'Installed: %s\n' "$target"
[ -z "$backup" ] || printf 'Backup: %s\n' "$backup"
exit 0
