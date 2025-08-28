# Set up GitHub

The GitHub workflows in this project require several secrets set at the repository level or at the environment level.

---

## Workflow Definitions

- **[1_deploy_infra.yml](./workflows/1_deploy_infra.yml):** Deploys the main-*.bicep template with all new resources and does nothing else. You can use this to do a `what-if` deployment to see what resources will be created/updated/deleted by the [main-basic.bicep](../infra/bicep/main-basic.bicep) file or  [main-advanced.bicep](../infra/bicep/main-advanced.bicep) file.
- **(Optional) [2-build-deploy-apps.yml](./workflows/2-build-deploy-apps.yml):** Builds the app and deploys it to Azure - this could/should be set up to happen automatically after each check-in to main branch app folder
- **[3-deploy-aif-project](./workflows/deploy-aif-project.yml):** Creates a resource group and deploys the AI Foundry Project and it's dependencies for a new application

---

## Quick Start Summary

Follow these steps to get started quickly:

1. Set up a federated App Registration configuration for this repo with your environment name. Alternatively, you can create a regular App Registration and use the Client Secret, but using a Federated Identity is recommended for security.

    See [https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-create-trust](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-create-trust)

1. Create these environment secrets either manually or by customizing these commands. They should be in each environment if you are using multiple environments, or could be at the repository level if you are only deploying one version.

    ```bash
    gh secret set --env <envName> AZURE_SUBSCRIPTION_ID -b xxx-xx-xx-xx-xxxx
    gh secret set --env <envName> AZURE_TENANT_ID -b xxx-xx-xx-xx-xxxx
    gh secret set --env <envName> CICD_CLIENT_ID -b xxx-xx-xx-xx-xxxx
    ```

    Optional - Add a client secret if not using a federated identity.

    > *Note that you only need to use CICD_CLIENT_SECRET if you are NOT using a Federated Identity. If you want to use a Federated Identity, you should omit this secret.*

    ```bash
    gh secret set --env <envName> CICD_CLIENT_SECRET -b xxxxxxxxxx
    ```

1. The following variables should be set or updated at the repository level, as they should be the same for most uses. If desired, you could set them at the environment level to customize them for each environment. These values are used by the Bicep templates to configure the resource names that are deployed.

     Make sure the App_Name variable is unique to your deploy. It will be used as the basis for the application name and for all the other Azure resources, some of which must be globally unique.    Update `APP_NAME` with a value that is unique to your deployment, which can contain dashes or underscores (i.e. 'xxx-doc-review'). The `APP_NAME` will be used as the basis for all of the resource names, with the environment name (i.e. dev/qa/prod) appended to each resource name.

    The Resource Group Name created will be `<RESOURCEGROUP_PREFIX>-<ENVIRONMENT>-<GLOBAL_REGION_CODE>-<INSTANCE>` and will be created in the `<RESOURCEGROUP_LOCATION>` Azure region. If you want to use an existing Resource Group Name or change the format of the `generatedResourceGroupName` variable in the [template-create-infra.yml](./workflows/template-create-infra.yml) file (and a few other YML files... search for `RESOURCEGROUP_PREFIX`).

    The `<AIFOUNDRY_DEPLOY_LOCATION>` can be specified if you want to deploy the OpenAI resources in a different region than the rest of the resources due to region constraints.

    ```bash
    gh variable set APP_NAME -b YOUR-APP-NAME
    gh variable set APP_ID -b YOUR-APP-ID
    gh variable set RESOURCEGROUP_PREFIX -b rg-PREFIX
    gh variable set RESOURCEGROUP_LOCATION -b eastus2
    gh variable set AIFOUNDRY_DEPLOY_LOCATION -b eastus2
    gh variable set OPENAI_DEPLOY_LOCATION -b eastus2
    gh variable set INSTANCE_NUMBER -b 01
    gh variable set GLOBAL_REGION_CODE -b AM
    ```

    For resource tags, set these variables:

    ```bash
    gh variable set APPLICATION_OWNER -b first.last_yourdomain.com
    gh variable set BUSINESS_OWNER -b first.last_yourdomain.com
    gh variable set COST_CENTER -b YOUR-VALUE
    gh variable set CREATED_BY -b first.last_yourdomain.com
    gh variable set LTI_SERVICE_CLASS -b YOUR-VALUE
    gh variable set PRIMARY_SUPPORT_PROVIDER -b YOUR-VALUE
    gh variable set REQUESTOR_NAME -b first.last_yourdomain.com
    gh variable set REQUEST_NUMBER -b YOUR-VALUE
    ```

    For each environment, you can control the AI Model capacity with this variable:

    ```bash
    gh variable set --env <envName> AI_MODEL_CAPACITY -b 20
    ```

    If you want to add additional configuration for the application, like Entra App Registrations or APIM keys, you may want to add keys like this: (note that these are all based on the code in the container app):

    Variables:

    ```bash
    gh variable set --env <envName> ENTRA_TENANT_ID -b <YOUR_ENTRA_TENANT_ID>
    gh variable set --env <envName> ENTRA_API_AUDIENCE -b <YOUR_ENTRA_API_AUDIENCE>
    gh variable set --env <envName> ENTRA_API_ISSUER -b <ENTRA_API_ISSUER>
    gh variable set --env <envName> ENTRA_REDIRECT_URI -b <YOUR_ENTRA_REDIRECT_URI>
    gh variable set --env <envName> ENTRA_SCOPES -b <YOUR_ENTRA_SCOPES>

    gh variable set --env <envName> APIM_ACCESS_URL -b https://<NAME>.azure-api.net/api/<NAME>-app-access/2025-06-24
    gh variable set --env <envName> APIM_BASE_URL -b https://<NAME>.azure-api.net/api/<NAME>-facade/2025-06-24
    ```

    Secrets:
    ```bash
    gh secret set --env <envName> ENTRA_CLIENT_ID -b <YOUR_ENTRA_CLIENT_ID>
    gh secret set --env <envName> ENTRA_CLIENT_SECRET -b <YOUR_ENTRA_CLIENT_SECRET>
    gh secret set --env <envName> APIM_ACCESS_KEY -b <SECRET_VALUE>
    ```

