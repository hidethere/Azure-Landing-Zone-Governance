/*
resource vmUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(vm.id, 'vm-user-login')
  
  scope: vm
  
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'fb879df8-f326-4884-b1cf-06f3ad86be52' // VM User Login
      )
      principalId: userObjectId
    }
  }
  */
