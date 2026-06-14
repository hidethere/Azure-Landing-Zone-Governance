@description('Creates a hub-side virtual network peering to a spoke VNet')
param hubVnetName string
param spokeVnetId string
param spokeVnetName string

resource hubVnet 'Microsoft.Network/virtualNetworks@2025-07-01' existing = {
  name: hubVnetName
}

resource hubToSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2025-07-01' = {
  name: '${hubVnetName}-to-${spokeVnetName}'
  parent: hubVnet
  properties: {
    remoteVirtualNetwork: {
      id: spokeVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
  }
}

output peeringId string = hubToSpokePeering.id