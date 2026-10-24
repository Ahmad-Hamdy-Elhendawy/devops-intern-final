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

## Task 4 — CI Pipeline

The GitHub Actions workflow (`.github/workflows/ci.yml`) automates linting, building, testing, and publishing the Docker image.

The workflow runs on pushes to `main` and `feature/project-structure`, and on pull requests targeting `main`.

#### 1. Lint

- **ShellCheck** checks shell scripts in `scripts/`.
- **Hadolint** checks `app/Dockerfile`.

#### 2. Build

- Builds the Docker image from `app/`.
- Passes the Git commit SHA through the `BUILD_SHA` build argument.
- Saves the image as `image.tar`.
- Uploads the image as a GitHub Actions artifact with a one-day retention period.

#### 3. Test

- Downloads and loads the image built by the previous job.
- Tags the image locally as `nginx-assessment:test`.
- Starts the container and maps host port `8080` to container port `8080`.
- Retries the root endpoint health check up to 20 times, with a two-second delay between attempts.
- Checks the `/healthz` endpoint separately.
- Removes the test container even if a preceding test step fails.

Both health checks use `scripts/healthcheck.sh`, executed through Bash. The script expects HTTP `200` and returns a non-zero exit code if the request fails or returns an unexpected status.

#### 4. Publish

The publish job runs only on pushes to `main`, after the lint, build, and test jobs succeed.

- Downloads and loads the same image artifact used by the test job.
- Converts the GitHub repository path to lowercase to comply with Docker registry naming requirements.
- Authenticates to GitHub Container Registry (GHCR) using the automatically provided `GITHUB_TOKEN`.
- Tags and pushes the image using both the commit SHA and `latest`.

#### Image Reuse

The Docker image is built once and transferred between jobs using a workflow artifact. The test and publish jobs load that artifact rather than rebuilding the image, ensuring that the published image is the same image that passed testing.

#### Published Image

Images are published to GHCR using these tags:

```text
ghcr.io/<owner>/<repository>:<commit-sha>
ghcr.io/<owner>/<repository>:latest
```

The repository path is converted to lowercase before tagging and pushing.

Publishing requires the workflow's `packages: write` permission and appropriate GHCR package access. The `GITHUB_TOKEN` is supplied by GitHub Actions and does not need to be hard-coded into the repository.
