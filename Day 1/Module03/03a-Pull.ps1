#Requires -RunAsAdministrator
Break
cls

Set-Location C:\PShell\Demos

# Manually copy xPSDesiredStateConfiguration module from here:
#explorer 'C:\PShell\DSC Resource Kit Wave 10 04012015.zip\All Resources\'
Install-Module xPSDesiredStateConfiguration -Force -Verbose

# to here:
explorer "$Env:ProgramFiles\WindowsPowerShell\Modules\"

# Configuration for a simple PULL server, unencrypted HTTP
configuration CreatePullServer
{
    param
    (
        [string[]]
        $ComputerName = 'localhost'
    )

    Import-DSCResource -ModuleName PSDesiredStateConfiguration
    # Update the module version appropriately
    Import-DSCResource -ModuleName xPSDesiredStateConfiguration -ModuleVersion 3.9.0.0

    Node $ComputerName
    {
        WindowsFeature DSCServiceFeature
        {
            Ensure = "Present"
            Name   = "DSC-Service"
        }
        xDscWebService PSDSCPullServer
        {
            Ensure                  = "Present"
            EndpointName            = "PSDSCPullServer"
            Port                    = 8080
            PhysicalPath            = "$env:SystemDrive\inetpub\wwwroot\PSDSCPullServer"
            CertificateThumbPrint   = "AllowUnencryptedTraffic"
            ModulePath              = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules"
            ConfigurationPath       = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"
            State                   = "Started"
            DependsOn               = "[WindowsFeature]DSCServiceFeature"
        }
    }
}

# Build the MOF
CreatePullServer -ComputerName $Env:ComputerName

# Apply the configuration.
Start-DscConfiguration .\CreatePullServer -Wait -Verbose

# View the web service
Start-Process "http://$($Env:ComputerName).contoso.com:8080/PSDSCPullServer.svc"

# Notice DSC-Service under Windows PowerShell
Get-WindowsFeature | Where-Object DisplayName -like '*PowerShell*'




<#
http://stackoverflow.com/questions/24252635/powershell-dsc-pull-server-throws-internal-error-microsoft-isam-esent-interop
*** Note that the Feb 2015 preview has an issue in the web.config.
C:\inetpub\wwwroot\PSDSCPullServer\web.config
replace this:
<add key="dbprovider" value="ESENT" />
<add key="dbconnectionstr" value="C:\Program Files\WindowsPowerShell\DscService\Devices.edb" />
with this:
<add key="dbprovider" value="System.Data.OleDb" />
<add key="dbconnectionstr" value="Provider=Microsoft.Jet.OLEDB.4.0;Data Source=C:\Program Files\WindowsPowerShell\DscService\Devices.mdb;"/>
#>
notepad C:\inetpub\wwwroot\PSDSCPullServer\web.config

# Optional IIS console
Install-WindowsFeature Web-Mgmt-Console
