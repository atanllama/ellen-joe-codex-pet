#!/bin/sh
set -u
fail() { code=$1; shift; printf '%s\n' "$*" >&2; exit "$code"; }
script_dir=$(CDPATH= cd -P "$(dirname "$0")" && pwd) || fail 3 'Cannot resolve script directory.'
repo_root=$(CDPATH= cd -P "$script_dir/.." && pwd) || fail 3 'Cannot resolve repository root.'
source_dir="$repo_root/pet/ellen-joe-pixel"
codex_home=${CODEX_HOME:-"$HOME/.codex"}
force=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --codex-home) [ "$#" -ge 2 ] || fail 3 'Missing --codex-home value.'; codex_home=$2; shift 2 ;;
        --force) force=1; shift ;;
        *) fail 3 "Unknown argument: $1" ;;
    esac
done
[ -n "$codex_home" ] && [ "$codex_home" != / ] || fail 3 'Invalid Codex home.'
[ -f "$source_dir/pet.json" ] && [ -f "$source_dir/spritesheet.webp" ] || fail 3 'Invalid source: package files are missing.'
grep -Eq '"id"[[:space:]]*:[[:space:]]*"ellen-joe-pixel"' "$source_dir/pet.json" || fail 3 'Invalid source id.'
grep -Eq '"spriteVersionNumber"[[:space:]]*:[[:space:]]*2' "$source_dir/pet.json" || fail 3 'Invalid sprite version.'
grep -Eq '"spritesheetPath"[[:space:]]*:[[:space:]]*"spritesheet.webp"' "$source_dir/pet.json" || fail 3 'Invalid spritesheet path.'
mkdir -p "$codex_home/pets" || fail 4 'Cannot create pets directory.'
pets_dir=$(CDPATH= cd -P "$codex_home/pets" && pwd) || fail 4 'Cannot resolve pets directory.'
target="$pets_dir/ellen-joe-pixel"
[ ! -L "$target" ] || fail 3 'Refusing a symbolic-link target.'
if [ -e "$target" ] && [ "$force" -ne 1 ]; then fail 2 "Target already exists: $target"; fi
stage=$(mktemp -d "$pets_dir/.ellen-joe-pixel.stage.XXXXXX") || fail 4 'Cannot create staging directory.'
backup=
cleanup() { [ -n "$stage" ] && [ -d "$stage" ] && rm -rf "$stage"; }
trap cleanup EXIT HUP INT TERM
cp "$source_dir/pet.json" "$source_dir/spritesheet.webp" "$stage/" || fail 4 'Cannot stage package files.'
if [ -e "$target" ]; then
    backup="$target.backup.$(date -u +%Y%m%dT%H%M%SZ).$$"
    mv "$target" "$backup" || fail 4 'Cannot create backup.'
fi
if ! mv "$stage" "$target"; then
    stage=
    if [ -n "$backup" ] && [ -e "$backup" ] && [ ! -e "$target" ]; then
        mv "$backup" "$target" || fail 5 'Install and rollback both failed.'
    fi
    fail 4 'Install failed; prior target restored when present.'
fi
stage=
trap - EXIT HUP INT TERM
printf 'Installed: %s\n' "$target"
[ -z "$backup" ] || printf 'Backup: %s\n' "$backup"
exit 0
