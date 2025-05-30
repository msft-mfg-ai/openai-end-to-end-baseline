# Azure DevOps YAML Pipeline Guidelines for Project

This document outlines the structured approach to Azure DevOps YAML pipelines used in this project. Following these guidelines will help maintain consistency across future projects.

## Table of Contents
1. [Pipeline Structure](#pipeline-structure)
2. [File Organization](#file-organization)
3. [Pipeline Types](#pipeline-types)
4. [Variable Management](#variable-management)
5. [Environment Strategy](#environment-strategy)
6. [Templates and Reusability](#templates-and-reusability)
7. [Security and Scanning](#security-and-scanning)
8. [Testing Strategy](#testing-strategy)
9. [Best Practices](#best-practices)
10. [Setup and Configuration](#setup-and-configuration)

## Pipeline Structure

### Main Components
- **Root Pipelines**: Entry points that orchestrate the overall deployment process
- **Pipeline Templates**: Reusable components designed set up all tasks for one environment (or multiple environments)
- **Variable Files**: Environment-specific and common variable definitions
- **Template Steps**: Granular, reusable task sequences

### Standard Pipeline Flow
1. **Parameter Definition**: Define pipeline parameters for user configuration
2. **Variable Loading**: Load environment-specific and common variables
3. **Stages Definition**: Define logical deployment stages
4. **Jobs Configuration**: Configure jobs within each stage
5. **Step Execution**: Execute steps within each job

## File Organization

```
.azdo/
├── pipelines/
│   ├── infra-and-webapp-pipeline.yml        # All-in-one infrastructure and application deployment
│   ├── infra-only-pipeline.yml              # Infrastructure-only deployment
│   ├── build-webapp-only-pipeline.yml       # Build and deploy application only
│   ├── deploy-webapp-only-pipeline.yml      # Deploy previously built application
│   ├── scan-pipeline.yml                    # Security scanning pipeline
│   ├── auto-test-pipeline.yml               # Automated testing pipeline
│   ├── smoke-test-pipeline.yml              # Smoke testing pipeline
│   ├── readme.md                            # Pipeline documentation
│   │
│   ├── pipes/                               # Modular pipeline components
│   │   ├── deploy-only-pipe.yml             # Deploy-only stage template
│   │   ├── infra-and-webapp-pipe.yml        # Combined infrastructure and app stage template
│   │   ├── infra-only-pipe.yml              # Infrastructure-only stage template
│   │   ├── webapp-only-pipe.yml             # Web app-only stage template
│   │   │
│   │   └── templates/                       # Reusable job templates
│   │       ├── build-webapp-template.yml    # Web app build job template
│   │       ├── create-infra-template.yml    # Infrastructure creation job template
│   │       ├── deploy-webapp-template.yml   # Web app deployment job template
│   │       ├── playwright-template.yml      # UI testing job template
│   │       ├── scan-code-template.yml       # Code scanning job template
│   │       └── steps-deploy-bicep-template.yml # Bicep deployment steps
│   │
│   └── vars/                                # Variable definitions
│       ├── var-common.yml                   # Common variables across environments
│       ├── var-dev.yml                      # Development environment variables
│       ├── var-qa.yml                       # QA environment variables
│       ├── var-prod.yml                     # Production environment variables
│       └── var-service-connections.yml      # Azure DevOps service connection variables
```

## Pipeline Types

### 1. Infrastructure and Application Pipeline
- **Purpose**: Complete deployment of both infrastructure and application
- **Entry Point**: `infra-and-webapp-pipeline.yml`
- **Stages**:
  - Infrastructure provisioning
  - Application build
  - Application deployment
  - Optional: Testing and scanning

### 2. Infrastructure-Only Pipeline
- **Purpose**: Deploy only the Azure infrastructure
- **Entry Point**: `infra-only-pipeline.yml`
- **Stages**:
  - Infrastructure provisioning

### 3. Application-Only Pipeline
- **Purpose**: Build and deploy only the application
- **Entry Point**: `build-webapp-only-pipeline.yml` or `deploy-webapp-only-pipeline.yml`
- **Stages**:
  - Application build (optional)
  - Application deployment

### 4. Scanning and Testing Pipelines
- **Purpose**: Security scanning and testing
- **Entry Points**: `scan-pipeline.yml`, `auto-test-pipeline.yml`, `smoke-test-pipeline.yml`
- **Stages**:
  - Code scanning
  - Unit testing
  - UI testing

## Variable Management

### Variable Hierarchy
1. **Pipeline Parameters**: User-configurable options defined at pipeline runtime
2. **Variable Groups**: Central, shared variables across pipelines (e.g., `application.Web`)
3. **Environment-Specific Variables**: Variables defined in environment-specific files
4. **Common Variables**: Shared variables across all environments

### Variable Files
- **var-common.yml**: Common settings (resource group prefix, location, SKUs, project paths)
- **var-dev.yml**, **var-qa.yml**, **var-prod.yml**: Environment-specific overrides
- **var-service-connections.yml**: Azure DevOps service connection configurations

### Variable Group Requirements

For projects, a variable group similar to this is required, which will defined variables that are UNIQUE to this deployment of this project:

``` yml
Application.Web
  - appName
  - apiKey
  - adDomain
  - serviceConnectionName
```

## Environment Strategy

### Multi-Stage Deployment
- **Development (DEV)**: Continuous integration, minimal approvals
- **QA**: Testing environment, may require approvals
- **Production (PROD)**: Live environment, requires approvals

### Environment-Specific Configuration
- Different resource SKUs per environment
- Different approval requirements
- Environment-specific variable overrides

### Dynamic Environment Selection
- User-selectable environment via pipeline parameters
- Conditional stage execution based on environment selection

## Templates and Reusability

### Template Hierarchy
1. **Root Pipeline Files**: Entry points with parameters and stage orchestration
2. **Pipe Files**: Stage-level templates that organize jobs and container all of the steps necessary to deploy one environment
3. **Template Files**: Job-level templates with reusable task sequences
4. **Step Templates**: Granular, reusable steps for common operations

### Template Parameters
- All templates should accept parameters for customization
- Default values should be provided where appropriate
- Clear parameter documentation within the template

### Template Types
- **Stage Templates**: `*-pipe.yml` files defining complete stages
- **Job Templates**: `*-template.yml` files defining reusable jobs
- **Step Templates**: Reusable step sequences within templates

## Security and Scanning

### Scanning Integration
- GitHub Advanced Security (GHAS) scanning
- Microsoft DevSecOps scanning
- Custom security scanning steps

### Scanning Options
- Configurable via pipeline parameters
- Integration with build validation
- Scheduled security scanning

### Secure Variable Handling
- Sensitive data stored in variable groups or key vaults
- Secrets masked in pipeline logs
- Principle of least privilege for service connections

## Testing Strategy

### Testing Levels
1. **Unit Tests**: Run during build stage
2. **UI Tests**: Run post-deployment
3. **Smoke Tests**: Validate deployment success

### Testing Configuration
- Optional test execution via parameters
- Configurable test types (unit, UI)
- Test results published as pipeline artifacts

## Best Practices

### Pipeline Design
1. **Modularity**: Use templates for reusable components
2. **Flexibility**: Provide parameters for customization
3. **Readability**: Use clear stage and job names
4. **Efficiency**: Minimize redundant steps

### Environment Isolation
1. **Service Connections**: Use separate service connections per environment
2. **Variable Overrides**: Use environment-specific variable files
3. **Approvals**: Configure appropriate approval gates

### Code Management
1. **Template Versioning**: Version templates for backward compatibility
2. **Documentation**: Maintain clear documentation in readme files
3. **Parameter Defaults**: Provide sensible defaults for optional parameters

## Setup and Configuration

### Prerequisites
1. **Service Connections**: Azure service connections for deployments
2. **Environments**: DevOps environments with appropriate approvals
3. **Variable Groups**: Required variable groups with necessary values

### Pipeline Creation Steps
1. Create Azure DevOps service connections for each environment
2. Create Azure DevOps environments with appropriate approval policies
3. Create the required variable group with appropriate values
4. Import the desired pipeline YAML file
5. Run the pipeline with appropriate parameters

### Service Connection Configuration
- Service connection per environment
- Appropriate permissions for resource deployment
- RBAC principles applied to service identities

---

## Example Usage

### 1. All-in-One Deployment
```yaml
trigger:
  branches:
    include:
      - main

parameters:
  - name: deployToEnvironment
    displayName: Deploy To
    type: string
    values:
      - DEV
      - QA
      - PROD
    default: DEV

variables:
  - group: Application.Web
  - template: vars/var-service-connections.yml

stages:
  - template: pipes/infra-and-webapp-pipe.yml
    parameters:
      environments: [${{ parameters.deployToEnvironment }}]
      runUnitTests: true
```

### 2. Infrastructure-Only Deployment
```yaml
parameters:
  - name: deployToEnvironment
    displayName: Deploy To
    type: string
    values:
      - DEV
      - QA
      - PROD
    default: DEV

variables:
  - group: Application.Web
  - template: vars/var-service-connections.yml

stages:
  - template: pipes/infra-only-pipe.yml
    parameters:
      environments: [${{ parameters.deployToEnvironment }}]
```

---

*This document was created to guide Azure DevOps pipeline development for projects similar to this. Follow these practices to maintain consistency and quality across CI/CD deployments.*
