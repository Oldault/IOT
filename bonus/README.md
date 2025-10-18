# Bonus: Local GitLab Setup for Kubernetes

This bonus section sets up a local GitLab instance in your Kubernetes cluster to work alongside the ArgoCD setup from p3.

## Overview

This setup installs:
- GitLab CE (Community Edition) via Helm
- GitLab in a dedicated `gitlab` namespace
- Ingress configuration for local access
- Integration with the existing k3d cluster from p3

## Prerequisites

Before running the bonus installation, ensure you have completed p3:

```bash
cd ../p3
make all
```

This will set up the k3d cluster that GitLab will be installed into.

## Installation

### Quick Start

```bash
# From the bonus directory
make all
```

This will:
1. Install Helm (if not already installed)
2. Create the `gitlab` namespace
3. Deploy GitLab using Helm
4. Configure local access at `gitlab.local`

### Manual Steps

```bash
# Install GitLab
make install

# Check installation status
make status

# Get the root password
make get-password
```

## Accessing GitLab

### Option 1: Via Ingress (Recommended)

Access GitLab at: **http://gitlab.local:8888**

- **Username**: `root`
- **Password**: `Sup3rS3cur3P@ss!` (or run `make get-password`)

### Option 2: Via Port-Forward

```bash
make gitlab-web
```

Then access GitLab at: **http://localhost:8081**

**Note**: ArgoCD from p3 uses port 8080, so GitLab uses port 8081 to avoid conflicts.

## What Gets Installed

The `install.sh` script performs the following:

1. **Helm Installation**: Installs Helm package manager if not present
2. **Namespace Creation**: Creates the `gitlab` Kubernetes namespace
3. **Secret Creation**: Creates initial root password secret
4. **GitLab Deployment**: Installs GitLab CE via Helm chart with optimized settings for local development
5. **Hosts Configuration**: Adds `gitlab.local` to `/etc/hosts`

### Resource Configuration

The GitLab installation is optimized for local development with reduced resource requirements:
- Minimal replicas (1) for each component
- Reduced CPU/memory limits
- Disabled unnecessary components (Prometheus, cert-manager, nginx-ingress)
- Uses Traefik ingress from k3d

## Verification

### 1. Check Pod Status

```bash
kubectl get pods -n gitlab
```

All pods should be in `Running` state.

### 2. Check Services

```bash
kubectl get svc -n gitlab
```

### 3. Check Ingress

```bash
kubectl get ingress -n gitlab
```

### 4. Verify Integration with p3

The bonus setup is designed to work alongside p3 ArgoCD:

```bash
# Check all namespaces
kubectl get namespaces

# You should see:
# - argocd (from p3)
# - dev (from p3)
# - gitlab (from bonus)
```

## Integration with ArgoCD (p3)

To integrate GitLab with your ArgoCD setup from p3:

1. **Create a Repository in GitLab**:
   - Access GitLab web UI
   - Create a new project/repository
   - Push your manifests to this repository

2. **Update ArgoCD Application**:
   - Modify `p3/src/confs/argocd-app.yml`
   - Change `repoURL` from GitHub to your local GitLab
   - Example: `http://gitlab-webservice-default.gitlab.svc:8181/root/your-repo.git`

3. **Configure ArgoCD Repository Access**:
   ```bash
   # Add GitLab repository to ArgoCD
   argocd repo add http://gitlab.local:8888/root/your-repo.git \
     --username root \
     --password $(make get-password)
   ```

## Uninstallation

### Complete Removal

```bash
make uninstall
```

This will:
1. Uninstall GitLab Helm release
2. Delete the `gitlab` namespace
3. Clean up persistent volumes
4. Remove `gitlab.local` from `/etc/hosts`

### Partial Cleanup

To keep GitLab installed but clean data:

```bash
make clean
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod logs
kubectl logs -n gitlab <pod-name>

# Check events
kubectl get events -n gitlab --sort-by='.lastTimestamp'
```

### Can't Access GitLab UI

1. Check ingress is running:
   ```bash
   kubectl get ingress -n gitlab
   ```

2. Verify `/etc/hosts` entry:
   ```bash
   grep gitlab.local /etc/hosts
   ```

3. Try port-forward instead:
   ```bash
   make gitlab-web
   ```

### GitLab Takes Too Long to Install

GitLab is a complex application. Initial installation can take 5-10 minutes. The installation script waits up to 10 minutes for all components to be ready.

### Helm Not Found After Installation

If Helm was just installed, you may need to reload your shell:

```bash
hash -r
# or
source ~/.bashrc
```

## Architecture

```
┌─────────────────────────────────────────┐
│         k3d Cluster (svolodin)          │
│                                         │
│  ┌───────────┐  ┌──────────┐  ┌──────┐ │
│  │  argocd   │  │   dev    │  │gitlab│ │
│  │ namespace │  │namespace │  │ ns   │ │
│  └───────────┘  └──────────┘  └──────┘ │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │   Traefik Ingress Controller    │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
           │
           │ :8888 (LoadBalancer)
           ▼
    http://gitlab.local:8888
```

## Files Structure

```
bonus/
├── Makefile                          # Main automation
├── README.md                         # This file
└── src/
    ├── scripts/
    │   ├── install.sh               # GitLab installation script
    │   └── uninstall.sh             # GitLab removal script
    └── confs/
        ├── namespace.yml             # GitLab namespace definition
        ├── gitlab-values.yaml        # Helm chart values
        └── gitlab-ingress.yml        # Ingress configuration
```

## Make Targets

| Target | Description |
|--------|-------------|
| `make all` | Complete setup (install + status) |
| `make install` | Install GitLab in the cluster |
| `make status` | Check GitLab pods and services |
| `make get-password` | Retrieve GitLab root password |
| `make gitlab-web` | Port-forward GitLab to localhost:8080 |
| `make clean` | Clean GitLab data (keep installed) |
| `make uninstall` | Completely remove GitLab |
| `make help` | Show help message |

## Notes

- GitLab installation requires significant resources (minimum 4GB RAM recommended)
- First startup can take 5-10 minutes
- All data is stored in persistent volumes within the cluster
- The setup uses HTTP (not HTTPS) for local development simplicity
- GitLab CE (Community Edition) is used for this setup
