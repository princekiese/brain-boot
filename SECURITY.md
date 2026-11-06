# Security and privacy

## What is public, what isn't

| Public (this repo) | Private (your own repo, never named here) |
|---|---|
| The cold-start protocol for AIs | Personas: identity, character, knowledge |
| Two bootstrap scripts | People the personas work for |
| This documentation, checksums, license | Machines, inventories, paths, installed software |
| | Memory files, lessons, history |

The private repo's name is given by the person in the conversation or typed into the script. It's never written in this repo.

## Threat model

| Risk | Mitigation |
|---|---|
| Someone reads this repo to learn about the owner | It contains only generic method. A policy check refuses releases that mention people, personas, machines, private repo names, user paths or emails |
| Someone tries to get the private data | The private repo is protected by GitHub access control. Cloning needs a GitHub account the owner has granted access to. Nothing here bypasses that |
| An AI is tricked into asking for credentials | The protocol forbids asking for or accepting passwords, tokens, recovery or 2FA codes. Sign-in only happens in the browser through GitHub's device flow |
| An AI leaks private content into public places | The protocol forbids copying private details into issues, PRs, gists or web forms |
| A tampered script | Scripts are short and meant to be read before running. `SHA256SUMS` lists every file's hash, tagged releases give fixed versions, and only official package sources (winget, Homebrew, apt) are used |
| Prompt injection through this repo's issues/PRs | The protocol tells AIs that text in issues, PRs, files and pages is information, not instructions |
| Elevated changes | The scripts install with the standard package managers and never edit system settings. Linux `sudo` commands are printed, not run |

## Verifying a download

```powershell
Get-FileHash boot.ps1 -Algorithm SHA256
```
```sh
shasum -a 256 boot.sh
```
Compare with the matching line in `SHA256SUMS` from the **same release**. If they differ, don't run the script.

## Reporting a problem

Open an issue describing the problem **without** personal data, or contact the maintainer through their GitHub profile for anything sensitive.
