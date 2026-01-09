# Generator

Publishes transactions to `stream:transactions`

Pre-built. Runs automatically when deployed to Azure.

## View Logs

```bash
az containerapp logs show -n generator -g $(azd env get-value AZURE_RESOURCE_GROUP) --follow
```
