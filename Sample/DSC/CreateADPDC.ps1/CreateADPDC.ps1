configuration CreateADPDC 
{ 
   param 
   ( 
        [Parameter(Mandatory = $true)][string]$adDomainName,
        [Parameter(Mandatory = $true)][string]$password 
    ) 
    
    Import-DscResource -ModuleName xNetworking
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${adDomainName}\$([Environment]::UserName)", `
        (convertto-securestring "' + $password + '" -asplaintext -force))


    Node localhost
    {
        # restart the node as soon as the configuration has been completely applies, without further warning
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }
        
        # Disable Automatic Update
        Registry UpdateTurnOff
        {
            Ensure = "Present"  # You can also set Ensure to "Absent"
            Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
            ValueName = "NoAutoUpdate"
            ValueData = "1"
            ValueType = "DWORD"

        }
        WindowsFeature DNS 
        { 
            Ensure = "Present" 
            Name = "DNS"
        }
        xDnsServerAddress DnsServerAddress 
        { 
            Address        = '127.0.0.1' 
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
        }
        WindowsFeature ADDS
        { 
            Ensure = "Present" 
            Name = "AD-Domain-Services"
        }  
        # Enable Active Directory Deployment Module
        Script ADModule
        {
            setSCript = 'Import-Module ADDSDeployment'
            TestScript = 'if(Get-Module ADDSDeployment){return $True}else{return $False}'
            GetScript = 'if(Get-Module ADDSDeployment){@("Present")}else{@("Absent")}'
            DependsOn = "[WindowsFeature]ADDS"
        }

        # Create Active Directory
        Script ADInstallation
        { 
            setSCript = 'Install-ADDSForest `
                    -CreateDnsDelegation:$false `
                    -DatabasePath "C:\Windows\NTDS" `
                    -DomainMode "Win2012R2" `
                    -DomainName "' + $ADdomainName + '" `
                    -DomainNetbiosName "' + $ADdomainName.split('.')[0] +  '" `
                    -ForestMode "Win2012R2" `
                    -InstallDns:$true `
                    -LogPath "C:\Windows\NTDS"  `
                    -NoRebootOnCompletion:$false `
                    -SysvolPath "C:\Windows\SYSVOL" `
                    -SafeModeAdministratorPassword (convertto-securestring "' + $password + '" -asplaintext -force) -Force:$true'
            TestScript = 'try{if(Get-ADDomainController){return $True}else{return $False}}catch{ return $False}'
            GetScript = 'try{if(Get-ADDomainController){return @("Present")}else{return @("Absent")}}catch{ return $False}'
            DependsOn = @("[WindowsFeature]ADDS","[Script]ADModule")
        }
   }
} 

#CreateADPDC -adDomainName "MyDomain.local" -password "P@ssw0rd.0"
#start-DscConfiguration -PAth .\CreateADPDC -verbose -Wait -Force