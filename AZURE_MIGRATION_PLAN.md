# Azure Migration Plan: Transaction Processing Workshop

## Executive Summary

This document outlines the complete architecture and implementation plan to migrate the Redis Transaction Processing Workshop from a local Docker-based environment to **Azure Container Apps** with **Azure Managed Redis (AMR)**, using **Azure Developer CLI (azd)** for deployment. The solution ensures each workshop student gets their own **fully isolated environment** with VNet integration and private endpoints, ensuring security and avoiding public endpoint limitations.

---

## Architecture: Full Isolation with VNet

### Deployment Time Breakdown

| Resource | Provisioning Time | Notes |
|----------|-------------------|-------|
| Virtual Network + Subnets | 1-2 minutes | |
| Private DNS Zones | 1-2 minutes | |
| **Azure Managed Redis** | **15-20 minutes** | 🐢 BIGGEST bottleneck |
| Private Endpoint (Redis) | 2-3 minutes | |
| Container Apps Environment | 3-5 minutes | VNet-integrated |
| Container Registry | 2-3 minutes | |
| Private Endpoint (ACR) | 2-3 minutes | |
| Container Apps (×5) | 2-3 minutes each | Including Redis Insight |
| Log Analytics | 1-2 minutes | |
| **Total per Student** | **~25-35 minutes** | Fully isolated |

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                           Azure Resource Group: rg-{envName}                             │
│                        (Each student gets unique envName, e.g., "workshop-alice")        │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                          │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                    Virtual Network: vnet-{envName}                                   │ │
│  │                    Address Space: 10.0.0.0/16                                        │ │
│  │                                                                                      │ │
│  │  ┌─────────────────────────────────────────────────────────────────────────────┐    │ │
│  │  │  Subnet: snet-container-apps (10.0.0.0/23) - Delegated to Container Apps    │    │ │
│  │  │                                                                              │    │ │
│  │  │  ┌──────────────────────────────────────────────────────────────────────┐   │    │ │
│  │  │  │              Container Apps Environment (Internal)                    │   │    │ │
│  │  │  │                                                                       │   │    │ │
│  │  │  │  ┌──────────┐ ┌──────────┐ ┌────────┐ ┌────────┐ ┌─────────────┐   │   │    │ │
│  │  │  │  │Generator │ │Processor │ │  API   │ │   UI   │ │Redis Insight│   │   │    │ │
│  │  │  │  │(Internal)│ │(Internal)│ │(Extern)│ │(Extern)│ │  (External) │   │   │    │ │
│  │  │  │  └────┬─────┘ └────┬─────┘ └───┬────┘ └───┬────┘ └──────┬──────┘   │   │    │ │
│  │  │  │       │            │           │          │             │          │   │    │ │
│  │  │  │       └────────────┴───────────┴──────────┴─────────────┘          │   │    │ │
│  │  │  │                                │                                       │   │    │ │
│  │  │  └────────────────────────────────┼───────────────────────────────────────┘   │    │ │
│  │  │                                   │                                           │    │ │
│  │  └───────────────────────────────────┼───────────────────────────────────────────┘    │ │
│  │                                      │                                                │ │
│  │  ┌───────────────────────────────────┼───────────────────────────────────────────┐    │ │
│  │  │  Subnet: snet-private-endpoints (10.0.2.0/24)                                 │    │ │
│  │  │                                   │                                           │    │ │
│  │  │    ┌──────────────────────────────▼────────────────────────────────────┐     │    │ │
│  │  │    │         Private Endpoint: pe-redis                                 │     │    │ │
│  │  │    │         ──────────────────────────────────────────                 │     │    │ │
│  │  │    │                              │                                     │     │    │ │
│  │  │    │                              ▼                                     │     │    │ │
│  │  │    │    ┌─────────────────────────────────────────────────────────┐    │     │    │ │
│  │  │    │    │          Azure Managed Redis (AMR)                      │    │     │    │ │
│  │  │    │    │          SKU: Balanced B3 (3GB) or B6 (6GB)             │    │     │    │ │
│  │  │    │    │          Cluster Policy: Enterprise                     │    │     │    │ │
│  │  │    │    │          Modules: RediSearch, RedisJSON, TimeSeries     │    │     │    │ │
│  │  │    │    │          Public Access: DISABLED                        │    │     │    │ │
│  │  │    │    └─────────────────────────────────────────────────────────┘    │     │    │ │
│  │  │    └───────────────────────────────────────────────────────────────────┘     │    │ │
│  │  │                                                                               │    │ │
│  │  │    ┌───────────────────────────────────────────────────────────────────┐     │    │ │
│  │  │    │         Private Endpoint: pe-acr                                   │     │    │ │
│  │  │    │         ──────────────────────────────────────                     │     │    │ │
│  │  │    │                              │                                     │     │    │ │
│  │  │    │                              ▼                                     │     │    │ │
│  │  │    │    ┌─────────────────────────────────────────────────────────┐    │     │    │ │
│  │  │    │    │          Azure Container Registry                       │    │     │    │ │
│  │  │    │    │          SKU: Premium (required for Private Endpoint)   │    │     │    │ │
│  │  │    │    │          Public Access: DISABLED                        │    │     │    │ │
│  │  │    │    └─────────────────────────────────────────────────────────┘    │     │    │ │
│  │  │    └───────────────────────────────────────────────────────────────────┘     │    │ │
│  │  │                                                                               │    │ │
│  │  └───────────────────────────────────────────────────────────────────────────────┘    │ │
│  │                                                                                       │ │
│  └───────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                            │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐  │
│  │  Private DNS Zones (linked to VNet)                                                  │  │
│  │  • privatelink.redis.cache.windows.net  → AMR private IP                            │  │
│  │  • privatelink.azurecr.io               → ACR private IP                            │  │
│  └─────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                            │
│  ┌──────────────────────────┐   ┌──────────────────────────┐                              │
│  │  User-Assigned Managed   │   │  Log Analytics Workspace │                              │
│  │  Identity (AcrPull)      │   │  (Monitoring & Logs)     │                              │
│  └──────────────────────────┘   └──────────────────────────┘                              │
│                                                                                            │
│           │                                                                                │
│           │  Internet Access (for students to reach UI)                                   │
│           ▼                                                                                │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐  │
│  │  Azure Application Gateway (Optional) OR Container Apps External Ingress            │  │
│  │  Public IP → Routes to UI/API Container Apps                                         │  │
│  └─────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                            │
└────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Networking Architecture (VNet with Private Endpoints)

