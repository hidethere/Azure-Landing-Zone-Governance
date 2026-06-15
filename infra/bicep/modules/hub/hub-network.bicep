param location string
param vnetName string
param addressPrefixes string
param subnetBastionPrefix string
param subnetFirewallPrefix string
param bastionName string
param firewallName string
param devAddressPrefixes string
param testAddressPrefixes string
param prodAddressPrefixes string


var pipBastionName = '${vnetName}-pip-bastion'
var pipFirewallName = '${vnetName}-pip-firewall'
var bastionIpConfigName = 'bastion-config'
var firewallIpConfigName = 'fw-ipconfig'


// Hub VNet
resource vnetHub 'Microsoft.Network/virtualNetworks@2025-07-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [ addressPrefixes ]
    }
  }
}

// Subnets
resource subnetBastion 'Microsoft.Network/virtualNetworks/subnets@2025-07-01' = {
  name: 'AzureBastionSubnet'
  parent: vnetHub
  properties: {
    addressPrefix: subnetBastionPrefix
  }
}

resource subnetFirewall 'Microsoft.Network/virtualNetworks/subnets@2025-07-01' = {
  name: 'AzureFirewallSubnet'
  parent: vnetHub
  properties: {
    addressPrefix: subnetFirewallPrefix
  }
}

// Public IPs
resource pipBastion 'Microsoft.Network/publicIPAddresses@2025-07-01' = {
  name: pipBastionName
  location: location
  sku: { name: 'Standard' }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource pipFirewall 'Microsoft.Network/publicIPAddresses@2025-07-01' = {
  name: pipFirewallName
  location: location
  sku: { name: 'Standard' }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Azure Bastion
resource bastion 'Microsoft.Network/bastionHosts@2025-07-01' = {
  name: bastionName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: bastionIpConfigName
        properties: {
          subnet: { id: subnetBastion.id }
          publicIPAddress: { id: pipBastion.id }
        }
      }
    ]
  }
}

// Azure Firewall
resource firewall 'Microsoft.Network/azureFirewalls@2025-07-01' = {
  name: firewallName
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: firewallIpConfigName
        properties: {
          subnet: { id: subnetFirewall.id }
          publicIPAddress: { id: pipFirewall.id }
        }
      }
    ]
    applicationRuleCollections: [
      {
        name: 'app-egress'
        properties: {
          priority: 100
        action: {
          type: 'Allow'
        }
        rules: [
          {
            name: 'allow-microsoft'
            sourceAddresses: [
              devAddressPrefixes
              testAddressPrefixes
              prodAddressPrefixes
            ]
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            targetFqdns: [
              'packages.microsoft.com'
              'archive.ubuntu.com'
              'security.ubuntu.com'
            ]
          }
        ]
        }
        
      }
    ]
  }
}



output vnetId string = vnetHub.id
output subnetBastionId string = subnetBastion.id
output subnetFirewallId string = subnetFirewall.id
output pipBastionId string = pipBastion.id
output pipFirewallId string = pipFirewall.id
output bastionId string = bastion.id
output firewallId string = firewall.id
output vnetName string = vnetName
output firewallPrivateIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
