# BRAIN BOOT for Windows: from a bare machine to a working persona.
# Public and generic: it contains no private data and knows nothing about your repo until you tell it.
# Read it before running it. Works with or without an AI.
#
#   powershell -ExecutionPolicy Bypass -File .\boot.ps1
#
# Optional:  -Repo my-personas   or   -Repo owner/my-personas     (skip the question in step 3)
#            -Dest D:\somewhere\my-personas                  (where to clone; default: your user folder)
#
# Steps (each skipped when already done, so it's safe to rerun):
#   1. Git and GitHub CLI, installed with winget (official sources)
#   2. GitHub sign-in: YOU do it in the browser. Nothing secret is typed into this script
#   3. Choose your private persona repo (from a list, or by name)
#   4. Clone it (or update an existing clone)
#   5. Run that repo's own bootstrap.ps1, if it has one
param(
    [string] $Repo,
    [string] $Dest
)
$ErrorActionPreference = 'Stop'

function Step([string] $Text) { Write-Host ''; Write-Host "== $Text" -ForegroundColor Cyan }
function Ok([string] $Text)   { Write-Host "ok      $Text" -ForegroundColor Green }
function Fail([string] $Text) {
    Write-Host ''
    Write-Host "STOPPED: $Text" -ForegroundColor Red
    Write-Host 'Fix that, then run the same command again. Finished steps are skipped.'
    exit 1
}
function Test-Command([string] $Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }
function Update-SessionPath {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
}
# Runs a command through cmd so only its exit code matters (no red PowerShell noise from stderr).
function Test-Quietly([string] $Command) { cmd /c "$Command >nul 2>nul"; return ($LASTEXITCODE -eq 0) }

Step '1/5 Git and GitHub CLI'
if (-not (Test-Command winget)) { Fail 'winget is missing. Install "App Installer" from the Microsoft Store.' }
$wingetArgs = @('--exact', '--source', 'winget', '--silent', '--accept-source-agreements', '--accept-package-agreements')
foreach ($pkg in @(@{ Cmd = 'git'; Id = 'Git.Git'; Name = 'Git' }, @{ Cmd = 'gh'; Id = 'GitHub.cli'; Name = 'GitHub CLI' })) {
    if (Test-Command $pkg.Cmd) { Ok $pkg.Name; continue }
    Write-Host "Installing $($pkg.Name). Windows may ask you to allow it."
    winget install --id $pkg.Id @wingetArgs
    Update-SessionPath
    if (-not (Test-Command $pkg.Cmd)) { Fail "$($pkg.Name) didn't install. Close this window, open a new PowerShell window and rerun." }
    Ok $pkg.Name
}

Step '2/5 GitHub sign-in (in your browser)'
if (-not (Test-Quietly 'gh auth status')) {
    Write-Host 'What happens next:'
    Write-Host '  1. If asked "Authenticate Git with your GitHub credentials?", answer Y.'
    Write-Host '  2. A one-time code is shown (and copied). Press Enter: your browser opens.'
    Write-Host '  3. In the browser: sign in, paste the code, approve.'
    Write-Host '  Never type your password or the code into this window or into an AI chat.'
    Write-Host ''
    gh auth login --hostname github.com --git-protocol https --web
    if ($LASTEXITCODE -ne 0) { Fail 'GitHub sign-in did not complete.' }
}
$me = (gh api user --jq .login)
if (-not $me) { Fail 'Signed in, but GitHub did not say which account. Run "gh auth status" to check.' }
Ok "signed in as $me"

Step '3/5 Choose your persona repo'
$list = @()
if (-not $Repo) {
    $list = @(gh repo list $me --visibility private --limit 100 --json nameWithOwner --jq '.[].nameWithOwner')
    if ($list.Count -gt 0) {
        Write-Host 'Your private repos:'
        for ($i = 0; $i -lt $list.Count; $i++) { Write-Host ('  {0,3}. {1}' -f ($i + 1), $list[$i]) }
    }
    Write-Host 'Type a number from the list, a repo name (like my-personas) or owner/name.'
    $Repo = Read-Host 'Repo'
}
# Accept "3", "my-personas", "owner/my-personas", "https://github.com/owner/my-personas(.git)".
$Repo = $Repo.Trim() -replace '^(https?://)?(www\.)?github\.com/', '' -replace '\.git$', '' -replace '/+$', ''
if (-not $Repo) { Fail 'No repo given.' }
if ($Repo -match '^\d+$' -and [int]$Repo -ge 1 -and [int]$Repo -le $list.Count) { $Repo = $list[[int]$Repo - 1] }
elseif ($Repo -notmatch '/') { $Repo = "$me/$Repo" }
if ($Repo -notmatch '^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$') { Fail "'$Repo' doesn't look like a repo name. Examples: my-personas, or owner/my-personas." }
if (-not (Test-Quietly "gh repo view $Repo --json name")) {
    Fail "Can't open $Repo as $me. Check the spelling, or that this account has access to it."
}
Ok $Repo

if (-not $Dest) { $Dest = Join-Path $env:USERPROFILE ($Repo.Split('/')[1]) }
Step "4/5 Clone into $Dest"
if (Test-Path (Join-Path $Dest '.git')) {
    git -C $Dest pull --ff-only
    if ($LASTEXITCODE -ne 0) { Fail "Couldn't update $Dest. It may have local changes: check it with 'git -C $Dest status'." }
} elseif ((Test-Path $Dest) -and (Get-ChildItem -Force $Dest | Select-Object -First 1)) {
    Fail "$Dest already exists and isn't a clone of $Repo. Move it away, or rerun with -Dest and another folder."
} else {
    gh repo clone $Repo $Dest
    if ($LASTEXITCODE -ne 0) { Fail "Cloning $Repo failed." }
}
Ok $Dest

Step '5/5 Your repo''s own setup'
$bootstrap = Join-Path $Dest 'bootstrap.ps1'
if (Test-Path $bootstrap) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $bootstrap
    if ($LASTEXITCODE -ne 0) { Fail "$Repo's bootstrap.ps1 stopped with an error (see above)." }
    Ok 'bootstrap.ps1'
} else {
    Ok 'no bootstrap.ps1, nothing to run'
}

$agents = Join-Path $Dest 'AGENTS.md'
Write-Host ''
Write-Host "Done. Your persona repo is at $Dest" -ForegroundColor Green
if (-not (Test-Path $agents)) { Write-Host "Note: there's no AGENTS.md in it yet. brain-boot expects one at the repo root." -ForegroundColor Yellow }
Write-Host ''
Write-Host 'Next, with an AI: tell it'
Write-Host "    My persona repo is at $Dest. Read its AGENTS.md and become (the persona's name)."
Write-Host "Next, without an AI: open $agents and follow it yourself."