### VNet Configuration

| Component | CIDR | Purpose |
|-----------|------|---------|
| **VNet** | `10.0.0.0/16` | Main virtual network |
| **snet-container-apps** | `10.0.0.0/23` | Container Apps Environment (min /23 required) |
| **snet-private-endpoints** | `10.0.2.0/24` | Private endpoints for AMR, ACR |

### Private Endpoints

| Service | Private Endpoint | DNS Zone |
|---------|-----------------|----------|
| Azure Managed Redis | `pe-redis-{envName}` | `privatelink.redis.cache.windows.net` |
| Azure Container Registry | `pe-acr-{envName}` | `privatelink.azurecr.io` |

### Ingress Configuration

| Service | Ingress Type | Access | Notes |
|---------|--------------|--------|-------|
| **UI** | External | ✅ Public | Students access via browser |
| **API** | External | ✅ Public | UI calls API (CORS configured) |
| **Generator** | None | ❌ Internal | Background worker |
| **Processor** | None | ❌ Internal | Background worker |

> **Note**: Container Apps can have external ingress while still being VNet-integrated. The apps connect to Redis/ACR via private endpoints, but expose HTTP endpoints publicly.

### Security Benefits

| Component | Security Mechanism |
|-----------|-------------------|
| **AMR** | Private endpoint only, no public access |
| **ACR** | Private endpoint only, Premium SKU required |
| **Container Apps** | VNet-integrated, outbound via VNet |
| **Secrets** | Key Vault with private endpoint (optional) |
| **TLS** | Managed certificates for external ingress |

---

## Current Architecture (Local Docker)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          Docker Compose                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐               │
│  │  Generator   │    │  Processor   │    │     API      │               │
│  │   (Python)   │    │   (Python)   │    │  (FastAPI)   │               │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘               │
│         │                   │                   │                        │
│         └───────────────────┼───────────────────┘                        │
│                             │                                            │
│                     ┌───────▼───────┐                                    │
│                     │ Redis Stack   │                                    │
│                     │  (localhost)  │                                    │
│                     │  Port: 6379   │                                    │
│                     └───────────────┘                                    │
│                                                                          │
│  ┌──────────────┐                                                        │
│  │      UI      │ ◄─────── Port 3001                                    │
│  │   (Nginx)    │                                                        │
│  └──────────────┘                                                        │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Current Components:
1. **Redis Stack** - Local Redis with JSON, Search, TimeSeries modules + **Redis Insight (port 8001)**
2. **Generator** - Produces fake transactions to Redis Streams
3. **Processor** - Consumes transactions, stores in various Redis data structures
4. **API** - FastAPI backend serving data to UI
5. **UI** - Static Nginx frontend (includes button to open Redis Insight)

---

## Redis Insight in Azure

### The Challenge

In local Docker, Redis Insight is bundled with the `redis/redis-stack` image on port 8001. In Azure:
- **Azure Managed Redis does NOT include Redis Insight**
- Redis Insight needs network access to AMR
- With private endpoints, only resources in the VNet can reach AMR

### The Solution: Redis Insight as Container App

Deploy Redis Insight as a **separate Container App** within the same VNet:

```
┌─────────────────────────────────────────────────────────────────────┐
│  Container Apps Environment (VNet-integrated)                        │
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐   │
│  │  UI (Nginx)  │  │  API         │  │  Redis Insight           │   │
│  │  External    │  │  External    │  │  External                │   │
│  │  Port 80     │  │  Port 80     │  │  Port 5540               │   │
│  └──────┬───────┘  └──────┬───────┘  └───────────┬──────────────┘   │
│         │                 │                       │                  │
│         │                 │    ┌──────────────────┘                  │
│         │                 │    │                                     │
│         │                 │    │  (connects via private endpoint)   │
│         │                 │    │                                     │
│         │                 │    ▼                                     │
│  ┌──────┴─────────────────┴────────────────────────────────────┐    │
│  │              Azure Managed Redis (Private Endpoint)          │    │
│  │              amr-xxx.redis.cache.windows.net:10000           │    │
│  └──────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```

### Redis Insight Container App Configuration

```bicep
module redisInsight 'modules/container-app.bicep' = {
  scope: rg
  name: 'redisinsight'
  params: {
    name: 'ca-redisinsight-${environmentName}'
    location: location
    environmentId: cae.outputs.id
    identityId: identity.outputs.id
    // Use official Redis Insight image
    image: 'redis/redisinsight:latest'
    external: true  // Students need to access from browser
    targetPort: 5540
    env: [
      // Pre-configure connection to AMR
      { name: 'RI_PROXY_PATH', value: '/' }
    ]
  }
}
```

### UI Code Changes

Update the Redis Insight button URL to point to the Container App:

**File: `ui/js/app.js`**
```javascript
// Before (local Docker)
insightBtn.onclick = () => window.open('http://localhost:8001', '_blank');

// After (Azure - dynamic URL)
const REDIS_INSIGHT_URL = window.REDIS_INSIGHT_URL || 'http://localhost:8001';
insightBtn.onclick = () => window.open(REDIS_INSIGHT_URL, '_blank');
```

**File: `ui/docker-entrypoint.sh`**
```bash
#!/bin/sh
cat > /usr/share/nginx/html/config.js << EOF
window.API_BASE_URL = '${API_URL:-http://localhost:8000}';
window.REDIS_INSIGHT_URL = '${REDIS_INSIGHT_URL:-http://localhost:8001}';
EOF
exec "$@"
```

