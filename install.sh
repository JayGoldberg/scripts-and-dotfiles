#!/bin/sh
cd "$(dirname "$0")"

if echo test | read -s -n1 testvar 2>/dev/null; then
    sread() { read -s -n1 "$@"; }
else
    sread() { read "$@"; }
fi

_install() {
    install -pvTD -- "$@"
}

_copy_to_git() {
    install -pT -- "$2" "$1"
}

safecopy() {
    local operation answer
    operation=_install
    if [ -r "$2" ]; then
        if ! diff -U5 "$2" "$1"; then
            echo "You have a different version of $1 - if you install, the above changes will be applied."
            answer=
            while :; do case $answer in
                [iI]) operation=_install; break;;
                [gG]) operation=_copy_to_git; break;;
                [sS]) return;;
                [qQ]) exit 0;;
                *)
                    echo "What should I do? (I)nstall, Update in (G)it repo, (S)kip, (Q)uit"
                    sread answer
                    ;;
            esac; done
        else
            return
        fi
    fi
    "$operation" "$@"
}

recurse() {
    for file in "$2"/*; do
        if [ -d "$file" ]; then
            recurse "$1" "$file"
        elif [ -f "$file" ]; then
            "$1" "$file"
        fi
    done
}

_copy_loop() {
    safecopy "$1" "$HOME/$1"
}
recurse _copy_loop bin

# TODO non-~/bin dotfiles
