// Role Assignment module for ACR pull permissions

@description('Principal ID to assign the role to')
param principalId string

@description('ACR resource ID')
param acrId string

@description('Role definition ID (AcrPull = 7f951dda-4ed3-4680-a7ca-43fe172d538d)')
param roleDefinitionId string = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

var roleAssignmentName = guid(acrId, principalId, roleDefinitionId)

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: roleAssignmentName
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

// Reference existing ACR
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: last(split(acrId, '/'))
}

output id string = roleAssignment.id