### First-Time Redis Insight Setup

When students first open Redis Insight, they'll need to add the AMR connection:

1. Open Redis Insight URL from the UI button
2. Click "Add Redis Database"
3. Enter connection details:
   - **Host**: `amr-xxx.redis.cache.windows.net` (from private DNS)
   - **Port**: `10000`
   - **Password**: Access key (provided via env var or shown in workshop instructions)
   - **TLS**: Enabled

> 💡 **Tip**: We can pre-configure the connection using Redis Insight's auto-discovery or environment variables to simplify student setup.

---

## Target Architecture (Azure with VNet)

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                           Azure Resource Group: rg-{envName}                             │
│                        (Each student gets unique envName, e.g., "workshop-alice")        │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                          │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                    Virtual Network: vnet-{envName} (10.0.0.0/16)                     │ │
│  │                                                                                      │ │
│  │  ┌───────────────────────────────────────────────────────────────────────────────┐  │ │
│  │  │  snet-container-apps (10.0.0.0/23) - Container Apps Environment               │  │ │
│  │  │                                                                                │  │ │
│  │  │  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐            │  │ │
│  │  │  │   ca-generator   │  │   ca-processor   │  │     ca-api       │            │  │ │
│  │  │  │    (Python)      │  │    (Python)      │  │   (FastAPI)      │            │  │ │
│  │  │  │   Scale: 1       │  │   Scale: 1       │  │   Scale: 1-3     │            │  │ │
│  │  │  │   Internal       │  │   Internal       │  │   External*      │            │  │ │
│  │  │  └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘            │  │ │
│  │  │           │                     │                     │                       │  │ │
│  │  │  ┌──────────────────┐          │                     │                       │  │ │
│  │  │  │     ca-ui        │          │                     │                       │  │ │
│  │  │  │   (Nginx)        │◄─────────┼─────────────────────┘                       │  │ │
│  │  │  │   External*      │          │  * External ingress with public URL         │  │ │
│  │  │  └────────┬─────────┘          │    but backend traffic stays in VNet        │  │ │
│  │  │           │                    │                                              │  │ │
│  │  └───────────┼────────────────────┼──────────────────────────────────────────────┘  │ │
│  │              │                    │                                                  │ │
│  │  ┌───────────┼────────────────────┼──────────────────────────────────────────────┐  │ │
│  │  │  snet-private-endpoints (10.0.2.0/24)                                         │  │ │
│  │  │           │                    │                                              │  │ │
│  │  │           └────────────────────┼──────────────┐                               │  │ │
│  │  │                                │              │                               │  │ │
│  │  │    ┌───────────────────────────▼───────┐     │                               │  │ │
│  │  │    │  Private Endpoint: pe-redis       │     │                               │  │ │
│  │  │    │  ─────────────────────────────    │     │                               │  │ │
│  │  │    │              │                    │     │                               │  │ │
│  │  │    │              ▼                    │     │                               │  │ │
│  │  │    │  ┌────────────────────────────┐   │     │                               │  │ │
│  │  │    │  │  Azure Managed Redis (AMR) │   │     │                               │  │ │
│  │  │    │  │  SKU: Balanced B3 (3GB)    │   │     │                               │  │ │
│  │  │    │  │  Cluster: Enterprise       │   │     │                               │  │ │
│  │  │    │  │  Port: 10000 (TLS)         │   │     │                               │  │ │
│  │  │    │  │  Public Access: DISABLED   │   │     │                               │  │ │
│  │  │    │  └────────────────────────────┘   │     │                               │  │ │
│  │  │    └───────────────────────────────────┘     │                               │  │ │
│  │  │                                              │                               │  │ │
│  │  │    ┌─────────────────────────────────────────▼──────┐                        │  │ │
│  │  │    │  Private Endpoint: pe-acr                      │                        │  │ │
│  │  │    │  ──────────────────────────────────            │                        │  │ │
│  │  │    │              │                                 │                        │  │ │
│  │  │    │              ▼                                 │                        │  │ │
│  │  │    │  ┌────────────────────────────────────────┐   │                        │  │ │
│  │  │    │  │  Azure Container Registry (Premium)    │   │                        │  │ │
│  │  │    │  │  acr{token}.azurecr.io                 │   │                        │  │ │
│  │  │    │  │  Public Access: DISABLED               │   │                        │  │ │
│  │  │    │  └────────────────────────────────────────┘   │                        │  │ │
│  │  │    └────────────────────────────────────────────────┘                        │  │ │
│  │  │                                                                               │  │ │
│  │  └───────────────────────────────────────────────────────────────────────────────┘  │ │
│  │                                                                                      │ │
│  └──────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                          │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │
│  │  Private DNS Zones (linked to VNet)                                                  │ │
│  │  • privatelink.redis.cache.windows.net  → pe-redis private IP                       │ │
│  │  • privatelink.azurecr.io               → pe-acr private IP                         │ │
│  └─────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                          │
│  ┌─────────────────────────────┐  ┌─────────────────────────────────────────────────┐   │
│  │  User-Assigned Managed ID   │  │  Azure Log Analytics Workspace                  │   │
│  │  (AcrPull role)             │  │  (for monitoring & diagnostics)                 │   │
│  └─────────────────────────────┘  └─────────────────────────────────────────────────┘   │
│                                                                                          │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Student Isolation Strategy

### Naming Convention
Each student deployment uses a unique **environment name** that becomes part of all Azure resource names:

```
Environment Name: workshop-{studentId}   (e.g., workshop-alice, workshop-bob)
Resource Group:   rg-workshop-{studentId}
Resource Token:   uniqueString(subscription().id, resourceGroup().id, location, environmentName)
```

