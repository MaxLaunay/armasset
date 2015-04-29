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

if ($PSScriptRoot){
    [string]$RootDir = $PSScriptRoot
}else{
    if (Test-Path ".\Set-Configuration.ps1"){
        [string]$RootDir = Convert-Path .
    }
}

Switch-AzureMode -Name AzureServiceManagement

# Set variables
[string]$SubscriptionName = "Osiatis CIS - MSDN Dev-Test" # Specify our Azure Subscription Name
[string]$StorageAccountName = "sourcedatafiles"
[string]$ContainerName = "configurationfiles"
[string]$DSCFile = "$RootDir\DSC\environmentDSC.ps1"
[string]$SQLSetupConfigurationFile = "$RootDir\SQL\ConfigurationFile.ini"
[string]$SQLdatabaseFile = "$RootDir\SQL\database.sql"
[string]$WebPackageFile = "$RootDir\..\BCampTestWeb.Deployment\bin\Debug\StorageDrop\BCampTestWeb\package.zip"
[string]$Location = "North Europe"


# Set Azure Subscription
Set-AzureSubscription `
    -SubscriptionName $subscriptionName

# Create a storage account for Configuration Files if it does not exist
if (!((Get-AzureStorageAccount).StorageAccountName -contains $StorageAccountName)){
    New-AzureStorageAccount -StorageAccountName $StorageAccountName `
        -Location $Location
}

Set-AzureSubscription `
    -SubscriptionName $subscriptionName `
    -CurrentStorageAccountName $StorageAccountName

# create a container for Configuration File if it does not exist
if (!((Get-AzureStorageContainer).Name -contains $ContainerName)){
    New-AzureStorageContainer -Name $ContainerName
}

# push Configuration Files to the container of the storage account
.\Set-Configuration.ps1 `
    -SubscriptionName $SubscriptionName `
    -StorageAccountName $StorageAccountName `
    -ContainerName $ContainerName `
    -SQLSetupConfigurationFile $SQLSetupConfigurationFile `
    -SQLdatabaseFile $SQLdatabaseFile `
    -WebPackageFile $WebPackageFile `
    -DSCFile $DSCFile