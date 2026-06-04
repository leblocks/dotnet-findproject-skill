#!/usr/bin/env bats

# Validates the bash usage patterns documented in ../../SKILL.md against the
# neutral dummy fixtures under ../source. Run inside the container defined by
# the sibling Dockerfile (which installs the findproject dotnet tool).

SRC="test/source"

setup() {
    if ! command -v findproject >/dev/null 2>&1; then
        skip "findproject is not on PATH"
    fi
}

# --- Quick start ---

@test "Quick start: resolves a .cs file to its owning .csproj" {
    run findproject "$SRC/src/DummyProject1/DummySource1.cs"
    [ "$status" -eq 0 ]
    [[ "$output" == *"/src/DummyProject1/DummyProject1.csproj" ]]
}

@test "Nearest project: a nested file resolves to the closest .csproj" {
    run findproject "$SRC/src/DummyProject2/SubFolder/DummySource2.cs"
    [ "$status" -eq 0 ]
    [[ "$output" == *"/src/DummyProject2/DummyProject2.csproj" ]]
}

# --- Detecting success (capture stdout, not exit code) ---

@test "Detecting success (found): prints the owning project with an Owns: prefix" {
    run bash -c 'proj=$(findproject '"$SRC"'/src/DummyProject1/DummySource1.cs); if [ -n "$proj" ]; then echo "Owns: $proj"; else echo "No project found"; fi'
    [ "$status" -eq 0 ]
    [[ "$output" == "Owns: "*"/DummyProject1.csproj" ]]
}

@test "Detecting success (not found): prints \"No project found\"" {
    run bash -c 'proj=$(findproject '"$SRC"'/src/DummyProject1/NoSuchFile.cs); if [ -n "$proj" ]; then echo "Owns: $proj"; else echo "No project found"; fi'
    [ "$status" -eq 0 ]
    [ "$output" = "No project found" ]
}

# --- Other invocation modes ---

@test "No-argument mode: finds the .csproj at or above the current directory" {
    run bash -c "cd '$SRC/src/DummyProject1' && findproject"
    [ "$status" -eq 0 ]
    [[ "$output" == *"/src/DummyProject1/DummyProject1.csproj" ]]
}

@test "Stdin mode: an absolute path is resolved to its nearest .csproj" {
    abs="$(realpath "$SRC/src/DummyProject2/SubFolder/DummySource2.cs")"
    run bash -c "echo '$abs' | findproject"
    [ "$status" -eq 0 ]
    [[ "$output" == *"/src/DummyProject2/DummyProject2.csproj" ]]
}