### Resource Naming Pattern
| Resource | Naming Pattern | Example |
|----------|----------------|---------|
| Resource Group | `rg-{envName}` | `rg-workshop-alice` |
| Container Registry | `acr{resourceToken}` | `acrxyz123abc` |
| Managed Identity | `id-{envName}` | `id-workshop-alice` |
| Redis Cache | `amr{resourceToken}` | `amrxyz123abc` |
| Container Apps Env | `cae-{envName}` | `cae-workshop-alice` |
| Generator App | `ca-generator-{envName}` | `ca-generator-workshop-alice` |
| Processor App | `ca-processor-{envName}` | `ca-processor-workshop-alice` |
| API App | `ca-api-{envName}` | `ca-api-workshop-alice` |
| UI App | `ca-ui-{envName}` | `ca-ui-workshop-alice` |
| Log Analytics | `log-{envName}` | `log-workshop-alice` |

---

## Azure Managed Redis Configuration

### Why Azure Managed Redis (not Azure Cache for Redis)?
- **Full Redis Stack support**: JSON, Search, TimeSeries, Probabilistic data structures
- **RediSearch module**: Required for vector search functionality (needs **minimum 3GB RAM**)
- **RedisJSON module**: Required for JSON document storage
- **RedisTimeSeries**: Required for time-series analytics
- **Redis Enterprise stack**: Multi-vCPU support for better performance

### Azure Managed Redis SKU Tiers

| Tier | Prefix | Memory:vCPU Ratio | Best For |
|------|--------|-------------------|----------|
| **Memory Optimized** | M | 8:1 | Dev/test, memory-heavy workloads |
| **Balanced** | B | 4:1 | Standard workloads (recommended) |
| **Compute Optimized** | X | 2:1 | High-throughput workloads |
| **Flash Optimized** | A | NVMe+RAM | Large datasets (⚠️ NO Search support) |

### Recommended SKU for Workshop

| SKU | Memory | vCPUs | Use Case |
|-----|--------|-------|----------|
| **B3** | 3 GB | 1 | Minimum for RediSearch - single student dev/test |
| **B6** | 6 GB | 2 | Recommended - comfortable headroom |
| **M12** | 12 GB | 2 | Budget option with more memory |

**Workshop Recommendation: `Balanced_B3` or `Balanced_B6`**

- **SKU Name**: `Balanced_B3` (3GB) or `Balanced_B6` (6GB)
- **Redis Version**: 7.4.x (latest with all modules)
- **TLS**: Enabled (port 10000)
- **Modules**: RedisJSON, RediSearch, RedisTimeSeries, RedisBloom (all included)

### Cluster Policy Selection

| Policy | Description | RediSearch Support |
|--------|-------------|-------------------|
| **OSS Cluster** | Redis OSS cluster protocol, higher throughput | ❌ **NOT supported** |
| **Enterprise Cluster** | Single endpoint, simpler client config | ✅ **Required for Search** |
| **Non-Clustered** | No sharding, ≤25GB only | ✅ Supported |

**Workshop Recommendation: `Enterprise`** (REQUIRED)

> ⚠️ **CRITICAL**: **RediSearch module ONLY works with Enterprise clustering policy!**
> 
> OSS cluster policy does NOT support RediSearch. Since this workshop uses vector search, we MUST use Enterprise cluster policy.

**Why Enterprise Cluster is required:**
- ✅ RediSearch/Vector Search support (required for Module 5)
- ✅ RedisJSON support
- ✅ RedisTimeSeries support  
- ✅ Single endpoint - simpler connection configuration
- ✅ No need for Redis Cluster-aware client
- ⚠️ Trade-off: Single proxy can be bottleneck (acceptable for workshop)

**Multi-key command limitations with Enterprise:**
- Allowed across slots: `DEL`, `MSET`, `MGET`, `EXISTS`, `UNLINK`, `TOUCH`
- Other multi-key commands require same hash slot

> ⚠️ **Important**: Cluster policy cannot be changed after creation (except NonCluster → Clustered)

### Connection Configuration
```python
# Environment variables for Azure Managed Redis
REDIS_HOST=amr{token}.redis.cache.windows.net
REDIS_PORT=10000  # Azure Managed Redis default port
REDIS_PASSWORD=<access-key>  # From Key Vault secret
REDIS_SSL=true
```

---

## Implementation Phases (Full Isolation with VNet)

### Phase 1: Infrastructure Setup

**Each student deploys their own complete, isolated environment.**

#### Infrastructure Files Structure:
```
infra/
├── main.bicep                 # Main deployment orchestration
├── main.parameters.json       # Parameters file for azd
├── abbreviations.json         # Resource naming abbreviations
└── modules/
    ├── virtual-network.bicep          # VNet + Subnets
    ├── private-dns-zones.bicep        # DNS zones for private endpoints
    ├── container-registry.bicep       # ACR (Premium for private endpoint)
    ├── redis-enterprise.bicep         # Azure Managed Redis
    ├── private-endpoint.bicep         # Generic PE module
    ├── container-apps-environment.bicep  # CAE with VNet integration
    ├── container-app.bicep            # Individual container app
    ├── managed-identity.bicep         # User-assigned identity
    └── log-analytics.bicep            # Monitoring
```

#### Student Deployment Commands:
```bash
# 1. Clone repo
git clone <repo-url>
cd workshop-transaction-processing

# 2. Login to Azure
azd auth login

# 3. Initialize YOUR unique environment
azd init -e workshop-yourname

# 4. Deploy everything (~25-35 min)
azd up

# This provisions:
# - VNet with 2 subnets
# - Private DNS zones
# - Azure Managed Redis (B3) with private endpoint
# - Azure Container Registry (Premium) with private endpoint
# - Container Apps Environment (VNet-integrated)
# - 4 Container Apps (generator, processor, api, ui)
# - Log Analytics workspace
# - Managed Identity

# 5. Get your URLs
azd show
# UI:  https://ca-ui-workshop-yourname.<region>.azurecontainerapps.io
# API: https://ca-api-workshop-yourname.<region>.azurecontainerapps.io

# 6. After workshop - clean up (deletes everything)
azd down --purge
```

---

### Phase 2: Application Code Changes

#### 2.1 Redis Client Updates (SSL + Password)

