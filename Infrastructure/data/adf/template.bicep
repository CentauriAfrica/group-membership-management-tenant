@minLength(2)
@maxLength(3)
@description('Enter an abbreviation for the solution.')
param solutionAbbreviation string

@minLength(2)
@maxLength(6)
@description('Enter an abbreviation for the environment.')
param environmentAbbreviation string

@description('Resource location.')
param location string

@description('Tenant Id.')
param tenantId string

@description('Name of SQL Server')
param sqlServerName string = '${solutionAbbreviation}-data-${environmentAbbreviation}-destination'

@description('Name of Azure Data Factory')
param azureDataFactoryName string = '${solutionAbbreviation}-data-${environmentAbbreviation}-adf'

var dataKeyVaultName = '${solutionAbbreviation}-data-${environmentAbbreviation}'

resource dataKeyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
	name: dataKeyVaultName
	scope: resourceGroup()
}

module azureDataFactoryTemplate 'azureDataFactory.bicep' = {
	name: 'azureDataFactoryTemplate'
	params: {
		factoryName: azureDataFactoryName
		environmentAbbreviation: environmentAbbreviation
		location: location
		sqlAdminPassword: dataKeyVault.getSecret('sqlAdminPassword')
		sqlServerName: sqlServerName
		azureUserReaderUrl: dataKeyVault.getSecret('azureUserReaderUrl')
		azureUserReaderFunctionKey: dataKeyVault.getSecret('azureUserReaderKey')
		storageAccountConnectionString: dataKeyVault.getSecret('storageAccountConnectionString')
	}
}

module keyVaultPoliciesTemplate 'keyVaultAccessPolicies.bicep' = {
	name: 'keyVaultPoliciesTemplate-${solutionAbbreviation}'
	params: {
		name: dataKeyVaultName
		policies: [
			{
				objectId: azureDataFactoryTemplate.outputs.systemAssignedIdentityId
				secrets: [
					'list'
					'get'
				]
			}
		]
		tenantId: tenantId
	}
	dependsOn: [
		azureDataFactoryTemplate
	]
}
