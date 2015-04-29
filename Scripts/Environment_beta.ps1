param (
    [string]$envName = "bcamptest01",
    [String]$Location = "North Europe",
    [String]$userName = "boot.camp",
    [SecureString]$password = (convertto-securestring "P@ssw0rd.1" -asplaintext -force),
    [String]$databaseName = "Test_DB"
)
# A importer en tant que modules Automation
Import-Module 'C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Azure.psd1'
Import-Module 'C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\ResourceManager\AzureResourceManager\AzureResourceManager.psd1'

# envoi les fichiers de ressources sur des blob
.\PushResources.ps1

# Variables à modifier au besoin
$TemplateURI = "https://sourcedatafiles.blob.core.windows.net/json-files/environnement_beta.json" # lien http du template Json
$DSCSCript = "eoBootCampDSC_beta.ps1" # 

# Variable à ne pas modifier 
$ResourceGroupName = $envName + "-ResourceGroup"
$storagedatafilesName = "sourcedatafiles"
[string]$subscriptionName = "Osiatis CIS - MSDN Dev-Test"
$Blob = "$DSCSCript.zip"
$Container = "dsc-files"
$moduleURL = "https://$storagedatafilesName.blob.core.windows.net/$Container/$Blob"

# Subscription
Select-AzureSubscription -SubscriptionName $subscriptionName
# Set Storage Account Data Files
Set-AzureSubscription `
    -SubscriptionName $subscriptionName `
    -CurrentStorageAccountName $storagedatafilesName

Switch-AzureMode -Name AzureServiceManagement
$srcStorageKey = (Get-AzureStorageKey -StorageAccountName $storagedatafilesName).Primary
$srcContext = New-AzureStorageContext  –StorageAccountName $storagedatafilesName `
        -StorageAccountKey $srcStorageKey 


# Get a Token to deploy DSC Extension
$startTime = Get-Date
$endTime = $startTime.AddHours(1.0)
$DSCToken = New-AzureStorageBlobSASToken -context $srcContext -Container $Container -Blob $blob `
    -Permission r -StartTime $startTime -ExpiryTime $endTime

# set AzureResourceManager Mode
Switch-AzureMode -Name AzureResourceManager

# Remove A resource Group
#Remove-AzureResourceGroup -Name 'bcamptest10-ResourceGroup' -force

# Create new Resource Group
if(!((get-AzureResourceGroup).ResourceGroupName -contains $ResourceGroupName)){
    New-AzureResourceGroup `
        -Location $Location `
        -Name $ResourceGroupName
}

# Create Environnement
New-AzureResourceGroupDeployment -verbose -ResourceGroupName $ResourceGroupName `
    -templateURI $TemplateURI `
    -location $location `
    -environmentName $envName `
    -userName $userName `
    -password $password `
    -DSCToken $DSCToken `
    -ModuleURL $moduleURL `
    -DSCSCript $DSCSCript `
    -databaseName $databaseName