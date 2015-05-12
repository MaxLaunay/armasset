<# 
.SYNOPSIS 
    Upload configuration files used to create the environment and update parameters.json.
.DESCRIPTION 
    Upload configuration files used to create the environment. Configuration Files are :
        - .\ResourcesManager\environnement.json : contains all resources who should be deployed
        - .\DSC\environmentDSC.ps1 : contains all DSC configurations who should be push to IaaS VMs
        - .\SQL\ConfigurationFile.ini : File use to set an unattend installation of SQL Server
        - .\SQL\database.sql : SQL Script use to create a database in the IaaS SQL Server
    Update parameters.json to use your own storage account and containers
    You must have an active Azure Subscription tu ose this script
.EXAMPLE 
   Set-Configuration.ps1 ` 
        -SubscriptionName "YourSubcription" `
        -StorageAccountName "YourStorageAccount" `
        -ContainerName "YourContainer" `
        -Location = "Your Azure Datacenter (eg : North Europe)" `
        -ParametersFile "..\Sample\ARM\parameters.json" `
        -TemplateParametersFile "..\Sample\ARM\parameters_template.json" `
        -DSCFile "..\Sample\DSC\environmentDSC.ps1.zip" `
        -SQLSetupConfigurationFile "..\Sample\SQL\ConfigurationFile.ini" `
        -SQLdatabaseFile "..\Sample\SQL\database.sql" `
        -WebPackageFile "..\Sample\WebPackage\WebPackage.zip"
.OUTPUTS 
    no output
#>

param (
    [Parameter(Mandatory = $true)][string]$SubscriptionName,
    [Parameter(Mandatory = $true)][string]$StorageAccountName,
    [Parameter(Mandatory = $true)][string]$ContainerName,
    [Parameter(Mandatory = $true)][string]$Location,
    [Parameter(Mandatory = $true)][string]$ParametersFile,
    [Parameter(Mandatory = $true)][string]$TemplateParametersFile,
    [Parameter(Mandatory = $true)][string]$DSCFile,
    [Parameter(Mandatory = $true)][string]$SQLSetupConfigurationFile,
    [Parameter(Mandatory = $true)][string]$SQLdatabaseFile,
    [Parameter(Mandatory = $true)][string]$WebPackageFile,
    [Parameter(Mandatory = $true)][string]$TemplateFile 
)

# Switch to Service Management Mode
Switch-AzureMode -Name AzureServiceManagement

#Select-AzureSubscription $subscriptionName
# Set Azure Subscription and current Storage Account
Set-AzureSubscription `
    -SubscriptionName $subscriptionName `
    -CurrentStorageAccountName $StorageAccountName

try{
    # Create a storage account for Configuration Files if it does not exist
    if (!((Get-AzureStorageAccount).StorageAccountName -contains $StorageAccountName)){
        New-AzureStorageAccount -StorageAccountName $StorageAccountName `
            -Location $Location | Out-Null
        write-verbose "Storage Account $StorageAccountName created"
    }
    
    # create a container (with public blob) for Configuration Files if it does not exist
    if (!((Get-AzureStorageContainer).Name -contains $ContainerName)){
        New-AzureStorageContainer -Name $ContainerName -Permission Blob | out-null
        write-verbose "Container $ContainerName created"
    }

    # get Parameters.json
    $ParametersFileObj = Get-Content $TemplateParametersFile -raw | ConvertFrom-Json

    # Upload DSC File File
    <#Publish-AzureVMDscConfiguration `
        -ConfigurationPath $DSCFile `
        -containerName $ContainerName `
        -Force
    write-output "- File '$DSCFile' push to the container '$ContainerName' on the storage account '$StorageAccountName'"#>
    Set-AzureStorageBlobContent -Container $ContainerName -File $DSCFile -Force | out-Null
    write-output "- File '$DSCFile' push to the container '$ContainerName' on the storage account '$StorageAccountName'"
    # Set DSCModuleURI
    $ParametersFileObj.DSCModuleURI.value = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/" `
        + (Get-Item $DSCFile).Name
    
    # Upload SQL Setup Configuration File
    Set-AzureStorageBlobContent -Container $ContainerName -File $SQLSetupConfigurationFile -Force | out-Null
    write-output "- File '$SQLSetupConfigurationFile' push to the container '$ContainerName' on the storage account '$StorageAccountName'"
    
    # Set SQLSetupConfigurationFileUri
    $ParametersFileObj.SQLSetupConfigurationFileUri.value = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/" `
        + (Get-Item $SQLSetupConfigurationFile).Name
    
    # Upload SQL Database File
    Set-AzureStorageBlobContent -Container $ContainerName -File $SQLdatabaseFile -Force | out-Null
    write-output "- File '$SQLdatabaseFile' push to the container '$ContainerName' on the storage account '$StorageAccountName'"
    # Set SQLDatabaseFileUri
    $ParametersFileObj.SQLDatabaseFileUri.value = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/" `        + (Get-Item $SQLdatabaseFile).Name
    
    # Upload Web Package File
    Set-AzureStorageBlobContent -Container $ContainerName -File $WebPackageFile -Force | out-Null
    write-output "- File '$WebPackageFile' push to the container '$ContainerName' on the storage account '$StorageAccountName'"

    # Upload Json Template
    Set-AzureStorageBlobContent -Container $ContainerName -File $TemplateFile -Force | out-Null
    write-output "- File '$TemplateFile' push to the container '$ContainerName' on the storage account '$StorageAccountName'"

    # Save Parameters.json
    $ParametersFileObj | ConvertTo-Json | Out-File $ParametersFile

}catch{
    write-host "Error during Files upload"
    throw $_
    #exit 1
}