param (
    [string]$envName = "bc2015dev", # 11 caractères max 
    [String]$Location = "North Europe",
    [String]$userName = "bcadmin", #! changer à la fois dans ConfigurationFile.ini (SQL)
    [SecureString]$password = (convertto-securestring "P@ssw0rd.1" -asplaintext -force),
    [String]$databaseName = "BootCampDB"
)
[string]$subscriptionName = "Osiatis CIS - MSDN Dev-Test"

# A importer en tant que modules Automation
Import-Module 'C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Azure.psd1'
Import-Module 'C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\ResourceManager\AzureResourceManager\AzureResourceManager.psd1'


# envoi les fichiers de ressources sur des blob
#.\PushResources.ps1

# Variables-paramètres
$TemplateFile = "environnement.json" 
$DSCSCript = "eoBootCampDSC.ps1"
#Const
$storagedatafilesName = "sourcedatafiles"

# Variables internes 
$ResourceGroupName = $envName + "-ResourceGroup"
$Blob = "$DSCSCript.zip"
$DSCContainer = "dsc-files"
$moduleURL = "https://$storagedatafilesName.blob.core.windows.net/$DSCContainer/$Blob"
$TemplateURI = "https://$storagedatafilesName.blob.core.windows.net/json-files/$TemplateFile" # lien http du template Json


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
$DSCToken = New-AzureStorageBlobSASToken -context $srcContext -Container $DSCContainer -Blob $blob `
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
New-AzureResourceGroupDeployment -verbose `
    -ResourceGroupName $ResourceGroupName `
    -templateURI $TemplateURI `
    -environmentName $envName `
    -userName $userName `
    -password $password `
    -location $Location `
    -DSCToken $DSCToken `
    -ModuleURL $moduleURL `
    -DSCSCript $DSCSCript `
    -databaseName $databaseName