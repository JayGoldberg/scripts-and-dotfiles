#!/bin/sh
cd "$(dirname "$0")"
my_dir=machine-specific/${HOSTNAME:-$(hostname)}

if echo test | read -s -n1 testvar 2>/dev/null; then
    sread() { read -s -n1 "$@"; }
else
    sread() { read "$@"; }
fi

_install() {
    install -pvTDm "$(stat -c%a "$1")" -- "$1" "$2"
}

_copy_to_git() {
    install -pTm "$(stat -c%a "$2")" -- "$2" "$1"
}

safecopy() {
    local operation answer

    [ -e "$my_dir/$1" ] && set -- "$my_dir/$1" "$2"

    operation=_install
    if [ -r "$2" ]; then
        if ! diff -U5 "$2" "$1"; then
            echo "You have a different version of $1 - if you install, the above changes will be applied."
            answer=
            while :; do case $answer in
                [iI]) operation=_install; break;;
                [gG]) operation=_copy_to_git; break;;
                [vV]) operation=vimdiff; break;;
                [sS]) return 0;;
                [qQ]) exit 0;;
                *)
                    echo "What should I do? (I)nstall, Update in (G)it repo, (V)imdiff, (S)kip, (Q)uit"
                    sread answer
                    ;;
            esac; done
        else
            return 0
        fi
    fi
    "$operation" "$@"
}

recurse() {
    for file in "$2"/* "$2"/.*; do
        case "$(basename "$file")" in
            # Handle globbed ./..
            .|..) continue;;
            # Handle failed globs (blah/* where * doesn't exist)
            *) [ -e "$file" ] || continue;;
        esac

        if [ -d "$file" ]; then
            recurse "$1" "$file"
        elif [ -f "$file" ]; then
            "$1" "$file"
        fi
    done
    true
}

_copy_loop() { safecopy "$1" "$HOME/$1"; }
recurse _copy_loop bin

_dotfiles_copy_loop() { safecopy "$1" "$HOME/${1#*/}"; }
recurse _dotfiles_copy_loop dotfiles

echo 'As always, make sure you have pulled submodules!'
cd pomfclip && ./install.sh
