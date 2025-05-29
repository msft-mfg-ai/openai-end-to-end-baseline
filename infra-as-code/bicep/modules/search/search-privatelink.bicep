param searchName string
param storageAccountName string = ''
param storageAccountResourceGroupName string = resourceGroup().name
param openAiServiceName string = ''
param openAiServiceResourceGroupName string = resourceGroup().name

resource searchService 'Microsoft.Search/searchServices@2024-06-01-preview' existing =  {
  name: searchName
}

resource existingStorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' existing = if (!empty(storageAccountName)) {
  name: storageAccountName
  scope: resourceGroup(storageAccountResourceGroupName)
}

resource existingOpenAiService 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = if (!empty(openAiServiceName)) {
  name: openAiServiceName
  scope: resourceGroup(openAiServiceResourceGroupName)
}

resource linkToStorage 'Microsoft.Search/searchServices/sharedPrivateLinkResources@2024-06-01-preview' = if (!empty(storageAccountName)) {
  name: 'link-to-storage-${storageAccountName}'
  parent: searchService
  properties: {
    groupId: 'blob'
    privateLinkResourceId: existingStorageAccount.id
    requestMessage: 'automatically created by the system'
    status: 'Approved'
    provisioningState: 'Succeeded'
  }
}

resource linkToOpenAi 'Microsoft.Search/searchServices/sharedPrivateLinkResources@2024-06-01-preview' = if (!empty(openAiServiceName)) {
  name: 'link-to-openai-${openAiServiceName}'
  parent: searchService
  properties: {
    groupId: 'openai_account'
    privateLinkResourceId: existingOpenAiService.id
    requestMessage: 'automatically created by the system'
    status: 'Approved'
    provisioningState: 'Succeeded'
  }
  dependsOn: [
    linkToStorage
  ]
}
