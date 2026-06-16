targetScope = 'subscription'

param platformAdminsObjectId string

param devGroupObjectId string
param devRgName string


param prodReadersObjectId string

resource platformAdminsRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, platformAdminsObjectId, 'owner-role')

  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '8e3af657-a8ff-443c-a75c-2fe8c4bcb635' // Owner
    )
    principalId: platformAdminsObjectId
  }
}

resource devRg 'Microsoft.Resources/resourceGroups@2025-04-01' existing = {
  name: devRgName
}

resource devContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(devRg.id, devGroupObjectId, 'contributor')

  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'b24988ac-6180-42a0-ab88-20f7382dd24c' // Contributor
    )
    principalId: devGroupObjectId
  }
}


resource prodRg 'Microsoft.Resources/resourceGroups@2025-04-01' existing = {
  name: 'azlz-rg-prod'
}

resource prodReaderRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(prodRg.id, prodReadersObjectId, 'reader')

  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'acdd72a7-3385-48ef-bd42-f606fba81ae7' // Reader
    )
    principalId: prodReadersObjectId
  }
}
