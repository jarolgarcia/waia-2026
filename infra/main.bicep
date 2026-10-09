targetScope = 'resourceGroup'

@description('Azure region for the WAIA server.')
param location string = resourceGroup().location
@description('Virtual machine name.')
param vmName string = 'waia-vm'
@description('Non-root Linux administrator username.')
param adminUsername string = 'waiaadmin'
@description('SSH public key for the standard administrator user.')
@secure()
param adminSshPublicKey string
@description('CIDR allowed to reach SSH, for example 203.0.113.10/32. Do not use 0.0.0.0/0.')
param adminAllowedIpCidr string
param vmSize string = 'Standard_B2s'

var vnetName = '${vmName}-vnet'
var subnetName = 'app'
var nsgName = '${vmName}-nsg'
var publicIpName = '${vmName}-pip'
var nicName = '${vmName}-nic'
var workspaceName = '${vmName}-logs'

resource logs 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  properties: {
    retentionInDays: 30
    sku: { name: 'PerGB2018' }
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      { name: 'allow-ssh-admin-only'; properties: { priority: 100; access: 'Allow'; direction: 'Inbound'; protocol: 'Tcp'; sourceAddressPrefix: adminAllowedIpCidr; sourcePortRange: '*'; destinationAddressPrefix: '*'; destinationPortRange: '22' } }
      { name: 'allow-http'; properties: { priority: 110; access: 'Allow'; direction: 'Inbound'; protocol: 'Tcp'; sourceAddressPrefix: '*'; sourcePortRange: '*'; destinationAddressPrefix: '*'; destinationPortRange: '80' } }
      { name: 'allow-https'; properties: { priority: 120; access: 'Allow'; direction: 'Inbound'; protocol: 'Tcp'; sourceAddressPrefix: '*'; sourcePortRange: '*'; destinationAddressPrefix: '*'; destinationPortRange: '443' } }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: { addressPrefixes: ['10.20.0.0/16'] }
    subnets: [{ name: subnetName; properties: { addressPrefix: '10.20.1.0/24'; networkSecurityGroup: { id: nsg.id } } }]
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: publicIpName
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static'; dnsSettings: { domainNameLabel: toLower(vmName) } }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [{ name: 'ipconfig'; properties: { privateIPAllocationMethod: 'Dynamic'; publicIPAddress: { id: publicIp.id }; subnet: { id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName) } } }]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  identity: { type: 'SystemAssigned' }
  properties: {
    hardwareProfile: { vmSize: vmSize }
    storageProfile: {
      imageReference: { publisher: 'Canonical'; offer: '0001-com-ubuntu-server-jammy'; sku: '22_04-lts-gen2'; version: 'latest' }
      osDisk: { createOption: 'FromImage'; managedDisk: { storageAccountType: 'Premium_LRS' } }
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      linuxConfiguration: { disablePasswordAuthentication: true; provisionVMAgent: true; ssh: { publicKeys: [{ path: '/home/${adminUsername}/.ssh/authorized_keys'; keyData: adminSshPublicKey }] } }
      customData: base64(replace(loadTextContent('cloud-init.yaml'), '__ADMIN_USERNAME__', adminUsername))
    }
    networkProfile: { networkInterfaces: [{ id: nic.id }] }
    diagnosticsProfile: { bootDiagnostics: { enabled: true } }
  }
}

resource vmMetrics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'vm-platform-metrics'
  scope: vm
  properties: { workspaceId: logs.id; metrics: [{ category: 'AllMetrics'; enabled: true }] }
}

output publicIpAddress string = publicIp.properties.ipAddress
output standardAdminUser string = adminUsername
output logAnalyticsWorkspace string = logs.name