**File: `lib/redis_client.py`**
```python
import os
import redis

_redis_client = None

def get_redis() -> redis.Redis:
    global _redis_client
    if _redis_client is not None:
        return _redis_client

    host = os.getenv("REDIS_HOST", "localhost")
    port = int(os.getenv("REDIS_PORT", "6379"))
    password = os.getenv("REDIS_PASSWORD", None)
    ssl_enabled = os.getenv("REDIS_SSL", "false").lower() == "true"

    pool = redis.ConnectionPool(
        host=host,
        port=port,
        password=password,
        ssl=ssl_enabled,
        ssl_cert_reqs=None if ssl_enabled else None,
        decode_responses=True,
        max_connections=10,
        socket_connect_timeout=30,  # Longer timeout for private endpoint
        socket_keepalive=True,
        retry_on_timeout=True,
    )
    _redis_client = redis.Redis(connection_pool=pool)
    return _redis_client
```

#### 2.2 UI Configuration Updates

**File: `ui/js/app.js`**
```javascript
// Dynamic API URL (injected at container startup)
const API_BASE = window.API_BASE_URL || 'http://localhost:8000';
```

**File: `ui/docker-entrypoint.sh`**
```bash
#!/bin/sh
# Generate config.js with API URL
cat > /usr/share/nginx/html/config.js << EOF
window.API_BASE_URL = '${API_URL:-http://localhost:8000}';
EOF
exec "$@"
```

---

### Phase 3: Infrastructure Files (Bicep)

#### Main Bicep Template (infra/main.bicep)
```bicep
targetScope = 'subscription'

param environmentName string
param location string

var resourceToken = uniqueString(subscription().id, location, environmentName)

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: { 'azd-env-name': environmentName }
}

// Virtual Network
module vnet 'modules/virtual-network.bicep' = {
  scope: rg
  name: 'vnet'
  params: {
    name: 'vnet-${environmentName}'
    location: location
    addressPrefix: '10.0.0.0/16'
    subnets: [
      {
        name: 'snet-container-apps'
        addressPrefix: '10.0.0.0/23'
        delegations: [
          {
            name: 'Microsoft.App/environments'
            properties: {
              serviceName: 'Microsoft.App/environments'
            }
          }
        ]
      }
      {
        name: 'snet-private-endpoints'
        addressPrefix: '10.0.2.0/24'
      }
    ]
  }
}

// Private DNS Zones
module dnsZoneRedis 'modules/private-dns-zone.bicep' = {
  scope: rg
  name: 'dnsZoneRedis'
  params: {
    name: 'privatelink.redis.cache.windows.net'
    vnetId: vnet.outputs.id
  }
}

module dnsZoneAcr 'modules/private-dns-zone.bicep' = {
  scope: rg
  name: 'dnsZoneAcr'
  params: {
    name: 'privatelink.azurecr.io'
    vnetId: vnet.outputs.id
  }
}

// Azure Container Registry (Premium for Private Endpoint)
module acr 'modules/container-registry.bicep' = {
  scope: rg
  name: 'acr'
  params: {
    name: 'acr${resourceToken}'
    location: location
    sku: 'Premium'  // Required for private endpoint
    publicNetworkAccess: 'Disabled'
  }
}

// ACR Private Endpoint
module acrPe 'modules/private-endpoint.bicep' = {
  scope: rg
  name: 'acrPe'
  params: {
    name: 'pe-acr-${environmentName}'
    location: location
    subnetId: vnet.outputs.subnets[1].id  // snet-private-endpoints
    privateLinkServiceId: acr.outputs.id
    groupIds: ['registry']
    privateDnsZoneId: dnsZoneAcr.outputs.id
  }
}

// Azure Managed Redis
module redis 'modules/redis-enterprise.bicep' = {
  scope: rg
  name: 'redis'
  params: {
    name: 'amr${resourceToken}'
    location: location
    skuName: 'Balanced_B3'  // 3GB minimum for RediSearch
    clusteringPolicy: 'EnterpriseCluster'  // REQUIRED for RediSearch
    publicNetworkAccess: 'Disabled'
  }
}

// Redis Private Endpoint
module redisPe 'modules/private-endpoint.bicep' = {
  scope: rg
  name: 'redisPe'
  params: {
    name: 'pe-redis-${environmentName}'
    location: location
    subnetId: vnet.outputs.subnets[1].id  // snet-private-endpoints
    privateLinkServiceId: redis.outputs.id
    groupIds: ['redisEnterprise']
    privateDnsZoneId: dnsZoneRedis.outputs.id
  }
}

// Log Analytics
module logAnalytics 'modules/log-analytics.bicep' = {
  scope: rg
  name: 'logAnalytics'
  params: {
    name: 'log-${environmentName}'
    location: location
  }
}

// Container Apps Environment (VNet-integrated)
module cae 'modules/container-apps-environment.bicep' = {
  scope: rg
  name: 'cae'
  params: {
    name: 'cae-${environmentName}'
    location: location
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
    subnetId: vnet.outputs.subnets[0].id  // snet-container-apps
    internal: false  // External ingress allowed for UI/API
  }
}

// Managed Identity
module identity 'modules/managed-identity.bicep' = {
  scope: rg
  name: 'identity'
  params: {
    name: 'id-${environmentName}'
    location: location
  }
}

// ACR Pull Role Assignment
module acrPullRole 'modules/acr-role-assignment.bicep' = {
  scope: rg
  name: 'acrPullRole'
  params: {
    acrName: acr.outputs.name
    principalId: identity.outputs.principalId
  }
}

// Container Apps
module generator 'modules/container-app.bicep' = {
  scope: rg
  name: 'generator'
  params: {
    name: 'ca-generator-${environmentName}'
    location: location
    environmentId: cae.outputs.id
    identityId: identity.outputs.id
    acrLoginServer: acr.outputs.loginServer
    imageName: 'generator:latest'
    external: false
    env: [
      { name: 'REDIS_HOST', value: redis.outputs.hostName }
      { name: 'REDIS_PORT', value: '10000' }
      { name: 'REDIS_SSL', value: 'true' }
      { name: 'REDIS_PASSWORD', secretRef: 'redis-password' }
    ]
    secrets: [
      { name: 'redis-password', value: redis.outputs.primaryKey }
    ]
  }
}

// ... similar for processor, api, ui apps

output UI_URL string = ui.outputs.fqdn
output API_URL string = api.outputs.fqdn
output REDIS_HOST string = redis.outputs.hostName
```

