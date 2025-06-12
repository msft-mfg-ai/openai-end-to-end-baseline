# Main Advanced Bicep Documentation

## Overview
The `main-advanced.bicep` file is designed to deploy an advanced version of the Landing Zone (LZ) with private networking capabilities. This template includes all necessary infrastructure components for the application deployment with support for existing resources.

## Key Features
- Private Networking Support
- Comprehensive Application Infrastructure
- Optional Parameters for Existing Resources
- Support for Azure AI and Machine Learning Services

## Required Services

### Core Services
- Container Apps
- Container Registry
- CosmosDB
- Storage Account
- Key Vault (for APIM Subscription key, certificates)
- Azure Foundry (includes Azure OpenAI)
- APIM (with support for existing instances)
- Advanced Private Networking Features

### Optional Services
- Azure AI Search
- Bing Grounding
- Document Intelligence

## Parameters

### Application Configuration
- `applicationName` (string): Full Application Name
- `applicationPrefix` (string, default: 'ai_doc'): Prefix for generating unique application name
- `environmentName` (string, default: 'dev'): Environment code (dev, qa, prod)
- `azdEnvName` (string): Environment name used by azd command
- `location` (string): Primary location for resources
- `openAI_deploy_location` (string): Region for OpenAI deployment

### Network Configuration
- `existingVnetName` (string): Name of existing VNET (if using existing network)
- `existingVnetResourceGroupName` (string): Resource group of existing VNET
- `vnetPrefix` (string, default: '10.183.4.0/22'): VNET address space
- Subnet configurations for:
  - Application Gateway
  - Application Services
  - Private Endpoints
  - Agent
  - Bastion
  - Jumpbox
  - Training
  - Scoring

### Virtual Machine Configuration
- `admin_username` (string): Admin username for VM
- `admin_password` (string, secure): Admin password for VM
- `vm_name` (string): VM name

### Container Registry
- `existing_ACR_Name` (string): Existing container registry name
- `existing_ACR_ResourceGroupName` (string): Resource group of existing registry

### Monitoring
- `existing_LogAnalytics_Name` (string): Existing Log Analytics workspace
- `existing_AppInsights_Name` (string): Existing Application Insights instance

### Container Apps
- `existing_managedAppEnv_Name` (string): Existing Container App Environment
- `appContainerAppEnvironmentWorkloadProfileName` (string): Workload profile name
- `containerAppEnvironmentWorkloadProfiles` (array): Workload profiles configuration

### AI Services
- `existing_CogServices_Name` (string): Existing Cognitive Services account
- `existing_SearchService_Name` (string): Existing Search Services account
- `existing_SearchService_ResourceGroupName` (string): Resource group for Search Services
- `aiProjectFriendlyName` (string): Friendly name for Azure AI resource
- `aiProjectDescription` (string): Description of Azure AI resource

### Database
- `existing_Cosmos_Name` (string): Existing Cosmos account
- `existing_Cosmos_ResourceGroupName` (string): Resource group for Cosmos DB

## Deployment Options
- `deployAIHub` (bool): Deploy AI Foundry Hub
- `publicAccessEnabled` (bool, default: true): Enable public access to resources
- `createDnsZones` (bool, default: true): Create DNS Zones
- `addRoleAssignments` (bool, default: true): Add Role Assignments
- `deduplicateKeyVaultSecrets` (bool, default: false): Deduplicate KeyVault secrets
- `appendResourceTokens` (bool, default: false): Append unique tokens to resource names

## Application Deployment
- `deployAPIApp` (bool): Deploy API container app
- `deployBatchApp` (bool, default: false): Deploy Batch container app
- `apiImageName` (string): API container image name
- `batchImageName` (string): Batch container image name

## Regional Configuration
- `regionCode` (string): Global region code (AM, EM, AP, CH)
- `instanceNumber` (string, default: '001'): Instance number for multiple deployments

## Tags
- `costCenterTag` (string)
- `ownerEmailTag` (string)
- `requestorName` (string, default: 'UNKNOWN')
- `applicationId` (string)
- `primarySupportProviderTag` (string)

## Usage Example

```powershell
az deployment group create `
    -n manual `
    --resource-group rg_mfg-ai-lz `
    --template-file 'main-advanced.bicep' `
    --parameters baseName='yourbasename' `
                appGatewayListenerCertificate='yourcertdata' `
                jumpBoxAdminPassword='yourPassword' `
                yourPrincipalId='yourprincipalId'
```

## Best Practices
1. Always use parameter files for production deployments
2. Store sensitive information in Key Vault
3. Use managed identities for authentication where possible
4. Implement proper RBAC assignments
5. Enable monitoring and diagnostics
6. Follow the principle of least privilege
7. Use existing resources when available

## Security Considerations
- Private endpoints for secure communication
- Network isolation through subnets
- Role-based access control (RBAC)
- Managed identities for authentication
- Key Vault integration for secrets management

## Networking Architecture
The template implements a hub-spoke network topology with:
- Dedicated subnets for different services
- Network security groups
- Private endpoints
- Application Gateway integration
- Bastion host for secure access

## Monitoring and Logging
- Application Insights integration
- Log Analytics workspace
- Diagnostic settings
- Custom metrics and dashboards

## Resource Naming
Resource names are generated using the `resourcenames.bicep` module, ensuring:
- Consistent naming conventions
- Proper abbreviations
- Unique identifiers
- Environment-specific prefixes/suffixes
