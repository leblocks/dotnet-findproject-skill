# Minimal container with the .NET SDK so the `findproject` global tool can be
# installed, plus bats to run the test suite. Build from the repo root:
#   docker build -f test/linux/Dockerfile -t findproject-skill-test .
#   docker run --rm findproject-skill-test
FROM mcr.microsoft.com/dotnet/sdk:9.0

RUN apt-get update \
    && apt-get install -y --no-install-recommends bats dos2unix \
    && rm -rf /var/lib/apt/lists/*

# Install the findproject dotnet tool and put it on PATH.
ENV PATH="${PATH}:/root/.dotnet/tools"
RUN dotnet tool install --global findproject

WORKDIR /app
COPY test/source test/source
COPY test/linux/findproject.bats test/linux/findproject.bats

RUN dos2unix test/linux/findproject.bats

ENTRYPOINT ["bats", "test/linux/findproject.bats"]
