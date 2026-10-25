
variable "image_tag" {
  description = "GHCR image tag to deploy"
  type        = string
  default     = "33c0c9592779f5475fd047cb65d7972f761ab136"
}

job "nginx-app" {
  datacenters = ["dc1"]
  type        = "service"

  update {
    max_parallel     = 1
    min_healthy_time = "10s"
    healthy_deadline = "2m"
    auto_revert      = true
  }

  group "nginx" {
    count = 1
    shutdown_delay = "5s"

    network {
      port "http" {
        to = 8080
      }
    }

    restart {
      attempts = 3
      interval = "5m"
      delay    = "15s"
      mode     = "fail"
    }

    reschedule {
      attempts  = 3
      interval  = "1h"
      delay     = "30s"
      unlimited = false
    }

    service {
      provider = "consul"
      name     = "nginx-app"
      port     = "http" 

      check {
        name     = "nginx-health"
        type     = "http"
        path     = "/healthz"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "ghcr.io/ahmad-hamdy-elhendawy/devops-intern-final:${var.image_tag}"
        ports = ["http"]
      }

      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}
