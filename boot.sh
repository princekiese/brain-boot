#!/bin/sh
# BRAIN BOOT for macOS / Linux: from a bare machine to a working persona.
# Public and generic: it contains no private data and knows nothing about your repo until you tell it.
# Read it before running it.
#
#   sh boot.sh <owner/repo> [destination]
#
# Steps (each skipped when already done): git + GitHub CLI, GitHub sign-in (YOU do it in the
# browser), clone your private repo, run that repo's own bootstrap.sh if it has one.
set -e
repo="$1"
if [ -z "$repo" ]; then
    printf 'Your private persona repo (owner/repo): '
    read -r repo
fi
case "$repo" in
    */*) ;;
    *) echo "'$repo' isn't in owner/repo form."; exit 1 ;;
esac
dest="${2:-$HOME/${repo#*/}}"
step() { printf '\n== %s\n' "$1"; }

step "1/4 Git and GitHub CLI"
missing=""
command -v git >/dev/null 2>&1 || missing="$missing git"
command -v gh >/dev/null 2>&1 || missing="$missing gh"
if [ -n "$missing" ]; then
    if [ "$(uname)" = "Darwin" ]; then
        command -v brew >/dev/null 2>&1 || { echo "Install Homebrew first (https://brew.sh), then rerun."; exit 1; }
        brew install $missing
    else
        echo "Run this yourself (needs sudo), then rerun:"
        echo "  sudo apt-get install -y$missing"
        exit 1
    fi
fi
echo "ok      git, gh"

step "2/4 GitHub sign-in (in your browser)"
if gh auth status >/dev/null 2>&1; then
    echo "ok      already signed in"
else
    echo "A browser window opens: sign in to GitHub there."
    gh auth login --hostname github.com --git-protocol https --web
fi

step "3/4 Clone $repo -> $dest"
if [ -d "$dest/.git" ]; then
    git -C "$dest" pull --ff-only
else
    gh repo clone "$repo" "$dest" || { echo "Cloning failed: does this GitHub account have access to $repo?"; exit 1; }
fi

step "4/4 Your repo's own setup"
if [ -f "$dest/bootstrap.sh" ]; then
    sh "$dest/bootstrap.sh"
else
    echo "No bootstrap.sh in $repo: nothing more to run."
fi

printf '\nDone. Open your AI in %s and ask it to read AGENTS.md and become your persona.\n' "$dest"
