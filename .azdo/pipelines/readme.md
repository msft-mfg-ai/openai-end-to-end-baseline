# Azure DevOps Pipelines

This directory contains Azure DevOps YAML pipeline templates and configurations for the OpenAI End-to-End Baseline project.

## Overview

The pipeline structure is designed to provide modular, reusable deployment automation with proper rollback capabilities. The key innovation is the **deploy-only pipeline with rollback functionality** that can either deploy new resources or rollback to a previous successful deployment.

## Key Features

### 🔄 Rollback Functionality
- **Automatic Rollback**: Identifies the most recent successful deployment and reverts to it
- **Targeted Rollback**: Allows rollback to a specific deployment by name
- **Rollback Validation**: Verifies the rollback operation completed successfully
- **Deployment History**: Maintains deployment history for audit and recovery purposes

### 🏗️ Deployment Modes
- **Standard Deployment**: Deploys new resources using current templates and parameters
- **Rollback Deployment**: Reverts to a previous deployment configuration
- **Validation Mode**: Validates templates without actually deploying resources

## Directory Structure

```
.azdo/
├── pipelines/
│   ├── deploy-webapp-only-pipeline.yml    # Main deploy-only pipeline with rollback
│   ├── readme.md                          # This file
│   │
│   ├── pipes/                             # Modular pipeline components
│   │   └── deploy-only-pipe.yml           # Deploy-only stage template with rollback logic
│   │
│   └── vars/                              # Variable definitions
│       ├── var-common.yml                 # Common variables across environments
│       ├── var-dev.yml                    # Development environment variables
│       ├── var-qa.yml                     # QA environment variables
│       ├── var-prod.yml                   # Production environment variables
│       └── var-service-connections.yml    # Service connection configurations
```

## Pipeline Usage

### Deploy-Only Pipeline (`deploy-webapp-only-pipeline.yml`)

This pipeline is designed for deployment-only operations and includes comprehensive rollback capabilities.

#### Standard Deployment
```yaml
# Deploy to DEV environment with current configuration
parameters:
  deployToEnvironment: DEV
  enableRollback: false
  templateFile: main-basic.bicep
  deploymentMode: Incremental
```

#### Rollback to Previous Deployment
```yaml
# Rollback to the most recent successful deployment
parameters:
  deployToEnvironment: PROD
  enableRollback: true
  rollbackToDeployment: ''  # Empty = auto-detect previous deployment
```

#### Rollback to Specific Deployment
```yaml
# Rollback to a specific deployment by name
parameters:
  deployToEnvironment: PROD
  enableRollback: true
  rollbackToDeployment: 'main-basic.bicep-rg-eastus-202312150900'
```

## Rollback Mechanism

### How Rollback Works

1. **Deployment Identification**: The pipeline queries Azure Resource Manager to find deployment history
2. **Target Selection**: 
   - If `rollbackToDeployment` is specified, uses that deployment
   - Otherwise, finds the most recent successful deployment (excluding current)
3. **Template Retrieval**: Extracts the original template and parameters from the target deployment
4. **Rollback Execution**: Deploys using the historical template and parameters
5. **Validation**: Confirms the rollback deployment completed successfully

### Rollback Safety Features

- **Validation Checks**: Ensures target deployment exists and was successful
- **Error Handling**: Provides detailed error messages if rollback fails
- **Audit Trail**: Maintains clear logging of rollback operations
- **Status Verification**: Confirms deployment status after rollback

### Rollback Limitations

- Can only rollback to deployments that are still accessible in Azure deployment history
- Rollback uses the same deployment mode as the original (typically Incremental)
- External dependencies (like secrets, certificates) may need manual verification
- Rollback doesn't affect external services or databases

## Environment Configuration

### Service Connections
Each environment requires a configured service connection:
- `sc-DEV`: Development environment connection
- `sc-QA`: QA environment connection  
- `sc-PROD`: Production environment connection

Service connections should have appropriate RBAC permissions:
- **Contributor** role on target resource groups
- **Reader** role on subscription
- **Key Vault Secrets Officer** role (if using Key Vault)

### Variable Groups
Create an `Application.Web` variable group with:
- `appName`: Application name
- `apiKey`: API key for the application
- `adDomain`: Active Directory domain
- `serviceConnectionName`: Service connection name

## Best Practices

### Deployment Strategy
1. **Test Rollback in Lower Environments**: Always test rollback procedures in DEV/QA before production
2. **Monitor Deployment History**: Keep track of deployment names and timestamps
3. **Backup Critical Data**: Ensure external data is backed up before major deployments
4. **Validate After Rollback**: Run health checks after rollback operations

### Security Considerations
1. **Principle of Least Privilege**: Grant minimal required permissions to service connections
2. **Approval Gates**: Configure approval requirements for production deployments
3. **Audit Logging**: Enable comprehensive logging for compliance and troubleshooting
4. **Secret Management**: Use Key Vault for sensitive configuration values

### Operational Guidelines
1. **Deployment Naming**: Use consistent naming conventions for deployments
2. **Parameter Management**: Keep parameter files in source control
3. **Environment Isolation**: Maintain separate service connections per environment
4. **Change Management**: Document all rollback operations and their reasons

## Troubleshooting

### Common Issues

**Rollback Target Not Found**
- Check if the deployment exists in Azure Portal
- Verify the deployment name is correct
- Ensure the deployment was successful

**Permission Errors**
- Verify service connection has appropriate RBAC roles
- Check if the service principal has access to the resource group
- Validate subscription-level permissions

**Template Validation Failures**
- Ensure template files exist in the repository
- Verify parameter file syntax is correct
- Check for missing required parameters

### Debugging Steps

1. **Check Deployment History**:
   ```bash
   az deployment group list --resource-group <rg-name> --query "[].{Name:name, Status:properties.provisioningState, Timestamp:properties.timestamp}" --output table
   ```

2. **Validate Service Connection**:
   - Test connection in Azure DevOps
   - Verify permissions in Azure Portal
   - Check service principal expiration

3. **Review Pipeline Logs**:
   - Check each pipeline step for errors
   - Look for Azure CLI command outputs
   - Verify template validation results

## Examples

### Example 1: Standard Deployment
Deploy infrastructure to DEV environment:
```yaml
trigger: none
parameters:
  deployToEnvironment: DEV
  enableRollback: false
  templateFile: main-basic.bicep
  createResourceGroup: true
```

### Example 2: Emergency Rollback
Rollback production to previous working state:
```yaml
trigger: none
parameters:
  deployToEnvironment: PROD
  enableRollback: true
  rollbackToDeployment: ''  # Auto-detect previous
```

### Example 3: Targeted Rollback
Rollback to a specific known-good deployment:
```yaml
trigger: none
parameters:
  deployToEnvironment: QA
  enableRollback: true
  rollbackToDeployment: 'main-basic.bicep-rg-eastus-202312140800'
```

## Support

For issues with the pipeline or rollback functionality:
1. Check the [troubleshooting section](#troubleshooting) above
2. Review Azure DevOps pipeline logs
3. Verify Azure resource deployment history
4. Consult the main project documentation

## Related Documentation

- [Azure DevOps YAML Pipeline Guidelines](../../docs/YML_AzDO.md)
- [Bicep Template Documentation](../../infra/bicep/README.md)
- [Azure Resource Manager Templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/)
- [Azure DevOps Service Connections](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints)