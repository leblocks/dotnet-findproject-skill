# finding-owning-csproj — Agent Skill

An [Agent Skill](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)
that teaches an agent to resolve a C# source file (`.cs`) to the `.csproj`
project that owns it, using the [`findproject`](https://www.nuget.org/packages/findproject)
.NET CLI tool.

## What it does

Given a path to a `.cs` file, `findproject` walks **up** the directory tree and
prints the absolute path of the nearest owning `.csproj`. This skill packages
the tool's usage, invocation modes, and gotchas so an agent can reliably locate,
build, or test the project that contains a given file.

## Skill contents

```text
finding-owning-csproj/
├── SKILL.md        # Entry point: metadata + concise instructions (loaded when triggered)
├── findproject.md  # Full behavior reference (loaded as needed)
└── README.md       # This file (human-facing overview)
```

- **[SKILL.md](SKILL.md)** — the skill itself. Its YAML frontmatter (`name`,
  `description`) is what the agent uses to discover and trigger the skill; the
  body gives quick-start usage and the most important rules.
- **[findproject.md](findproject.md)** — the comprehensive reference: every
  invocation mode, selection rule, and edge case, with worked examples verified
  against the [`powerbi-powershell`](https://github.com/microsoft/powerbi-powershell)
  repository and the tool's source.

## Prerequisite

The `findproject` command must be installed and on `PATH`:

```bash
dotnet tool install --global findproject
```

## Quick example

```bash
findproject src/Common/Commands.Common/PowerBICmdlet.cs
# -> .../src/Common/Commands.Common/Commands.Common.csproj
```

> **Tip:** `findproject` always exits with code `0`. Detect success by checking
> whether it produced output, not by the exit code.

## Installing the skill

Place this folder where your agent loads skills from. For example, with the
Claude Skills directory layout, copy the folder so that `SKILL.md` sits at the
skill root:

```text
<skills-dir>/finding-owning-csproj/SKILL.md
```

The agent reads the `description` in `SKILL.md` to decide when to activate the
skill, then loads `findproject.md` only when fuller detail is required.

## Credits

The `findproject` tool is authored and maintained by **Kirill Osenkov**
([@KirillOsenkov](https://github.com/KirillOsenkov)) as part of
**CodeCleanupTools**. All credit for the tool belongs to the author.

- **NuGet package:** <https://www.nuget.org/packages/findproject>
- **Source code:** <https://github.com/KirillOsenkov/CodeCleanupTools/tree/main/FindProject>
