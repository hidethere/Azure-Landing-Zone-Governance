targetScope = 'subscription'
@description('Deployment location')
param location string

@description('prefix for generated names')
param prefix string = 'azlz'

@description('Top-level resource group names')
param resourceGroups object

@description('Hub settings')
param hub object

@description('Shared services settings')
param shared object

@description('Dev spoke settings')
param dev object

@description('Test spoke settings')
param test object

@description('Prod spoke settings')
param prod object

@description('identity settings')
param identity object

@description('governance settings')
param gov object


// Create resource groups
resource rgHub 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroups.hub
  location: location
}

resource rgShared 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroups.shared
  location: location
}

resource rgDev 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroups.dev
  location: location
}

resource rgTest 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroups.test
  location: location
}

resource rgProd 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroups.prod
  location: location
}

// Hub network module in hub RG
module hubNetwork 'modules/hub/hub-network.bicep' = {
  name: 'hubNetwork'
  scope: resourceGroup(resourceGroups.hub)
  params: {
    location: location
    vnetName: hub.vnetName
    addressPrefixes: hub.addressPrefixes
    subnetBastionPrefix: hub.subnetBastionPrefix
    subnetFirewallPrefix: hub.subnetFirewallPrefix
    bastionName: hub.bastionName
    firewallName: hub.firewallName
    devSubnetPrefix: dev.subnetPrefix
    prodSubnetPrefix: prod.subnetPrefix
    testSubnetPrefix: test.subnetPrefix
  }
  dependsOn: [ rgHub ]
}



// Dev network in dev RG
module devNetwork 'modules/spokes/dev/dev-network.bicep' = {
  name: 'devNetwork'
  scope: resourceGroup(resourceGroups.dev)
  params: {
    location: location
    vnetName: dev.vnetName
    addressPrefixes: dev.addressPrefixes
    subnetName: dev.subnetName
    subnetPrefix: dev.subnetPrefix
    hubVnetId: hubNetwork.outputs.vnetId
    hubVnetName: hub.vnetName
    firewallPrivateIp: hubNetwork.outputs.firewallPrivateIp
  }
  dependsOn: [ rgDev ]
}


// Test network in test RG
module testNetwork 'modules/spokes/test/test-network.bicep' = {
  name: 'testNetwork'
  scope: resourceGroup(resourceGroups.test)
  params: {
    location: location
    vnetName: test.vnetName
    addressPrefixes: test.addressPrefixes
    subnetName: test.subnetName
    subnetPrefix: test.subnetPrefix
    hubVnetId: hubNetwork.outputs.vnetId
    hubVnetName: hub.vnetName
    firewallPrivateIp: hubNetwork.outputs.firewallPrivateIp
  }
  dependsOn: [ rgTest ]
}


// Prod network in prod RG
module prodNetwork 'modules/spokes/prod/prod-network.bicep' = {
  name: 'prodNetwork'
  scope: resourceGroup(resourceGroups.prod)
  params: {
    location: location
    vnetName: prod.vnetName
    addressPrefixes: prod.addressPrefixes
    subnetName: prod.subnetName
    subnetPrefix: prod.subnetPrefix
    hubVnetId: hubNetwork.outputs.vnetId
    hubVnetName: hub.vnetName
    firewallPrivateIp: hubNetwork.outputs.firewallPrivateIp
  }
  dependsOn: [ rgProd ]
}


// Shared services module in shared RG
module sharedServices 'modules/shared/shared-services.bicep' = {
  name: 'sharedServices'
  scope: resourceGroup(resourceGroups.shared)
  params: {
    location: location
    vnetName: shared.vnetName
    addressPrefixes: shared.addressPrefixes
    subnetPrivEndpAddressPrefix: shared.subnetPrivEndpPrefix
    keyVaultName: shared.keyVaultName
    devVnetId: devNetwork.outputs.vnetId
    testVnetId: testNetwork.outputs.vnetId
    prodVnetId: prodNetwork.outputs.vnetId
  }
  dependsOn: [ rgShared ]
}

// Dev compute in dev RG
module devCompute 'modules/compute/dev/dev-compute.bicep' = {
  name: 'devCompute'
  scope: resourceGroup(resourceGroups.dev)
  params: {
    location: location
    subnetId: devNetwork.outputs.subnetId
    vmName: '${prefix}-vm-dev'
    workspaceId: sharedServices.outputs.workspaceId
    adminUsername: identity.adminUsername
    vmAccessId: gov.vmAccessId
  }
  dependsOn: [ rgDev ]
}



// Test compute in test RG
module testCompute 'modules/compute/test/test-compute.bicep' = {
  name: 'testCompute'
  scope: resourceGroup(resourceGroups.test)
  params: {
    location: location
    subnetId: testNetwork.outputs.subnetId
    vmName: '${prefix}-vm-test'
    workspaceId: sharedServices.outputs.workspaceId
    adminUsername: identity.adminUsername
    vmAccessId: gov.vmAccessId

  }
  dependsOn: [ rgTest ]
}


// Prod compute in prod RG
module prodCompute 'modules/compute/prod/prod-compute.bicep' = {
  name: 'prodCompute'
  scope: resourceGroup(resourceGroups.prod)
  params: {
    location: location
    subnetId: prodNetwork.outputs.subnetId
    vmName: '${prefix}-vm-prod'
    workspaceId: sharedServices.outputs.workspaceId
    adminUsername: identity.adminUsername
    vmAccessId: gov.vmAccessId

  }
  dependsOn: [ rgProd ]
}

// Hub-to-spoke peerings in hub RG
module hubToDevPeering 'modules/hub/peering.bicep' = {
  name: 'hubToDevPeering'
  scope: resourceGroup(resourceGroups.hub)
  params: {
    hubVnetName: hub.vnetName
    spokeVnetId: devNetwork.outputs.vnetId
    spokeVnetName: dev.vnetName
  }

}

module hubToTestPeering 'modules/hub/peering.bicep' = {
  name: 'hubToTestPeering'
  scope: resourceGroup(resourceGroups.hub)
  params: {
    hubVnetName: hub.vnetName
    spokeVnetId: testNetwork.outputs.vnetId
    spokeVnetName: test.vnetName
  }

}

module hubToProdPeering 'modules/hub/peering.bicep' = {
  name: 'hubToProdPeering'
  scope: resourceGroup(resourceGroups.hub)
  params: {
    hubVnetName: hub.vnetName
    spokeVnetId: prodNetwork.outputs.vnetId
    spokeVnetName: prod.vnetName
  }
}

// Governance
/*
module governancePolicies 'modules/governance/policies.bicep' = {
  name: 'governancePolicies'
  scope: subscription()
  params: {
    location: location
  }
  dependsOn: [ hubNetwork, sharedServices ]
}
*/

output resourceGroupNames object = resourceGroups
output hubOutput object = hubNetwork.outputs
output sharedOutput object = sharedServices.outputs
output devOutput object = devNetwork.outputs
output testOutput object = testNetwork.outputs
output prodOutput object = prodNetwork.outputs


