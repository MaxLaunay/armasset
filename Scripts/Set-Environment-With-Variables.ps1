param (
    [string]$envName = "assetarm", # 11 caractères max 
    [String]$Location = "North Europe",
    [String]$userName = "bcadmin", #! changer à la fois dans ConfigurationFile.ini (SQL)
    [SecureString]$password = (convertto-securestring "P@ssw0rd.1" -asplaintext -force),
    [String]$databaseName = "BootCampDB",
    [string]$subscriptionName = "Osiatis CIS - MSDN Dev-Test",
    [string]$domainName = "MyDomain.local"
)


# A importer en tant que modules Automation
Import-Module 'C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Azure.psd1'
Import-Module 'C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\ResourceManager\AzureResourceManager\AzureResourceManager.psd1'


# Parameters
[string]$TemplateFile = "environnement.json"
[string]$DSCSCript = "environmentDSC.ps1"
#Const
[string]$StorageAccountName = "sourcedatafiles"
[string]$ContainerName = "configurationfiles"

# Internal Variables
[string]$ResourceGroupName = $envName + "-ResourceGroup"
[string]$Blob = "$DSCSCript.zip"
[string]$staticADIpAddress = "10.0.0.4"
# [uri]$TemplateURI = "https://$storagedatafilesName.blob.core.windows.net/json-files/$TemplateFile" # lien http du template Json
[string]$TemplateFile = ".\ResourcesManager\$TemplateFile" # lien http du template Json
[uri]$DSCmoduleURI = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/$Blob"
[uri]$SQLSetupConfigurationFileUri = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/ConfigurationFile.ini"
[uri]$SQLDatabaseFileUri = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/database.sql"
[uri]$SQLServerISOUri = "http://download.microsoft.com/download/4/C/7/4C7D40B9-BCF8-4F8A-9E76-06E9B92FE5AE/ENU/SQLFULL_ENU.iso"

<# A SUPPRIMER #>
# envoi les fichiers de ressources sur des blob
[string]$SQLSetupConfigurationFile = ".\SQL\ConfigurationFile.ini"
[string]$SQLdatabaseFile = ".\SQL\database.sql"
[string]$WebPackageFile = "..\BCampTestWeb.Deployment\bin\Debug\StorageDrop\BCampTestWeb\package.zip"
.\Set-Configuration.ps1 `
    -SubscriptionName $SubscriptionName `
    -StorageAccountName $StorageAccountName `
    -ContainerName $ContainerName `
    -SQLSetupConfigurationFile $SQLSetupConfigurationFile `
    -SQLdatabaseFile $SQLdatabaseFile `
    -WebPackageFile $WebPackageFile `
    -DSCFile ".\DSC\$DSCSCript"
<#/A SUPPRIMER #>

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

# Create the environnement
New-AzureResourceGroupDeployment -verbose `
    -ResourceGroupName $ResourceGroupName `
    -TemplateFile $TemplateFile `
    -EnvironmentName $EnvName `
    -UserName $UserName `
    -Password $Password `
    -Location $Location `
    -DSCToken $DSCToken `
    -DSCModuleURI $DSCModuleURI.AbsoluteUri `
    -DSCSCript $DSCSCript `
    -DatabaseName $DatabaseName `
    -DomainName $DomainName `
    -DomainNetbiosName ($DomainName.split('.'))[0] `
    -SQLSetupConfigurationFileUri $SQLSetupConfigurationFileUri.AbsoluteUri `
    -SQLServerISOUri $SQLServerISOUri.AbsoluteUri `
    -SQLDatabaseFileUri $SQLDatabaseFileUri.AbsoluteUri `
    -staticADIpAddress $staticADIpAddress