<# 
.SYNOPSIS 
    Set configuration to use this project
.DESCRIPTION
    Set configuration to use this project and run a basic deployment :
        - 1 IaaS VM for Active Directory
        - 1 IaaS VM for SQL Server
        - 1 Azure Web Site
    Only SubscriptionName, StorageAccountName and envName must be set (because here must be unique in Azure). All other 
    parameters are in this script and in .\ResourcesManager\environment_template.json file.
    You must have an active Azure Subscription and set an Azure Account (Add-AzureAccount) before used this script
.EXAMPLE 
    ./Startup.ps1
.OUTPUTS 
   no output
#>

param (
    [string]$SubscriptionName = "Osiatis CIS - MSDN Dev-Test", # Specify our Azure Subscription Name
    [string]$StorageAccountName = "sourcedatafiles",
    [string]$envName = "armasset" # Lower Case, 11 chars max
)

Switch-AzureMode -Name AzureServiceManagement

# Set variables

[string]$ContainerName = "configurationfiles"
[string]$DSCFile = ".\DSC\environmentDSC.ps1"
[string]$SQLSetupConfigurationFile = ".\SQL\ConfigurationFile.ini"
[string]$SQLdatabaseFile = ".\SQL\database.sql"
[string]$WebPackageFile = ".\WebPackage\WebPackage.zip"
[string]$Location = "North Europe"
[string]$ParametersFile = ".\ResourcesManager\parameters.json"
[string]$TemplateFile = ".\ResourcesManager\environnement.json"
[string]$TemplateParametersFile = ".\ResourcesManager\parameters_template.json"

# Internal Variables
$DSCArchive = "$DSCFile.zip"

Set-AzureSubscription `
    -SubscriptionName $subscriptionName `
    -CurrentStorageAccountName $StorageAccountName

# push Configuration Files to the container of the storage account
.\Set-Configuration.ps1 `
    -SubscriptionName $SubscriptionName `
    -StorageAccountName $StorageAccountName `
    -ContainerName $ContainerName `
    -Location $Location `
    -ParametersFile $ParametersFile `
    -DSCFile $DSCFile `
    -SQLSetupConfigurationFile $SQLSetupConfigurationFile `
    -SQLdatabaseFile $SQLdatabaseFile `
    -WebPackageFile $WebPackageFile `
    -TemplateParametersFile $TemplateParametersFile

.\Set-Environment-With-Parameters-File.ps1 `
    -TemplateFile $TemplateFile `
    -ParametersFile $ParametersFile `
    -envName $envName `
    -subscriptionName $subscriptionName `
    -Location $Location `
    -StorageAccountName $StorageAccountName `
    -ContainerName $ContainerName `
    -DSCArchive $DSCArchive