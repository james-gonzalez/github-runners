# github-runners

Self-hosted GitHub Actions runner for k8s homelab. Built on the official GitHub runner package — no third-party images.

## What it is

A Docker image + k8s manifest that runs the official GitHub Actions runner inside your cluster. Registers itself on startup, deregisters cleanly on shutdown.

**Image:** `ghcr.io/james-gonzalez/github-runners:latest`  
**Base:** `ubuntu:24.04` + official GitHub runner v2.333.0

## Deploy to k8s

**1. Get a registration token**

Go to: `https://github.com/james-gonzalez/<repo>/settings/actions/runners/new`

Copy the token from the `--token` flag. Tokens expire after 1 hour.

**2. Create the secret**
```bash
kubectl create secret generic github-runner-token \
  --namespace github-runners \
  --from-literal=token=YOUR_REGISTRATION_TOKEN \
  --from-literal=repo_url=https://github.com/james-gonzalez/your-repo
```

**3. Apply the manifest**
```bash
kubectl apply -f k8s/runner.yaml
```

**4. Verify**
```bash
kubectl get pods -n github-runners
kubectl logs -n github-runners deployment/github-runner -f
```

Runner appears at: `https://github.com/james-gonzalez/<repo>/settings/actions/runners`

## Use in a workflow

```yaml
jobs:
  deploy:
    runs-on: [self-hosted, k8s]
    steps:
      - name: Update deployment
        run: |
          kubectl set image deployment/my-app \
            app=ghcr.io/james-gonzalez/my-app:${{ github.sha }}
          kubectl rollout status deployment/my-app --timeout=120s
```

## Switching to a different repo

Update the secret and restart:
```bash
kubectl create secret generic github-runner-token \
  --namespace github-runners \
  --from-literal=token=NEW_TOKEN \
  --from-literal=repo_url=https://github.com/james-gonzalez/new-repo \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl rollout restart deployment/github-runner -n github-runners
```
