# BRAIN BOOT for Windows: from a bare machine to a working persona.
# Public and generic: it contains no private data and knows nothing about your repo until you tell it.
# Read it before running it.
#
#   powershell -ExecutionPolicy Bypass -File .\boot.ps1 -Repo <owner/repo>
#
# Steps (each skipped when already done):
#   1. Git and GitHub CLI, installed with winget (official sources)
#   2. GitHub sign-in: YOU do it in the browser. Nothing is typed into this script
#   3. Clone your private repo (or update an existing clone)
#   4. Run that repo's own bootstrap.ps1, if it has one
param(
    [string] $Repo,
    [string] $Dest
)
$ErrorActionPreference = 'Stop'

function Step([string] $Text) { ''; "== $Text" }
function Test-Command([string] $Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }
function Update-SessionPath {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
}

if (-not $Repo) { $Repo = Read-Host 'Your private persona repo (owner/repo)' }
if ($Repo -notmatch '^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$') { throw "'$Repo' isn't in owner/repo form." }
if (-not $Dest) { $Dest = Join-Path $env:USERPROFILE ($Repo.Split('/')[1]) }

Step '1/4 Git and GitHub CLI'
if (-not (Test-Command winget)) { throw 'winget is missing: install "App Installer" from the Microsoft Store, then rerun.' }
$wingetArgs = @('--exact', '--source', 'winget', '--silent', '--accept-source-agreements', '--accept-package-agreements')
foreach ($pkg in @(@{ Cmd = 'git'; Id = 'Git.Git' }, @{ Cmd = 'gh'; Id = 'GitHub.cli' })) {
    if (Test-Command $pkg.Cmd) { "ok      $($pkg.Cmd)" } else { winget install --id $pkg.Id @wingetArgs; Update-SessionPath }
}

Step '2/4 GitHub sign-in (in your browser)'
cmd /c "gh auth status >nul 2>nul"   # via cmd: exit code is reliable and stderr can't trip $ErrorActionPreference
if ($LASTEXITCODE -ne 0) {
    'A browser window opens: sign in to GitHub there and enter the code shown below.'
    gh auth login --hostname github.com --git-protocol https --web
    if ($LASTEXITCODE -ne 0) { throw 'GitHub sign-in did not complete. Rerun when ready.' }
} else { 'ok      already signed in' }

Step "3/4 Clone $Repo -> $Dest"
if (Test-Path (Join-Path $Dest '.git')) {
    git -C $Dest pull --ff-only
} else {
    gh repo clone $Repo $Dest
    if ($LASTEXITCODE -ne 0) { throw "Cloning $Repo failed: does this GitHub account have access to it?" }
}

Step '4/4 Your repo''s own setup'
$bootstrap = Join-Path $Dest 'bootstrap.ps1'
if (Test-Path $bootstrap) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $bootstrap
} else {
    "No bootstrap.ps1 in ${Repo}: nothing more to run."
}

''
"Done. Open your AI in $Dest and ask it to read AGENTS.md and become your persona."
