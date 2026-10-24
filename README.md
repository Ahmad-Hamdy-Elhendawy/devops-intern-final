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

The GitHub Actions workflow runs on pushes and pull requests targeting main.

1. Lint

ShellCheck analyzes shell scripts in scripts/.

Hadolint checks app/Dockerfile.

2. Build

Builds the Docker image.

Passes the Git commit SHA as a build argument.

Saves the image as a TAR archive.

Uploads the archive as a workflow artifact.

3. Test

Downloads and loads the image built by the previous job.

Starts the container and maps port 8080.

Retries the application health check until the service responds or the timeout is reached.

Verifies the /healthz endpoint.

Removes the test container, including when the job fails.

4. Publish

Publishing runs only after the lint, build, and test jobs succeed, and only for pushes to main.

Authenticates to GHCR using the automatically provided GITHUB_TOKEN.

Tags the existing image with the commit SHA and latest.

Pushes both tags to the registry.

Image reuse: The Docker image is built once and transferred between jobs using a workflow artifact. The test and publish jobs reuse that same image rather than rebuilding it, ensuring the published image is the one that was tested.

Container Registry

After a successful push to main, the image is published to:

ghcr.io/<owner>/<repository>:<commit-sha>
ghcr.io/<owner>/<repository>:latest

Replace <owner> and <repository> with the GitHub account or organization and repository name.

The repository's GitHub Actions permissions and GHCR package access must allow the workflow to publish packages.

Verification

The pipeline succeeds when:

Shell scripts and the Dockerfile pass linting.

The Docker image builds successfully.

The application responds with HTTP 200.

The /healthz endpoint passes its health check.

On pushes to main, the image is successfully published to GHCR.

Security

The workflow uses read-only repository permissions by default.

Package write permission is granted only to the publishing job.

Authentication uses GitHub's automatically generated token instead of a hard-coded credential.