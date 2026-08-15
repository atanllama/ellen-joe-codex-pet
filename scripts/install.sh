#!/bin/sh
set -u
fail() { code=$1; shift; printf '%s\n' "$*" >&2; exit "$code"; }
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
    [ "$result" != / ] || fail 3 'Codex home cannot be a filesystem root.'
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
# The shipped manifest is a controlled, canonical one-line JSON contract. This
# exact comparison rejects malformed JSON, duplicate keys, and substring values.
expected_manifest='{"id":"ellen-joe-pixel","displayName":"Ellen Joe Pixel","description":"A sleepy full-body Ellen Joe fan-art Codex Pet.","spriteVersionNumber":2,"spritesheetPath":"spritesheet.webp"}'
actual_manifest=$(cat "$source_dir/pet.json") || fail 3 'Invalid source: cannot read manifest.'
[ "$actual_manifest" = "$expected_manifest" ] || fail 3 'Invalid source: manifest contract mismatch.'

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
