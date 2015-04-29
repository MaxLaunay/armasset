Configuration eoBootCampAD {

    Param (
        [string]$password
    )

    Node "localhost"
    {
        LocalConfigurationManager
            {
                RebootNodeIfNeeded = $true
            }
        Registry UpdateTurnOff
        {
            Ensure = "Present"  # You can also set Ensure to "Absent"
            Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
            ValueName = "NoAutoUpdate"
            ValueData = "1"
            ValueType = "DWORD"

        }
        # Install Active Directory Features
        WindowsFeature ADDS
        {
            Ensure = "Present"
            Name = "AD-Domain-Services"
        }

        Script ADModule
        {
            setSCript = 'Import-Module ADDSDeployment'
            TestScript = 'if(Get-Module ADDSDeployment){return $True}else{return $False}'
            GetScript = 'if(Get-Module ADDSDeployment){@("Present")}else{@("Absent")}'
            DependsOn = "[WindowsFeature]ADDS"
        }

        # Set Active Directory
        Script ADInstallation
        { 
            setSCript = 'Install-ADDSForest `
                    -CreateDnsDelegation:$false `
                    -DatabasePath "C:\Windows\NTDS" `
                    -DomainMode "Win2012R2" `
                    -DomainName "bootcamp.local" `
                    -DomainNetbiosName "BOOTCAMP" `
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

Configuration eoBootCampSQL {
    Param (
        [string]$username,
        [String]$password,
        [string]$databaseName
    )
    Node "localhost"
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }
        Registry UpdateTurnOff
        {
            Ensure = "Present"  # You can also set Ensure to "Absent"
            Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
            ValueName = "NoAutoUpdate"
            ValueData = "1"
            ValueType = "DWORD"

        }
        
        # Configuration Active Directory
        Script SetAD
        {
            setSCript = '$pass =  "'+ $password +'" | ConvertTo-SecureString -asPlainText -Force ;
                $domain = "bootcamp.local" ;
                $user = "$domain\' + $username + '" ;
                $credential = New-Object System.Management.Automation.PSCredential($user,$pass);
                Add-Computer -DomainName $domain -Credential $credential'
            TestScript = 'if ((Get-WmiObject Win32_ComputerSystem).domain -eq "bootcamp.local"){return $True}else{return $false}'
            GetScript = '@((Get-WmiObject Win32_ComputerSystem).domain)'
        }
        

        File SourcesFolder
        {
            Ensure = "Present"  # You can also set Ensure to "Absent"
            Type = "Directory" # Default is "File".
            DestinationPath = "C:\sources"    
        }
        
        Script ConfigurationFile
        {
            setSCript = '
                $source = "https://sourcedatafiles.blob.core.windows.net/sql/ConfigurationFile.ini" ;
                $destination = "c:\sources\ConfigurationFile.ini" ;
                (new-object system.net.webclient).DownloadFile($source,$destination)'
            TestScript = 'Test-Path "c:\sources\ConfigurationFile.ini"'
            GetScript = 'if (Test-Path "c:\sources\ConfigurationFile.ini"){return @("Present")}else{return @("Absent")}'
            DependsOn = "[File]SourcesFolder"
        }
        
        # get SLQ Server 2012 Express
        Script SQLServerDownload
        {
            setSCript = '$source = "https://bootcampdatafiles.blob.core.windows.net/sql/SQLFULL_ENU.iso" ;
                $destination = "c:\sources\SQLFULL_ENU.iso" ;
                (new-object system.net.webclient).DownloadFile($source,$destination)'
            TestScript = 'Test-Path c:\sources\SQLFULL_ENU.iso'
            GetScript = 'if (Test-Path c:\sources\SQLFULL_ENU.iso){return @("Present")}else{return @("Absent")}'
            DependsOn = @("[File]SourcesFolder","[Script]SetAD")
        }

        # Mount ISO
        Script MountISO
        {
            setSCript = 'Mount-DiskImage -ImagePath c:\sources\SQLFULL_ENU.iso ; start-sleep 10'
            TestScript = '(Get-DiskImage -ImagePath c:\sources\SQLFULL_ENU.iso).Attached'
            GetScript = '
                if((Get-DiskImage -ImagePath c:\sources\SQLFULL_ENU.iso).Attached){
                    return @("Present")
                }else{
                    return @("Absent")'
            DependsOn = "[Script]SQLServerDownload"
        }

        # Install SQL Server
        Script SQLServerInstallation
        {
            setSCript = '$driverletter = ((get-Volume -DiskImage (Get-DiskImage -ImagePath "c:\sources\SQLFULL_ENU.iso")).DriveLetter) + ":" ;
                $cmd = "$driverletter\Setup.exe /Q /IACCEPTSQLSERVERLICENSETERMS /ACTION=install /ConfigurationFile=c:\sources\ConfigurationFile.ini /SQLSVCPASSWORD=P@ssw0rd.1 /AGTSVCPASSWORD=P@ssw0rd.1 /SAPWD=P@ssw0rd.1" ;
                Invoke-Expression $cmd'
            TestScript = '($sqlInstances = gwmi win32_service -computerName localhost | 
                ? { $_.Name -match "mssql*" -and $_.PathName -match "sqlservr.exe" } | 
                % { $_.Caption }) -ne $null -and $sqlInstances -gt 0'
            GetScript = '$sqlInstances = gwmi win32_service -computerName localhost | 
                ? { $_.Name -match "mssql*" -and $_.PathName -match "sqlservr.exe" } | % { $_.Caption } ;
                $res = $sqlInstances -ne $null -and $sqlInstances -gt 0 ;
                $vals = @{Installed = $res;InstanceCount = $sqlInstances.count} ;
                $vals'
            DependsOn = @("[Script]MountISO","[Script]ConfigurationFile")
        }

        # Dismount ISO
        Script DismountISO
        {
            setSCript = 'Dismount-DiskImage -ImagePath c:\sources\SQLFULL_ENU.iso'
            TestScript = '(!((Get-DiskImage -ImagePath c:\sources\SQLFULL_ENU.iso).Attached))'
            GetScript = 'if((Get-DiskImage -ImagePath c:\sources\SQLFULL_ENU.iso).Attached){return @("Absent")}else{return @("Present")}'
            DependsOn = "[Script]SQLServerInstallation"
        }

        Script sqlfile
        {
            setSCript = '
                $source = "https://sourcedatafiles.blob.core.windows.net/sql/database.sql" ;
                $destination = "c:\sources\database.sql" ;
                (new-object system.net.webclient).DownloadFile($source,$destination)'
            TestScript = 'Test-Path "c:\sources\database.sql"'
            GetScript = 'if (Test-Path "c:\sources\database.sql"){return @("Present")}else{return @("Absent")}'
            DependsOn = "[Script]SQLServerInstallation"
        }

        Script SetSqlPs
        {
            setSCript = 'Import-Module "C:\Program Files (x86)\Microsoft SQL Server\110\Tools\PowerShell\Modules\SQLPS\SQLPS.psd1"'
            TestScript = 'if (Get-Module SqlPs){return $True}else{return $False}'
            GetScript = 'if (Get-Module SqlPs){@("Present")}else{@("Absent")}'
            DependsOn = "[Script]SQLServerInstallation"
        }
         
        # Dismount ISO
        Script CreateDB
        {
            setSCript = 'Invoke-Sqlcmd -InputFile "C:\sources\database.sql" -ServerInstance "." -ErrorAction "Stop" `
                -Password P@ssw0rd.1 -Username sa -Verbose -Variable databaseName=' + $databaseName + ' -QueryTimeout 1800'
            TestScript = '((Invoke-SQLCmd -Query "sp_databases" -Database master -ServerInstance "." -Password P@ssw0rd.1 -Username sa).DATABASE_NAME -contains "' + $databaseName + '")'
            GetScript = 'Invoke-SQLCmd -Query "sp_databases" -Database master -ServerInstance . -Password P@ssw0rd.1 -Username sa'
            DependsOn = @("[Script]SetSqlPs","[Script]sqlfile")
        }

        Script setSQLFireWallRule
        {
            setSCript = 'New-NetFirewallRule -DisplayName “SQL Server” -Direction Inbound –Protocol TCP –LocalPort 1433 -Action allow'
            TestScript = '((Get-NetFirewallRule).displayName -contains “SQL Server”)'
            GetScript = 'if((Get-NetFirewallRule).displayName -contains “SQL Server”){@("Present")}else{@("Absent")}'
        }
    }
}

#eoBootCampSQL -Node "localhost"
#start-DscConfiguration -PAth .\eoBootCampSQL -verbose -Wait -Force