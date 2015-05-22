
$vm = Get-AzureVM -Name "armagit-ad" -ServiceName "armagit-domain" 
$ConfigurationArgument = @{"adDomainName"="MyDomain"}
$ConfigurationArgument += @{"password"="Passw0rd.0"}

$vm = Set-AzureVMDscExtension -VM $vm `
        -ConfigurationArchive "environmentDSC.ps1.zip" `
        -ConfigurationName "CreateADPDC" `
        -ConfigurationDataPath "C:\Users\maxim_000\git\myPowershell\armaassetgithub\Sample\DSC\environmentDSC.ps1\environmentDSC.psd1" `        -container "configurationfiles" `        -ConfigurationArgument $ConfigurationArgument 

$vm | stop-AzureVM