#!/bin/sh
set -u
fail() { code=$1; shift; printf '%s\n' "$*" >&2; exit "$code"; }
is_filesystem_root() {
    case "$1" in /|//|//* ) return 0 ;; esac
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
finish_failed_install() {
    failure_message=$1
    rollback_ok=1
    if [ -n "$backup" ]; then
        if [ -e "$backup" ] && [ ! -e "$target" ]; then
            mv "$backup" "$target" || rollback_ok=0
        else
            rollback_ok=0
        fi
    fi
    if cleanup_stage && [ "$rollback_ok" -eq 1 ]; then
        stage=
        trap - EXIT HUP INT TERM
        fail 4 "Install failed; prior target restored when present: $failure_message"
    fi
    stage=
    trap - EXIT HUP INT TERM
    fail 5 "Install failed and rollback or cleanup failed: $failure_message"
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
# Python 3 is a declared runtime dependency for this Python package. Prefer the
# usual python3 command and accept python only when it identifies as Python 3.
# If neither is available, validation fails explicitly rather than falling back
# to a best-effort or substring-based parser.
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


def object_with_safe_required_keys(pairs):
    value = {}
    for key, item in pairs:
        if key in required and key in value:
            raise ValueError(f"duplicate required key: {key}")
        value[key] = item
    return value


try:
    with open(sys.argv[1], "r", encoding="utf-8", newline=None) as handle:
        manifest = json.load(handle, object_pairs_hook=object_with_safe_required_keys)
    if type(manifest) is not dict:
        raise ValueError("manifest must be an object")
    if manifest.get("id") != "ellen-joe-pixel":
        raise ValueError("invalid id")
    if type(manifest.get("spriteVersionNumber")) is not int or manifest["spriteVersionNumber"] != 2:
        raise ValueError("invalid sprite version")
    if manifest.get("spritesheetPath") != "spritesheet.webp":
        raise ValueError("invalid spritesheet path")
    if not isinstance(manifest.get("description"), str) or not manifest["description"].strip():
        raise ValueError("description must be non-empty")
except (OSError, ValueError, json.JSONDecodeError, TypeError) as error:
    print(f"Invalid source: manifest contract mismatch ({error}).", file=sys.stderr)
    sys.exit(1)
PY
[ "$?" -eq 0 ] || fail 3 'Invalid source: manifest contract mismatch.'

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
if is_link_or_reparse "$target"; then
    fail 3 'Refusing a symbolic-link target.'
elif [ -e "$target" ]; then
    [ -d "$target" ] || fail 3 'Refusing a non-directory target.'
    [ "$force" -eq 1 ] || fail 2 "Target already exists: $target"
fi

stage=$(mktemp -d "$pets_dir/.ellen-joe-pixel.stage.XXXXXX") || fail 4 'Cannot create staging directory.'
backup=
trap 'cleanup_stage || :' EXIT HUP INT TERM
cp "$source_dir/pet.json" "$source_dir/spritesheet.webp" "$stage/" || finish_failed_install 'Cannot stage package files.'
if [ -e "$target" ]; then
    backup="$target.backup.$(date -u +%Y%m%dT%H%M%SZ).$$"
    mv "$target" "$backup" || finish_failed_install 'Cannot create backup.'
fi
if ! mv "$stage" "$target"; then
    finish_failed_install 'Final move failed.'
fi
stage=
trap - EXIT HUP INT TERM
printf 'Installed: %s\n' "$target"
[ -z "$backup" ] || printf 'Backup: %s\n' "$backup"
exit 0
