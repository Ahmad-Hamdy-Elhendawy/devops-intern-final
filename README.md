DevOps intern final assemsnet



## Task 2 — Linux Scripting

The repository includes two executable Bash scripts.

- `scripts/sysinfo.sh` reports the current user, effective UID, hostname, kernel release, ISO-8601 date, disk usage, memory usage, and Docker daemon status.
- `scripts/healthcheck.sh` checks a target URL for HTTP 200. Its default URL is `http://localhost:8080`.

### Validation

Run ShellCheck:

```bash
shellcheck scripts/sysinfo.sh scripts/healthcheck.sh
```

Run the system information report:

```bash
./scripts/sysinfo.sh
```

Check the application:

```bash
./scripts/healthcheck.sh
./scripts/healthcheck.sh http://localhost:8080/healthz
```

Both scripts are tracked as executable files in Git. Sample output should be recorded from the actual environment used for validation.


## Task 3 — Containerisation

A static HTML application served by NGINX on port `8080`. The container uses a pinned base-image tag, runs as a non-root user, injects a build identifier, and provides a `/healthz` endpoint.

### Build and run

From the repository root:

```bash
docker build --build-arg BUILD_SHA=local-test -t devops-intern-final:local ./app
docker run -d --name devops-test -p 8080:8080 devops-intern-final:local
```

The image built successfully and the container started.

### Verification

```bash
curl -i http://localhost:8080/healthz
```

**Observed:** HTTP `200`, body `healthy`.

```bash
docker inspect --format='{{.State.Health.Status}}' devops-test
```

**Observed:** `healthy`.

The home page loaded successfully, the build identifier was replaced with `local-test`, and the container ran as a non-root user.

### Image size

```bash
docker image inspect --format='{{.Size}}' devops-intern-final:local
docker image ls devops-intern-final:local
```

**Observed results:**
- Image metadata size: `20,979,993` bytes.
- `docker image ls` displayed disk usage of `73.7MB`.

The image-size requirement of under 60 MB still needs verification against the assessment's expected measurement.

### Status

- [x] Image builds and runs.
- [x] Application and health endpoint verified.
- [x] Build identifier injected.
- [x] Non-root runtime verified.
- [ ] Resolve the image-size requirement.

