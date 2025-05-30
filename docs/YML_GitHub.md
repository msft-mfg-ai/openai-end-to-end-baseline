# GitHub Actions YAML Pipeline Guidelines for Project

This document outlines the structured approach to GitHub Actions workflows used in this project. Following these guidelines will help maintain consistency across future projects.

## Table of Contents
1. [Workflow Structure](#workflow-structure)
2. [File Organization](#file-organization)
3. [Workflow Types](#workflow-types)
4. [Variable Management](#variable-management)
5. [Environment Strategy](#environment-strategy)
6. [Reusable Workflows](#reusable-workflows)
7. [Security and Scanning](#security-and-scanning)
8. [Testing Strategy](#testing-strategy)
9. [Best Practices](#best-practices)
10. [Setup and Configuration](#setup-and-configuration)

## Workflow Structure

### Main Components
- **Main Workflows**: Entry point workflows
- **Template Workflows**: Reusable workflow components prefixed with "template-"
- **Scheduled Workflows**: Workflows that run on a defined schedule using cron expressions
- **Event-Triggered Workflows**: Workflows triggered by specific GitHub events

### Standard Workflow Format

```yaml
# ------------------------------------------------------------------------------------------------------------------------
# Descriptive header explaining the workflow purpose
# ------------------------------------------------------------------------------------------------------------------------
name: meaningful.workflow.name

on: 
  workflow_dispatch:     # Manual trigger with input parameters
  push:                  # Git event triggers
    branches:
      - main
  schedule:              # Schedule-based triggers using cron syntax
    - cron: '0 0 * * *'  # Example: daily at midnight

permissions:            # Define least-privilege permissions
  id-token: write
  contents: read
  actions: read

jobs:
  job-name:             # Define jobs that make up the workflow
    name: Display Name
    runs-on: ubuntu-latest
    steps:
      - name: Step 1
        uses: actions/checkout@v4
```

## File Organization

### Workflow File Types
1. **Main Workflows**: Main entry points
   - `bicep-only.yml`: Infrastructure deployment only
   - `build-app-only.yml`: Application build only
   - `build-deploy-app.yml`: Application build and deployment
   - `bicep-build-deploy-app.yml`: Full stack deployment
   - `smoke-test.yml`: Post-deployment validation
   - `scan-build-pr.yml`: PR validation and scanning
   - `scan-devsecops.yml`: Security scanning (scheduled)
   - `scan-codeql.yml`: Code quality scanning (scheduled)

2. **Template Workflows**: Reusable components
   - `template-create-infra.yml`: Infrastructure deployment
   - `template-webapp-build.yml`: Web application build
   - `template-webapp-deploy.yml`: Web application deployment
   - `template-scan-code.yml`: Security scanning
   - `template-smoke-test.yml`: Post-deployment testing

3. **Special-Purpose Workflows**:
   - `azure-dev.yml`: Integration with Azure Developer CLI

## Workflow Types

### 1. Infrastructure Deployment Workflows
- **Purpose**: Deploy Azure resources using Bicep templates
- **Key Workflows**: `bicep-only.yml`, `template-create-infra.yml`
- **Features**:
  - Parameterized environment selection
  - Bicep template and parameter file inputs
  - Deployment mode configuration
  - Infrastructure output capture

### 2. Application Build Workflows
- **Purpose**: Build, test, and package application code
- **Key Workflows**: `build-app-only.yml`, `template-webapp-build.yml`
- **Features**:
  - .NET build and test
  - Artifact packaging
  - Optional test coverage reporting
  - Build validation

### 3. Application Deployment Workflows
- **Purpose**: Build and deploy application to Azure
- **Key Workflows**: `build-deploy-app.yml`, `template-webapp-deploy.yml`
- **Features**:
  - Environment-specific configuration
  - Azure authentication
  - Deployment slot management
  - Post-deployment validation

### 4. End-to-End Workflows
- **Purpose**: Comprehensive deployment of infrastructure and application
- **Key Workflows**: `bicep-build-deploy-app.yml`
- **Features**:
  - Orchestration of multiple template workflows
  - Sequential job dependencies
  - Optional component selection (security scan, infrastructure, application)
  - Smoke testing

### 5. Security and Compliance Workflows
- **Purpose**: Code scanning, security validation, and compliance checks
- **Key Workflows**: `scan-build-pr.yml`, `scan-devsecops.yml`, `scan-codeql.yml`
- **Features**:
  - CodeQL analysis
  - DevSecOps scanning
  - Scheduled execution
  - Security report generation

## Variable Management

### Environment Variables
- **GitHub Secrets**: Sensitive values stored as repository or organization secrets
- **GitHub Variables**: Non-sensitive configuration values stored at repository or environment level
- **Input Parameters**: User-configurable options defined in workflow_dispatch triggers
- **Workflow Outputs**: Values passed between jobs and workflows

### Required Variables
- **Application Variables**:
  - `APP_PROJECT_FOLDER_NAME`: Root folder of the application
  - `APP_PROJECT_NAME`: Name of the application project
  - `APP_TEST_FOLDER_NAME`: Root folder of the test project
  - `APP_TEST_PROJECT_NAME`: Name of the test project

- **Azure Variables**:
  - `AZURE_CLIENT_ID`: Service principal client ID
  - `AZURE_CLIENT_SECRET`: Service principal client secret
  - `AZURE_SUBSCRIPTION_ID`: Azure subscription ID
  - `AZURE_TENANT_ID`: Azure tenant ID

- **Environment Variables**:
  - `RESOURCEGROUP_PREFIX`: Prefix for resource group names
  - `RESOURCEGROUP_LOCATION`: Azure region for deployments

### Variable Scope
- **Organization-Level**: Shared across repositories
- **Repository-Level**: Available to all workflows in the repository
- **Environment-Level**: Environment-specific variables
- **Workflow-Level**: Defined within a specific workflow
- **Job-Level**: Defined within a specific job

## Environment Strategy

### Environment Configuration
- **Development (dev)**: Development and testing environment
- **QA (qa)**: Quality assurance and testing
- **Production (prod)**: Production environment

### Environment Protection
- **Required Reviewers**: Configure approval requirements for protected environments
- **Deployment Branches**: Restrict which branches can deploy to specific environments
- **Environment Secrets**: Store environment-specific secrets

### Environment Selection
- **Manual Selection**: Input parameters in workflow_dispatch
- **Branch-Based**: Automatic environment selection based on branch
- **Matrix Strategy**: Deploy to multiple environments in parallel

## Reusable Workflows

### Workflow Calls
- Use the `workflow_call` trigger to define reusable workflows
- Pass inputs and secrets between workflows
- Chain workflows with dependencies

```yaml
on:
  workflow_call:
    inputs:
      envCode:
        required: true
        type: string
    secrets:
      AZURE_CREDENTIALS:
        required: true
```

### Input Standardization
- Use consistent input names across templates
- Provide descriptive defaults where appropriate
- Use explicit type definitions (string, boolean, number)

### Workflow Dependencies
- Use `needs` to establish job dependencies
- Pass outputs between jobs using `outputs` and `${{ needs.job_id.outputs.output_name }}`
- Conditionally run jobs based on previous job outcomes or input parameters

## Security and Scanning

### Security Best Practices
- Use least-privilege permissions for workflows
- Store secrets in GitHub Secrets
- Use OpenID Connect (OIDC) for Azure authentication when possible
- Implement dependabot for action updates

### Scanning Integration
- **CodeQL Analysis**: For code quality and security vulnerabilities
- **Microsoft Security DevOps**: For Azure resource security
- **Custom Scanning**: Application-specific security validation

### Scheduled Scans
- Use cron expressions for regular security checks
- Implement different scan frequencies based on environment
- Send scan results to security teams

## Testing Strategy

### Test Execution
- Run unit tests during build phase
- Run integration tests after deployment
- Implement smoke tests for basic functionality verification

### Test Configuration
- Use environment-specific test settings
- Parameterize test execution with workflow inputs
- Publish test results and coverage reports

### Smoke Testing
- Implement basic health checks post-deployment
- Use Playwright for UI testing
- Use HTTP requests for API testing

## Best Practices

### Workflow Design
1. **Modularity**: Break down workflows into reusable components
2. **Readability**: Use clear naming and commenting
3. **Idempotency**: Ensure workflows can be run repeatedly with consistent results
4. **Error Handling**: Implement proper error handling and reporting

### Security Considerations
1. **Least Privilege**: Use minimum required permissions
2. **Secret Management**: Store sensitive data in GitHub Secrets
3. **Dependency Scanning**: Regularly update actions and dependencies
4. **Audit Logging**: Enable audit logs for GitHub Actions

### Performance Optimization
1. **Caching**: Use GitHub's caching mechanisms for dependencies
2. **Artifact Management**: Clean up artifacts when no longer needed
3. **Conditional Execution**: Skip unnecessary steps based on conditions
4. **Self-Hosted Runners**: Consider for specialized workloads

## Setup and Configuration

### Initial Setup Steps
1. Create `.github/workflows` directory
2. Configure repository secrets
3. Define GitHub environments
4. Set up repository variables
5. Implement base workflows

### Example Secrets Configuration
```
AZURE_CLIENT_ID: Service principal client ID
AZURE_CLIENT_SECRET: Service principal client secret
AZURE_SUBSCRIPTION_ID: Azure subscription ID
AZURE_TENANT_ID: Azure tenant ID
```

---

## Example Workflows

### 1. Basic Infrastructure Deployment
```yaml
name: Deploy Infrastructure

on:
  workflow_dispatch:
    inputs:
      environmentName:
        description: 'Target Environment'
        required: true
        default: 'dev'
        type: choice
        options:
          - dev
          - qa
          - prod

jobs:
  deploy-infra:
    uses: ./.github/workflows/template-create-infra.yml
    with:
      envCode: ${{ inputs.environmentName }}
      templatePath: './infra/Bicep/'
      templateFile: 'main.bicep'
      parameterFile: 'main.parameters.json'
    secrets: inherit
```

### 2. Complete CI/CD Pipeline
```yaml
name: CI/CD Pipeline

on:
  push:
    branches:
      - main
  workflow_dispatch:
    inputs:
      environmentName:
        description: 'Target Environment'
        required: true
        default: 'dev'

jobs:
  security-scan:
    uses: ./.github/workflows/template-scan-code.yml
    with:
      runSecurityScan: true
    secrets: inherit

  deploy-infrastructure:
    needs: security-scan
    uses: ./.github/workflows/template-create-infra.yml
    with:
      envCode: ${{ inputs.environmentName || 'dev' }}
    secrets: inherit

  build-application:
    needs: deploy-infrastructure
    uses: ./.github/workflows/template-webapp-build.yml
    with:
      envCode: ${{ inputs.environmentName || 'dev' }}
      rootDirectory: 'src/Application'
      projectName: 'Application.Web'
    secrets: inherit

  deploy-application:
    needs: build-application
    uses: ./.github/workflows/template-webapp-deploy.yml
    with:
      envCode: ${{ inputs.environmentName || 'dev' }}
    secrets: inherit

  smoke-test:
    needs: deploy-application
    uses: ./.github/workflows/template-smoke-test.yml
    with:
      envCode: ${{ inputs.environmentName || 'dev' }}
    secrets: inherit
```

---

*This document was created to guide GitHub Actions workflow development for projects similar to this. Follow these practices to maintain consistency and quality across CI/CD implementations.*
