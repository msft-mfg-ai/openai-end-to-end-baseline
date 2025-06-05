param apimName string = ''
param apimLoggerName string = ''
param cognitiveServicesName string = ''

param deploymentSuffix string = ''

module apimApisSwagger 'apis/swagger-api.bicep' = {
  name: 'apim-swagger-api${deploymentSuffix}'
  params: {
    serviceName: apimName
  }
}

module apimBackendsOpenAI 'apim-backends-aoai.bicep' = {
  name: 'apim-openai-backends${deploymentSuffix}'
  params: {
    apimName: apimName
    backendPoolName: 'openaibackendpool'
    backendNames: [
      cognitiveServicesName
    ]
  }
}

module apimNameValueOpenAIPool 'apim-namevalue.bicep' = {
  name: 'apim-namedvalue-openai-pool${deploymentSuffix}'
  params: {
    apiManagementServiceName: apimName
    name: 'openai-backend-pool'
    displayName: 'OpenAI-Backend-Pool'
    value: apimBackendsOpenAI.outputs.backendPoolName
  }
}

module apimNamedValueOpenAINonLoadBalancedPool 'apim-namevalue.bicep' = {
  name: 'apim-namedvalue-openai-non-load-balanced-pool${deploymentSuffix}'
  params: {
    name: 'non-load-balanced-openai-backend-name'
    apiManagementServiceName: apimName
    displayName: 'non-load-balanced-openai-backend-name'
    value: cognitiveServicesName
  }
}

module apimApisOpenAI 'apis/openai-api.bicep' = {
  name: 'apim-openai-api${deploymentSuffix}'
  params: {
    serviceName: apimName
    // backendName: apimBackendsOpenAI.outputs.backendPoolName
    apimLoggerName: apimLoggerName
  }
  dependsOn: [
    apimNameValueOpenAIPool
    apimNamedValueOpenAINonLoadBalancedPool
  ]
}
