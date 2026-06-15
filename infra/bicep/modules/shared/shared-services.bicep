param location string
param vnetName string
param addressPrefixes string
param subnetPrivEndpName string = 'snet-privendpoint'
param subnetPrivEndpAddressPrefix string
param keyVaultName string
param hubVnetId string = ''
param hubVnetName string = ''

param devVnetId string
param prodVnetId string
param testVnetId string
// Shared VNet
resource vnetShared 'Microsoft.Network/virtualNetworks@2025-07-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [ addressPrefixes ]
    }
  }
}

resource subnetPrivEndp 'Microsoft.Network/virtualNetworks/subnets@2025-07-01' = {
  name: subnetPrivEndpName
  parent: vnetShared
  properties: {
    addressPrefix: subnetPrivEndpAddressPrefix
  }
}

// Key Vault (shared)
resource keyvault 'Microsoft.KeyVault/vaults@2026-02-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    enableRbacAuthorization: true
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      bypass: 'None'
      defaultAction: 'Deny'
    }
  }
}

// Log Analytics workspace
resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${keyVaultName}-law'
  location: location
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 30
  }
}

resource devVnet 'Microsoft.Network/virtualNetworks@2025-07-01' existing = {
  name: devVnetId
}

resource prodVnet 'Microsoft.Network/virtualNetworks@2025-07-01' existing = {
  name: prodVnetId
}

resource testVnet 'Microsoft.Network/virtualNetworks@2025-07-01' existing = {
  name: testVnetId
}
// Private DNS for keyvault private endpoint
resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
}

resource sharedDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${dnsZone.name}-${vnetName}-link'
  parent: dnsZone
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetShared.id
    }
    registrationEnabled: false
  }
}

resource devDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${dnsZone.name}-${devVnet.name}-link'
  parent: dnsZone
  location: 'global'
  properties: {
    virtualNetwork: {
      id: devVnet.id
    }
    registrationEnabled: false
  }
}

resource testDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${dnsZone.name}-${testVnet.name}-link'
  parent: dnsZone
  location: 'global'
  properties: {
    virtualNetwork: {
      id: testVnet.id
    }
    registrationEnabled: false
  }
}

resource prodDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${dnsZone.name}-${prodVnet.name}-link'
  parent: dnsZone
  location: 'global'
  properties: {
    virtualNetwork: {
      id: prodVnet.id
    }
    registrationEnabled: false
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: '${keyVaultName}-pe'
  location: location
  properties: {
    subnet: {
      id: subnetPrivEndp.id
    }
    privateLinkServiceConnections: [
      {
        name: '${keyVaultName}-pe-conn'
        properties: {
          privateLinkServiceId: keyvault.id
          groupIds: [ 'vault' ]
        }
      }
    ]
  }
}

resource dnsKvZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = {
  name: 'kv-dns-zone-group'
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'keyvault-dns'
        properties: {
          privateDnsZoneId: dnsZone.id
        }
      }
    ]
  }
}

// Peering
resource spokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2025-07-01' = if(hubVnetId != '') {
  name: '${vnetName}-to-${hubVnetName}'
  parent: vnetShared
  properties: {
    remoteVirtualNetwork: {
      id: hubVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
  }
}

// Diagnostic settings
resource keyvaultDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${keyvault.name}-diag'
  scope: keyvault
  properties: {
    workspaceId: law.id
    logs: [
      {
        categoryGroup: 'Audit'
        enabled: true
      }
    ]
  }
}

output keyVaultId string = keyvault.id
output workspaceId string = law.id
output vnetId string = vnetShared.id
output subnetPrivEndpId string = subnetPrivEndp.id
