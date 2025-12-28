# OptScale Helm Chart

A Helm chart for deploying OptScale - an open-source FinOps and cloud cost management platform.

## Prerequisites

- Kubernetes 1.23+
- Helm 3.0+
- NGINX Ingress Controller
- At least 8 CPU cores, 16GB RAM, 150GB storage

## Quick Start

### Option A: Use Official Hystax Images (Recommended for testing)

The fastest way to get started - no image building required!

```bash
# Create your values file from the template
cp helm-chart/optscale/values-hystax.yaml my-values.yaml

# Edit my-values.yaml with your settings (passwords, AWS credentials, etc.)

# Install
helm install optscale helm-chart/optscale -f my-values.yaml
```

### Option B: Build Your Own Images (For customization)

Build and push all OptScale images to your Docker Hub repository:

```bash
# Make the script executable
chmod +x build-all.sh

# Build and push all images
./build-all.sh v1.0.0

# Or use the advanced script
./build-and-push.sh -t v1.0.0

# Build only (no push)
./build-and-push.sh --build-only

# List available components
./build-and-push.sh --list
```

### Create Custom Values File

Create a `my-values.yaml` file with your configuration:

```yaml
global:
  # Use "hystax" for official images, or "akashkaveti" for your own
  imageRegistry: "hystax"
  imageTag: "latest"

cluster:
  publicIp: "optscale.yourdomain.com"
  companyName: "YourCompany"

secrets:
  clusterSecret: "your-unique-uuid-here"
  encryptionSalt: "your-encryption-salt"
  encryptionKey: "your-encryption-key"

# AWS credentials for cost recommendations
serviceCredentials:
  aws:
    enabled: true
    accessKeyId: "YOUR_AWS_ACCESS_KEY"
    secretAccessKey: "YOUR_AWS_SECRET_KEY"

# Database passwords (CHANGE THESE!)
mariadb:
  credentials:
    rootPassword: "secure-mariadb-password"

mongodb:
  credentials:
    password: "secure-mongodb-password"
    key: "secure-mongodb-key"

rabbitmq:
  credentials:
    password: "secure-rabbitmq-password"

# SMTP for email notifications
smtp:
  enabled: true
  server: "smtp.yourcompany.com"
  port: 587
  email: "optscale@yourcompany.com"
  login: "your-smtp-login"
  password: "your-smtp-password"
  protocol: "TLS"
```

### 3. Install the Chart

```bash
# Add the chart directory
cd helm-chart

# Install
helm install optscale ./optscale -f my-values.yaml

# Or install in a specific namespace
helm install optscale ./optscale -f my-values.yaml -n optscale --create-namespace
```

### 4. Verify Installation

```bash
# Check pods
kubectl get pods

# Check services
kubectl get svc

# Get ingress IP
kubectl get ingress
```

### 5. Access OptScale

Access the UI at `https://<your-public-ip>` or the domain you configured.

## Configuration

### Global Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.imageRegistry` | Docker registry for images | `akashkaveti` |
| `global.imageTag` | Default image tag | `latest` |
| `global.imagePullPolicy` | Image pull policy | `IfNotPresent` |

### Cluster Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `cluster.publicIp` | Public IP or domain | `""` |
| `cluster.companyName` | Company name for branding | `MyCompany` |
| `cluster.productName` | Product name | `OptScale` |

### Service Credentials (for cost recommendations)

| Parameter | Description |
|-----------|-------------|
| `serviceCredentials.aws.accessKeyId` | AWS Access Key ID |
| `serviceCredentials.aws.secretAccessKey` | AWS Secret Access Key |
| `serviceCredentials.azure.*` | Azure credentials |
| `serviceCredentials.gcp.*` | GCP credentials |

### Core Services

Each service can be enabled/disabled and configured:

```yaml
restApi:
  enabled: true
  replicaCount: 1
  resources:
    requests:
      memory: "512Mi"
      cpu: "250m"
```

### Database Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `mariadb.enabled` | Enable MariaDB | `true` |
| `mariadb.credentials.rootPassword` | Root password | `change-me` |
| `mongodb.enabled` | Enable MongoDB | `true` |
| `mongodb.credentials.password` | Password | `change-me` |
| `redis.enabled` | Enable Redis | `true` |

## Upgrading

```bash
helm upgrade optscale ./optscale -f my-values.yaml
```

## Uninstalling

```bash
helm uninstall optscale
```

## Architecture

OptScale consists of multiple microservices:

- **restapi** - Main REST API server
- **auth** - Authentication service
- **ngui** - Frontend UI (React)
- **diworker** - Data import worker (AWS, Azure, GCP, K8s)
- **herald** - Notification service
- **keeper** - Event tracking
- **bumi*** - Recommendation engine
- **insider** - Pricing data service
- **metroculus** - Metrics collection
- **katara** - Report generation

## Troubleshooting

### Pods not starting

Check init containers:
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name> -c wait-etcd
```

### Database connection issues

Verify secrets:
```bash
kubectl get secrets
kubectl describe secret optscale-mariadb
```

### Ingress not working

Check ingress controller:
```bash
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx <ingress-pod>
```

## License

Apache 2.0 - See [LICENSE](../LICENSE.md)
