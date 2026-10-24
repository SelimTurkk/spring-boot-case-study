# Spring Boot DevOps Case Study

## Overview

This project demonstrates Docker image optimization, container deployment on Ubuntu, and infrastructure automation using Vagrant and VirtualBox.

The application is a Spring Boot service packaged as a Docker image and deployed to an Ubuntu virtual machine.

## Architecture

- **Host OS:** Windows 11
- **Hypervisor:** Oracle VirtualBox
- **VM provisioning:** Vagrant
- **Guest OS:** Ubuntu 26.04
- **Container runtime:** Docker Engine
- **Application orchestration:** Docker Compose
- **Application:** Spring Boot
- **Container registry:** Docker Hub

### Deployment flow

1. Vagrant creates and configures the Ubuntu virtual machine.
2. The provisioning script installs Docker Engine and the Docker Compose plugin.
3. Docker pulls the application image from Docker Hub.
4. Docker Compose starts the application container.
5. Vagrant forwards host port `8081` to guest port `8080`.
6. The application is accessed from the host at `http://localhost:8081`.

## Project Structure

```text
.
├── Dockerfile
├── Dockerfile.baseline
├── docker-compose.yml
├── Vagrantfile
├── provision.sh
├── README.md
└── .gitignore
```

## Prerequisites

Install the following tools on the host machine:

- Windows 11
- Oracle VirtualBox
- Vagrant
- Git
- An internet connection to download the VM box and Docker image

Docker Engine is installed automatically inside the guest VM by the provisioning script.

## Run the Application

Open PowerShell and navigate to the project directory:

```powershell
cd phase3-vagrant
```

Start the virtual machine and run provisioning:

```powershell
vagrant up
```

Vagrant creates the VM, runs `provision.sh`, installs Docker, pulls the application image, and starts the container.

Open the application in a browser:

```text
http://localhost:8081
```

To check the VM status:

```powershell
vagrant status
```

To connect to the VM:

```powershell
vagrant ssh
```

Inside the VM, inspect the application container:

```bash
cd /home/vagrant
sudo docker compose ps
sudo docker compose logs app
```

To stop the VM:

```powershell
vagrant halt
```

To remove the Vagrant-managed VM when it is no longer needed:

```powershell
vagrant destroy
```

**Warning:** `vagrant destroy` removes the VM. Use it only when you no longer need that VM or its local data.

## Docker Image Optimization

The baseline image uses a single build-and-runtime stage based on a Maven image containing the JDK. The optimized image uses a multi-stage build and a smaller JRE-based runtime image.

| Metric | Baseline | Optimized |
|---|---:|---:|
| Docker image disk usage | 726 MB | 298 MB |
| Image content size | 264 MB | 87.8 MB |

Based on the recorded measurements, disk usage decreased by approximately **59%**, while image content size decreased by approximately **66.7%**.

The optimization reduces the amount of build tooling included in the runtime image and uses a JRE instead of a full JDK.

The measurements are specific to the local Docker environment and may vary by platform and image version.

## Security Considerations

- The optimized image runs the application as a non-root user.
- The runtime image excludes Maven build tooling and source files.
- Docker packages are installed from the official Docker apt repository.
- The application port is exposed through explicit port mappings.
- The VM's forwarded host port is bound to `127.0.0.1` in the Vagrant configuration.

## Validation

The following checks were performed:

- The Docker image was pushed to Docker Hub.
- The application container started successfully through Docker Compose.
- The container status was verified using `docker compose ps`.
- An HTTP request from the Windows host to `http://localhost:8081` returned **HTTP 200 OK**.

## Limitations

This project is a local development and automation demonstration. It does not implement a production-grade high-availability deployment, automated monitoring, or a complete CI/CD pipeline.

## Author

Selim Türk