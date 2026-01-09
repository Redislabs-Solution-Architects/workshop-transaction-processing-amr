# CI/CD: Workload Identity Federation (OIDC)

> **Note**: This document is for reference only. The workshop currently supports **interactive login** and **Service Principal** authentication. 
> Use this guide if you want to set up passwordless CI/CD with GitHub Actions in the future.

This guide shows how to configure **passwordless authentication** from GitHub Actions to Azure using OIDC (OpenID Connect).

## Why Federated Identity?

| Feature | Service Principal + Secret | Federated Identity |
|---------|---------------------------|-------------------|
| Secrets to manage | Yes ⚠️ | **No** ✅ |
| Secret rotation | Manual | Not needed |
| Security risk | Secret leakage | Minimal |
| Setup complexity | Simple | Moderate |

## Setup Steps

### 1. Create App Registration

```bash
# Create the App Registration
az ad app create --display-name "redis-workshop-github"

# Get the App ID (Client ID)
APP_ID=$(az ad app list --display-name "redis-workshop-github" --query "[0].appId" -o tsv)
echo "AZURE_CLIENT_ID: $APP_ID"

# Create a Service Principal for the App
az ad sp create --id $APP_ID

# Get your Tenant ID
TENANT_ID=$(az account show --query tenantId -o tsv)
echo "AZURE_TENANT_ID: $TENANT_ID"
```

### 2. Add Federated Credential

```bash
# Set your GitHub org/repo
GITHUB_ORG="your-org"
GITHUB_REPO="workshop-transaction-processing"

# Create federated credential for the main branch
az ad app federated-credential create --id $APP_ID --parameters '{
  "name": "github-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'

# Create federated credential for workflow_dispatch (manual runs)
az ad app federated-credential create --id $APP_ID --parameters '{
  "name": "github-workflow-dispatch",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':environment:production",
  "audiences": ["api://AzureADTokenExchange"]
}'
```

### 3. Grant Azure Permissions

```bash
# Get your Subscription ID
SUB_ID=$(az account show --query id -o tsv)
echo "AZURE_SUBSCRIPTION_ID: $SUB_ID"

# Grant Contributor role on the subscription
az role assignment create \
  --assignee $APP_ID \
  --role Contributor \
  --scope /subscriptions/$SUB_ID
```

### 4. Configure GitHub Repository

Go to your repository: **Settings → Secrets and variables → Actions → Variables**

Add these **Repository Variables** (not secrets!):

| Variable | Value |
|----------|-------|
| `AZURE_CLIENT_ID` | The App ID from step 1 |
| `AZURE_TENANT_ID` | Your Azure AD Tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Your Subscription ID |

### 5. Create GitHub Environment

Go to: **Settings → Environments → New environment**

- Name: `production`
- Add any protection rules if desired (approvals, etc.)

## Usage

### Deploy via GitHub Actions

1. Go to **Actions → Deploy Workshop**
2. Click **Run workflow**
3. Enter:
   - Student name: `john`
   - Location: `eastus`
   - Action: `up`
4. Click **Run workflow**

### Destroy Resources

Same as above, but select Action: `down`

## Troubleshooting

### "AADSTS70021: No matching federated identity record found"

The subject claim doesn't match. Check:
- Repository name is correct
- Branch name matches (main vs master)
- Environment name matches (`production`)

### "Authorization failed"

The App Registration doesn't have permissions:
```bash
# Verify role assignment
az role assignment list --assignee $APP_ID --subscription $SUB_ID
```

## Local Development

For local development, students should use interactive login:

```bash
cp workshop.env.template workshop.env
# Edit workshop.env with your settings
./setup.sh
azd up
```

No secrets needed - browser-based authentication is used.
