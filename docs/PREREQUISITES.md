# Prerequisites & Setup Guide

This document lists all software needed to run the Transaction Processing Workshop on Azure.

## Required Software

| Software | Version | Purpose | Installation |
|----------|---------|---------|--------------|
| **VS Code** | Latest | Code editor | [Download](https://code.visualstudio.com/download) |
| **Git** | 2.x+ | Version control | [Download](https://git-scm.com/downloads) |
| **Azure CLI** | 2.50+ | Azure management | [Install Guide](https://docs.microsoft.com/cli/azure/install-azure-cli) |
| **Azure Developer CLI (azd)** | 1.22+ | Deployment automation | [Install Guide](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd) |
| **Docker** | Latest | Build container images | [Download](https://www.docker.com/products/docker-desktop/) |

> **Note for Mac**: You can use [Colima](https://github.com/abiosoft/colima) as a lightweight alternative to Docker Desktop: `brew install colima docker`

---

## Installation Commands

### macOS

```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install all required tools
brew install git
brew install --cask visual-studio-code
brew install --cask docker          # Or: brew install colima docker
brew install azure-cli
brew tap azure/azd && brew install azd
```

### Windows

```powershell
# Using winget (Windows Package Manager)
winget install Git.Git
winget install Microsoft.VisualStudioCode
winget install Docker.DockerDesktop
winget install Microsoft.AzureCLI
winget install Microsoft.Azd
```

### Linux (Ubuntu/Debian)

```bash
# Install Git and VS Code
sudo apt update
sudo apt install git
sudo snap install code --classic

# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Install Azure tools
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
curl -fsSL https://aka.ms/install-azd.sh | bash
```

---

## VS Code Extensions (Recommended)

| Extension | ID | Purpose |
|-----------|-----|---------|
| **Python** | `ms-python.python` | Python language support |
| **Azure Tools** | `ms-vscode.vscode-node-azure-pack` | Azure integration |

Install:
```bash
code --install-extension ms-python.python
code --install-extension ms-vscode.vscode-node-azure-pack
```

---

## Verify Installation

```bash
# Check all tools are installed
git --version          # Should show: git version 2.x.x
docker --version       # Should show: Docker version 2x.x.x
az --version           # Should show: azure-cli 2.x.x
azd version            # Should show: azd version 1.x.x
```

### Verify Docker is Running

```bash
docker ps              # Should not show error
```

If Docker isn't running:
```bash
# macOS with Docker Desktop
open -a Docker

# macOS with Colima
colima start
```

---

## Azure Requirements

### Subscription Access

You need an Azure subscription with permissions to create:
- Resource Groups
- Azure Managed Redis (Enterprise tier)
- Azure Container Registry
- Azure Container Apps
- Virtual Networks
- Storage Accounts

### Required Role

Minimum: **Contributor** on the subscription or a dedicated resource group.

### Cost Estimate

| Resource | ~Cost/Hour |
|----------|------------|
| Azure Managed Redis (Balanced B3) | ~$0.37 |
| Container Registry (Premium) | ~$0.07 |
| Container Apps (5 apps) | ~$0.05 |
| Storage Account | ~$0.01 |
| **Total** | **~$0.50/hour** |

⚠️ **Remember to run `azd down` when done to avoid charges!**

---

## Troubleshooting

### Docker Not Running

**Error**: `Cannot connect to the Docker daemon`

**Solution**:
```bash
# macOS with Docker Desktop
open -a Docker

# macOS with Colima
colima start

# Linux
sudo systemctl start docker
```

### Azure Login Issues

**Error**: `You must be logged into Azure`

**Solution**:
```bash
azd auth login
az login
```

### Permission Denied

**Error**: `AuthorizationFailed` during deployment

**Solution**: Contact your Azure administrator to ensure you have Contributor access.