#### VNet Module (infra/modules/virtual-network.bicep)
```bicep
param name string
param location string
param addressPrefix string
param subnets array

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [addressPrefix]
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        delegations: contains(subnet, 'delegations') ? subnet.delegations : []
        privateEndpointNetworkPolicies: 'Disabled'
      }
    }]
  }
}

output id string = vnet.id
output subnets array = vnet.properties.subnets
```

#### Private Endpoint Module (infra/modules/private-endpoint.bicep)
```bicep
param name string
param location string
param subnetId string
param privateLinkServiceId string
param groupIds array
param privateDnsZoneId string

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: name
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${name}-connection'
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: groupIds
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

output id string = privateEndpoint.id
output ipAddress string = privateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
```

#### Redis Enterprise Module (infra/modules/redis-enterprise.bicep)
```bicep
param name string
param location string
param skuName string = 'Balanced_B3'
param clusteringPolicy string = 'EnterpriseCluster'
param publicNetworkAccess string = 'Disabled'

resource redisEnterprise 'Microsoft.Cache/redisEnterprise@2024-02-01' = {
  name: name
  location: location
  sku: {
    name: skuName
  }
  properties: {
    minimumTlsVersion: '1.2'
  }
}

resource database 'Microsoft.Cache/redisEnterprise/databases@2024-02-01' = {
  parent: redisEnterprise
  name: 'default'
  properties: {
    clientProtocol: 'Encrypted'
    port: 10000
    clusteringPolicy: clusteringPolicy
    evictionPolicy: 'NoEviction'
    modules: [
      { name: 'RediSearch' }
      { name: 'RedisJSON' }
      { name: 'RedisTimeSeries' }
      { name: 'RedisBloom' }
    ]
  }
}

output id string = redisEnterprise.id
output hostName string = redisEnterprise.properties.hostName
output primaryKey string = database.listKeys().primaryKey
```

---

### Phase 4: Azure Developer CLI (azd) Setup

#### azure.yaml
```yaml
name: redis-transaction-workshop
metadata:
  template: redis-transaction-workshop@1.0.0

infra:
  provider: bicep
  path: ./infra

services:
  generator:
    project: ./generator
    host: containerapp
    language: python
    docker:
      path: ./generator/Dockerfile
      context: .

  processor:
    project: ./processor
    host: containerapp
    language: python
    docker:
      path: ./processor/Dockerfile
      context: .

  api:
    project: ./api
    host: containerapp
    language: python
    docker:
      path: ./api/Dockerfile
      context: .

  ui:
    project: ./ui
    host: containerapp
    language: js
    docker:
      path: ./ui/Dockerfile
      context: ./ui

hooks:
  postprovision:
    shell: sh
    run: |
      echo "============================================="
      echo "WORKSHOP ENVIRONMENT READY!"
      echo "============================================="
      echo "UI URL:  ${SERVICE_UI_ENDPOINT}"
      echo "API URL: ${SERVICE_API_ENDPOINT}"
      echo ""
      echo "Redis (private): ${REDIS_HOST}:10000"
      echo "============================================="
```

#### Student Workflow

```bash
# 1. Clone the repository
git clone <repo-url>
cd workshop-transaction-processing

# 2. Login to Azure
azd auth login

# 3. Initialize your unique environment (use your name!)
azd init -e workshop-yourname

# 4. Deploy everything (~25-35 min first time)
azd up

# 5. After making code changes, redeploy:
azd deploy processor  # Deploy specific service
azd deploy            # Deploy all services

# 6. Clean up when done
azd down --purge
```

---

### Phase 5: Easy Update Strategy

#### Deployment Stages Support

Students can deploy in stages to validate their code:

```bash
# Deploy infrastructure only
azd provision

# Deploy specific service after code changes
azd deploy api

# Deploy all services
azd deploy

# Full redeploy
azd up
```

#### Hot Reload Alternative (Development Mode)

For active development, students can:
1. Use local Docker for rapid iteration
2. Point local containers to Azure Managed Redis (via VPN/bastion if private only)
3. Only deploy to Container Apps for final testing

```bash
# Start local containers (local Redis for dev)
docker compose up

# Or connect to Azure Redis if you have network access
REDIS_HOST=amr{token}.redis.cache.windows.net \
REDIS_PORT=10000 \
REDIS_PASSWORD={key} \
REDIS_SSL=true \
docker compose up
```

---

## File Changes Summary

### New Files to Create:

| File | Purpose |
|------|---------|
| `azure.yaml` | azd project configuration |
| `infra/main.bicep` | Main Bicep template |
| `infra/main.parameters.json` | Bicep parameters |
| `infra/abbreviations.json` | Naming abbreviations |
| `infra/modules/virtual-network.bicep` | VNet + Subnets |
| `infra/modules/private-dns-zone.bicep` | Private DNS zones |
| `infra/modules/private-endpoint.bicep` | Generic PE module |
| `infra/modules/container-registry.bicep` | ACR (Premium) |
| `infra/modules/redis-enterprise.bicep` | Azure Managed Redis |
| `infra/modules/container-apps-environment.bicep` | CAE with VNet |
| `infra/modules/container-app.bicep` | Container app |
| `infra/modules/managed-identity.bicep` | User-assigned ID |
| `infra/modules/log-analytics.bicep` | Monitoring |
| `.azure/config.json` | azd environment config |
| `ui/nginx.conf` | Custom Nginx config for env injection |
| `ui/docker-entrypoint.sh` | UI startup script |

### Files to Modify:

