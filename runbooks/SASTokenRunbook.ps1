workflow SASToken
{
    [OutputType([string])]
    param (
        [string]$storagedatafilesName = "sourcedatafiles",
        [string]$Container = "dsc-files",        
        [string]$Blob = "eoBootCamp.ps1.zip",
        [string]$subscriptionName = "Osiatis CIS - MSDN Dev-Test",
        [string]$ServiceAccount = "cisazureservice@osiatispracticeazure.onmicrosoft.com"
    )
    # Get Azure Credential
    $Cred = Get-AutomationPSCredential -Name $ServiceAccount 
    Add-AzureAccount -Credential $Cred | Write-Verbose
    # Set Subscription
    Select-AzureSubscription -SubscriptionName $subscriptionName
    
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
        }
    }catch{
        throw $_
    }
}