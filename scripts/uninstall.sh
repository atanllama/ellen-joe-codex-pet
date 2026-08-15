#!/bin/sh
set -u
fail() { code=$1; shift; printf '%s\n' "$*" >&2; exit "$code"; }
codex_home=${CODEX_HOME:-"$HOME/.codex"}
while [ "$#" -gt 0 ]; do
    case "$1" in
        --codex-home) [ "$#" -ge 2 ] || fail 3 'Missing --codex-home value.'; codex_home=$2; shift 2 ;;
        *) fail 3 "Unknown argument: $1" ;;
    esac
done
[ -n "$codex_home" ] && [ "$codex_home" != / ] || fail 3 'Invalid Codex home.'
[ -d "$codex_home/pets" ] || fail 2 'Pet is not installed.'
pets_dir=$(CDPATH= cd -P "$codex_home/pets" && pwd) || fail 3 'Cannot resolve pets directory.'
target="$pets_dir/ellen-joe-pixel"
[ "$(basename "$target")" = 'ellen-joe-pixel' ] || fail 3 'Target verification failed.'
[ ! -L "$target" ] || fail 3 'Refusing a symbolic-link target.'
[ -d "$target" ] || fail 2 "Target is not installed: $target"
rm -rf "$target" || fail 5 'Uninstall failed.'
printf 'Uninstalled: %s\n' "$target"
exit 0