| File | Changes |
|------|---------|
| `lib/redis_client.py` | Add SSL support, password auth |
| `ui/js/app.js` | Dynamic API_BASE configuration |
| `api/Dockerfile` | Production optimizations |
| `processor/Dockerfile` | Production optimizations |
| `generator/Dockerfile` | Production optimizations |
| `ui/Dockerfile` | Add nginx config, env injection |
| `docker-compose.yml` | Add Azure Redis connection option |
| `README.md` | Add Azure deployment instructions |

---

## Detailed Implementation Steps

### Step 1: Create Bicep Infrastructure

```bicep
// infra/main.bicep - Key structure
targetScope = 'subscription'

param environmentName string
param location string

var resourceToken = uniqueString(subscription().id, location, environmentName)
var resourceGroupName = 'rg-${environmentName}'

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: {
    'azd-env-name': environmentName
  }
}

// Deploy all modules to resource group
module resources './modules/all-resources.bicep' = {
  scope: rg
  name: 'resources'
  params: {
    environmentName: environmentName
    location: location
    resourceToken: resourceToken
  }
}
```

### Step 2: Update Redis Client

```python
# lib/redis_client.py - Updated version
def get_redis() -> redis.Redis:
    global _redis_client
    if _redis_client is not None:
        return _redis_client

    host = os.getenv("REDIS_HOST", "localhost")
    port = int(os.getenv("REDIS_PORT", "6379"))
    password = os.getenv("REDIS_PASSWORD", None)
    ssl_enabled = os.getenv("REDIS_SSL", "false").lower() == "true"

    pool = redis.ConnectionPool(
        host=host,
        port=port,
        password=password,
        ssl=ssl_enabled,
        ssl_cert_reqs=None if ssl_enabled else None,
        decode_responses=True,
        max_connections=10,
        socket_keepalive=True,
        socket_connect_timeout=10,
        retry_on_timeout=True,
    )
    _redis_client = redis.Redis(connection_pool=pool)
    return _redis_client
```

### Step 3: Create azure.yaml

```yaml
# azure.yaml
name: redis-transaction-workshop
metadata:
  template: redis-transaction-workshop@1.0.0

infra:
  provider: bicep
  path: infra

services:
  generator:
    project: ./generator
    host: containerapp
    language: python
    docker:
      path: ./generator/Dockerfile
      context: .

  processor:
    project: ./processor
    host: containerapp
    language: python
    docker:
      path: ./processor/Dockerfile
      context: .

  api:
    project: ./api
    host: containerapp
    language: python
    docker:
      path: ./api/Dockerfile
      context: .

  ui:
    project: ./ui
    host: containerapp
    language: js
    docker:
      path: ./ui/Dockerfile
      context: ./ui
```

### Step 4: Update UI for Dynamic API URL

```dockerfile
# ui/Dockerfile - Updated
FROM nginx:alpine

# Copy UI files
COPY . /usr/share/nginx/html/

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy entrypoint script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
```

```bash
# ui/docker-entrypoint.sh
#!/bin/sh
# Generate config.js with API URL
cat > /usr/share/nginx/html/config.js << EOF
window.API_BASE_URL = '${API_URL:-http://localhost:8000}';
EOF
exec "$@"
```

---

## Workshop Student Guide (Quick Start)

### Prerequisites
- Azure subscription with Contributor access
- Azure CLI installed (`az --version`)
- Azure Developer CLI installed (`azd version`)
- Docker installed (`docker --version`)

### Deployment Steps

```bash
# 1. Clone the repository
git clone https://github.com/Redislabs-Solution-Architects/workshop-transaction-processing.git
cd workshop-transaction-processing

# 2. Login to Azure
azd auth login

# 3. Create your unique environment (use your name/id)
azd init -e workshop-yourname

# 4. Deploy to Azure (takes ~25-35 minutes first time)
#    This deploys VNet, Redis, ACR, and all apps
azd up

# 5. Access your workshop
# - UI URL will be displayed after deployment
# - Complete the workshop modules as before

# 6. After making code changes, redeploy:
azd deploy processor  # Deploy specific service
azd deploy            # Deploy all services

# 7. Clean up when done
azd down --purge
```

### Troubleshooting

```bash
# View logs
azd monitor --logs

# Check deployment status
azd show

# Redeploy with verbose output
azd up --debug
```

---

## Cost Considerations

### Full Isolation with VNet (Per Student Per Hour)

| Resource | SKU | Est. Cost/Hour |
|----------|-----|----------------|
| **Azure Managed Redis** | Balanced B3 (3GB) | **~$0.35** |
| Container Registry | Premium (required for PE) | ~$0.07 |
| Container Apps (5 apps) | Consumption | ~$0.10 |
| VNet + Private Endpoints (2) | - | ~$0.02 |
| Private DNS Zones (2) | - | ~$0.002 |
| Log Analytics | Pay-per-GB | ~$0.01 |
| **Per Student Total** | | **~$0.55/hour** |

### Cost Breakdown Details

| Component | Pricing Model | Notes |
|-----------|---------------|-------|
| **AMR B3** | ~$250/month = ~$0.35/hr | Biggest cost driver |
| **ACR Premium** | ~$50/month = ~$0.07/hr | Required for private endpoint |
| **Container Apps** | ~$0.02/hr per app × 5 apps | Generator, Processor, API, UI, Redis Insight |
| **Private Endpoints** | ~$0.01/hr each × 2 | Redis + ACR |
| **Private DNS Zones** | ~$0.50/month each | Minimal cost |

### Workshop Total Examples

| Students | Duration | Est. Total Cost |
|----------|----------|-----------------|
| 5 students | 4 hours | ~$11.00 |
| 10 students | 4 hours | ~$22.00 |
| 10 students | 8 hours | ~$44.00 |
| 20 students | 4 hours | ~$44.00 |

### Cost Optimization Tips

1. **Cleanup immediately**: Run `azd down --purge` right after workshop
2. **Use B3 SKU**: 3GB is minimum for RediSearch, don't over-provision
3. **Share ACR** (optional): If security allows, one Premium ACR could serve all students
4. **Pre-provision**: Deploy before workshop starts, delete within same hour if possible

