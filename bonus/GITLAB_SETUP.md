# GitLab Integration with ArgoCD

This guide explains how to use ArgoCD with your local GitLab instance instead of GitHub.

## Overview

This setup uses a **proper DevOps architecture** with:
- **Internal service communication**: ArgoCD pulls from GitLab using Kubernetes service DNS
- **External ingress access**: You can access GitLab UI and clone repos via ingress
- **No port-forwarding hacks**: Everything uses native Kubernetes networking

## Architecture

```
┌─────────────────────────────────────────────────┐
│           k3d Cluster (svolodin)                │
│                                                 │
│  ┌──────────┐          ┌──────────┐            │
│  │  argocd  │  pulls   │  gitlab  │            │
│  │namespace │◄─────────┤namespace │            │
│  └──────────┘ internal └──────────┘            │
│                service                          │
│                                                 │
│         Traefik Ingress (port 8888)            │
└─────────────────────────────────────────────────┘
                    │
                    │ External access
                    ▼
          http://gitlab.gitlab.local:8888
```

## Access Methods

### 1. ArgoCD (Internal - Pod to Pod)
- **URL**: `http://gitlab-webservice-default.gitlab.svc:8181`
- **Access**: Internal Kubernetes service DNS
- **Security**: Not exposed externally
- **Use case**: ArgoCD pulling manifests from GitLab

### 2. You (External - Browser/Git)
- **URL**: `http://gitlab.gitlab.local:8888`
- **Access**: Ingress via Traefik LoadBalancer
- **Security**: Accessible on your local network (port 8888)
- **Use case**: Web UI, git clone, git push

## Prerequisites

1. k3d cluster and ArgoCD must be installed:
   ```bash
   cd ../p3
   make all
   ```

2. GitLab must be installed in the cluster:
   ```bash
   cd ../bonus
   make all
   ```

3. Add GitLab hostname to /etc/hosts:
   ```bash
   echo "127.0.0.1 gitlab.gitlab.local" | sudo tee -a /etc/hosts
   ```

## Deployment Options

### Option 1: Deploy with GitHub (Default - from p3)
```bash
cd ../p3
make argocd-deploy
```
- Uses: `https://github.com/Nakusu/owl-llepage-svolodin`
- No credentials needed (public repo)

### Option 2: Deploy with GitLab (Local - from bonus)
```bash
cd ../bonus
make argocd-deploy-gitlab
```
- Uses: `http://gitlab-webservice-default.gitlab.svc:8181/root/owl-llepage-svolodin.git`
- Credentials: Automatically configured
- This is the **recommended DevOps approach**

## Working with the GitLab Repository

### Clone the Repository
```bash
# Option 1: Clone with token (recommended)
git clone http://root:argocd-migration-2024-token@gitlab.gitlab.local:8888/root/owl-llepage-svolodin.git

# Option 2: Clone and configure credentials later
git clone http://gitlab.gitlab.local:8888/root/owl-llepage-svolodin.git
```

### Make Changes
```bash
cd owl-llepage-svolodin

# Make your changes to manifests
vim manifests/deployment.yaml

# Commit and push
git add .
git commit -m "Update deployment"
git push origin main
```

### ArgoCD Auto-Sync
ArgoCD will automatically detect changes and sync within seconds!

## Repository Credentials

- **Username**: `root`
- **Password/Token**: `argocd-migration-2024-token`
- **GitLab Root Password**: Run `cd ../bonus && make get-password`

## Accessing GitLab UI

### Via Web Browser
1. Open: http://gitlab.gitlab.local:8888
2. Username: `root`
3. Password: `Sup3rS3cur3P@ss!` (or run `cd ../bonus && make get-password`)

## Switching Between GitHub and GitLab

### Switch to GitLab
```bash
cd bonus
make argocd-deploy-gitlab
```

### Switch Back to GitHub
```bash
cd ../p3
make argocd-deploy
```

Both options are always available - just run the appropriate command from the right directory!

## Verification

### Check ArgoCD is Using GitLab
```bash
kubectl get application playground -n argocd -o jsonpath='{.spec.source.repoURL}'
```
Should return: `http://gitlab-webservice-default.gitlab.svc:8181/root/owl-llepage-svolodin.git`

### Check Application Status
```bash
cd ../p3
make argocd-status
```
Should show: `Synced` and `Healthy`

### Test GitLab Access
```bash
curl -s http://gitlab.gitlab.local:8888/api/v4/version \
  --header "PRIVATE-TOKEN: argocd-migration-2024-token"
```

## Security Notes

### What's Exposed?
- **Port 8888**: k3d LoadBalancer (accessible on local network)
  - GitLab web UI
  - ArgoCD web UI (via ingress)

### What's NOT Exposed?
- **Internal services**: Only accessible within the cluster
  - `gitlab-webservice-default.gitlab.svc:8181`
  - All pod-to-pod communication

### Why This is Secure DevOps
- ArgoCD never needs to access external networks to pull from GitLab
- All manifest pulls happen over internal Kubernetes DNS
- No credentials stored in public GitHub
- No reliance on external services for CD pipeline

## Troubleshooting

### ArgoCD Can't Pull from GitLab
```bash
# Recreate credentials (from bonus directory)
kubectl delete secret gitlab-repo-secret -n argocd
cd bonus
make argocd-gitlab-creds

# Check credentials
kubectl get secret gitlab-repo-secret -n argocd -o jsonpath='{.data.url}' | base64 -d
```

### Can't Access GitLab UI
```bash
# Check ingress
kubectl get ingress -n gitlab

# Verify /etc/hosts
grep gitlab.gitlab.local /etc/hosts

# Should see: 127.0.0.1 gitlab.gitlab.local
```

### Repository Not Found
```bash
# Verify repository exists in GitLab
curl -s http://gitlab.gitlab.local:8888/api/v4/projects/1 \
  --header "PRIVATE-TOKEN: argocd-migration-2024-token"
```

## Files

### GitLab Configuration (in bonus/)
- `bonus/src/confs/argocd-app-gitlab.yml` - ArgoCD Application (GitLab)
- `bonus/src/confs/argocd-app-project-gitlab.yml` - ArgoCD AppProject (GitLab)
- `bonus/GITLAB_SETUP.md` - This documentation

### GitHub Configuration (in p3/)
- `p3/src/confs/argocd-app.yml` - ArgoCD Application (GitHub - original)
- `p3/src/confs/argocd-app-project.yml` - ArgoCD AppProject (GitHub - original)

## Why This Setup is Production-Ready

1. **Service Discovery**: Uses Kubernetes DNS (`.svc` domains)
2. **No Port Forwarding**: All pod-to-pod communication is native
3. **Proper Separation**: Internal vs External access clearly defined
4. **Scalable**: Works the same in production with proper ingress controller
5. **Secure**: No external dependencies for critical CD pipeline
