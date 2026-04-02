# Prometheus Observability Stack on Azure

A production-ready monitoring stack deployed on **Azure Virtual Machine** using **Terraform** and **Docker Compose**.

Includes Prometheus, Grafana, Alertmanager, and Node Exporter — all provisioned automatically with infrastructure-as-code.

---

## Table of Contents

- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Technology Stack](#technology-stack)
  - [Terraform](#terraform)
  - [Azure Virtual Machine](#azure-virtual-machine)
  - [Azure Virtual Network](#azure-virtual-network)
  - [Azure Network Security Group](#azure-network-security-group)
  - [Docker](#docker)
  - [Docker Compose](#docker-compose)
  - [Prometheus](#prometheus)
  - [Grafana](#grafana)
  - [Alertmanager](#alertmanager)
  - [Node Exporter](#node-exporter)
- [Alert Rules](#alert-rules)
- [Prerequisites](#prerequisites)
- [Deployment Guide](#deployment-guide)
- [Accessing the Services](#accessing-the-services)
- [Configuring Alerts](#configuring-alerts)
- [Terraform Commands Reference](#terraform-commands-reference)
- [Docker Compose Commands Reference](#docker-compose-commands-reference)

---

## Architecture
```
Azure Subscription
└── Resource Group: prometheus-stack-dev-rg
    ├── Virtual Network (10.0.0.0/16)
    │   └── Subnet (10.0.1.0/24)
    ├── Network Security Group
    │   └── Inbound: 22, 80, 443, 9090, 9093, 9100, 3000
    ├── Public IP (Static)
    ├── Network Interface
    └── Linux VM — Ubuntu 22.04 (Standard_B2s)
        └── Docker Compose Stack
            ├── Prometheus    → :9090
            ├── Grafana       → :3000
            ├── Alertmanager  → :9093
            └── Node Exporter → :9100
```

---

## Project Structure
```
04-prometheus-observability-stack/
├── Makefile
├── alertmanager/
│   └── alertmanager.yml
├── docker-compose.yml
├── prometheus/
│   ├── alertrules.yml
│   ├── prometheus.yml
│   └── targets.json
└── terraform-azure/
    ├── modules/
    │   ├── vm/
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   ├── user-data.sh
    │   │   └── variables.tf
    │   └── security-group/
    │       ├── main.tf
    │       ├── outputs.tf
    │       └── variables.tf
    ├── prometheus-stack/
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    └── vars/
        └── azure.tfvars
```

---

## Technology Stack

### Terraform

Terraform is an open-source **Infrastructure as Code (IaC)** tool developed by HashiCorp. It allows you to define, provision, and manage cloud infrastructure using a declarative configuration language called **HCL (HashiCorp Configuration Language)**.

Instead of manually clicking through the Azure portal to create a VM, a network, or a security group, you write `.tf` files that describe what you want, and Terraform figures out how to create it. This makes infrastructure repeatable, version-controlled, and consistent across environments.

Terraform works in three main steps:

- `terraform init` — downloads the required provider plugins (in this case the Azure provider `azurerm`)
- `terraform plan` — previews what resources will be created, modified, or destroyed
- `terraform apply` — provisions the actual infrastructure on Azure

In this project, Terraform is organized into **modules** — reusable blocks of infrastructure code. The `vm` module handles the Virtual Machine, Public IP, and Network Interface. The `security-group` module handles the Network Security Group and its rules. The `prometheus-stack` folder is the root module that calls both and wires everything together.

---

### Azure Virtual Machine

An **Azure Virtual Machine (VM)** is a scalable, on-demand compute resource provided by Microsoft Azure. It is the equivalent of renting a physical server in a Microsoft data center — you get full control of the operating system, networking, and installed software.

In this project, we provision a Linux VM running **Ubuntu 22.04 LTS** using the `Standard_B2s` size (2 vCPUs, 4 GB RAM), which is sufficient to run the full Docker Compose monitoring stack.

The VM is bootstrapped automatically using a **user-data script** (`user-data.sh`). This script runs once on first boot and handles:

- Adding 2GB of swap memory
- Installing Docker and Docker Compose
- Starting the Docker service
- Adding `azureuser` to the docker group

This means by the time you SSH into the VM, it is already fully ready to run containers.

---

### Azure Virtual Network

An **Azure Virtual Network (VNet)** is the fundamental networking building block in Azure. It is a logically isolated network within the Azure cloud where your resources — VMs, databases, load balancers — communicate with each other securely.

A VNet is divided into **subnets**, which are smaller IP address ranges within the VNet used to organize and segment resources.

In this project:

- The VNet is created with address space `10.0.0.0/16`, which provides 65,536 private IP addresses
- A single subnet `10.0.1.0/24` (256 addresses) is created inside the VNet
- The VM's Network Interface is placed inside this subnet, giving it a private IP automatically

The VNet ensures the VM is not directly exposed on a flat public network — all traffic passes through Azure's controlled networking layer.

---

### Azure Network Security Group

A **Network Security Group (NSG)** acts as a virtual firewall for your Azure resources. It contains a list of security rules that allow or deny inbound and outbound network traffic based on port, protocol, and source/destination IP.

NSG rules are evaluated by priority — lower numbers are evaluated first. Each rule either allows or denies the traffic that matches it.

In this project, the NSG is associated with the subnet and allows the following inbound ports:

| Port | Protocol | Purpose       |
|------|----------|---------------|
| 22   | TCP      | SSH access    |
| 80   | TCP      | HTTP          |
| 443  | TCP      | HTTPS         |
| 9090 | TCP      | Prometheus    |
| 9093 | TCP      | Alertmanager  |
| 9100 | TCP      | Node Exporter |
| 3000 | TCP      | Grafana       |

All outbound traffic is allowed by default. The rules are defined dynamically in `azure.tfvars` using a list of objects, so adding or removing a port only requires updating the vars file.

---

### Docker

**Docker** is a platform that packages applications and their dependencies into lightweight, portable units called **containers**. A container includes everything the application needs to run — the code, runtime, libraries, and config — so it behaves identically regardless of where it runs.

Unlike Virtual Machines, containers share the host OS kernel and do not need a full OS per application, making them significantly faster to start and more resource-efficient.

In this project, each monitoring tool (Prometheus, Grafana, Alertmanager, Node Exporter) runs as its own Docker container. Docker is installed automatically on the VM via `user-data.sh` on first boot.

Key Docker concepts used in this project:

- **Image** — a read-only template used to create a container (e.g. `prom/prometheus:latest`)
- **Container** — a running instance of an image
- **Volume** — a mechanism to mount local config files into a container (e.g. mounting `prometheus.yml` into the Prometheus container)
- **Network** — containers in the same Docker network can communicate with each other by container name

---

### Docker Compose

**Docker Compose** is a tool for defining and running multi-container Docker applications. Instead of starting each container manually with a long `docker run` command, you describe all your services in a single `docker-compose.yml` file and start everything with one command.

In this project, `docker-compose.yml` defines four services — Prometheus, Grafana, Alertmanager, and Node Exporter — all connected through a shared Docker bridge network called `monitor`.

Key sections in `docker-compose.yml`:

- `image` — the Docker image to use for the container
- `ports` — maps a host port to a container port (`host:container`)
- `volumes` — mounts local config files into the container at the specified path
- `command` — overrides the default startup command of the container
- `networks` — connects the container to a named network so services can reach each other
- `restart: always` — ensures containers automatically restart if they crash or the VM reboots

---

### Prometheus

**Prometheus** is an open-source monitoring and alerting toolkit originally built at SoundCloud and now a graduated project of the **Cloud Native Computing Foundation (CNCF)**. It is the most widely used monitoring tool in the cloud-native ecosystem.

Prometheus works on a **pull model** — instead of applications pushing metrics to Prometheus, Prometheus scrapes (pulls) metrics from configured targets at regular intervals. Each target exposes a `/metrics` HTTP endpoint.

Key concepts:

- **Scrape** — the act of Prometheus fetching metrics from a target endpoint
- **Scrape interval** — how often Prometheus collects metrics (set to `15s` in this project)
- **Time series** — every metric is stored as a time-stamped sequence of values identified by a metric name and key-value labels
- **PromQL** — Prometheus Query Language, used to query and aggregate metrics
- **Rule files** — YAML files that define alerting conditions (e.g. CPU > 90% for 1 minute)
- **Targets** — the list of endpoints Prometheus scrapes, defined in `targets.json` using file-based service discovery

In this project, Prometheus scrapes the Node Exporter for host metrics and uses `alertrules.yml` to define alert conditions. It sends firing alerts to Alertmanager.

---

### Grafana

**Grafana** is an open-source analytics and visualization platform. It connects to data sources like Prometheus and renders the metrics as beautiful, interactive dashboards with graphs, charts, gauges, and tables.

Grafana does not store metrics itself — it queries Prometheus using PromQL and visualizes the results in real time.

Key concepts:

- **Data source** — a connection to a metrics backend (Prometheus in this case)
- **Dashboard** — a collection of panels arranged on a canvas
- **Panel** — a single visualization (graph, stat, gauge, table, etc.)
- **Variables** — dynamic filters that let you switch between instances or time ranges on a dashboard
- **Alerting** — Grafana also supports its own alert rules, separate from Prometheus alerts

In this project, Grafana runs on port `3000` and can be accessed via the browser. On first login (`admin` / `admin`), you add Prometheus as a data source using the URL `http://prometheus:9090` (container name resolution within the Docker network) and then import or build dashboards.

---

### Alertmanager

**Alertmanager** is a component of the Prometheus ecosystem that handles alerts sent by Prometheus. When a Prometheus alert rule fires, Prometheus forwards the alert to Alertmanager, which then takes care of deduplication, grouping, silencing, and routing the alert to the correct notification channel.

Alertmanager separates the concern of *detecting* a problem (Prometheus) from *notifying* about it (Alertmanager).

Key concepts:

- **Route** — defines how alerts are matched and which receiver handles them
- **Receiver** — the notification destination (email, Slack, PagerDuty, webhook, etc.)
- **Grouping** — combines multiple related alerts into a single notification to reduce noise
- **Inhibition** — suppresses certain alerts when another related alert is already firing
- **Silencing** — temporarily mutes specific alerts during planned maintenance

In this project, Alertmanager is configured in `alertmanager/alertmanager.yml` to route all alerts to an email receiver by default. A Slack receiver is also defined and can be enabled by updating the route.

---

### Node Exporter

**Node Exporter** is a Prometheus exporter for hardware and OS-level metrics on Linux hosts. It exposes a `/metrics` endpoint on port `9100` that Prometheus scrapes to collect system-level data.

Node Exporter collects metrics including:

- **CPU** — usage per core, idle time, system/user/iowait breakdown
- **Memory** — total, used, free, cached, swap usage
- **Disk** — read/write bytes, filesystem usage per mount point
- **Network** — bytes sent/received, packet errors and drops per interface
- **System** — load average, uptime, open file descriptors, running processes

These metrics form the foundation of the alert rules in this project — for example, the `HighCpuUsage` alert uses the `node_cpu_seconds_total` metric exposed by Node Exporter.

In this project, Node Exporter runs as a container on port `9100`, and its address (`127.0.0.1:9100`) is registered as a scrape target in `prometheus/targets.json`.

---

## Alert Rules

| Alert            | Condition                         | Severity |
|------------------|-----------------------------------|----------|
| InstanceDown     | Target unreachable for 1m         | —        |
| HighCpuUsage     | CPU usage > 90% for 1m            | warning  |
| HighMemoryUsage  | Container memory > 90GB/ns for 1m | warning  |
| HighStorageUsage | Disk usage > 90% for 1m           | warning  |

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.3
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Docker](https://docs.docker.com/engine/install/) and [Docker Compose](https://docs.docker.com/compose/install/)
- An active Azure subscription
- An SSH key pair on your local machine

---

## Deployment Guide

### Step 1 — Login to Azure
```bash
az login
```

If you have multiple subscriptions, set the one you want to use:
```bash
az account set --subscription "<your-subscription-id>"
```

### Step 2 — Configure Variables

Open `terraform-azure/vars/azure.tfvars` and update the values:
```hcl
location            = "eastus"
name                = "prometheus-stack"
environment         = "dev"
owner               = "your-name"
ssh_public_key_path = "~/.ssh/id_rsa.pub"
vm_size             = "Standard_B2s"
```

### Step 3 — Provision the Infrastructure
```bash
cd terraform-azure/prometheus-stack/

terraform fmt
terraform validate
terraform init
terraform plan --var-file=../vars/azure.tfvars
terraform apply --var-file=../vars/azure.tfvars
```

After apply, Terraform will output the VM's public IP:
```
instance_public_ip = "xx.xx.xx.xx"
```

### Step 4 — SSH into the VM
```bash
ssh azureuser@<vm_public_ip>
```

> Wait 1–2 minutes after `terraform apply` for the `user-data.sh` script to finish installing Docker.

### Step 5 — Clone the Repository on the VM
```bash
git clone https://github.com/<your-username>/04-prometheus-observability-stack.git
cd 04-prometheus-observability-stack
```

### Step 6 — Run Service Discovery

This replaces `127.0.0.1` with the VM's actual public IP in `prometheus.yml` and `targets.json` so Prometheus and Alertmanager can communicate properly:
```bash
make service-discovery
```

To revert back to localhost:
```bash
make rollback
```

### Step 7 — Start the Stack
```bash
docker-compose up -d
```

Verify all containers are running:
```bash
docker-compose ps
```

---

## Accessing the Services

| Service       | URL                        | Default Credentials |
|---------------|----------------------------|---------------------|
| Prometheus    | `http://<public-ip>:9090`  | —                   |
| Grafana       | `http://<public-ip>:3000`  | admin / admin       |
| Alertmanager  | `http://<public-ip>:9093`  | —                   |
| Node Exporter | `http://<public-ip>:9100`  | —                   |

---

## Configuring Alerts

### Email Notifications

Edit `alertmanager/alertmanager.yml` and replace the placeholder values:
```yaml
receivers:
- name: 'email-notifications'
  email_configs:
    - to: 'your-email@example.com'
      from: 'prometheus@example.com'
      smarthost: 'smtp.example.com:587'
      auth_username: 'your-username'
      auth_password: 'your-password'
```

### Slack Notifications
```yaml
- name: 'slack-notifications'
  slack_configs:
    - api_url: "https://hooks.slack.com/services/YOUR-SLACK-WEBHOOK"
      channel: '#your-channel'
      send_resolved: true
```

Restart Alertmanager after any config change:
```bash
docker-compose restart alertmanager
```

---

## Terraform Commands Reference
```bash
# Format code
terraform fmt

# Validate configuration
terraform validate

# Preview changes
terraform plan --var-file=../vars/azure.tfvars

# Apply changes
terraform apply --var-file=../vars/azure.tfvars

# Refresh outputs
terraform refresh --var-file=../vars/azure.tfvars

# Show current state
terraform show

# Destroy all resources
terraform destroy --var-file=../vars/azure.tfvars
```

---

## Docker Compose Commands Reference
```bash
# Start the stack
docker-compose up -d

# Stop the stack
docker-compose down

# View logs for all services
docker-compose logs -f

# View logs for a specific service
docker-compose logs -f prometheus

# Restart a specific service
docker-compose restart grafana

# Check container status
docker-compose ps
```

---

## Hit the Star! ⭐

If you found this project useful for learning, please give it a star. Thanks!
