# Troubleshooting: No Resources Created

If `helm install` completes but no resources are created in the cluster, check the following:

## 1. Check Helm Install Output

```bash
helm install my-openclaw ./openclaw --debug --dry-run
```

This will show you what resources would be created and any validation errors.

## 2. Verify Chart Structure

Ensure you have:
- `Chart.yaml` in the root directory
- `values.yaml` in the root directory  
- `templates/` directory with template files

## 3. Check for Validation Errors

```bash
# If helm is installed
helm lint ./openclaw

# Or check YAML syntax
yamllint Chart.yaml values.yaml
```

## 4. Verify Required Values

The chart requires:
- A valid image (default: `openclaw/openclaw:latest`)
- If using `existingSecret`, the secret must exist before installation
- If using `secret.enabled: true`, provide `secret.data` with base64-encoded values

## 5. Check Kubernetes API Access

```bash
kubectl cluster-info
kubectl get nodes
```

## 6. Common Issues

### Issue: ConfigMap with empty data
**Fixed**: ConfigMap now only creates if data is provided.

### Issue: Missing required secrets
**Solution**: Create the secret first:
```bash
kubectl create secret generic openclaw-secrets \
  --from-literal=ANTHROPIC_API_KEY=your-key
```

### Issue: Invalid YAML in templates
**Check**: All template files should have valid YAML syntax.

## 7. Debug Installation

```bash
# Install with verbose output
helm install my-openclaw ./openclaw --debug

# Check what was actually created
kubectl get all -l app.kubernetes.io/name=openclaw

# Check for events
kubectl get events --sort-by='.lastTimestamp'
```

## 8. Minimum Resources That Should Always Be Created

With default values, these resources should always be created:
- StatefulSet (1 replica)
- Service (ClusterIP)
- Service (headless, for StatefulSet)
- ServiceAccount (if `serviceAccount.create: true`)
- RBAC Role and RoleBinding (if `rbac.create: true`)

If none of these appear, there's likely a validation error preventing the chart from being processed.
