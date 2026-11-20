#!/bin/sh
# BRAIN BOOT for macOS / Linux: from a bare machine to a working persona.
# Public and generic: it contains no private data and knows nothing about your repo until you tell it.
# Read it before running it. Works with or without an AI.
#
#   sh boot.sh                      (asks which repo, after sign-in)
#   sh boot.sh my-personas [destination]  (or owner/my-personas)
#
# Steps (each skipped when already done, so it's safe to rerun): git + GitHub CLI, GitHub sign-in
# (YOU do it in the browser), choose your private repo, clone it, run its own bootstrap.sh if any.
set -e
repo="$1"
dest="$2"
step() { printf '\n== %s\n' "$1"; }
ok()   { printf 'ok      %s\n' "$1"; }
fail() { printf '\nSTOPPED: %s\nFix that, then run the same command again. Finished steps are skipped.\n' "$1"; exit 1; }

step "1/5 Git and GitHub CLI"
missing=""
command -v git >/dev/null 2>&1 || missing="$missing git"
command -v gh >/dev/null 2>&1 || missing="$missing gh"
if [ -n "$missing" ]; then
    if [ "$(uname)" = "Darwin" ]; then
        command -v brew >/dev/null 2>&1 || fail "Homebrew is missing. Install it from https://brew.sh"
        brew install $missing
    else
        printf 'Run this yourself (it needs sudo), then rerun:\n  sudo apt-get install -y%s\n' "$missing"
        printf '(GitHub CLI may need its own apt source: https://github.com/cli/cli/blob/trunk/docs/install_linux.md)\n'
        exit 1
    fi
fi
ok "git, gh"

step "2/5 GitHub sign-in (in your browser)"
if ! gh auth status >/dev/null 2>&1; then
    echo 'What happens next:'
    echo '  1. If asked "Authenticate Git with your GitHub credentials?", answer Y.'
    echo '  2. A one-time code is shown. Press Enter: your browser opens.'
    echo '  3. In the browser: sign in, enter the code, approve.'
    echo '  Never type your password or the code into this window or into an AI chat.'
    echo
    gh auth login --hostname github.com --git-protocol https --web || fail "GitHub sign-in did not complete."
fi
me="$(gh api user --jq .login)" || fail "Signed in, but GitHub did not say which account. Run 'gh auth status' to check."
ok "signed in as $me"

step "3/5 Choose your persona repo"
list=""
if [ -z "$repo" ]; then
    list="$(gh repo list "$me" --visibility private --limit 100 --json nameWithOwner --jq '.[].nameWithOwner' || true)"
    if [ -n "$list" ]; then
        echo 'Your private repos:'
        printf '%s\n' "$list" | awk '{ printf "  %3d. %s\n", NR, $0 }'
    fi
    echo 'Type a number from the list, a repo name (like my-personas) or owner/name.'
    printf 'Repo: '
    read -r repo
fi
# Accept "3", "my-personas", "owner/my-personas", "https://github.com/owner/my-personas(.git)".
repo="$(printf '%s' "$repo" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
    -e 's#^https\{0,1\}://##' -e 's#^www\.##' -e 's#^github\.com/##' -e 's#\.git$##' -e 's#/*$##')"
[ -n "$repo" ] || fail "No repo given."
case "$repo" in
    *[!0-9]*) ;;
    *) picked="$(printf '%s\n' "$list" | sed -n "${repo}p")"
       [ -n "$picked" ] && repo="$picked" ;;
esac
case "$repo" in */*) ;; *) repo="$me/$repo" ;; esac
printf '%s' "$repo" | grep -Eq '^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$' \
    || fail "'$repo' doesn't look like a repo name. Examples: my-personas, or owner/my-personas."
gh repo view "$repo" --json name >/dev/null 2>&1 \
    || fail "Can't open $repo as $me. Check the spelling, or that this account has access to it."
ok "$repo"

dest="${dest:-$HOME/${repo#*/}}"
step "4/5 Clone into $dest"
if [ -d "$dest/.git" ]; then
    git -C "$dest" pull --ff-only || fail "Couldn't update $dest. It may have local changes: check it with 'git -C $dest status'."
elif [ -d "$dest" ] && [ -n "$(ls -A "$dest")" ]; then
    fail "$dest already exists and isn't a clone of $repo. Move it away, or pass another destination."
else
    gh repo clone "$repo" "$dest" || fail "Cloning $repo failed."
fi
ok "$dest"

step "5/5 Your repo's own setup"
if [ -f "$dest/bootstrap.sh" ]; then
    sh "$dest/bootstrap.sh" || fail "$repo's bootstrap.sh stopped with an error (see above)."
    ok "bootstrap.sh"
else
    ok "no bootstrap.sh, nothing to run"
fi

printf '\nDone. Your persona repo is at %s\n' "$dest"
[ -f "$dest/AGENTS.md" ] || printf "Note: there's no AGENTS.md in it yet. brain-boot expects one at the repo root.\n"
printf '\nNext, with an AI: tell it\n'
printf "    My persona repo is at %s. Read its AGENTS.md and become (the persona's name).\n" "$dest"
printf 'Next, without an AI: open %s/AGENTS.md and follow it yourself.\n' "$dest"
