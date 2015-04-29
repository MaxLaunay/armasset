<# 
.SYNOPSIS 
   Upload configuration files used to create the environment
   Create a new VM Image, based on the provided stock image, and the WebPI application. 
.DESCRIPTION 
   Upload configuration files used to create the environment. Configuration Files are :
   - .\ResourcesManager\environnement.json : contains all resources who should be deployed
   - .\DSC\environmentDSC.ps1 : contains all DSC configurations who should be push to IaaS VMs
   (- .\SQL\ConfigurationFile.ini :)
   (- .\SQL\database.sql :)
   You must have an active Azure Subscription and a storage account
   
(
.EXAMPLE 
   New-AzureVmImageWithWebPiApp.ps1 ` 
       -WebPIApplicationName blogengineNET -WebPIApplicationAnswerFile .\BlogengineNet.app ` 
       -ImageName bengineimage -ImageLabel bengineimagelabel  
.OUTPUTS 
   Microsoft.WindowsAzure.Management.ServiceManagement.Model.OSImageContext 
)
#>

param (
    [Parameter(Mandatory = $true)][string]$SubscriptionName = "Osiatis CIS - MSDN Dev-Test",
    [Parameter(Mandatory = $true)][string]$StorageAccountName = "sourcedatafiles",
    [Parameter(Mandatory = $true)][string]$ContainerName = "configurationfiles",
    [Parameter(Mandatory = $true)][string]$DSCFile = ".\DSC\environmentDSC.ps1",
    [Parameter(Mandatory = $true)][string]$SQLSetupConfigurationFile = ".\SQL\ConfigurationFile.ini",
    [Parameter(Mandatory = $true)][string]$SQLdatabaseFile = ".\SQL\database.sql",
    [Parameter(Mandatory = $true)][string]$WebPackageFile = "..\BCampTestWeb.Deployment\bin\Debug\StorageDrop\BCampTestWeb\package.zip"
)

# Modules Importation
Import-Module 'C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Azure.psd1'
Import-Module 'C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\ResourceManager\AzureResourceManager\AzureResourceManager.psd1'
#
# Switch to Service Management Mode
Switch-AzureMode -Name AzureServiceManagement
#
#Select-AzureSubscription $subscriptionName
# Set Azure Subscription and current Storage Account
Set-AzureSubscription `
    -SubscriptionName $subscriptionName `
    -CurrentStorageAccountName $StorageAccountName

try{
    # Upload DSC File File
    Publish-AzureVMDscConfiguration `
        -ConfigurationPath $DSCFile `
        -containerName $ContainerName `
        -Force
    write-output "- File '$DSCFile' push to the container '$ContainerName' on the storage account '$StorageAccountName'"
    # Upload SQL Setup Configuration File
    Set-AzureStorageBlobContent -Container $ContainerName -File $SQLSetupConfigurationFile -Force | out-Null
    write-output "- File '$SQLSetupConfigurationFile' push to the container '$ContainerName' on the storage account '$StorageAccountName'"
    # Upload SQL Database File
    Set-AzureStorageBlobContent -Container $ContainerName -File $SQLdatabaseFile -Force | out-Null
    write-output "- File '$SQLdatabaseFile' push to the container '$ContainerName' on the storage account '$StorageAccountName'"
    # Upload Web Package File
    Set-AzureStorageBlobContent -Container $ContainerName -File $WebPackageFile -Force | out-Null
    write-output "- File '$WebPackageFile' push to the container '$ContainerName' on the storage account '$StorageAccountName'"
}catch{
    write-host "Error during Files upload"
    throw $_
    break
}