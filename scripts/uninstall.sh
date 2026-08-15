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
canonical_existing_home() {
    [ -n "$1" ] || fail 3 'Invalid Codex home.'
    [ -e "$1" ] || fail 2 'Pet is not installed.'
    [ -d "$1" ] || fail 3 'Refusing a non-directory Codex home.'
    result=$(CDPATH= cd -P "$1" && pwd -P) || fail 3 'Cannot resolve Codex home.'
    [ "$result" != / ] || fail 3 'Codex home cannot be a filesystem root.'
    printf '%s\n' "$result"
}

if [ -n "${CODEX_HOME-}" ]; then
    codex_home=$CODEX_HOME
elif [ -n "${HOME-}" ]; then
    codex_home="$HOME/.codex"
else
    codex_home=
fi
home_specified=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --codex-home)
            [ "$#" -ge 2 ] && [ "$home_specified" -eq 0 ] && [ -n "$2" ] || fail 3 'Invalid --codex-home value.'
            codex_home=$2
            home_specified=1
            shift 2
            ;;
        *) fail 3 "Unknown argument: $1" ;;
    esac
done
[ -n "$codex_home" ] || fail 3 'Invalid Codex home.'

codex_home=$(canonical_existing_home "$codex_home") || exit $?
pets_candidate="$codex_home/pets"
if is_link_or_reparse "$pets_candidate" || [ -n "$(readlink "$pets_candidate" 2>/dev/null || :)" ]; then
    fail 3 'Refusing a symbolic-link pets directory.'
fi
[ -e "$pets_candidate" ] || fail 2 'Pet is not installed.'
[ -d "$pets_candidate" ] || fail 3 'Refusing a non-directory pets path.'
pets_dir=$(CDPATH= cd -P "$pets_candidate" && pwd -P) || fail 3 'Cannot resolve pets directory.'
[ "$pets_dir" = "$pets_candidate" ] || fail 3 'Pets directory escapes Codex home.'
target="$pets_dir/ellen-joe-pixel"
[ "$(basename "$target")" = 'ellen-joe-pixel' ] || fail 3 'Target verification failed.'
is_link_or_reparse "$target" && fail 3 'Refusing a symbolic-link target.'
[ -e "$target" ] || fail 2 "Target is not installed: $target"
[ -d "$target" ] || fail 3 'Refusing a non-directory target.'
rm -rf "$target" || fail 5 'Uninstall failed.'
printf 'Uninstalled: %s\n' "$target"
exit 0
