break
cls

Set-Location C:\PShell\Demos

# View former HTTP site and binding in IIS and remove the PSDSCPullServer site if present
Start C:\windows\system32\inetsrv\InetMgr.exe

# Get the SSL cert thumbprint
dir Cert:\LocalMachine\My -SSLServerAuthentication

# Thumbprint goes into CertificateThumbPrint below
Configuration CreateHTTPSPullServer
{
    Import-DSCResource -ModuleName PSDesiredStateConfiguration
    # Update the module version appropriately
    Import-DSCResource -ModuleName xPSDesiredStateConfiguration #-ModuleVersion 3.9.0.0

    Node localhost 
    {
        WindowsFeature DSCServiceFeature
        {
            Ensure = "Present"
            Name   = "DSC-Service"
        }
        xDscWebService PSDSCPullServer
        {
            Ensure                   = 'Present'
            EndpointName             = 'PSDSCPullServer'
            Port                     = 8080
            PhysicalPath             = "$env:SystemDrive\inetpub\wwwroot\PSDSCPullServer"
            CertificateThumbPrint    = '9853B67886F504A617086554F995927EEABA2DDD'
            ModulePath               = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules"
            ConfigurationPath        = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"
            State                    = 'Started'
            UseSecurityBestPractices = $false
            DependsOn                = '[WindowsFeature]DSCServiceFeature'
        }
        WindowsFeature IISMgmtGui
        {
            Ensure = "Present"
            Name   = "Web-Mgmt-Console"
            DependsOn = '[xDscWebService]PSDSCPullServer'
        }
        WindowsFeature IISScripting
        {
            Ensure = "Present"
            Name   = "Web-Scripting-Tools"
            DependsOn = '[xDscWebService]PSDSCPullServer'
        }
    }
} 

CreateHTTPSPullServer
Start-DscConfiguration -Path .\CreateHTTPSPullServer -Wait -Verbose -Force

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

# Test HTTPS pull server
Start-Process "https://pull.contoso.com:8080/PSDSCPullServer.svc"
