# `findproject` — Find the owning `.csproj` for a C# file

`findproject` is a .NET global tool that, given a path to a C# source file
(`.cs`), prints the absolute path of the **`.csproj`** project that owns it. It
does this by walking **up** the directory tree from the file and returning the
nearest project file.

This document describes the tool's behavior as observed by exercising it against
the [`powerbi-powershell`](https://github.com/microsoft/powerbi-powershell)
repository, cross-checked against the tool's source.

> This is the full reference for the **finding-owning-csproj** skill. For the
> concise entry point, see [SKILL.md](../SKILL.md).

## Contents

- [Install](#install)
- [Synopsis](#synopsis)
- [Basic usage](#basic-usage)
- [How it resolves the project (nearest-ancestor walk-up)](#how-it-resolves-the-project-nearest-ancestor-walk-up)
- [Selection rules and edge cases](#selection-rules-and-edge-cases)
- [Other invocation modes](#other-invocation-modes) (no-argument mode, stdin mode)
- [Behavior summary](#behavior-summary)
- [Practical tips](#practical-tips)
- [Source & credits](#source--credits)

> **Credits.** `findproject` is created by **Kirill Osenkov**
> ([@KirillOsenkov](https://github.com/KirillOsenkov)) as part of his
> **CodeCleanupTools** project. All credit for the tool goes to the author.
>
> - **NuGet package:** <https://www.nuget.org/packages/findproject>
> - **Source code:** <https://github.com/KirillOsenkov/CodeCleanupTools/tree/main/FindProject>

---

## Install

It is distributed as a .NET global tool on NuGet
([`findproject`](https://www.nuget.org/packages/findproject)):

```powershell
dotnet tool install --global findproject
```

The package targets `net9.0` and has no dependencies.

---

## Installation / location

The tool is installed as a .NET global tool and is available on `PATH`:

```
C:\Users\<you>\.dotnet\tools\findproject.exe
```

Metadata reported by the executable:

| Property         | Value                                              |
| ---------------- | -------------------------------------------------- |
| File             | `FindProject.dll` (wrapped by `findproject.exe`)   |
| File description | `FindProject`                                      |
| Product          | `FindProject`                                      |
| File version     | `1.0.0.0`                                           |
| Product version  | `1.0.0+06d3206a1dd1182f82ec5ae21acb8424561c3fe6`   |

Verify it is resolvable:

```powershell
Get-Command findproject
```

---

## Synopsis

```
findproject <path-to-cs-file>    # single-file mode
findproject                      # no-argument mode (uses current directory)
<paths> | findproject            # stdin mode (one absolute path per line)
```

The primary, **single-file** mode:

- Takes **exactly one** argument: the path to an existing `.cs` file.
- The path may be **relative** (resolved against the current working directory)
  or **absolute**.
- Both **back-slashes** (`\`) and **forward-slashes** (`/`) are accepted.
- On success, prints the **absolute path** of the owning `.csproj` to standard
  output, followed by a newline.
- On any failure (file not found, wrong extension, no project found, etc.) it
  prints **nothing**.
- The **exit code is always `0`**, regardless of whether a project was found.
  (Do not rely on the exit code to detect success — check whether output was
  produced instead.)

Two additional modes are described under
[Other invocation modes](#other-invocation-modes).

---

## Basic usage

Run from the repository root (`C:\Users\sagurevich\repos\powerbi-powershell`):

```powershell
findproject "src\Common\Commands.Common\PowerBICmdlet.cs"
```

Output:

```
C:\Users\sagurevich\repos\powerbi-powershell\src\Common\Commands.Common\Commands.Common.csproj
```

An absolute input path produces the same result:

```powershell
findproject "C:\Users\sagurevich\repos\powerbi-powershell\src\Common\Commands.Common\PowerBICmdlet.cs"
# -> ...\src\Common\Commands.Common\Commands.Common.csproj
```

Forward slashes work too:

```powershell
findproject "src/Common/Common.Api/ActivityEvent/ActivityEventResponse.cs"
# -> ...\src\Common\Common.Api\Common.Api.csproj
```

---

## How it resolves the project (nearest-ancestor walk-up)

Starting from the directory that contains the input `.cs` file, `findproject`
searches each directory level moving **upward** toward the filesystem root and
returns the **nearest** `.csproj`.

### Example: file in a nested subfolder

A source file nested several folders below its project still resolves to that
project:

```powershell
findproject "src\Common\Common.Abstractions\Interfaces\IAccessToken.cs"
# -> ...\src\Common\Common.Abstractions\Common.Abstractions.csproj
```

```powershell
findproject "src\Modules\Profile\Commands.Profile\Errors\PowerBIErrorRecord.cs"
# -> ...\src\Modules\Profile\Commands.Profile\Commands.Profile.csproj
```

Even generated files deep under `obj\` resolve to the owning project:

```powershell
findproject "src\Common\Commands.Common\obj\Debug\netstandard2.0\.NETStandard,Version=v2.0.AssemblyAttributes.cs"
# -> ...\src\Common\Commands.Common\Commands.Common.csproj
```

### "Nearest" means closest ancestor wins

When two projects exist along the path, the **closest** one (deepest in the
tree) is selected. For example, given:

```
src\Common\Common.Api\Common.Api.csproj          (far ancestor)
src\Common\Common.Api\Sub\Inner.csproj           (near ancestor)
src\Common\Common.Api\Sub\Deeper\Deep.cs         (the input file)
```

```powershell
findproject "src\Common\Common.Api\Sub\Deeper\Deep.cs"
# -> ...\src\Common\Common.Api\Sub\Inner.csproj   (the nearer project)
```

---

## Selection rules and edge cases

The following behaviors were confirmed empirically.

### The single-file argument must be an existing `.cs` file

In the single-argument form, the input must be an existing `.cs` file (this
extension check applies **only** to the argument form — see
[stdin mode](#stdin-mode-one-path-per-line) for the extension-agnostic path):

| Input                                                | Output    |
| ---------------------------------------------------- | --------- |
| Existing `.cs` file                                  | project   |
| Existing `.CS` file (uppercase extension)            | project   |
| Non-existent `.cs` path (e.g. `src\does\not.cs`)     | *nothing* |
| Existing non-`.cs` file (e.g. `README.md`, `.txt`)   | *nothing* |
| Existing file with **no** extension                  | *nothing* |
| A directory path                                     | *nothing* |

So the file must (a) **exist** and (b) have a **`.cs`** extension
(case-insensitive). Anything else produces no output.

### A directory level is only used if it contains exactly one `.csproj`

If a directory along the walk-up path contains **more than one** `.csproj`, that
level is treated as ambiguous and **skipped**; the search continues upward.

```
_fp_test\B\One.csproj
_fp_test\B\Two.csproj
_fp_test\B\f.cs
```

```powershell
findproject "_fp_test\B\f.cs"
# -> nothing (two projects in the same folder, no other ancestor project)
```

But if a single-project ancestor exists higher up, it is returned instead:

```
src\Common\Common.Api\Common.Api.csproj          (single project)
src\Common\Common.Api\Multi\AlphaProj.csproj     (ambiguous level...)
src\Common\Common.Api\Multi\BravoProj.csproj
src\Common\Common.Api\Multi\Thing.cs             (the input file)
```

```powershell
findproject "src\Common\Common.Api\Multi\Thing.cs"
# -> ...\src\Common\Common.Api\Common.Api.csproj   (skips ambiguous Multi level)
```

### Only `.csproj` is matched

Other project file types are **not** recognized — only C# projects:

| Project file in folder | Result    |
| ---------------------- | --------- |
| `*.csproj`             | matched   |
| `*.vbproj`             | *nothing* |
| `*.fsproj`             | *nothing* |

### No project anywhere up the tree

If no `.csproj` is found between the file and the filesystem root, nothing is
printed:

```powershell
findproject "LICENSE"     # root-level file, not a .cs -> nothing anyway
```

### Only one positional argument is honored

The tool only processes the single-file argument form when **exactly one**
argument is supplied. Passing multiple file paths as arguments produces **no
output**:

```powershell
findproject "a.cs" "b.cs"
# -> nothing
```

To resolve several files at once, use **stdin mode** (below) instead.

---

## Other invocation modes

In addition to the single-file argument form, `findproject` supports two more
modes.

### No-argument mode (use the current directory)

Run with **no arguments** and `findproject` searches for a `*.csproj` starting
at the **current working directory** and walking upward. This is handy for
discovering the project that owns the folder you are standing in:

```powershell
cd src\Common\Commands.Common
findproject
# -> ...\src\Common\Commands.Common\Commands.Common.csproj
```

If there is no `.csproj` at or above the current directory, nothing is printed.

### Stdin mode (one path per line)

When input is **redirected/piped**, `findproject` reads file paths from standard
input — **one per line**, stopping at the first blank line or end of input — and
prints the nearest project for each. Notes:

- Paths read from stdin **must be absolute (rooted)**. Unlike the single-file
  argument form, stdin paths are **not** normalized to full paths, and the
  upward search bails out on a non-rooted directory — so relative paths yield
  nothing.
- Stdin paths are **extension-agnostic**: any existing file works, not just
  `.cs`. (The `.cs` requirement applies only to the single-argument form.)
- Output is **de-duplicated** (case-insensitive) and **sorted ascending**, so
  multiple files that share a project collapse to a single line.

```powershell
# single absolute path
(Resolve-Path "src\Common\Common.Api\ActivityEvent\ActivityEventResponse.cs").Path | findproject
# -> ...\src\Common\Common.Api\Common.Api.csproj

# multiple files -> distinct, sorted projects
@(
  (Resolve-Path "src\Common\Common.Api\ActivityEvent\ActivityEventResponse.cs").Path,
  (Resolve-Path "src\Common\Commands.Common\PowerBICmdlet.cs").Path
) | findproject
# -> ...\src\Common\Commands.Common\Commands.Common.csproj
#    ...\src\Common\Common.Api\Common.Api.csproj
```

```powershell
# relative stdin path -> nothing (must be absolute)
"src\Common\Common.Api\ActivityEvent\ActivityEventResponse.cs" | findproject
# -> nothing
```

### No help/usage text

`findproject`, `findproject -h`, `findproject --help`, and `findproject help`
all exit `0` and print nothing. There is no built-in usage banner.

---

## Behavior summary

| Aspect              | Behavior                                                                 |
| ------------------- | ------------------------------------------------------------------------ |
| Arguments           | `0` or `1`; `1` = path to a `.cs` file, `0` = use current directory       |
| Path forms          | Relative (to CWD) or absolute; `\` or `/` separators                     |
| Input requirement   | Argument form: file must **exist** and have a **`.cs`** extension         |
| Search direction    | Walks **up** from the file's directory toward the root                   |
| Match               | **Nearest** directory containing exactly **one** `.csproj`               |
| Ambiguous level     | Directory with >1 `.csproj` is skipped; search continues upward          |
| Project types       | `.csproj` only (not `.vbproj` / `.fsproj`)                               |
| Output              | Absolute path(s) of project(s) on stdout, de-duped and sorted, or nothing |
| Exit code           | Always `0` (even when nothing is found)                                   |
| No-argument mode    | Finds `*.csproj` at/above the current working directory                  |
| stdin mode          | Reads **absolute** paths (one per line, until blank line); extension-agnostic |
| Help text           | None                                                                     |

---

## Practical tips

- **Detect success by output, not exit code.** Because the exit code is always
  `0`, capture stdout and check whether it is empty:

  ```powershell
  $proj = findproject "src\Common\Commands.Common\PowerBICmdlet.cs"
  if ($proj) { "Owning project: $proj" } else { "No project found" }
  ```

- **Use it to build/test the project that owns a file** you are editing:

  ```powershell
  $proj = findproject "src\Common\Common.Api\ActivityEvent\ActivityEventResponse.cs"
  dotnet build $proj
  ```

- **Relative paths resolve against the current directory**, so run it from a
  stable location (e.g. the repo root) or pass absolute paths in scripts.

---

## Source & credits

`findproject` is authored and maintained by **Kirill Osenkov**
([@KirillOsenkov](https://github.com/KirillOsenkov)) as part of the
**CodeCleanupTools** repository. Full credit for the tool belongs to the author.

- **NuGet package:** <https://www.nuget.org/packages/findproject>
- **Source code:** <https://github.com/KirillOsenkov/CodeCleanupTools/tree/main/FindProject>

