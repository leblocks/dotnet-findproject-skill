# Tests

Validates that the examples documented in [`../SKILL.md`](../SKILL.md) actually
work with the `findproject` tool.

## Layout

```text
test/
├── source/    # Dummy .cs / .csproj fixtures (shared by all suites)
├── windows/   # Pester tests for the Windows cmd.exe examples
└── linux/     # bats tests for the bash examples, in a minimal .NET container
```

## Fixtures (`test/source`)

A minimal project tree with neutral dummy names (empty files — only the folder
structure matters to `findproject`):

```text
src/DummyProject1/DummyProject1.csproj
src/DummyProject1/DummySource1.cs
src/DummyProject2/DummyProject2.csproj
src/DummyProject2/SubFolder/DummySource2.cs
```

`DummyProject2` keeps its source in a sub-folder so the "nearest project"
behavior can be exercised.

## Running

### Windows (Pester)

Requires [Pester](https://pester.dev) 5+ and `findproject` on `PATH`
(`dotnet tool install --global findproject`).

```powershell
Invoke-Pester -Path test/windows/cmd.Tests.ps1 -Output Detailed
```

The `windows/cmd.Tests.ps1` suite runs the cmd.exe snippets from SKILL.md
against the fixtures and asserts the documented output (quick start, nearest
project, success/no-output detection, no-argument mode, and stdin mode).

### Linux (bats, containerized)

Requires only Docker. The `linux/Dockerfile` builds a minimal `dotnet/sdk:9.0`
image, installs the `findproject` tool and `bats`, and runs the bash-example
suite. Build and run from the **repo root**:

```bash
docker build -f test/linux/Dockerfile -t findproject-skill-test .
docker run --rm findproject-skill-test
```

`linux/findproject.bats` mirrors the Windows suite using the bash examples from
SKILL.md (quick start, nearest project, success/no-output detection,
no-argument mode, and stdin mode).

