param name string
param location string = resourceGroup().location
param tags object = {}

param kind string = ''
param reserved bool = true
@description('The pricing tier for the hosting plan.')
@allowed([
  'F1'
  'D1'
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1'
  'P2'
  'P3'
  'P4'
])
param sku string = 'F1'
@description('The instance size of the hosting plan (small, medium, or large).')
@allowed([
  '0'
  '1'
  '2'
])
param workerSize string = '1'

resource hostingPlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
    capacity: int(workerSize)
  }
  kind: kind
  properties: {
    reserved: reserved
  }
}

output id string = hostingPlan.id
output name string = hostingPlan.name
