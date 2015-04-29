<# 
.SYNOPSIS 
    Create the environment specified in Template File with parameters specified in parameters file.
.DESCRIPTION 
    Create the environnement specified in the template File (by default .\ResourcesManager\Environment.json) with 
    the parameters specified in the parameters file (by default .\ResourcesManager\parameters.json).
    To use this script, you must : 
        - have an active Azure Subscription 
        - run the script .\set-configuration.ps1 one time
.EXAMPLE 
    Set-Environment-With-Parameters-File.ps1 `
        -envName "YourEnvironement" `
        -subscriptionName "Your Subscription" `
        -Location "Your Azure Datacenter (eg : North Europe)" `
        -StorageAccountName "yourstorageaccount" `
        -ContainerName "yourcontainer" `
        -TemplateFile ".\ResourcesManager\environnement.json" `
        -ParametersFile ".\ResourcesManager\parameters.json" `
        -DSCArchive "environmentDSC.ps1.zip"
.OUTPUTS 
    no output
#>
param (
    [Parameter(Mandatory = $true)][string]$envName,
    [Parameter(Mandatory = $true)][string]$subscriptionName,
    [Parameter(Mandatory = $true)][string]$Location,
    [Parameter(Mandatory = $true)][string]$StorageAccountName,
    [Parameter(Mandatory = $true)][string]$ContainerName,
    [Parameter(Mandatory = $true)][string]$DSCArchive,
    [string]$TemplateFile = ".\ResourcesManager\environnement.json",
    [string]$ParametersFile = ".\ResourcesManager\parameters.json"
)


<#[string]$SubscriptionName = "Osiatis CIS - MSDN Dev-Test" # Specify our Azure Subscription Name
[string]$StorageAccountName = "sourcedatafiles"
[string]$ContainerName = "configurationfiles"
[string]$DSCFile = ".\DSC\environmentDSC.ps1"
[string]$SQLSetupConfigurationFile = ".\SQL\ConfigurationFile.ini"
[string]$SQLdatabaseFile = ".\SQL\database.sql"
[string]$WebPackageFile = ".\WebPackage\WebPackage.zip"
[string]$Location = "North Europe"
[string]$ParametersFile = ".\ResourcesManager\parameters.json"
[string]$TemplateFile = ".\ResourcesManager\environnement.json"
[string]$envName = "armasset" # Lower Case, 11 chars max
#>

# Import module Azure Resource Manager
if (!(get-module AzureResourceManager)){
    try{
        Import-Module 'C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\ResourceManager\AzureResourceManager\AzureResourceManager.psd1'
    }catch{
        Write-output "Unable to found Azure Resource Manager Module. Please download it"
        throw $_
    }
}

# Internal Variables
$ResourceGroupName = $envName + "-ResourceGroup" # Resource Group Name
$DSCArchive = (get-item $DSCFile).name + ".zip"

# Switch to Service Management mode
Switch-AzureMode -Name AzureServiceManagement

# Subscription
Select-AzureSubscription -SubscriptionName $subscriptionName
# Set Storage Account Data Files
Set-AzureSubscription `
    -SubscriptionName $subscriptionName `
    -CurrentStorageAccountName $StorageAccountName

# Switch to Service Management Mode
Switch-AzureMode -Name AzureServiceManagement

# Get Storage Context
$srcStorageKey = (Get-AzureStorageKey -StorageAccountName $StorageAccountName).Primary
$srcContext = New-AzureStorageContext  –StorageAccountName $StorageAccountName `
        -StorageAccountKey $srcStorageKey 
# Get a Token to deploy DSC Extension
$startTime = Get-Date
$endTime = $startTime.AddHours(1.0)
$DSCToken = New-AzureStorageBlobSASToken -context $srcContext -Container $ContainerName -Blob $DSCArchive `
    -Permission r -StartTime $startTime -ExpiryTime $endTime

# set AzureResourceManager Mode
Switch-AzureMode -Name AzureResourceManager

# Create new Resource Group if not exists
if(!((get-AzureResourceGroup).ResourceGroupName -contains $ResourceGroupName)){
    New-AzureResourceGroup `
        -Location $Location `
        -Name $ResourceGroupName
}

# Create all resourcs specified in the TemplateFile
New-AzureResourceGroupDeployment -verbose `
    -ResourceGroupName $ResourceGroupName `
    -TemplateFile $TemplateFile `
    -TemplateParameterFile $ParametersFile `
    -EnvironmentName $EnvName `
    -DSCToken $DSCToken `
    -Location $Location

# Create all resourcs specified in the TemplateFile
New-AzureResourceGroupDeployment -verbose `
    -ResourceGroupName $ResourceGroupName `
    -TemplateFile $TemplateFile `
    -TemplateParameterFile $ParametersFile `
    -EnvironmentName $EnvName `
    -DSCToken $DSCToken `
    -Location $Location