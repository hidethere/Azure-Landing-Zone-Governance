param location string
param subnetId string
param vmName string
param workspaceId string
param managementSource string = '*'

param sshPublicKey string
param vmAccessId string
param adminUsername string

var nicName = 'nic-${vmName}'
var nsgName = 'nsg-${vmName}'


resource vmNsg 'Microsoft.Network/networkSecurityGroups@2025-07-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-SSH'
        properties: {
          priority: 100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: managementSource
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRanges: [ '22' ]
        }
      }
    ]
  }
}

resource vmNic 'Microsoft.Network/networkInterfaces@2025-07-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: { id: subnetId }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2025-11-01' = {
  name: vmName
  location: location
  identity: { type: 'SystemAssigned' }
  properties: {
    hardwareProfile: { vmSize: 'Standard_B2s' }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: { storageAccountType: 'Standard_LRS' }
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
         ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
      
    }
    
    networkProfile: { networkInterfaces: [ { id: vmNic.id } ] }
    
  }
  
}

resource vmLoginRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(vm.id, vmAccessId, 'vm-login')
  scope: vm
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '1c0163c0-47e6-4577-8991-ea5c82e286e4' // VM adminstrator Login
    )
    principalId: vmAccessId
  }
}
// SSH Entra ID login
resource aadSSH 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = {
  name: 'AADSSHLoginForLinux'
  parent: vm
  location: location

  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADSSHLoginForLinux'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
  }

}

// Diagnostic settings
resource vmDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${vm.name}-diag'
  scope: vm
  properties: { workspaceId: workspaceId }
}

output nicId string = vmNic.id
output vmId string = vm.id
output nsgId string = vmNsg.id 
