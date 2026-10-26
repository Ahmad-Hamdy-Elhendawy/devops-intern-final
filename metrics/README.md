# NGINX Metrics Stack

## Overview

This directory contains a Docker Compose stack for collecting and visualizing NGINX metrics.

The stack consists of:

- **NGINX:** Serves the web application and exposes the internal `/stub_status` endpoint.
- **NGINX Prometheus Exporter:** Converts NGINX status data into Prometheus metrics.
- **Prometheus:** Scrapes metrics every 15 seconds and stores the collected data.
- **Grafana:** Visualizes metrics using a provisioned dashboard.

## Architecture

```text
NGINX (:8080)
    |
    | /stub_status
    v
NGINX Prometheus Exporter (:9113)
    |
    | Metrics
    v
Prometheus (:9090)
    |
    | Data source
    v
Grafana (:3000)
```

All services communicate through a dedicated Docker Compose network. NGINX and the exporter are accessible internally and do not publish host ports.

## Prerequisites

- Docker
- Docker Compose

Run commands from the repository root.

## Start the Stack

Validate the configuration:

```bash
docker compose -f metrics/docker-compose.yaml config -q
```

Build and start the services:

```bash
docker compose -f metrics/docker-compose.yaml up -d --build
```

Check container status:

```bash
docker compose -f metrics/docker-compose.yaml ps
```

## Access the Services

| Service | URL |
|---|---|
| Prometheus | http://localhost:8624 |
| Grafana | http://localhost:3001 |

Grafana's local default credentials are `admin` / `admin`.

Host port `8624` maps to Prometheus container port `9090`. Internal service communication continues to use port `9090`.

## Verify NGINX Status

```bash
docker compose -f metrics/docker-compose.yaml exec nginx \
  wget -qO- http://127.0.0.1:8080/stub_status
```

The output should include active connections and accepted, handled, and total request counts.

## Verify the Exporter

```bash
docker compose -f metrics/docker-compose.yaml exec nginx-exporter \
  wget -qO- http://127.0.0.1:9113/metrics
```

Look for metrics beginning with `nginx_`.

### Metrics Screenshots

**Prometheus — Scrape Targets**

![Prometheus targets showing NGINX scrape status](docs/screenshots/prometheus-targets.png)


## Verify Prometheus

Open [Prometheus Targets](http://localhost:8624/targets).

The `nginx` job should report **UP**.

Example PromQL queries:

```promql
up{job="nginx"}
```

```promql
nginx_http_requests_total
```

```promql
nginx_connections_active
```

## Grafana Dashboard

Open [Grafana](http://localhost:3001) and navigate to:

**Dashboards → Infrastructure → NGINX Metrics**

The dashboard JSON is stored at:

`metrics/grafana/dashboards/nginx-metrics.json`

The dashboard includes panels for exporter availability, total NGINX requests, active connections, connection states, and scrape duration.

The Prometheus data source is provisioned at `http://prometheus:9090`, using the internal Docker Compose network.

**Grafana — NGINX Metrics Dashboard**

![Grafana dashboard displaying NGINX metrics](docs/screenshots/grafana-nginx-dashboard.png)


## Configuration Files

```text
metrics/
├── docker-compose.yaml
├── prometheus/
│   └── prometheus.yml
├── grafana/
│   ├── dashboards/
│   │   └── nginx-metrics.json
│   └── provisioning/
│       ├── datasources/
│       │   └── prometheus.yml
│       └── dashboards/
│           └── dashboards.yml
└── README.md
```

## Stop the Stack

Stop containers and remove the Compose network:

```bash
docker compose -f metrics/docker-compose.yaml down
```

To also remove the persisted Prometheus and Grafana data:

```bash
docker compose -f metrics/docker-compose.yaml down -v
```

**Warning:** The `-v` option deletes the metrics stack's persisted data.
