#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

# Pester tests validating the Windows cmd.exe usage patterns documented in
# ../../SKILL.md. Each test runs the cmd snippet exactly as a user would (via a
# temporary .cmd batch file, or a direct `cmd /c` invocation) against the neutral
# dummy fixtures under ../source, and asserts the documented behavior.

BeforeAll {
    $script:SourceDir = (Resolve-Path (Join-Path $PSScriptRoot '..\source')).Path

    if (-not (Get-Command findproject -ErrorAction SilentlyContinue)) {
        throw "findproject is not on PATH. Install it: dotnet tool install --global findproject"
    }

    # Runs a cmd batch snippet from within the fixtures directory and returns
    # trimmed stdout. Mirrors how the SKILL.md batch-file examples are used.
    # The script is written with Windows (CRLF) line endings because cmd.exe
    # mishandles LF-only batch files (notably `for` / `if (...)` blocks).
    function Invoke-CmdBatch {
        param([string]$Script)
        $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("fp_" + [guid]::NewGuid().ToString('N') + ".cmd")
        Set-Content -Path $tmp -Value ($Script -split "`r?`n") -Encoding Ascii
        try {
            (& cmd.exe /c "cd /d `"$script:SourceDir`" && `"$tmp`"" 2>&1 | Out-String).Trim()
        }
        finally {
            Remove-Item $tmp -ErrorAction SilentlyContinue
        }
    }
}

Describe 'SKILL.md cmd.exe examples' {

    It 'Quick start: resolves a .cs file to its owning .csproj' {
        $out = & cmd.exe /c "cd /d `"$SourceDir`" && findproject src\DummyProject1\DummySource1.cs"
        $out.Trim() | Should -BeLike '*\src\DummyProject1\DummyProject1.csproj'
    }

    It 'Nearest project: a nested file resolves to the closest .csproj' {
        $out = & cmd.exe /c "cd /d `"$SourceDir`" && findproject src\DummyProject2\SubFolder\DummySource2.cs"
        $out.Trim() | Should -BeLike '*\src\DummyProject2\DummyProject2.csproj'
    }

    It 'Detecting success (found): prints the owning project with an "Owns:" prefix' {
        $batch = @'
@echo off
set "proj="
for /f "delims=" %%i in ('findproject src\DummyProject1\DummySource1.cs') do set "proj=%%i"
if not defined proj echo No project found
if defined proj echo Owns: %proj%
'@
        $out = Invoke-CmdBatch $batch
        $out | Should -BeLike 'Owns: *\DummyProject1.csproj'
    }

    It 'Detecting success (not found): prints "No project found"' {
        $batch = @'
@echo off
set "proj="
for /f "delims=" %%i in ('findproject src\DummyProject1\NoSuchFile.cs') do set "proj=%%i"
if not defined proj echo No project found
if defined proj echo Owns: %proj%
'@
        $out = Invoke-CmdBatch $batch
        $out | Should -Be 'No project found'
    }

    It 'No-argument mode: finds the .csproj at or above the current directory' {
        $out = & cmd.exe /c "cd /d `"$SourceDir\src\DummyProject1`" && findproject"
        $out.Trim() | Should -BeLike '*\src\DummyProject1\DummyProject1.csproj'
    }

    It 'Stdin mode: an absolute path is resolved to its nearest .csproj' {
        $abs = (Resolve-Path (Join-Path $SourceDir 'src\DummyProject2\SubFolder\DummySource2.cs')).Path
        $out = & cmd.exe /c "echo $abs| findproject"
        $out.Trim() | Should -BeLike '*\src\DummyProject2\DummyProject2.csproj'
    }
}
