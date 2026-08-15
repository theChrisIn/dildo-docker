# dildo-docker

[![CI](https://github.com/theChrisIn/dildo-docker/actions/workflows/ci.yml/badge.svg)](https://github.com/theChrisIn/dildo-docker/actions/workflows/ci.yml)
[![Release](https://github.com/theChrisIn/dildo-docker/actions/workflows/release.yml/badge.svg)](https://github.com/theChrisIn/dildo-docker/actions/workflows/release.yml)
[![Check upstream ViperServer release](https://github.com/theChrisIn/dildo-docker/actions/workflows/upstream-check.yml/badge.svg)](https://github.com/theChrisIn/dildo-docker/actions/workflows/upstream-check.yml)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

Ready-to-use Docker container for [ViperServer](https://github.com/viperproject/viperserver), the verification server behind [go-dildo](https://github.com/theChrisIn/go-dildo). Pre-packaged with a JRE, pinned Z3 solver, and (Carbon variant) Boogie and .NET. No local toolchain configuration required.

`go-dildo` itself only ever talks to a `viper_url`; it has no Docker dependency of its own. This project is what puts something at that URL.

---

## Quickstart

```bash
docker run --rm -p 12345:12345 ghcr.io/theChrisIn/dildo-docker --port 12345
```

Point `go-dildo`'s config at `http://localhost:12345`.

---

## Selecting a Verification Backend

### 1. Silicon Backend (Default)

```bash
docker run --rm -p 12345:12345 ghcr.io/theChrisIn/dildo-docker:silicon --port 12345
```

### 2. Carbon Backend

Uses verification condition generation via Boogie and Z3.

```bash
docker run --rm -p 12345:12345 ghcr.io/theChrisIn/dildo-docker:carbon --port 12345
```

---

## Building a Specific ViperServer Version

```bash
docker build --build-arg VIPERSERVER_REF=v-2026-08-13-0738 -t dildo-docker:silicon -f Dockerfile .
```

`VIPERSERVER_REF` is a release tag from [viperproject/viperserver releases](https://github.com/viperproject/viperserver/releases). ViperServer publishes a pre-built `viperserver.jar` per release, so no build-from-source step is needed inside the image.

---

## Version Reporting

ViperServer's own HTTP API has no version or health endpoint; its version is only ever printed to console at startup. Since `go-dildo`'s version-matrix check (`Register(url)`) needs to query the running backend over HTTP, this image runs a small companion server alongside ViperServer, started by `entrypoint.sh` before ViperServer itself:

```bash
curl http://localhost:9191/dildo/version
# {"image_version":"1.2.0","viperserver_ref":"v-2026-08-13-0738"}
```

`image_version` is this image's own SemVer tag, baked in at build time via `IMAGE_VERSION`. `viperserver_ref` is the exact upstream ViperServer release it wraps.

---

## Repository Layout

```
Dockerfile           Silicon backend image
Dockerfile.carbon     Carbon backend image (adds .NET + Boogie)
entrypoint.sh          Dispatches CLI args, launches the version shim before ViperServer
shim/                  Standalone Go module for the version-reporting companion server,
                        multi-stage-built into both images as a static binary
```

`shim/` is the one piece of Go source in an otherwise Docker-only repository. It exists solely because ViperServer has no version endpoint of its own; nothing else here depends on Go.

---

## Staying Current With Upstream

Three workflows chained by trigger, each doing one thing:

1. **`upstream-check.yml`** runs weekly (and on manual dispatch): checks the latest `viperproject/viperserver` release, builds and tests this image against it if it's newer than what's pinned, and if that passes, commits the bumped `VIPERSERVER_REF` directly to `main`.
2. **`bump.yml`** picks up that commit the same as any other change and creates a new version tag.
3. **`release.yml`** triggers on that tag, builds both backends, tests them again, and publishes to `ghcr.io/theChrisIn/dildo-docker`: `latest` / `silicon` / `v<version>` for Silicon, `carbon` / `carbon-v<version>` for Carbon.

Publishing is tied to the tag, not to `upstream-check.yml` directly, so any version bump gets published, not just upstream-triggered ones.

---

## Development

* `make build`: Build local Silicon container image.
* `make build-carbon`: Build local Carbon container image.
* `make test`: Run the Silicon container's `--help` output as a smoke test.
* `make lint`: Run pre-commit checks (hadolint, shellcheck, commit format).
* `make cz-commit`: Commit using Conventional Commits.
* `make cz-bump`: Bump version and update CHANGELOG.md.

---

## License

Apache License 2.0. ViperServer, Z3, Boogie, and underlying tools retain their original open-source licenses.
