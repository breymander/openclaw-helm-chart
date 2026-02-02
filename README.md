# OpenClaw Helm Chart

A Helm chart for deploying [OpenClaw](https://github.com/openclaw/openclaw), an open-source personal AI assistant powered by Anthropic's Claude LLM.

## Overview

OpenClaw (formerly known as MoltBot/ClawdBot) is a personal, open-source AI assistant that functions as "Claude with hands." It can execute terminal commands, run scripts, browse the web, read/write files, control browsers, and retain memory across sessions. The project is written in TypeScript and is MIT-licensed.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- A valid Anthropic API key
- Persistent storage (if persistence is enabled)
- **NetworkPolicy support**: If using NetworkPolicies, your cluster must have a CNI plugin that supports NetworkPolicy (e.g., Calico, Cilium, Weave Net)

## Installation

### Add the Helm repository

```bash
helm repo add openclaw https://breymander.github.io/openclaw-helm-chart
helm repo update
```

**Note**: If you're installing from the GitHub repository directly, you can skip this step and install from the local chart directory.

**Dev / prerelease versions**: The repo publishes both stable (e.g. `0.1.0`) and dev (e.g. `0.1.0-dev`) chart versions. In **Rancher**, prerelease versions are hidden by default. To see them: click your user avatar → **Preferences** → under **Helm Charts**, enable **Include Prerelease Versions**. From the CLI, install a specific version with `helm install my-openclaw openclaw/openclaw --version 0.1.0-dev`.

### Secure Secret Management (REQUIRED)

**IMPORTANT**: Never put API keys or other secrets directly in `values.yaml` or pass them via `--set`. Always use Kubernetes Secrets.

#### Option 1: Create Secret First (Recommended)

The gateway requires **OPENCLAW_GATEWAY_TOKEN** (used to authenticate to the gateway / Control UI). Generate a random token, e.g. `openssl rand -hex 32`.

```bash
# Step 1: Create a Kubernetes Secret (API key + gateway token)
kubectl create secret generic openclaw-secrets \
  --from-literal=ANTHROPIC_API_KEY=your-api-key-here \
  --from-literal=OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32)

# Step 2: Install the chart referencing the existing secret
helm install my-openclaw ./openclaw \
  --set existingSecret.name=openclaw-secrets \
  --set existingSecret.keys.ANTHROPIC_API_KEY=ANTHROPIC_API_KEY \
  --set existingSecret.keys.OPENCLAW_GATEWAY_TOKEN=OPENCLAW_GATEWAY_TOKEN
```

Or use a values file:
```yaml
existingSecret:
  name: openclaw-secrets
  keys:
    ANTHROPIC_API_KEY: ANTHROPIC_API_KEY
    OPENCLAW_GATEWAY_TOKEN: OPENCLAW_GATEWAY_TOKEN  # gateway auth token (required)
```

#### Option 2: Use envFromSecret

```bash
# Create a Kubernetes Secret (include OPENCLAW_GATEWAY_TOKEN for gateway auth)
kubectl create secret generic openclaw-secrets \
  --from-literal=ANTHROPIC_API_KEY=your-api-key-here \
  --from-literal=OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32)

# Install with envFromSecret
helm install my-openclaw ./openclaw \
  --set envFromSecret[0].secretRef.name=openclaw-secrets
```

### Install the chart

```bash
# Install with custom values (after creating secrets)
helm install my-openclaw ./openclaw -f my-values.yaml

# Install from local chart
helm install my-openclaw ./
```

## Configuration

The following table lists the configurable parameters and their default values.

### Image Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Container image repository | `openclaw/openclaw` |
| `image.tag` | Container image tag | `latest` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |

### Environment Variables

#### Core Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `env.CLAUDE_MODEL` | Claude model to use | `claude-3-5-sonnet-20241022` |
| `env.PORT` | Service port | `18789` |
| `env.HOST` | Bind host | `0.0.0.0` |
| `existingSecret.name` | Name of existing Kubernetes Secret | `""` |
| `existingSecret.keys` | Map of env var names to secret keys (format: `envVarName: secretKeyName`) | `{}` |
| `env.PORT` | Service port | `18789` |
| `env.HOST` | Bind host | `0.0.0.0` |
| `env.LOG_LEVEL` | Logging level | `info` |
| `env.DATA_DIR` | Data directory path | `/data` |
| `env.MEMORY_ENABLED` | Enable memory persistence | `true` |

#### Extensibility

For future configuration options, you can use:

- `extraEnv`: Array of additional environment variables
- `envFromConfigMap`: Reference ConfigMaps for environment variables
- `envFromSecret`: Reference Secrets for environment variables

Example:

```yaml
extraEnv:
  - name: CUSTOM_VAR
    value: "custom-value"
  - name: SECRET_VAR
    valueFrom:
      secretKeyRef:
        name: my-secret
        key: secret-key

envFromConfigMap:
  - configMapRef:
      name: my-configmap

envFromSecret:
  - secretRef:
      name: my-secret
```

### Service Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Service port | `18789` |
| `service.annotations` | Service annotations | `{}` |

### Ingress Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.className` | Ingress class name | `""` |
| `ingress.annotations` | Ingress annotations | `{}` |
| `ingress.hosts` | Ingress hosts configuration | See values.yaml |
| `ingress.tls` | TLS configuration | `[]` |

### Persistence Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `persistence.enabled` | Enable persistent storage | `true` |
| `persistence.storageClass` | Storage class name | `""` |
| `persistence.accessMode` | Access mode | `ReadWriteOnce` |
| `persistence.size` | Storage size | `10Gi` |
| `persistence.annotations` | PVC annotations | `{}` |

### Resource Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources.limits.cpu` | CPU limit | `2000m` |
| `resources.limits.memory` | Memory limit | `4Gi` |
| `resources.requests.cpu` | CPU request | `500m` |
| `resources.requests.memory` | Memory request | `1Gi` |

### Gateway Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `gateway.controlUi.allowInsecureAuth` | Allow token-in-URL auth for Control UI (e.g. `?token=...`). With persistence: init merges into `/data/.openclaw/openclaw.json` (creates if missing). Without persistence: ephemeral config at `~/.openclaw/openclaw.json`. | `true` |
| `gateway.initImage` | Init container image; must have `sh` and `jq` (merge/create JSON). Default: `imega/jq:1.6`. | `imega/jq:1.6` |

### Security Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `serviceAccount.create` | Create service account | `true` |
| `serviceAccount.name` | Service account name | `""` |
| `rbac.create` | Create RBAC resources | `true` |
| `networkPolicy.enabled` | Enable network policy | `false` |
| `networkPolicy.allowDNS` | Allow DNS resolution (UDP/TCP port 53) | `true` |
| `networkPolicy.allowSameNamespace` | Allow traffic to/from same namespace | `false` |
| `networkPolicy.allowKubeSystem` | Allow traffic to kube-system namespace | `false` |
| `networkPolicy.allowedNamespaces` | Additional allowed namespaces (by label) | `[]` |
| `networkPolicy.allowedPods` | Additional allowed pods (by label) | `[]` |
| `networkPolicy.customEgressPorts` | Custom egress ports (HTTP/HTTPS, etc.) | `[]` |
| `podSecurityContext` | Pod security context | See values.yaml |
| `securityContext` | Container security context | See values.yaml |

### StatefulSet Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `1` |
| `updateStrategy.type` | Update strategy | `RollingUpdate` |
| `podManagementPolicy` | Pod management policy | `OrderedReady` |
| `replicaOverrides` | Per-replica configuration overrides | `{}` |

**Per-Replica Configuration**: When `replicaCount > 1`, you can configure different settings for each replica using `replicaOverrides`. Replica indices are 0-based (0 = first replica, 1 = second replica, etc.). Each replica will have access to a `STATEFULSET_REPLICA_INDEX` environment variable containing its index.

### Health Checks

| Parameter | Description | Default |
|-----------|-------------|---------|
| `livenessProbe.enabled` | Enable liveness probe | `true` |
| `livenessProbe.tcpSocket.port` | TCP port for liveness check | `18789` |
| `livenessProbe.initialDelaySeconds` | Initial delay | `30` |
| `readinessProbe.enabled` | Enable readiness probe | `true` |
| `readinessProbe.tcpSocket.port` | TCP port for readiness check | `18789` |
| `readinessProbe.initialDelaySeconds` | Initial delay | `10` |

**Note**: OpenClaw doesn't expose HTTP health check endpoints, so the chart uses TCP socket checks to verify the service is listening on port 18789.

## Examples

### Secure Installation with Existing Secret (Recommended)

First, create the secret:
```bash
kubectl create secret generic openclaw-secrets \
  --from-literal=ANTHROPIC_API_KEY=your-api-key-here
```

Then install with values.yaml:
```yaml
existingSecret:
  name: openclaw-secrets
  keys:
    ANTHROPIC_API_KEY: ANTHROPIC_API_KEY

env:
  CLAUDE_MODEL: "claude-3-5-sonnet-20241022"
  PORT: "18789"
```

**Note**: The format is `envVarName: secretKeyName`. If they're the same (most common case), you can use:
```yaml
existingSecret:
  name: openclaw-secrets
  keys:
    ANTHROPIC_API_KEY: ANTHROPIC_API_KEY  # env var name = secret key name
```

If the env var name differs from the secret key:
```yaml
existingSecret:
  name: openclaw-secrets
  keys:
    API_KEY: ANTHROPIC_API_KEY  # env var will be API_KEY, loads from secret key ANTHROPIC_API_KEY
```

### Using envFromSecret

Create the secret:
```bash
kubectl create secret generic openclaw-secrets \
  --from-literal=ANTHROPIC_API_KEY=your-api-key-here
```

Install with envFromSecret:
```yaml
envFromSecret:
  - secretRef:
      name: openclaw-secrets

env:
  CLAUDE_MODEL: "claude-3-5-sonnet-20241022"
```

### With Custom Storage

```yaml
persistence:
  enabled: true
  storageClass: "fast-ssd"
  size: 50Gi
```

### With Ingress

```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: openclaw.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: openclaw-tls
      hosts:
        - openclaw.example.com
```

### With Network Policy

#### Basic Network Policy (Allow DNS and Same Namespace)

```yaml
networkPolicy:
  enabled: true
  allowDNS: true
  allowSameNamespace: true
```

#### Network Policy with Custom Rules

```yaml
networkPolicy:
  enabled: true
  allowDNS: true
  allowSameNamespace: true
  allowKubeSystem: true  # For metrics, etc.
  allowedNamespaces:
    - matchLabels:
        name: monitoring
  customEgressPorts:
    - protocol: TCP
      port: 443  # HTTPS
    - protocol: TCP
      port: 80   # HTTP
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              name: monitoring
        - podSelector:
            matchLabels:
              app: prometheus
      ports:
        - protocol: TCP
          port: 9090
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: ingress-nginx
      ports:
        - protocol: TCP
          port: 18789
```

#### Restrictive Network Policy (Only DNS)

```yaml
networkPolicy:
  enabled: true
  allowDNS: true
  allowSameNamespace: false
  allowKubeSystem: false
  # Only DNS is allowed, all other traffic is blocked
```

### With Extra Environment Variables (Non-Sensitive)

```yaml
extraEnv:
  - name: EMAIL_SMTP_HOST
    value: "smtp.example.com"
  - name: EMAIL_SMTP_PORT
    value: "587"
```

### With Multiple Secrets

```bash
# Create secret with multiple keys
kubectl create secret generic openclaw-secrets \
  --from-literal=ANTHROPIC_API_KEY=your-api-key \
  --from-literal=TELEGRAM_BOT_TOKEN=your-telegram-token
```

```yaml
existingSecret:
  name: openclaw-secrets
  keys:
    ANTHROPIC_API_KEY: ANTHROPIC_API_KEY
    TELEGRAM_BOT_TOKEN: TELEGRAM_BOT_TOKEN
```

### With Per-Replica Configuration

When running multiple replicas, you can configure different settings for each replica:

```yaml
replicaCount: 3

replicaOverrides:
  # Configure replica 0 (first replica) as primary
  "0":
    env:
      REPLICA_ROLE: "primary"
      REPLICA_PRIORITY: "high"
  
  # Configure replica 1 (second replica) with different resources
  "1":
    env:
      REPLICA_ROLE: "secondary"
      CUSTOM_VAR: "replica-1-value"
    # Note: Resources, nodeSelector, tolerations, and affinity cannot be
    # different per replica in a single StatefulSet. For those, consider
    # using multiple StatefulSets or the application can use STATEFULSET_REPLICA_INDEX
    # to apply different logic internally.
  
  # Configure replica 2 (third replica)
  "2":
    env:
      REPLICA_ROLE: "secondary"
      CUSTOM_VAR: "replica-2-value"
```

**Note**: Each pod will have a `STATEFULSET_REPLICA_INDEX` environment variable (0, 1, 2, etc.) that your application can use to determine which replica it is and apply different logic accordingly. Per-replica ConfigMaps are automatically created and loaded via `envFrom`.

## Security Considerations

OpenClaw has powerful capabilities that require careful security configuration:

1. **API Keys and Secrets**: 
   - **NEVER** put API keys, passwords, or tokens directly in `values.yaml` or pass them via `--set`
   - **ALWAYS** use Kubernetes Secrets created separately
   - Use `existingSecret` (simpler) or `envFromSecret` to reference pre-created secrets
   - With `existingSecret`, use the format: `envVarName: secretKeyName` in the `keys` map
   - The chart's `secret.enabled` is set to `false` by default to prevent accidental secret exposure
   - For production, use external secret management tools (e.g., Sealed Secrets, External Secrets Operator, Vault)

2. **Network Security**: 
   - Enable NetworkPolicies to restrict pod communication and follow the principle of least privilege
   - The chart supports configurable NetworkPolicies with common use cases:
     - DNS resolution (enabled by default when NetworkPolicy is enabled)
     - Same namespace communication
     - kube-system access for metrics/monitoring
     - Custom namespace and pod selectors
     - Custom egress ports for external services
   - Consider using a service mesh for additional security
   - Be aware that default ports may be scanned by attackers
   - When NetworkPolicy is enabled, only explicitly allowed traffic is permitted

3. **RBAC**: The chart creates minimal RBAC by default. Adjust permissions based on your needs.

4. **Pod Security**: The chart includes security contexts with non-root user and dropped capabilities. Review and adjust based on your security requirements.

5. **Storage**: Ensure persistent volumes are properly secured and backed up.

## Troubleshooting

### Pod not starting

1. Check pod logs:
   ```bash
   kubectl logs -l app.kubernetes.io/name=openclaw
   ```

2. Verify API key is set in the secret:
   ```bash
   # If using existingSecret
   kubectl get secret <your-secret-name> -o jsonpath='{.data.ANTHROPIC_API_KEY}' | base64 -d
   
   # Or check if the secret exists
   kubectl get secrets
   ```

3. Check pod events:
   ```bash
   kubectl describe pod <pod-name>
   ```

### Persistent volume issues

1. Check PVC status:
   ```bash
   kubectl get pvc
   ```

2. Verify storage class exists:
   ```bash
   kubectl get storageclass
   ```

### Service not accessible

1. Check service endpoints:
   ```bash
   kubectl get endpoints openclaw
   ```

2. Verify service selector matches pod labels:
   ```bash
   kubectl get pods --show-labels
   kubectl get svc openclaw -o yaml
   ```

## Upgrading

```bash
# Upgrade with same values
helm upgrade my-openclaw ./openclaw

# Upgrade with new values
helm upgrade my-openclaw ./openclaw -f new-values.yaml

# Check upgrade status
helm status my-openclaw
```

## Uninstalling

```bash
helm uninstall my-openclaw
```

**Note**: This will delete all resources including persistent volumes. Make sure to backup data if needed.

## Contributing

Contributions are welcome! Please ensure that:

1. All environment variables are documented
2. Security best practices are followed
3. Tests are added for new features
4. Documentation is updated

## License

This Helm chart is provided as-is. OpenClaw itself is licensed under the MIT License.

## References

- [OpenClaw Helm Chart Repository](https://github.com/breymander/openclaw-helm-chart)
- [OpenClaw GitHub Repository](https://github.com/openclaw/openclaw)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
