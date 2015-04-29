# A importer en tant que modules Automation
Import-Module 'C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Azure.psd1'
Import-Module 'C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\ResourceManager\AzureResourceManager\AzureResourceManager.psd1'
#

# Switch to Service Management Mode
Switch-AzureMode -Name AzureServiceManagement
#
# Subscription
    [string]$subscriptionName = "Osiatis CIS - MSDN Dev-Test"
# Set Storage Account Data Files
    $storagedatafilesName = "sourcedatafiles"

    Select-AzureSubscription $subscriptionName
    Set-AzureSubscription `
        -SubscriptionName $subscriptionName `
        -CurrentStorageAccountName $storagedatafilesName
# Upload JSon To Azure
	$JSonContainer = "json-files"
    $JSonFiles = @(
			".\ResourcesManager\environnement_beta.json",
            ".\ResourcesManager\environnement.json"
        )
    
    foreach ($JSonFile in $JSonFiles){
        $file = get-Item $JSonFile
        Set-AzureStorageBlobContent -Container $JSonContainer -File $file.FullName -Force
    }

    $SQLContainer = "sql"
    $SQLFiles = @(
		".\SQL\ConfigurationFile.ini",
		".\SQL\database.sql"
    )
    
    foreach ($SQL in $SQLFiles){
        $file = get-Item $SQL
        Set-AzureStorageBlobContent -Container $SQLContainer -File $file.FullName -Force
    }

    $DSCContainer = "dsc-files"
    $DSCFiles = @(
			".\DSC\eoBootCampDSC_beta.ps1",
            ".\DSC\eoBootCampDSC.ps1"
        )
    foreach ($DSCFile in $DSCFiles){
        Publish-AzureVMDscConfiguration `
            -ConfigurationPath $DSCFile `
            -containerName $DSCContainer `
            -Force
    }

	$WebPackageContainer = "web"
	$WebPackageFile = "..\BCampTestWeb.Deployment\bin\Debug\StorageDrop\BCampTestWeb\package.zip"
    Set-AzureStorageBlobContent -Container $WebPackageContainer -File $WebPackageFile -Force
    