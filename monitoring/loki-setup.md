# Loki Log Aggregation

## Overview

This setup collects Docker container logs using Promtail, stores and queries them in Loki, and provides a Grafana interface for log exploration.

**Components**
- **Loki:** log storage and query API, exposed on port `3100`.
- **Promtail:** discovers Docker containers and forwards their logs to Loki.
- **Grafana:** log exploration interface, exposed on port `3000`.
- **Docker Compose:** runs the monitoring stack on the `monitoring_monitoring` network.

## Configuration

The monitoring stack is defined in `docker-compose.yaml`. Loki uses `loki-config.yaml`, while Promtail uses `promtail-config.yaml`.

Promtail discovers containers through the Docker socket and forwards logs to:

```text
http://loki:3100/loki/api/v1/push
```

The configured log labels include:
- `container`
- `job`
- `service`
- `nomad_alloc_id`

These labels were verified in Grafana Explore.

## Start the Monitoring Stack

Run from the repository root:

```bash
docker compose -f monitoring/docker-compose.yaml config
docker compose -f monitoring/docker-compose.yaml up -d
docker compose -f monitoring/docker-compose.yaml ps
```

Check Loki readiness:

```bash
curl -i http://localhost:3100/ready
```

**Observed result:** Loki returned `ready`.

The root endpoint (`http://localhost:3100/`) returned HTTP 404. This is expected; the readiness endpoint is `/ready`.

## Grafana Setup

Open [http://localhost:3000](http://localhost:3000).

Configure the Loki data source with the URL:

```text
http://loki:3100
```

Select Loki as the default data source if needed. The connection test succeeded, and log queries could then be executed in Grafana Explore using Code mode.

The hostname `loki` resolves within the Docker Compose network; use `localhost:3100` when accessing Loki directly from the host.

## Generate and Query a Test Log

Request a nonexistent path from the NGINX application:

```bash
curl -i http://127.0.0.1:8080/task6-test-not-found
```

This request is intended to generate an NGINX 404 access-log entry.

In Grafana Explore, select Loki, use Code mode, and run the following LogQL queries.

Show log streams with a container label:

```logql
{container=~".+"}
```

Filter for the test request:

```logql
{container=~".+"} |= "/task6-test-not-found"
```

Set an appropriate time range, such as **Last 15 minutes**, and run the query.

The required labels `container`, `job`, `service`, and `nomad_alloc_id` were confirmed in Grafana Explore.

## Troubleshooting

### Grafana query returned `unsupported protocol scheme ""`

The Loki readiness endpoint was working, and Grafana and Loki were attached to the same Docker network. The issue was resolved by setting Loki as Grafana's default data source.

### Opening Loki's root URL returned HTTP 404

The root path is not the readiness endpoint. Use:

```bash
curl -i http://localhost:3100/ready
```

### Container networking

The Compose network `monitoring_monitoring` contained the `loki`, `promtail`, and `grafana` containers. The Grafana-to-Loki URL uses the Compose service hostname `loki`.

## Screenshot Evidence

Grafana Explore screenshot showing the test-log query and matching result:

`docs/screenshots/loki-404-query.png`

## Limitations

- This is a local, single-node monitoring setup intended for the assessment.
- Grafana's initial credentials are for local development only and must not be exposed publicly.
- Log collection depends on Promtail having access to the Docker socket and on the target container producing logs.
