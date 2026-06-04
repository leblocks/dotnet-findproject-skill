---
name: finding-owning-csproj
description: Finds the .csproj project that owns a given C# (.cs) source file using the findproject dotnet CLI tool. Use when locating, building, or testing the project that contains a specific .cs file, when resolving a file to its nearest project, or when the user mentions findproject, csproj lookup, or a file's owning project.
---

# Finding the owning .csproj for a C# file

`findproject` is a .NET global CLI tool that, given a path to a C# source file,
prints the absolute path of the nearest `.csproj` that owns it by walking **up**
the directory tree.

For the full behavior reference (every mode, edge case, and selection rule), see
[findproject.md](findproject.md).

## When to use

**You MUST use `findproject` whenever you need to resolve the `.csproj` that owns
a given C# (`.cs`) source file.** Do not guess the project, hand-craft a manual
directory walk, or grep for `.csproj` files — call `findproject` instead.

Use it whenever you need to:

- Find the project that contains a specific `.cs` file.
- Build, test, restore, or run the project that owns a file you are editing.
- Map one or more `.cs` files to their owning project(s).

If a task involves "which project does this file belong to" (explicitly or
implicitly), reach for this tool first.

## Prerequisite

The `findproject` command must be on `PATH`. If it is missing, install it:

```bash
dotnet tool install --global findproject
```

## Quick start

Pass one existing `.cs` file (relative to the current directory or absolute):

```bash
findproject src/Common/Commands.Common/PowerBICmdlet.cs
# -> .../src/Common/Commands.Common/Commands.Common.csproj
```

On Windows **cmd.exe**, the invocation is the same (backslashes also work):

```bat
findproject src\Common\Commands.Common\PowerBICmdlet.cs
```

It returns the **nearest** project, so files in nested subfolders still resolve
to their owning project.

## Detecting success (important)

The exit code is **always `0`**, even when nothing is found. Do not branch on
the exit code — capture stdout and check whether it is empty.

```bash
proj=$(findproject path/to/File.cs)
if [ -n "$proj" ]; then echo "Owns: $proj"; else echo "No project found"; fi
```

On Windows **cmd.exe** (batch file), capture the output with `for /f` and test
with `if defined`:

```bat
@echo off
set "proj="
for /f "delims=" %%i in ('findproject path\to\File.cs') do set "proj=%%i"
if not defined proj echo No project found
if defined proj echo Owns: %proj%
```

> At the interactive `cmd` prompt, use a single `%i` instead of `%%i`.
> The two separate `if` lines (instead of `if (...) else (...)`) keep the example
> robust even when the resolved path contains parentheses, e.g. `...\Foo (x86)\...`.

## Common workflow: build or test the owning project

```bash
proj=$(findproject src/Common/Common.Api/ActivityEvent/ActivityEventResponse.cs)
[ -n "$proj" ] && dotnet build "$proj"
```

On Windows **cmd.exe** (batch file):

```bat
@echo off
set "proj="
for /f "delims=" %%i in ('findproject src\Common\Common.Api\ActivityEvent\ActivityEventResponse.cs') do set "proj=%%i"
if defined proj dotnet build "%proj%"
```

## Invocation modes (summary)

- **Single file (primary):** `findproject <file.cs>` — the argument must exist
  and end in `.cs` (case-insensitive). Relative or absolute; `/` or `\`.
- **No arguments:** `findproject` — finds the `.csproj` at or above the current
  working directory.
- **Stdin:** pipe one path per line (`paths | findproject`). Stdin paths must be
  **absolute** and may be any existing file (not just `.cs`); output is
  de-duplicated and sorted. On cmd: `echo C:\full\path\File.cs| findproject`.

## Key rules to remember

- Selection walks **up** and stops at the **nearest** directory that contains
  **exactly one** `.csproj`. A directory with multiple `.csproj` is ambiguous
  and skipped (search continues upward).
- Only `.csproj` is matched — not `.vbproj` or `.fsproj`.
- No output means "not found" (bad/missing path, no project above, or ambiguity).

See [findproject.md](findproject.md) for worked examples and every edge case.

## Credits

`findproject` is authored by Kirill Osenkov ([@KirillOsenkov](https://github.com/KirillOsenkov))
as part of CodeCleanupTools.
Package: <https://www.nuget.org/packages/findproject> ·
Source: <https://github.com/KirillOsenkov/CodeCleanupTools/tree/main/FindProject>
