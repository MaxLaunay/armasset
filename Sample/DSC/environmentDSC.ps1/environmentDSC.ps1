configuration CreateADPDC
{ 
   param 
   ( 
        [Parameter(Mandatory = $true)][string]$adDomainName,
        [Parameter(Mandatory = $true)][string]$password 
    ) 
    
    Import-DscResource -ModuleName xNetworking,xActiveDirectory
    [string]$forwarder1 = "8.8.8.8"
    [string]$forwarder2 = "8.8.4.4"
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${adDomainName}\[Environment]::UserName)", (convertto-securestring "' + $password + '" -asplaintext -force))

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
        xADDomain FirstDS 
        {
            DomainName = $adDomainName
            DomainAdministratorCredential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DatabasePath = "C:\NTDS"
            LogPath = "C:\NTDS"
            SysvolPath = "C:\SYSVOL"
        } 

        # Add 8.8.8.8 in DNS forwarders
        Script FirstForwarders
        {
            setSCript = 'Add-DnsServerForwarder -IPAddress ' + $forwarder1 + ' -PassThru'
            TestScript = 'try{if((Get-DnsServerForwarder).IPAddress.IPAddressToString -contains "' + $forwarder1 + '"){return $True}else{return $False}}catch{ return $False}'
            GetScript = 'try{if((Get-DnsServerForwarder).IPAddress.IPAddressToString -contains "' + $forwarder1 + '"){return "Present"}else{return "Absent"}}catch{ return "Absent"}'
            DependsOn = "[Script]ADInstallation"
        }

        # Add 8.8.4.4 in DNS forwarders
        Script SecondForwarders
        {
            setSCript = 'Add-DnsServerForwarder -IPAddress ' + $forwarder2 + ' -PassThru'
            TestScript = 'try{if((Get-DnsServerForwarder).IPAddress.IPAddressToString -contains "' + $forwarder2 + '"){return $True}else{return $False}}catch{ return $False}'
            GetScript = 'try{if((Get-DnsServerForwarder).IPAddress.IPAddressToString -contains "' + $forwarder2 + '"){return "Present"}else{return "Absent"}}catch{ return "Absent"}'
            DependsOn = "[Script]ADInstallation"
        }
   }
} 

configuration CreateADPDCOLD 
{ 
   param 
   ( 
        [Parameter(Mandatory = $true)][string]$adDomainName,
        [Parameter(Mandatory = $true)][string]$password 
    ) 
    
    Import-DscResource -ModuleName xNetworking
    [string]$forwarder1 = "8.8.8.8"
    [string]$forwarder2 = "8.8.4.4"

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

        # Add 8.8.8.8 in DNS forwarders
        Script FirstForwarders
        {
            setSCript = 'Add-DnsServerForwarder -IPAddress ' + $forwarder1 + ' -PassThru'
            TestScript = 'try{if((Get-DnsServerForwarder).IPAddress.IPAddressToString -contains "' + $forwarder1 + '"){return $True}else{return $False}}catch{ return $False}'
            GetScript = 'try{if((Get-DnsServerForwarder).IPAddress.IPAddressToString -contains "' + $forwarder1 + '"){return "Present"}else{return "Absent"}}catch{ return "Absent"}'
            DependsOn = "[Script]ADInstallation"
        }

        # Add 8.8.4.4 in DNS forwarders
        Script SecondForwarders
        {
            setSCript = 'Add-DnsServerForwarder -IPAddress ' + $forwarder2 + ' -PassThru'
            TestScript = 'try{if((Get-DnsServerForwarder).IPAddress.IPAddressToString -contains "' + $forwarder2 + '"){return $True}else{return $False}}catch{ return $False}'
            GetScript = 'try{if((Get-DnsServerForwarder).IPAddress.IPAddressToString -contains "' + $forwarder2 + '"){return "Present"}else{return "Absent"}}catch{ return "Absent"}'
            DependsOn = "[Script]ADInstallation"
        }
   }
} 

