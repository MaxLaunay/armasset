<# 
.SYNOPSIS 
   
.DESCRIPTION
    ...
    You must have an active Azure Subscription and set an Azure Account (Add-AzureAccount) Before used this script
   
(
.EXAMPLE 
   Startup.ps1
.OUTPUTS 
   Microsoft.WindowsAzure.Management.ServiceManagement.Model.OSImageContext 
)
#>

Switch-AzureMode -Name AzureServiceManagement

# Set variables
[string]$SubscriptionName = "Osiatis CIS - MSDN Dev-Test" # Specify our Azure Subscription Name
[string]$StorageAccountName = "sourcedatafiles"
[string]$ContainerName = "configurationfiles"
[string]$DSCFile = ".\DSC\environmentDSC.ps1"
[string]$SQLSetupConfigurationFile = ".\SQL\ConfigurationFile.ini"
[string]$SQLdatabaseFile = ".\SQL\database.sql"
[string]$WebPackageFile = ".\WebPackage\WebPackage.zip"
[string]$Location = "North Europe"
[string]$ParametersFile = ".\ResourcesManager\parameters.json"
[string]$TemplateFile = ".\ResourcesManager\environnement.json"
[string]$TemplateParametersFile = = ".\ResourcesManager\environnement_template.json"
[string]$envName = "armasset" # Lower Case, 11 chars max

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
    -WebPackageFile $WebPackageFile

.\Set-Environment-With-Parameters-File.ps1 `
    -TemplateFile $TemplateFile `
    -ParametersFile $ParametersFile `
    -envName $envName `
    -subscriptionName $subscriptionName `
    -Location $Location `
    -StorageAccountName $StorageAccountName `
    -ContainerName $ContainerName `
    -DSCArchive $DSCArchive