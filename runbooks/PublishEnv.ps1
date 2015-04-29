workflow PublishEnv
{
    Param(
        [string]$envName = "bcampauto",
        [String]$Location = "North Europe",
        [String]$userName = "boot.camp",
        [String]$password = "P@ssw0rd.1",
        [String]$databaseName = "Test_DB"
    )
    # Variables
    [string]$DSCSCript = "eoBootCampDSC_beta.ps1" # Nom du script DSC
    [string]$storagedatafilesName = "sourcedatafiles" # Nom du storage Account contenant les fichiers de confituration / doit être créé avant
    [string]$Container = "dsc-files" # Nom du container contenant les scripts DSC
    [string]$subscriptionName = "Osiatis CIS - MSDN Dev-Test" # Nom de la souscription
    [string]$ServiceAccount = "cisazureservice@osiatispracticeazure.onmicrosoft.com" # Nom du Credential Azure Automation
    [string]$TemplateURI = "https://sourcedatafiles.blob.core.windows.net/json-files/environnement_beta.json" # Nom du template Json en local

    # Variable à ne pas modifier 
    [string]$ResourceGroupName = $envName + "-ResourceGroup" # Nom du ResourceGroup (Aligner avec le template JSON)
    [string]$Blob = $DSCSCript + ".zip" # Nom du fichier contenant les DSC
    [string]$moduleURL = "https://" + $storagedatafilesName + ".blob.core.windows.net/" + $Container + "/" + $Blob # URL d'accès aux scripts DSC
    
    # Get Azure Credential
    $Cred = Get-AutomationPSCredential -Name $ServiceAccount 
    Add-AzureAccount -Credential $Cred | Write-Verbose
    # Set Subscription
    Select-AzureSubscription -SubscriptionName $subscriptionName
    
    [System.Security.SecureString]$securePassword = (convertto-securestring $password -asplaintext -force)

    try{
        inlineScript{
            $srcStorageKey = (Get-AzureStorageKey -StorageAccountName $using:storagedatafilesName).Primary
            $srcContext = New-AzureStorageContext  –StorageAccountName $using:storagedatafilesName `
                    -StorageAccountKey $srcStorageKey
                    
            # Get a Token to deploy DSC Extension
            $startTime = Get-Date
            $endTime = $startTime.AddHours(1.0)
            $DSCToken = New-AzureStorageBlobSASToken -context $srcContext -Container $using:Container `
                -Blob $using:blob -Permission r -StartTime $startTime -ExpiryTime $endTime
            Write-Output $DSCToken
            
            # Create new Resource Group
            if(!((get-AzureResourceGroup).ResourceGroupName -contains $using:ResourceGroupName)){
                New-AzureResourceGroup ****
                    -Location $using:Location `
                    -Name $using:ResourceGroupName
            }
    
            # Create Environnement
            New-AzureResourceGroupDeployment -verbose -ResourceGroupName $using:ResourceGroupName `
                -templateURI $using:TemplateURI `
                -location $using:location `
                -environmentName $using:envName `
                -userName $using:userName `
                -password $using:securePassword `
                -DSCToken $using:DSCToken `
                -ModuleURL $using:moduleURL `
                -DSCSCript $using:DSCSCript `
                -databaseName $using:databaseName
        }
    }catch{
        throw $_
    }
}