configuration SQLServer 
{ 
 Param (
        [Parameter(Mandatory = $true)][string]$username,
        [Parameter(Mandatory = $true)][String]$password,
        [Parameter(Mandatory = $true)][string]$databaseName,
        [Parameter(Mandatory = $true)][string]$adDomainName,
        [Parameter(Mandatory = $true)][string]$SQLSetupConfigurationFileUri,
        [Parameter(Mandatory = $true)][string]$SQLServerISOUri,
        [Parameter(Mandatory = $true)][string]$SQLDatabaseFileUri
    )

    Import-DscResource -ModuleName xPSDesiredStateConfiguration

    #[System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${adDomainName}\$([Environment]::UserName)", `
    #    (convertto-securestring "' + $password + '" -asplaintext -force))
    [string]$ISOFile = "c:\sources\SQLFULL_ENU.iso"
    [string]$ConfINI = "c:\sources\ConfigurationFile.ini"
    [string]$SQLFile = "c:\sources\database.sql"

    Node "localhost"
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
        
        # Add computer to Active Directory
        Script SetAD
        {
            setSCript = '$pass =  "'+ $password +'" | ConvertTo-SecureString -asPlainText -Force ;
                $user = "'+ $ADdomainName +'\' + $username + '" ;
                $credential = New-Object System.Management.Automation.PSCredential($user,$pass);
                Add-Computer -DomainName ' + $ADdomainName + ' -Credential $credential'
            TestScript = 'if ((Get-WmiObject Win32_ComputerSystem).domain -eq "'+ $ADdomainName +'"){return $True}else{return $false}'
            GetScript = '@((Get-WmiObject Win32_ComputerSystem).domain)'
        }

        # create a source folder before upload configuration files and SQL Server ISO
        File SourcesFolder
        {
            Ensure = "Present"  # You can also set Ensure to "Absent"
            Type = "Directory" # Default is "File".
            DestinationPath = "C:\sources"    
        }

        # XremoteFile bug when download SQL server (infinity loop ?)
        Script SQLServerDownload
        {
            setSCript = '$source = "' + $SQLServerISOUri + '" ;
                $destination = "' + $ISOFile + '" ;
                (new-object system.net.webclient).DownloadFile($source,$destination)'
            TestScript = 'Test-Path ' + $ISOFile + ''
            GetScript = 'if (Test-Path ' + $ISOFile + '){return @("Present")}else{return @("Absent")}'
            DependsOn = @("[File]SourcesFolder","[Script]SetAD")
        }

        xRemoteFile ConfigurationFile
        {
            DestinationPath = $ConfINI
            Uri = $SQLSetupConfigurationFileUri
            #DependsOn = @("[File]SourcesFolder","[Script]SetAD")
        }


        # Mount ISO
        Script MountISO
        {
            setSCript = 'Mount-DiskImage -ImagePath ' + $ISOFile + ' ; start-sleep 10'
            TestScript = '(Get-DiskImage -ImagePath ' + $ISOFile + ').Attached'
            GetScript = '
                if((Get-DiskImage -ImagePath ' + $ISOFile + ').Attached){
                    return @("Present")
                }else{
                    return @("Absent")'
            DependsOn = "[Script]SQLServerDownload"
        }

       # Install SQL Server
        Script SQLServerInstallation
        {
            setSCript = '$driverletter = ((get-Volume -DiskImage (Get-DiskImage -ImagePath "' + $ISOFile + '")).DriveLetter) + ":" ;
                $cmd = "$driverletter\Setup.exe /Q /IACCEPTSQLSERVERLICENSETERMS /ACTION=install /ConfigurationFile=' + $ConfINI + '" ;
                $cmd += " /SQLSYSADMINACCOUNTS=' + $ADdomainName + '\' + $username + ' /SQLSVCPASSWORD='+$password+' /AGTSVCPASSWORD='+$password+' /SAPWD='+$password+'" ;
                Invoke-Expression $cmd'
            TestScript = '($sqlInstances = gwmi win32_service -computerName localhost | 
                ? { $_.Name -match "mssql*" -and $_.PathName -match "sqlservr.exe" } | 
                % { $_.Caption }) -ne $null -and $sqlInstances -gt 0'
            GetScript = '$sqlInstances = gwmi win32_service -computerName localhost | 
                ? { $_.Name -match "mssql*" -and $_.PathName -match "sqlservr.exe" } | % { $_.Caption } ;
                $res = $sqlInstances -ne $null -and $sqlInstances -gt 0 ;
                $vals = @{Installed = $res;InstanceCount = $sqlInstances.count} ;
                $vals'
            DependsOn = @("[Script]MountISO","[xRemoteFile]ConfigurationFile")
        }

        xRemoteFile sqlFileDownload
        {
            DestinationPath = $SQLFile
            Uri = $SQLDatabaseFileUri
            DependsOn = "[Script]SQLServerInstallation"
        }

        Script SetSqlPs
        {
            setSCript = 'Import-Module "C:\Program Files (x86)\Microsoft SQL Server\110\Tools\PowerShell\Modules\SQLPS\SQLPS.psd1"'
            TestScript = 'if (Get-Module SqlPs){return $True}else{return $False}'
            GetScript = 'if (Get-Module SqlPs){@("Present")}else{@("Absent")}'
            DependsOn = "[Script]SQLServerInstallation"
        }

        Script CreateDB
        {
            setSCript = 'Invoke-Sqlcmd -InputFile "' + $SQLFile + '" -ServerInstance "." -ErrorAction "Stop" `
                -Password '+$password+' -Username sa -Verbose -Variable databaseName=' + $databaseName + ' -QueryTimeout 1800'
            TestScript = '((Invoke-SQLCmd -Query "sp_databases" -Database master -ServerInstance "." -Password '+$password+' -Username sa).DATABASE_NAME -contains "' + $databaseName + '")'
            GetScript = 'Invoke-SQLCmd -Query "sp_databases" -Database master -ServerInstance . -Password '+$password+' -Username sa'
            DependsOn = @("[Script]SetSqlPs","[xRemoteFile]sqlFileDownload")
        }

        Script setSQLFireWallRule
        {
            setSCript = 'New-NetFirewallRule -DisplayName “SQL Server” -Direction Inbound –Protocol TCP –LocalPort 1433 -Action allow'
            TestScript = '((Get-NetFirewallRule).displayName -contains “SQL Server”)'
            GetScript = 'if((Get-NetFirewallRule).displayName -contains “SQL Server”){@("Present")}else{@("Absent")}'
        }

        # Dismount ISO
        Script DismountISO
        {
            setSCript = 'Dismount-DiskImage -ImagePath ' + $ISOFile
            TestScript = '(!((Get-DiskImage -ImagePath ' + $ISOFile + ').Attached))'
            GetScript = 'if((Get-DiskImage -ImagePath ' + $ISOFile + ').Attached){return @("Absent")}else{return @("Present")}'
            DependsOn = "[Script]SQLServerInstallation"
        }
    }
} 

#eoBootCampSQL -Node "localhost"
#start-DscConfiguration -PAth .\eoBootCampSQL -verbose -Wait -Force