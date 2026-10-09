# Azure WAIA

`main.bicep` provisions an Ubuntu VM with:

- a non-root SSH administrator (`waiaadmin` by default);
- SSH restricted to the CIDR supplied at deployment time;
- only ports 80 and 443 exposed publicly;
- Docker and Docker Compose installed by cloud-init;
- Standard static public IP and managed identity;
- Boot diagnostics and platform metrics sent to Log Analytics.

Deploy from a machine with Azure CLI and an SSH key already created:

```powershell
az login
az group create --name rg-waia-prod --location eastus
az deployment group create --resource-group rg-waia-prod --template-file infra/main.bicep --parameters adminSshPublicKey="$(Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub)" adminAllowedIpCidr="203.0.113.10/32"
```

The application is deployed by the standard user, never by root:

```bash
scp -r .env.production docker-compose.prod.yml Dockerfile.frontend Dockerfile.backend docker database waiaadmin@SERVER_IP:/opt/waia/
ssh waiaadmin@SERVER_IP
cd /opt/waia
docker compose --env-file .env.production -f docker-compose.prod.yml up -d --build
```

Create `.env.production` on the server from `.env.production.example`, generate strong random values, and never commit it.
