# DevOps Intern Final Assessment

[![CI](https://github.com/Ahmad-Hamdy-Elhendawy/devops-intern-final/actions/workflows/ci.yaml/badge.svg?branch=main)](https://github.com/Ahmad-Hamdy-Elhendawy/devops-intern-final/actions/workflows/ci.yaml)

**Developer:** Ahmed El Hendawy

**Assessment date:** 2026-10-24

This repository contains the implementation for the DevOps intern final
assessment. It includes Linux utility scripts, a containerised NGINX
application, a GitHub Actions pipeline, a Nomad job, and local logging and
metrics stacks.

## Repository layout

```text
.
├── .github/workflows/ci.yaml       # GitHub Actions pipeline
├── app/                            # NGINX image and static application
├── docs/screenshots/               # Monitoring evidence
├── metrics/                        # Prometheus and Grafana metrics stack
├── monitoring/                     # Loki, Promtail, and Grafana log stack
├── nomad/                          # Nomad deployment job
└── scripts/                        # Bash utilities
```

## Prerequisites

- Docker 29.4.3 and Docker Compose v5.1.3 were installed in the verification
  environment.
- Bash and `curl`
- ShellCheck and Hadolint for local linting (versions were not available in
  the verification environment)
- Nomad and Consul for the deployment task (versions were not available in
  the verification environment)

Commands below are intended to be run from the repository root.

## Architecture

```text
Source + feature branch
        |
        v
GitHub Actions: lint -> build -> test -> publish
        |
        v
GHCR image (:commit-sha, :latest)
        |
        v
Nomad + Docker driver + Consul health check
        |
        +--> NGINX access logs -> Promtail -> Loki -> Grafana
        |
        +--> /stub_status -> Prometheus exporter -> Prometheus -> Grafana
```

The CI build produces one image artifact. The test and publish jobs reuse that
artifact, so the image published to GHCR is the image that passed the
health-check test.

## Quick Start

The following commands clone the repository, build the application, start it,
and verify both the home page and health endpoint:

```bash
git clone https://github.com/Ahmad-Hamdy-Elhendawy/devops-intern-final.git
cd devops-intern-final
docker build --build-arg BUILD_SHA=local-test -t devops-intern-final:local ./app
docker run -d --name devops-test -p 8080:8080 devops-intern-final:local
curl -i http://localhost:8080/
curl -i http://localhost:8080/healthz
docker inspect --format='{{.State.Health.Status}}' devops-test
docker rm -f devops-test
```

The expected health response is HTTP 200 with the body `healthy`, and the
container health status is `healthy`.

## Task 1 — Source control

The public repository is
[`Ahmad-Hamdy-Elhendawy/devops-intern-final`](https://github.com/Ahmad-Hamdy-Elhendawy/devops-intern-final).
The repository uses incremental conventional-style commits such as `feat:`,
`fix:`, `docs:`, and `ci:`. IDE metadata and secrets are excluded by
[`.gitignore`](.gitignore).

Review the local history, branches, and release tags with:

```bash
git log --oneline --decorate --graph --all
git branch --all
git tag --list
```

The intended delivery workflow is to develop on `feature/*`, open and
self-review a pull request, merge to `main`, and tag the final state. The
repository has a `feature/project-structure` remote branch, and the final
state is tagged
[`v1.0.0`](https://github.com/Ahmad-Hamdy-Elhendawy/devops-intern-final/releases/tag/v1.0.0):

```bash
git switch -c feature/<description>
git add .
git commit -m "feat: <description>"
git push -u origin feature/<description>
# Open and review the pull request on GitHub, then merge it to main.
git switch main
git pull --ff-only
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

The inspected history confirms incremental commits with `feat`, `fix`, and
`docs` prefixes. Pull request
[#5](https://github.com/Ahmad-Hamdy-Elhendawy/devops-intern-final/pull/5)
was merged from `feature/project-structure` into `main`.

## Task 2 — Linux scripting

The repository includes two executable Bash scripts:

- `scripts/sysinfo.sh` reports the current user, effective UID, hostname,
  kernel release, ISO-8601 date, disk usage, memory usage, and Docker daemon
  status. It uses `free` when available and falls back to `/proc/meminfo`.
- `scripts/healthcheck.sh [URL]` checks that a URL returns HTTP 200. Its
  default URL is `http://localhost:8080`. It applies five-second connection
  and ten-second total request timeouts.

Run ShellCheck and the scripts:

```bash
shellcheck scripts/sysinfo.sh scripts/healthcheck.sh
./scripts/sysinfo.sh
./scripts/healthcheck.sh
./scripts/healthcheck.sh http://localhost:8080/healthz
```

Expected ShellCheck result: the command exits with status 0 and prints no
diagnostics.

The exact system-information values are host-dependent. Capture the output
from the environment used for submission:

```bash
./scripts/sysinfo.sh > docs/sysinfo-output.txt
```

Do not commit host-sensitive output unless it is required as assessment
evidence.

`sysinfo.sh` exits non-zero when Docker is not installed or the daemon is not
accessible. `healthcheck.sh` exits non-zero when `curl` is unavailable, the
target cannot be reached, or the response status is not 200.

## Task 3 — Containerisation

The application is a static HTML page served by NGINX on port `8080`.

The image in [`app/Dockerfile`](app/Dockerfile):

- uses the pinned `nginx:1.27-alpine` base image;
- accepts `BUILD_SHA` and stores it in the OCI revision label and the page;
- runs NGINX as the non-root `appuser`;
- configures writable temporary and PID paths under `/tmp`;
- defines a Docker health check for `/healthz`; and
- exposes `/stub_status` for the metrics exporter.

Build and run the image:

```bash
docker build \
  --build-arg BUILD_SHA=local-test \
  -t devops-intern-final:local \
  ./app

docker run -d \
  --name devops-test \
  -p 8080:8080 \
  devops-intern-final:local
```

Verify the application, health check, build identifier, and runtime user:

```bash
curl -i http://localhost:8080/
curl -i http://localhost:8080/healthz
docker inspect --format='{{.State.Health.Status}}' devops-test
docker inspect --format='{{.Config.User}}' devops-test
docker image inspect --format='{{index .Config.Labels "org.opencontainers.image.revision"}}' \
  devops-intern-final:local
```

The health endpoint returns HTTP 200 with `healthy`. The image-size
requirement should be evaluated using the measurement specified by the
assessment:

```bash
docker image inspect --format='{{.Size}}' devops-intern-final:local
docker image ls devops-intern-final:local
```

Observed validation from the assessment environment:

- `/healthz` returned HTTP 200 with body `healthy`.
- Docker reported the container health status as `healthy`.
- The image metadata size was `20,979,993` bytes.
- `docker image ls` displayed `73.7MB`; this uses a different display
  measurement from the metadata size and should be compared with the
  assessor's stated definition of “under 60 MB”.

Clean up the local container when finished:

```bash
docker rm -f devops-test
```

## Task 4 — CI pipeline

The workflow in [`.github/workflows/ci.yaml`](.github/workflows/ci.yaml) runs
on pushes to `main` and on pull requests
targeting `main`.

### Lint

- ShellCheck analyzes the scripts in `scripts/`.
- Hadolint analyzes `app/Dockerfile`.
- The workflow uses `actions/checkout@v4`,
  `ludeeus/action-shellcheck@2.0.0`, and
  `hadolint/hadolint-action@v3.1.0`.

### Build

The build job creates an image tagged with the commit SHA, passes
`GITHUB_SHA` as `BUILD_SHA`, saves the image as `image.tar`, and uploads it as
the `nginx-image` artifact with one-day retention.

### Test

The test job downloads and loads the artifact, tags it as
`nginx-assessment:test`, starts it on host port `8080`, and retries the
application health check for up to 20 attempts with a two-second delay. It
then checks `/healthz` and removes the test container with an `always()` cleanup
step.

### Publish

Publishing runs only after lint, build, and test succeed, and only for pushes
to `main`. It:

1. loads the image built by the build job;
2. creates a lowercase GHCR image name from `github.repository`;
3. tags the same image with both `GITHUB_SHA` and `latest`;
4. authenticates with the automatically provided `GITHUB_TOKEN`; and
5. pushes both tags to:

```text
ghcr.io/<owner>/<repository>:<commit-sha>
ghcr.io/<owner>/<repository>:latest
```

The publish job requests `packages: write`; no registry credential is
hard-coded in the repository.

The workflow grants `contents: read` by default and adds only `packages: write`
to the publish job. The build artifact is retained for one day and is loaded
by both the test and publish jobs, so the published image is not rebuilt.

The badge at the top of this document links to the `main` workflow status.
Workflow run
[#24](https://github.com/Ahmad-Hamdy-Elhendawy/devops-intern-final/actions/runs/40254845307)
completed successfully on `main`; its lint, build, test, and publish jobs all
passed. The publish job pushed both the commit-SHA and `latest` tags to GHCR.
For a local equivalent, run the same checks used by CI:

```bash
shellcheck scripts/sysinfo.sh scripts/healthcheck.sh
hadolint app/Dockerfile
```

## Task 5 — Nomad deployment

[`nomad/nginx-app.nomad.hcl`](nomad/nginx-app.nomad.hcl) defines a one-instance
Nomad service job named `nginx-app`:

- Docker driver and GHCR image
  `ghcr.io/ahmad-hamdy-elhendawy/devops-intern-final:${var.image_tag}`;
- default image tag
  `33c0c9592779f5475fd047cb65d7972f761ab136`;
- 100 MHz CPU and 64 MB memory;
- dynamically assigned host port mapped to container port `8080`;
- Consul service registration named `nginx-app`;
- HTTP health check for `/healthz` every 10 seconds with a two-second timeout;
- one-at-a-time updates, a ten-second minimum healthy period, a two-minute
  healthy deadline, and automatic rollback; and
- bounded restart and rescheduling policies.

Validate and plan the job:

```bash
nomad job validate nomad/nginx-app.nomad.hcl
nomad job plan \
  -var="image_tag=33c0c9592779f5475fd047cb65d7972f761ab136" \
  nomad/nginx-app.nomad.hcl
```

Run and inspect it:

```bash
nomad job run \
  -var="image_tag=33c0c9592779f5475fd047cb65d7972f761ab136" \
  nomad/nginx-app.nomad.hcl
nomad job status nginx-app
nomad job allocs nginx-app
```

Use the dynamically assigned host port shown by Nomad to verify the service:

```bash
curl -i http://127.0.0.1:<allocated-port>/healthz
```

Previously recorded deployment verification reported one running and healthy
allocation:

```text
Status                  = running
Latest Deployment Status = successful
Desired  Placed  Healthy  Unhealthy
1        1       1        0
```

## Task 6 — Log aggregation with Loki

The [`monitoring/`](monitoring/) Compose stack contains:

- Loki 3.5.0 for log storage and queries on host port `3100`;
- Promtail 3.5.0, which discovers Docker containers through the read-only
  Docker socket and forwards logs to Loki;
- Grafana 11.6.0 on host port `3000`; and
- persistent Docker volumes for Loki data, Promtail positions, and Grafana
  data.

Promtail adds the `container`, `job`, `service`, and `nomad_alloc_id` labels.
The `service` label is set to `nginx-app` by the configuration.

Start and check the stack:

```bash
docker compose -f monitoring/docker-compose.yaml config
docker compose -f monitoring/docker-compose.yaml up -d
docker compose -f monitoring/docker-compose.yaml ps
curl -i http://localhost:3100/ready
```

Open [Grafana](http://localhost:3000), configure Loki with the internal URL
`http://loki:3100`, and use Explore in Code mode. Generate a test NGINX
access-log entry and query it:

```bash
curl -i http://127.0.0.1:8080/task6-test-not-found
```

```logql
{container=~".+"}
{container=~".+"} |= "/task6-test-not-found"
```

Additional setup and troubleshooting details are in
[`monitoring/loki-setup.md`](monitoring/loki-setup.md). Screenshot evidence
is available at
[`docs/screenshots/loki-404-query.png`](docs/screenshots/loki-404-query.png).

Stop the stack with:

```bash
docker compose -f monitoring/docker-compose.yaml down
```

## Metrics stack

The [`metrics/`](metrics/) Compose stack collects NGINX metrics through the
NGINX Prometheus Exporter:

```text
NGINX :8080/stub_status
    -> nginx-prometheus-exporter :9113
    -> Prometheus :9090
    -> Grafana :3000
```

The stack publishes Prometheus on host port `8624` and Grafana on host port
`3001`. Prometheus scrapes the exporter every 15 seconds, and Grafana
provisions the Prometheus data source and the NGINX dashboard.

Start and validate the stack:

```bash
docker compose -f metrics/docker-compose.yaml config -q
docker compose -f metrics/docker-compose.yaml up -d --build
docker compose -f metrics/docker-compose.yaml ps
```

Open:

- [Prometheus](http://localhost:8624)
- [Prometheus targets](http://localhost:8624/targets)
- [Grafana](http://localhost:3001), using local credentials `admin` / `admin`

The `nginx` target should be **UP**. Useful PromQL queries include:

```promql
up{job="nginx"}
nginx_http_requests_total
nginx_connections_active
```

For component-level verification, see
[`metrics/README.md`](metrics/README.md). Screenshots:

- [Prometheus targets](docs/screenshots/prometheus-targets.png)
- [Grafana NGINX dashboard](docs/screenshots/grafana-nginx-dashboard.png)

Stop the metrics stack:

```bash
docker compose -f metrics/docker-compose.yaml down
```

Add `-v` to remove the persisted Prometheus and Grafana volumes.

## Troubleshooting

The Loki troubleshooting records below are documented in
[`monitoring/loki-setup.md`](monitoring/loki-setup.md). The container restart
and Prometheus checks are diagnostic procedures; they are not claims that
those failures occurred in the verification environment.

### The health check cannot connect

Confirm that the container is running and that port `8080` is not already in
use:

```bash
docker ps
docker logs devops-test
docker rm -f devops-test
docker run -d --name devops-test -p 8080:8080 devops-intern-final:local
```

### Loki readiness succeeds but Grafana cannot query Loki

Grafana runs inside the Compose network, so its data source URL must be
`http://loki:3100`, not `localhost:3100`. Verify readiness from the host with
`curl http://localhost:3100/ready`, then configure the internal service URL in
Grafana and test the connection.

### Loki root URL returns 404

The Loki root path is not a readiness endpoint. Use:

```bash
curl -i http://localhost:3100/ready
```

An HTTP 404 from `http://localhost:3100/` is expected.

### Prometheus does not show the NGINX target as UP

Check that the exporter can reach the NGINX `/stub_status` endpoint and that
all metrics services are on the same Compose network:

```bash
docker compose -f metrics/docker-compose.yaml ps
docker compose -f metrics/docker-compose.yaml exec nginx \
  wget -qO- http://127.0.0.1:8080/stub_status
docker compose -f metrics/docker-compose.yaml exec nginx-exporter \
  wget -qO- http://127.0.0.1:9113/metrics
```

