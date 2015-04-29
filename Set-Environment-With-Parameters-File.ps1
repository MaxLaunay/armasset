param (
    [string]$envName = "assetarm", # 11 caractères max 
    [string]$subscriptionName = "Osiatis CIS - MSDN Dev-Test",
    [string]$Location = "North Europe"
)


# A importer en tant que modules Automation
Import-Module 'C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Azure.psd1'
Import-Module 'C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\ResourceManager\AzureResourceManager\AzureResourceManager.psd1'

# Parameters
[string]$TemplateFile = ".\ResourcesManager\$TemplateFile"


$DSCSCript = "environmentDSC.ps1"
$parametersFile = ".\ResourcesManager\parameters.json"
#Const
[string]$StorageAccountName = "sourcedatafiles"
[string]$ContainerName = "configurationfiles"

# Internal Variables
$ResourceGroupName = $envName + "-ResourceGroup" # Resource Group Name
$Blob = "$DSCSCript.zip"
# [uri]$TemplateURI = "https://$storagedatafilesName.blob.core.windows.net/json-files/$TemplateFile" # lien http du template Json

[uri]$DSCmoduleURI = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/$Blob"
#[uri]$SQLSetupConfigurationFileUri = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/ConfigurationFile.ini"
#[uri]$SQLDatabaseFileUri = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/database.sql"
#[uri]$SQLServerISOUri = "http://download.microsoft.com/download/4/C/7/4C7D40B9-BCF8-4F8A-9E76-06E9B92FE5AE/ENU/SQLFULL_ENU.iso"

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
$DSCToken = New-AzureStorageBlobSASToken -context $srcContext -Container $ContainerName -Blob $blob `
    -Permission r -StartTime $startTime -ExpiryTime $endTime

# set AzureResourceManager Mode
Switch-AzureMode -Name AzureResourceManager

# Create new Resource Group if not exists
if(!((get-AzureResourceGroup).ResourceGroupName -contains $ResourceGroupName)){
    New-AzureResourceGroup `
        -Location $Location `
        -Name $ResourceGroupName
}

New-AzureResourceGroupDeployment -verbose `
    -ResourceGroupName $ResourceGroupName `
    -TemplateFile $TemplateFile `
    -EnvironmentName $EnvName `
    -DSCToken $DSCToken `
    -Location $Location `
    -TemplateParameterFile $parametersFile