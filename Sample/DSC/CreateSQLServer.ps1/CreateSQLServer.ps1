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

    Import-DscResource -ModuleName xComputerManagement,xSQLServer,xPSDesiredStateConfiguration, xDatabase

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${adDomainName}\$([Environment]::UserName)", `
        (convertto-securestring "' + $password + '" -asplaintext -force))
    [string]$computerName = [Environment]::MachineName
    [string]$ISOFile = "c:\sources\SQLFULL_ENU.iso"

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
        xComputer JoinDomain 
        { 
            Name          = $computerName  
            DomainName    = $adDomainName 
            Credential    = $DomainCreds  # Credential to join to domain 
        }
        
        # create a source folder before upload configuration files and SQL Server ISO
        File SourcesFolder
        {
            Ensure = "Present"  # You can also set Ensure to "Absent"
            Type = "Directory" # Default is "File".
            DestinationPath = "C:\sources"    
        }

        xRemoteFile SQLServerDownload
        {
            DestinationPath = $ISOFile
            Uri = $SQLServerISOUri
            DependsOn = @("[File]SourcesFolder","[xComputer]JoinDomain")
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
            DependsOn = "[xRemoteFile]SQLServerDownload"
        }

        xSQLServerSetup SQLServerSetup
        {
            SourcePath = ((get-Volume -DiskImage (Get-DiskImage -ImagePath "c:\sources\SQLFULL_ENU.iso")).DriveLetter) + ":" # REQUIRED - UNC path to the root of the source files for installation.
            SetupCredential = $DomainCreds # REQUIRED - Credential to be used to perform the installation.
            Features = "SQLENGINE,SSMS,ADV_SSMS" #: KEY - SQL features to be installed.
            InstanceName = "MSSQLSERVER" # KEY - SQL instance to be installed.
            SECURITYMODE="SQL"
            SAPwd = $password
            SQLSysAdminAccounts = "$ADdomainName\$username" #: Array of accounts to be made SQL administrators.
            <#
            SourceFolder: Folder within the source path containing the source files for installation.InstanceID: SQL instance ID, if different from InstanceName.
            PID: Product key for licensed installations.
            UpdateEnabled: Enabled updates during installation.
            UpdateSource: Source of updates to be applied during installation.
            SQMReporting: Enable customer experience reporting.
            ErrorReporting: Enable error reporting.
            InstallSharedDir: Installation path for shared SQL files.
            InstallSharedWOWDir: Installation path for x86 shared SQL files.
            InstanceDir: Installation path for SQL instance files.
            SQLSvcAccount: Service account for the SQL service.
            SQLSvcAccountUsername: Output username for the SQL service.
            AgtSvcAccount: Service account for the SQL Agent service.
            AgtSvcAccountUsername: Output username for the SQL Agent service.
            SQLCollation: Collation for SQL.
            InstallSQLDataDir: Root path for SQL database files.
            SQLUserDBDir: Path for SQL database files.
            SQLUserDBLogDir: Path for SQL log files.
            SQLTempDBDir: Path for SQL TempDB files.
            SQLTempDBLogDir: Path for SQL TempDB log files.
            SQLBackupDir: Path for SQL backup files.
            FTSvcAccount: Service account for the Full Text service.
            FTSvcAccountUsername: Output username for the Full Text service.
            RSSvcAccount: Service account for Reporting Services service.
            RSSvcAccountUsername: Output username for the Reporting Services service.
            ASSvcAccount: Service account for Analysus Services service.
            ASSvcAccountUsername: Output username for the Analysis Services service.
            ASCollation: Collation for Analysis Services.
            ASSysAdminAccounts: Array of accounts to be made Analysis Services admins.
            ASDataDir: Path for Analysis Services data files.
            ASLogDir: Path for Analysis Services log files.
            ASBackupDir: Path for Analysis Services backup files.
            ASTempDir: Path for Analysis Services temp files.
            ASConfigDir: Path for Analysis Services config.
            ISSvcAccount: Service account for Integration Services service.
            ISSvcAccountUsername: Output username for the Integration Services service.#>
            DependsOn = @("[Script]MountISO")
        }

        xRemoteFile sqlFileDownload
        {
            DestinationPath = "c:\sources\database.sql"
            Uri = $SQLDatabaseFileUri
            DependsOn = "[xSQLServerSetup]SQLServerSetup"
        }
         
        xDatabase CreateDB 
        { 
            Ensure = "Present"
            SqlServer = "localhost" 
            SqlServerVersion = "2012" 
            DatabaseName = $databaseName 
            Credentials = $DomainCreds 
            DependsOn = "[xRemoteFile]sqlFileDownload"
        }

        xSQLServerFirewall setSQLFireWallRule
        {
            Ensure = "Present"
            SourcePath = ((get-Volume -DiskImage (Get-DiskImage -ImagePath "c:\sources\SQLFULL_ENU.iso")).DriveLetter) + ":" # REQUIRED - UNC path to the root of the source files for installation.
            Features = "SQLENGINE" #: KEY - SQL features to be installed.
            InstanceName = "MSSQLSERVER" #(Key) SQL instance to enable firewall rules for.
    <#
    DatabaseEngineFirewall = $true #Is the firewall rule for the Database Engine enabled?
    SourceFolder: Folder within the source path containing the source files for installation.
    DatabaseEngineFirewall: Is the firewall rule for the Database Engine enabled?
    BrowserFirewall: Is the firewall rule for the Browser enabled?
    ReportingServicesFirewall: Is the firewall rule for Reporting Services enabled?
    AnalysisServicesFirewall: Is the firewall rule for Analysis Services enabled?
    IntegrationServicesFirewall: Is the firewall rule for the Integration Services enabled?#>
            DependsOn = "[xSQLServerSetup]SQLServerSetup"
        }

        # Dismount ISO
        Script DismountISO
        {
            setSCript = 'Dismount-DiskImage -ImagePath c:\sources\SQLFULL_ENU.iso'
            TestScript = '(!((Get-DiskImage -ImagePath c:\sources\SQLFULL_ENU.iso).Attached))'
            GetScript = 'if((Get-DiskImage -ImagePath c:\sources\SQLFULL_ENU.iso).Attached){return @("Absent")}else{return @("Present")}'
            DependsOn = "[xSQLServerFirewall]setSQLFireWallRule"
        }
    }
} 