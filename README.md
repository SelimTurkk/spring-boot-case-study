# Spring Boot DevOps Case Study

[![Build and Publish Docker Image](https://github.com/SelimTurkk/spring-boot-case-study/actions/workflows/cicd.yml/badge.svg)](https://github.com/SelimTurkk/spring-boot-case-study/actions/workflows/cicd.yml)

Docker image optimization, Ubuntu VM deployment, Vagrant automation, and a GitHub Actions CI/CD pipeline for a Spring Boot application.

- **Source repository:** https://github.com/SelimTurkk/spring-boot-case-study
- **Docker Hub image:** https://hub.docker.com/r/selsec/spring-boot-case-study

## Overview

The application is the Spring Boot "Getting Started" sample (Maven, `complete` project). It is packaged as a Docker image with a multi-stage build, deployed to an Ubuntu 26.04 LTS virtual machine with Docker Compose, provisioned automatically with Vagrant, and rebuilt and published to Docker Hub by GitHub Actions on every push to `main`.

## Architecture

```
GitHub repository -> GitHub Actions (CI) -> Docker Hub -> Vagrant VM (Ubuntu 26.04) -> Docker Compose -> Spring Boot container
```

```
Windows host                     VirtualBox VM (Ubuntu 26.04)          Container
127.0.0.1:8081  --forwarded-->   port 8080  --Docker mapping-->        port 8080
```

| Layer | Component |
|---|---|
| Host OS | Windows 11 |
| Hypervisor | Oracle VirtualBox |
| VM provisioning | Vagrant (box `bento/ubuntu-26.04`) |
| Guest OS | Ubuntu 26.04 LTS |
| Container runtime | Docker Engine + Docker Compose plugin |
| Application | Spring Boot (Maven, Java 17) |
| Registry | Docker Hub (`selsec/spring-boot-case-study`) |
| CI/CD | GitHub Actions (`.github/workflows/cicd.yml`) |

## Project Structure

```
.
├── .github/workflows/cicd.yml   # CI/CD pipeline
├── src/                         # Spring Boot source code
├── pom.xml                      # Maven project descriptor
├── Dockerfile                   # Optimized multi-stage image
├── Dockerfile.baseline          # Single-stage image used for comparison
├── docker-compose.yml           # Runs the application from Docker Hub
├── Vagrantfile                  # VM definition
├── provision.sh                 # Installs Docker and starts the application
├── README.md
└── .gitignore
```

## Prerequisites

Quick start (Phase 3 only) needs:

- Windows 11
- [Oracle VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://developer.hashicorp.com/vagrant)
- Git
- An internet connection (downloads the VM box and the Docker image)

To reproduce Phase 1 (building and pushing the image) you additionally need:

- WSL2 and Docker Desktop with the WSL2 backend
- A Docker Hub account

Docker Engine inside the VM is installed by `provision.sh`; you do not install it on the host for the Vagrant workflow.

## Quick Start

```powershell
git clone https://github.com/SelimTurkk/spring-boot-case-study.git
cd spring-boot-case-study

vagrant up
```

Vagrant downloads the box, creates the VM, runs `provision.sh` (installs Docker Engine and the Compose plugin, pulls the image, starts the container), and forwards the application port.

Open the application on the host:

```
http://localhost:8081
```

Expected response: `Greetings from Spring Boot!`

Useful commands:

```powershell
vagrant status     # VM state
vagrant ssh        # connect to the VM
vagrant halt       # stop the VM
vagrant destroy    # remove the VM (deletes its local data)
```

Inside the VM:

```bash
cd /home/vagrant
sudo docker compose ps
sudo docker compose logs app
```

> **Warning:** `vagrant destroy` removes the VM. Use it only when you no longer need the VM or its local data.

## Step-by-Step Reproduction Guide

### Phase 1: Local environment and containerization

1. **Install WSL2 and Docker Desktop.** From an elevated PowerShell run `wsl --install`, reboot, then install Docker Desktop and enable *Use the WSL 2 based engine* in its settings.
2. **Get the source.** The Spring Boot `complete` project is in this repository (`src/` and `pom.xml`).
3. **Build the baseline and the optimized images.**

   ```powershell
   docker build -f Dockerfile.baseline -t spring-boot-case-study:baseline .
   docker build -t spring-boot-case-study:v1 .
   docker images
   ```

4. **Push to Docker Hub.**

   ```powershell
   docker login
   docker tag spring-boot-case-study:v1 selsec/spring-boot-case-study:v1
   docker push selsec/spring-boot-case-study:v1
   ```

### Phase 2: Manual VM deployment

1. Create an Ubuntu 26.04 LTS VM in VirtualBox with a NAT port forward for SSH and for the application port (8080), then connect over SSH.
2. Install Docker Engine and the Compose plugin from Docker's official apt repository:

   ```bash
   sudo apt-get update
   sudo apt-get install -y ca-certificates curl
   sudo install -m 0755 -d /etc/apt/keyrings
   sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
   sudo chmod a+r /etc/apt/keyrings/docker.asc

   sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
   Types: deb
   URIs: https://download.docker.com/linux/ubuntu
   Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
   Components: stable
   Architectures: $(dpkg --print-architecture)
   Signed-By: /etc/apt/keyrings/docker.asc
   EOF

   sudo apt-get update
   sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
   ```

3. Copy `docker-compose.yml` to the VM, then start the application and verify it:

   ```bash
   sudo docker compose up -d
   sudo docker compose ps
   curl -i http://localhost:8080
   ```

### Phase 3: Infrastructure as Code with Vagrant

`Vagrantfile` and `provision.sh` automate everything from Phase 2. `vagrant up` creates the VM, installs Docker, copies `docker-compose.yml`, and starts the container (see [Quick Start](#quick-start)).

**Box choice:** the VM uses the `bento/ubuntu-26.04` box (version `202606.01.0` when this project was built). The Ubuntu 26.04 LTS box is available for VirtualBox on Vagrant Cloud, so no older Ubuntu release is needed.

### Phase 4: Documentation and delivery

This repository contains the Dockerfiles, Compose file, Vagrantfile, provisioning script, source code, workflow, and this README.

### Phase 5: CI/CD pipeline

The workflow `.github/workflows/cicd.yml` ("Build and Publish Docker Image"):

- runs on every push to `main` and can be started manually (`workflow_dispatch`);
- logs in to Docker Hub using GitHub Actions secrets;
- builds the multi-stage image and pushes it with two tags: `latest` and `sha-<commit>`.

To set it up in your own fork, add these repository secrets under *Settings -> Secrets and variables -> Actions*:

| Secret | Value |
|---|---|
| `DOCKERHUB_USERNAME` | Your Docker Hub username |
| `DOCKERHUB_TOKEN` | A Docker Hub access token (not your password) |

## Docker Image Optimization

The baseline image (`Dockerfile.baseline`) builds and runs the application in a single Maven/JDK stage. The optimized image (`Dockerfile`) uses a multi-stage build: Maven with JDK 17 (Alpine) compiles the application, and only the JAR is copied into an `eclipse-temurin:17-jre-alpine` runtime image that runs as a non-root user.

| Metric | Baseline | Optimized | Reduction |
|---|---:|---:|---:|
| Docker image disk usage | 726 MB | 298 MB | approx. 59.0% |
| Image content size | 264 MB | 87.8 MB | approx. 66.7% |

Measured with `docker images` after building both images locally (see Phase 1). Disk usage and content size are distinct metrics, and values vary with platform, image metadata, and runtime version.

## Security Considerations

- The optimized image runs the application as a dedicated non-root user.
- The runtime image contains no Maven build tooling or source files.
- Docker Engine is installed from Docker's official apt repository.
- The Vagrant forwarded port is bound to `127.0.0.1`, so the application is reachable only from the host machine.
- Docker Hub credentials are stored as GitHub Actions secrets and are never committed to the repository.

## Validation

The following checks were performed:

- The optimized image was pushed to Docker Hub (`v1`).
- On a manually created Ubuntu VM, `docker compose ps` showed the container running and `curl http://localhost:8080` returned HTTP 200 with `Greetings from Spring Boot!`.
- With Vagrant, an HTTP request from the Windows host to `http://localhost:8081` returned HTTP 200.
- The GitHub Actions workflow completed successfully and published both the `latest` and `sha-...` tags to Docker Hub.

## Limitations

This project is a local demonstration. It does not implement a production-grade high-availability setup, monitoring, or automated rollback. The VM deployment pulls the `v1` image tag and does not update automatically when the pipeline publishes a new image (the optional Watchtower step is not implemented).

## Author

Selim Türk