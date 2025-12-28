# OptScale Helm Chart

A Helm chart for deploying OptScale - an open-source FinOps and cloud cost optimization platform.

## Prerequisites

- Kubernetes 1.21+
- Helm 3.0+
- Ingress controller (nginx recommended)
- cert-manager (for automatic TLS certificates)
- Persistent storage (for MongoDB, MariaDB, ClickHouse)

## Quick Start

```bash
# Add your values file
cp values-example.yaml values-myenv.yaml
# Edit values-myenv.yaml with your configuration

# Install
helm install optscale . -f values-myenv.yaml -n optscale --create-namespace
```

## Production Deployment

### 1. Create Values File

Create a values file for your environment (e.g., `values-production.yaml`):

```yaml
global:
  imageRegistry: "hystax"
  imageTag: "2025112701-public"

cluster:
  publicIp: "optscale.yourdomain.com"
  companyName: "Your Company"
  productName: "OptScale"

ssl:
  enabled: true
  certManager:
    enabled: true
    issuer: "your-cluster-issuer"
    issuerType: "cluster-issuer"

ingress:
  enabled: true
  className: "nginx"

# Generate secure passwords for production
secrets:
  clusterSecret: "your-secure-cluster-secret"
  encryptionSalt: "your-secure-salt"
  encryptionKey: "your-secure-key"

mariadb:
  credentials:
    rootPassword: "secure-mariadb-password"
  persistence:
    enabled: true
    hostPath: /data/optscale/mariadb

mongodb:
  credentials:
    username: "root"
    password: "secure-mongodb-password"
    key: "secure-mongodb-replica-key-min-6-chars"
  persistence:
    enabled: true
    hostPath: /data/optscale/mongodb

rabbitmq:
  credentials:
    username: "optscale"
    password: "secure-rabbitmq-password"
    cookie: "secure-erlang-cookie"
```

### 2. Deploy

```bash
helm install optscale . -f values-production.yaml -n optscale --create-namespace
```

### 3. Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n optscale

# Check services
kubectl get svc -n optscale

# Check ingress
kubectl get ingress -n optscale
```

## Architecture

The chart deploys the following components:

### Core Services
- **restapi** - REST API server
- **auth** - Authentication service
- **ngui** - Web UI (Next.js)
- **keeper** - Resource management
- **herald** - Notification service
- **diworker** - Data import worker
- **diproxy** - Data import proxy

### Databases
- **MariaDB** - Primary relational database
- **MongoDB** - Document store (replica set)
- **ClickHouse** - Analytics database
- **Redis** - Caching
- **InfluxDB** - Time series metrics
- **etcd** - Configuration store

### Message Queue
- **RabbitMQ** - Message broker

### Schedulers & Workers
- **bumi-scheduler/worker** - Recommendation engine
- **insider-scheduler/worker** - Pricing data
- **metroculus-scheduler/worker** - Metrics collection
- **katara-scheduler/worker** - Reports
- **report-import-scheduler** - Data import scheduling
- **risp-scheduler/worker** - Reserved instance analysis
- **gemini-scheduler/worker** - Duplicate detection
- **bi-scheduler/exporter** - Business intelligence

## Configuration

### SSL/TLS

The chart supports automatic TLS certificate management via cert-manager:

```yaml
ssl:
  enabled: true
  certManager:
    enabled: true
    issuer: "letsencrypt-prod"
    issuerType: "cluster-issuer"
```

### Persistence

For production, enable persistence for stateful services:

```yaml
mariadb:
  persistence:
    enabled: true
    hostPath: /data/optscale/mariadb

mongodb:
  persistence:
    enabled: true
    hostPath: /data/optscale/mongodb

clickhouse:
  persistence:
    enabled: true
    size: 50Gi

minio:
  persistence:
    enabled: true
    size: 20Gi
```

### AWS Integration

To connect AWS accounts for cost monitoring:

1. Create an AWS Cost and Usage Report (CUR) in your AWS account
2. Configure the CUR with:
   - Hourly time granularity
   - Resource IDs enabled
   - Parquet format recommended
3. Add the cloud account in OptScale UI with:
   - AWS Access Key ID
   - AWS Secret Access Key
   - S3 bucket name containing CUR
   - Report name/prefix

## Upgrading

```bash
helm upgrade optscale . -f values-production.yaml -n optscale
```

## Troubleshooting

### MongoDB Replica Set Issues

The chart automatically initializes the MongoDB replica set. If issues occur:

```bash
# Check MongoDB logs
kubectl logs -n optscale mongodb-0 -c mongodb
kubectl logs -n optscale mongodb-0 -c mongodb-init

# Verify replica set status
kubectl exec -it mongodb-0 -n optscale -c mongodb -- mongo --eval "rs.status()"
```

### Data Import Not Working

1. Check diworker logs:
```bash
kubectl logs -n optscale -l app=diworker
```

2. Verify RabbitMQ queues:
```bash
kubectl exec -it rabbitmq-0 -n optscale -- rabbitmqctl list_queues
```

3. Check report import status:
```bash
kubectl exec -it mariadb-0 -n optscale -- mysql -uroot -p<password> -e "SELECT * FROM \`my-db\`.reportimport ORDER BY created_at DESC LIMIT 5;"
```

### Configurator Job Fails

If the configurator job fails, check for stale etcd locks:

```bash
# List locks
kubectl exec -it etcd-0 -n optscale -- curl -s http://localhost:2379/v2/keys/_locks

# Delete stale locks if needed
kubectl exec -it etcd-0 -n optscale -- curl -s -X DELETE http://localhost:2379/v2/keys/_locks?recursive=true
```

## Uninstalling

```bash
helm uninstall optscale -n optscale
kubectl delete namespace optscale

# Clean up persistent data (if using hostPath)
# WARNING: This deletes all data!
rm -rf /data/optscale
```

## License

OptScale is licensed under Apache 2.0. See [LICENSE](../../LICENSE.md) for details.
