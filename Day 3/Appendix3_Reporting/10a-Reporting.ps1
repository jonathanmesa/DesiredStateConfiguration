
# DSC Reporting Database
dir 'C:\Program Files\WindowsPowerShell\DscService\Devices.mdb'

# ODATA methods
start "https://pull.contoso.com:8080/psdscpullserver.svc"

# Connect to all nodes
$computers = 'ms1.contoso.com','ms2.contoso.com','pull.contoso.com'
$cim = New-CimSession -ComputerName $computers

# List all current LCM configurations
Get-DscLocalConfigurationManager -CimSession $cim | select PSComputerName, RefreshMode, AgentID, ConfigurationID, ConfigurationDownloadManagers, ReportManagers | ogv
Get-DscLocalConfigurationManager

# Configure the target nodes for reporting
[DscLocalConfigurationManager()]
Configuration ReportingClientMetaConfig
{
Param(
    [string[]]$ComputerName,
    [string]$GUID
)
    Node $ComputerName
    {
        Settings
        {
            RefreshMode = 'Pull'
            ConfigurationID = 'aa3c8b57-f589-4de5-a88c-834cea90d804'
        }

        ConfigurationRepositoryWeb PullHTTPS
        {
            ServerURL = 'https://pull.contoso.com:8080/psdscpullserver.svc'
            RegistrationKey = $GUID
        }

        ReportServerWeb ReportManager
        {
            ServerUrl = 'https://pull.contoso.com:8080/psdscpullserver.svc'
            RegistrationKey = $GUID
        }
    }
}

$GUID = (New-Guid).Guid
Add-Content -Path 'C:\Program Files\WindowsPowerShell\DscService\RegistrationKeys.txt' -Value $GUID
ReportingClientMetaConfig -ComputerName $Computers -GUID $GUID

# Apply the LCM reporting settings
Set-DscLocalConfigurationManager -Path .\ReportingClientMetaConfig -CimSession $cim

# Trigger an update on the nodes, which will fail, and report up a failure
Update-DscConfiguration -CimSession $cim -Wait -Verbose


# List all current LCM configurations
Get-DscLocalConfigurationManager -CimSession $cim | select PSComputerName, RefreshMode, AgentID, ConfigurationID, ConfigurationDownloadManagers, ReportManagers | ogv
Get-DscLocalConfigurationManager


# SAMPLE WEB REQUEST TO GATHER CONFIGURATION STATUS 
#$statusReports = Invoke-WebRequest -Uri "https://pull.contoso.com:8080/psdscpullserver.svc//Node(ConfigurationId='$guid')/StatusReports" -UseBasicParsing -UseDefaultCredentials -ContentType "application/json;odata=minimalmetadata;streaming=true;charset=utf-8" -Method Post -Headers @{Accept = "application/json"; ProtocolVersion = "1.1"} 
$statusReports = Invoke-WebRequest -Uri "https://pull.contoso.com:8080/psdscpullserver.svc//Node(ConfigurationId='aa3c8b57-f589-4de5-a88c-834cea90d804')/StatusReports" -UseBasicParsing -UseDefaultCredentials -ContentType "application/json;odata=minimalmetadata;streaming=true;charset=utf-8" -Method Get -Headers @{Accept = "application/json"; ProtocolVersion = "1.1"} 

($statusReports.Content | ConvertFrom-Json).value | ogv

($statusReports.Content | ConvertFrom-Json).value[0].StatusData | ConvertFrom-Json | ogv
($statusReports.Content | ConvertFrom-Json).value[0].Errors | ConvertFrom-Json | ogv

(($statusReports.Content | ConvertFrom-Json).value[0].StatusData | ConvertFrom-Json).ResourcesInDesiredState
(($statusReports.Content | ConvertFrom-Json).value[0].StatusData | ConvertFrom-Json).ResourcesNotInDesiredState
