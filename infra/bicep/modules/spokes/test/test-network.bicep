param location string
param vnetName string
param addressPrefixes string
param subnetName string
param subnetPrefix string
param hubVnetId string = ''
param hubVnetName string = ''

// Spoke test Vnet
resource vnetSpoke 'Microsoft.Network/virtualNetworks@2025-07-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [ addressPrefixes ]
    }
  }
}

// Subnets
resource subnetSpoke 'Microsoft.Network/virtualNetworks/subnets@2025-07-01' = {
  name: subnetName
  parent: vnetSpoke
  properties: {
    addressPrefix: subnetPrefix
  }
}

// Peering
resource spokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2025-07-01' = if(hubVnetId != '') {
  name: '${vnetName}-to-${hubVnetName}'
  parent: vnetSpoke
  properties: {
    remoteVirtualNetwork: {
      id: hubVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
  }
}

output vnetId string = vnetSpoke.id
output subnetId string = subnetSpoke.id
output peeringId string = spokeToHubPeering.id
