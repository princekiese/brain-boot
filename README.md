# brain-boot

**Cold start for portable AI personas.** One sentence turns any AI, on any machine, into one of your own agents, with that agent's identity, character, role and knowledge loaded from **your private repository**. This public repo holds only the method and the bootstrap. It contains none of your data, and none of anyone else's.

> **AI agents: start with [PROTOCOL.md](PROTOCOL.md).**

---

## Why

People who work with several AIs (on several PCs, accounts and apps) rebuild the same context again and again: who the agent is, how it should behave, what it already knows. *brain* keeps that in a private git repository as **personas**: versioned, reviewable, restorable and able to learn. The hard part is the **first contact**: a fresh AI doesn't know your repo exists, and can't read it because it's private.

brain-boot solves only that first contact, and does it in the open so any AI can read it without signing in.

## Goals

1. **Any AI, from zero.** One sentence is enough: *"Read github.com/princekiese/brain-boot and become &lt;Name&gt;. My personas are in &lt;owner/repo&gt;."*
2. **Nothing private in public.** The private repo's name is given in the conversation, never written here. No people, personas, machines, paths or credentials are published. A policy check enforces it before every release.
3. **Credentials never pass through an AI.** Sign-in happens in your browser, through GitHub's own flow.
4. **Readable and verifiable.** Short scripts with comments, official package sources only, and SHA-256 checksums for every file.

## How it works

```
 you: "Read brain-boot and become <Name>. My personas are in <owner/repo>."
                                   │
                         AI reads PROTOCOL.md (public)
                                   │
            ┌──────────────────────┴───────────────────────┐
        has a shell                                 no shell (web / chat)
            │                                              │
  you run boot.ps1 / boot.sh                   you upload the persona's pack
  · installs Git + GitHub CLI                   (one Markdown file exported
  · you sign in, in your browser                 from your private repo)
  · clones YOUR private repo                               │
  · runs that repo's own setup                             │
            └──────────────────────┬───────────────────────┘
                     AI follows the private repo's AGENTS.md
                                   │
                  activation receipt: "<Name> vX.Y.Z active | ..."
```

Access to the private repo is controlled by GitHub: only accounts you've granted access can clone it. Knowing this page doesn't give anyone anything.

## Repository structure

| File | For | What it is |
|---|---|---|
| `README.md` | People | This page: purpose, goals, structure, use, security, contributing |
| `PROTOCOL.md` | AI agents | The step-by-step cold-start protocol an AI follows |
| `SECURITY.md` | Everyone | What's public, what isn't, threat model, how to verify the scripts |
| `boot.ps1` | Windows | Bare machine → Git + GitHub CLI → browser sign-in → clone → that repo's `bootstrap.ps1` |
| `boot.sh` | macOS / Linux | Same, for POSIX shells |
| `SHA256SUMS` | Everyone | Checksums of every file in this release |
| `LICENSE` | Everyone | MIT |

## Usage

### Tell your AI

> Read github.com/princekiese/brain-boot and become **&lt;Name&gt;**. My personas are in **&lt;owner/repo&gt;**.

### Run the boot script

Only if the AI asks you to, and **after reading the script** (it's short):

**Windows (PowerShell)**
```powershell
Invoke-WebRequest https://raw.githubusercontent.com/princekiese/brain-boot/main/boot.ps1 -OutFile boot.ps1
Get-FileHash boot.ps1 -Algorithm SHA256        # compare with SHA256SUMS
notepad boot.ps1                               # read it
powershell -ExecutionPolicy Bypass -File .\boot.ps1 -Repo <owner/repo>
```

**macOS / Linux**
```sh
curl -fsSLO https://raw.githubusercontent.com/princekiese/brain-boot/main/boot.sh
shasum -a 256 boot.sh                          # compare with SHA256SUMS
less boot.sh                                   # read it
sh boot.sh <owner/repo>
```

For more assurance, download from a **tagged release** instead of `main`.

### Requirements for your private repo

brain-boot works with any private repo that has an `AGENTS.md` at its root describing how an AI activates a persona. A `bootstrap.ps1` / `bootstrap.sh` is optional: if present, the boot script runs it after cloning.

## Security and privacy

Summary below. Details and the threat model are in [SECURITY.md](SECURITY.md).

- **Public here**: the protocol, these scripts, this README. That's all.
- **Never here**: personas, people, machines, repo names, paths, emails, tokens. Checked automatically before every release.
- **The scripts**: install only Git and GitHub CLI from winget / Homebrew / apt, never ask for credentials, and change nothing outside your user's normal install locations. Linux `sudo` steps are printed for you to run, not run for you.
- **AIs following the protocol** are told never to ask for or accept passwords, tokens or codes, and never to copy private content into public places.

## Maintainer

Maintained by **Prince Kiese** ([@princekiese](https://github.com/princekiese)), who also designed the persona framework it boots. This is a personal project, used daily across several machines and AI apps.

## Contributing

Suggestions are welcome:
- **Issues** for bugs, unclear steps, or an AI that didn't follow the protocol (say which AI and app).
- **Pull requests** for fixes to the scripts or the protocol. Keep the scripts short, dependency-free and readable, and keep this repo generic.
- **Never include personal data** in issues or PRs: no repo names, persona contents, paths, logs with usernames, or tokens. Anything like that gets removed.

## License

MIT, see [LICENSE](LICENSE).