1. Run the **[1-infra-build-deploy-all](./workflows/1-infra-build-deploy-all.yml):** action in this repo to deploy the UI.

That's it - you should have a fully working deployed environment!

### Additional Settings

Once that is deployed, when you deploy an app or a foundry project you may also need the following settings, some of which can't be known before the first deploy.

Secrets:

```bash
gh secret set --env <envName> APIM_KEY -b <VALUE>
gh secret set --env <envName> APPLICATIONINSIGHTS_CONNECTION_STRING -b <VALUE>
gh secret set --env <envName> DOCKER_PASSWORD -b <VALUE>
```

Variables:

```bash
gh variable set --env <envName> RESOURCEGROUP_NAME -b <YOUR_RG_NAME>
gh variable set --env <envName> CONTAINER_REGISTRY_REPOSITORY_NAME -b <YOUR_CR_NAME>
gh variable set --env <envName> CONTAINER_REGISTRY_URL -b <YOUR_CR_URL>
gh variable set --env <envName> APIM_ACCESS_URL -b <YOUR_APIM_URL>
gh variable set --env <envName> APIM_BASE_URL -b  <YOUR_APIM_BASE_URL>
gh variable set --env <envName> API_URL -b  <YOUR_AGENT_API_URL>
gh variable set --env <envName> AZURE_AI_AGENT_ENDPOINT -b https://<YOUR_FOUNDRY_NAME>.services.ai.azure.com/api/projects/<YOUR_PROJECT_NAME>
gh variable set --env <envName> AZURE_AI_AGENT_MODEL_DEPLOYMENT_NAME -b gpt-4.1
gh variable set --env <envName> DOCKER_USERNAME -b <YOUR_DOCKER_NAME>
gh variable set --env <envName> ACR_NAME -b <YOUR_ACR_NAME>
gh variable set --env <envName> CONTAINER_APP_ENV_NAME -b <YOUR_CAE_NAME>
gh variable set --env <envName> CONTAINER_REGISTRY_REPOSITORY_NAME -b <YOUR_CR_REPO_NAME>
gh variable set --env <envName> CONTAINER_REGISTRY_URL -b <YOUR_ACR_URL>
gh variable set --env <envName> COSMOS_DB_ENDPOINT -b https://<YOUR_COSMOS_NAME>.documents.azure.com:443/
gh variable set --env <envName> USER_ASSIGNED_IDENTITY_CLIENT_ID -b <YOUR_MI_USER_CLIENT_ID>
gh variable set --env <envName> USER_ASSIGNED_IDENTITY_ID -b <YOUR_MI_USER_RESOURCE_ID>
```

---

### Admin Rights

USER_PRINCIPAL_ID is an optional settings at the environment level - set this only if you want your admin to have access to the Key Vault and Container Registry. You can customize this by environment if desired.

```bash
gh secret set --env dev USER_PRINCIPAL_ID <yourGuid>
```

<!-- ADMIN_IP_ADDRESS and USER_PRINCIPAL_ID are optional settings at the environment level - set these only if you want your admin to have access to the Key Vault and Container Registry. You can customize and run the following commands, or you can set these secrets up manually.

```bash
gh secret set --env dev ADMIN_IP_ADDRESS 192.168.1.1
gh secret set --env dev USER_PRINCIPAL_ID <yourGuid>
``` -->

---

## References

- [Deploying ARM Templates with GitHub Actions](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-github-actions)
- [GitHub Secrets CLI](https://cli.github.com/manual/gh_secret_set)

---

[Home Page](../README.md)
