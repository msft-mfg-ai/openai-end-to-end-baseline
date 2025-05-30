# Infrastructure as Code Guidelines for Project

This document outlines the structured approach to Infrastructure as Code (IaC) used in the project. Following these guidelines will help maintain consistency across future projects.

## Table of Contents
1. [Folder Structure](#folder-structure)
2. [File Naming Conventions](#file-naming-conventions)
3. [Resource Naming Standards](#resource-naming-standards)
4. [Bicep File Structure](#bicep-file-structure)
5. [Deployment Methods](#deployment-methods)
6. [Parameterization](#parameterization)
7. [Tagging Strategy](#tagging-strategy)
8. [Environment Considerations](#environment-considerations)
9. [Best Practices](#best-practices)
10. [Examples](#examples)

## Folder Structure

```
/infra
└───Bicep/
    │   main.bicep                # Main template that deploys all resources
    │   main.bicepparam           # Environment-specific Bicep parameter files
    │   resourcenames.bicep       # Centralized resource naming module
    │   *.bicep                   # Resource-specific modules (website.bicep, etc.)
    │   azd-main.bicep            # Main entry point for Azure Developer CLI (azd) deployments
    │   azd-main.bicepparam       # Bicep parameters for azd deployments
    └───data/
            resourceAbbreviations.json  # Resource abbreviation definitions
            roleDefinitions.json        # RBAC role definitions
```

### Key Components

- **Entry Points**:
  - `Bicep/main.bicep`: Primary Bicep file for manual deployments
  - `Bicep/azd-main.bicep`: Entry point for Azure Developer CLI (azd) deployments

- **Resource Modules**: Individual Bicep files for each resource type:
  - `website.bicep`: Web App and App Service Plan
  - `containerRegistry.bicep`: Azure Container Registry
  - `identity.bicep`: User-assigned Managed Identities
  - etc.

- **Supporting Files**:
  - `resourcenames.bicep`: Centralized resource naming logic
  - `data/resourceAbbreviations.json`: Resource name abbreviations
  - `role-assignments.bicep`: RBAC role assignments - all of the security role assignments are in this file - that enables us to document the assignments and also separate out those assignment if we do not have rights to do the security admin role in a subscription.

## File Naming Conventions

- **Main Files**: `main.bicep`, `azd-main.bicep`
- **Resource Modules**: Use descriptive names that indicate the Azure resource being provisioned
  - Example: `website.bicep`, `storageaccount.bicep`, `containerRegistry.bicep`
- **Parameter Files**: Follow the pattern `main.parameters.[environment].json`
  - Example: `main.parameters.gha.json`, `main.parameters.azdo.json`
- **Helper Files**: Use descriptive names with clear action verbs
  - Example: `Run_Deploy_Locally.ps1`

## Resource Naming Standards

Resource naming is centralized in `resourcenames.bicep` which provides consistent naming across all deployments:

1. **Naming Pattern**: `[appName]-[environmentCode]-[resourceAbbreviation]`
   - Example: `application-dev-appsvc` for an App Service Plan

2. **Abbreviations**: Stored in `data/resourceAbbreviations.json` for consistency:
   - `appsvc` for App Service Plans
   - `insights` for Application Insights
   - `law` for Log Analytics Workspaces
   - etc.

3. **Environment Codes**: Standardized environment identifiers:
   - `dev`, `demo`, `qa`, `stg`, `prod`
   - Special codes: `azd`, `gha`, `azdo` for different deployment pipelines

## Bicep File Structure

Each Bicep file should follow this structure:

1. **Header Comment Block**:
   ```bicep
   // --------------------------------------------------------------------------------
   // This BICEP file will create [resource description]
   // --------------------------------------------------------------------------------
   ```

2. **Parameters Section**:
   ```bicep
   param appName string
   param environmentCode string = 'dev'
   param location string = resourceGroup().location
   ```

3. **Variables Section**:
   ```bicep
   var templateTag = { TemplateFile: '~[filename].bicep' }
   var tags = union(commonTags, templateTag)
   ```

4. **Resource Definitions**:
   ```bicep
   resource webSite 'Microsoft.Web/sites@2021-02-01' = {
     // Resource properties
   }
   ```

5. **Outputs Section**:
   ```bicep
   output webSiteName string = webSite.name
   output webSiteId string = webSite.id
   ```

## Parameterization

### Parameter Types

1. **Required Parameters**:
   - `appName`: Base name for all resources
   - `environmentCode`: Environment identifier (dev, qa, prod, etc.)

2. **Optional with Defaults**:
   - `location`: Default is `resourceGroup().location`
   - `sku`: Default sizing for resources

3. **Sensitive Parameters**:
   - API keys, credentials, and other secrets
   - Should be provided via secure methods, not hardcoded

### Parameter Files

- Use parameter files for environment-specific configurations
- Format: `main.parameters.[environment].json`
- Store non-sensitive defaults in these files
- Obtain sensitive values from:
  - Key Vault references
  - Pipeline variables
  - Environment variables

## Tagging Strategy

Apply consistent tagging to all resources:

```bicep
var commonTags = {
  LastDeployed: runDateTime
  Application: appName
  Environment: environmentCode
}

var templateTag = { TemplateFile: '~website.bicep' }
var tags = union(commonTags, templateTag)
```

### Required Tags

- **Application**: Name of the application
- **Environment**: Deployment environment
- **LastDeployed**: Timestamp of last deployment
- **TemplateFile**: Source Bicep file name
- **azd-env-name**: For resources deployed with Azure Developer CLI
- **azd-service-name**: For service components in azd deployments

## Environment Considerations

### Multi-Environment Design

The infrastructure is designed to support multiple environments:

1. **Dev/Test Environments**:
   - Use `F1`/`B1` SKUs for App Service
   - Basic monitoring configuration

2. **Production Environments**:
   - Use `S1` or higher SKUs
   - Enhanced monitoring
   - Backup configurations

### Conditionally Deployed Resources

Some resources are deployed conditionally based on the environment:

```bicep
var deployAdvancedMonitoring = environmentCode == 'prod' || environmentCode == 'stg'
```

## Best Practices

1. **Modularity**:
   - Break down templates into logical, reusable modules
   - Each resource type should have its own Bicep file

2. **Naming Consistency**:
   - Use centralized naming in `resourcenames.bicep`
   - Follow consistent naming patterns for all resources

3. **Dependencies**:
   - Explicitly define dependencies with `dependsOn` if needed, otherwise rely on Bicep's implicit dependency resolution
   - Use symbolic resource references instead of string references

4. **Error Handling**:
   - Include conditional checks for resource existence
   - Provide clear error messages in output

5. **Documentation**:
   - Include thorough comments in Bicep files
   - Document parameter requirements and constraints

6. **Security**:
   - Use managed identities for authentication where possible
   - Never hardcode secrets in templates
   - Apply principle of least privilege for role assignments

7. **Resource Provisioning Order**:
   - Deploy dependencies before dependent resources
   - Use logical dependency chains

## Examples

### Resource Module Example

```bicep
// -----------------------------------------------
// This BICEP file creates a web application
// -----------------------------------------------
param webSiteName string
param location string = resourceGroup().location
param environmentCode string = 'dev'
param commonTags object = {}

var templateTag = { TemplateFile: '~website.bicep' }
var tags = union(commonTags, templateTag)

resource webSite 'Microsoft.Web/sites@2021-02-01' = {
  name: webSiteName
  location: location
  tags: tags
  properties: {
    // Properties
  }
}

output webSiteUrl string = 'https://${webSite.properties.defaultHostName}'
```

### Main Deployment Example

```bicep
// Import the resource naming module
module names 'resourcenames.bicep' = {
  name: 'resourcenames'
  params: {
    appName: appName
    environmentCode: environmentCode
  }
}

// Deploy a web app
module webApp 'website.bicep' = {
  name: 'website-${deploymentSuffix}'
  params: {
    webSiteName: names.outputs.webSiteName
    location: location
    environmentCode: environmentCode
    commonTags: commonTags
  }
}
```

---

*This document was created to guide infrastructure development for projects similar to this. Follow these practices to maintain consistency and quality across infrastructure deployments.*