---

## Final Architecture Summary

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                       PER-STUDENT ISOLATED ENVIRONMENT                               │
│                          Deployment Time: ~25-35 min                                 │
│                          Cost: ~$0.55/hour per student                               │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│  Resource Group: rg-workshop-{studentName}                                           │
│                                                                                      │
│  ┌────────────────────────────────────────────────────────────────────────────────┐ │
│  │  Virtual Network: vnet-workshop-{studentName} (10.0.0.0/16)                    │ │
│  │                                                                                 │ │
│  │  ┌──────────────────────────────────────────────────────────────────────────┐  │ │
│  │  │  snet-container-apps (10.0.0.0/23)                                       │  │ │
│  │  │  ┌────────────────────────────────────────────────────────────────────┐  │  │ │
│  │  │  │  Container Apps Environment (VNet-integrated)                      │  │  │ │
│  │  │  │                                                                     │  │  │ │
│  │  │  │  ┌──────────┐ ┌──────────┐ ┌────────┐ ┌────────┐ ┌──────────────┐  │  │  │ │
│  │  │  │  │Generator │ │Processor │ │  API   │ │   UI   │ │Redis Insight │  │  │  │ │
│  │  │  │  │(internal)│ │(internal)│ │(extern)│ │(extern)│ │  (external)  │  │  │  │ │
│  │  │  │  └────┬─────┘ └────┬─────┘ └───┬────┘ └───┬────┘ └──────┬───────┘  │  │  │ │
│  │  │  │       │            │           │          │             │          │  │  │ │
│  │  │  │       └────────────┴───────────┴──────────┴─────────────┘          │  │  │ │
│  │  │  │                                    │                                │  │  │ │
│  │  │  │                                    │ (Private Endpoint)             │  │  │ │
│  │  │  │                                    ▼                                │  │  │ │
│  │  │  └────────────────────────────────────────────────────────────────────┘  │  │ │
│  │  └──────────────────────────────────────────────────────────────────────────┘  │ │
│  │                                                                                 │ │
│  │  ┌──────────────────────────────────────────────────────────────────────────┐  │ │
│  │  │  snet-private-endpoints (10.0.2.0/24)                                    │  │ │
│  │  │                                                                           │  │ │
│  │  │   ┌─────────────────────────────┐    ┌─────────────────────────────┐     │  │ │
│  │  │   │ pe-redis                    │    │ pe-acr                      │     │  │ │
│  │  │   │         │                   │    │         │                   │     │  │ │
│  │  │   │         ▼                   │    │         ▼                   │     │  │ │
│  │  │   │ ┌─────────────────────────┐│    │ ┌─────────────────────────┐ │     │  │ │
│  │  │   │ │ Azure Managed Redis     ││    │ │ Azure Container Registry│ │     │  │ │
│  │  │   │ │ SKU: Balanced B3 (3GB)  ││    │ │ SKU: Premium            │ │     │  │ │
│  │  │   │ │ Cluster: Enterprise     ││    │ │ Public: Disabled        │ │     │  │ │
│  │  │   │ │ RediSearch ✓            ││    │ └─────────────────────────┘ │     │  │ │
│  │  │   │ │ Port: 10000 (TLS)       ││    └─────────────────────────────┘     │  │ │
│  │  │   │ └─────────────────────────┘│                                        │  │ │
│  │  │   └─────────────────────────────┘                                        │  │ │
│  │  └──────────────────────────────────────────────────────────────────────────┘  │ │
│  │                                                                                 │ │
│  │  Private DNS Zones:                                                             │ │
│  │  • privatelink.redis.cache.windows.net                                          │ │
│  │  • privatelink.azurecr.io                                                       │ │
│  └─────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                      │
│  External URLs (Public Access):                                                      │
│  • https://ca-ui-workshop-yourname.<region>.azurecontainerapps.io                   │
│  • https://ca-api-workshop-yourname.<region>.azurecontainerapps.io                  │
│  • https://ca-redisinsight-workshop-yourname.<region>.azurecontainerapps.io         │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Decisions Made ✅

| Question | Decision |
|----------|----------|
| Azure Managed Redis SKU | **Balanced B3** (3GB) - minimum for RediSearch |
| Cluster Policy | **Enterprise** (required for RediSearch) |
| Networking | **VNet + Private Endpoints** (enterprise security) |
| Container Registry SKU | **Premium** (required for private endpoint) |
| Public Access AMR/ACR | **Disabled** (private endpoints only) |
| AMR Port | **10000** (TLS) |
| Student Isolation | **Full isolation** (own VNet, Redis, ACR per student) |
| Container Apps | **5 apps**: Generator, Processor, API, UI, Redis Insight |
| Redis Insight | **Separate Container App** (external ingress) |

---

## Next Steps: Implementation Order

1. **Create Bicep modules** (`infra/modules/*.bicep`)
   - `virtual-network.bicep` - VNet + Subnets
   - `private-dns-zone.bicep` - DNS zones for private endpoints
   - `private-endpoint.bicep` - Generic PE module
   - `container-registry.bicep` - ACR (Premium)
   - `redis-enterprise.bicep` - Azure Managed Redis
   - `container-apps-environment.bicep` - CAE with VNet integration
   - `container-app.bicep` - Container app template
   - `managed-identity.bicep` - User-assigned identity
   - `log-analytics.bicep` - Monitoring workspace

2. **Create main.bicep** (`infra/main.bicep`) - Main orchestration

3. **Create azure.yaml** (root) - azd configuration

4. **Update lib/redis_client.py** - SSL, password auth, longer timeouts

5. **Update UI** - Dynamic API URL injection
   - `ui/docker-entrypoint.sh`
   - `ui/nginx.conf`
   - `ui/Dockerfile`

6. **Test deployment** (~25-35 min)

7. **Create student instructions** (README update)

*Ready to proceed with implementation!*
