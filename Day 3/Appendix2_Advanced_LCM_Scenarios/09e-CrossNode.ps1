break
cls

Set-Location C:\PShell\Demos

# Resource syntax
Get-DscResource WaitForAll,WaitForAny,WaitForSome -Syntax

# Resource folder
dir "$((Get-Module PSDesiredStateConfiguration).ModuleBase)\"

# Resource module
ise "$((Get-Module PSDesiredStateConfiguration).ModuleBase)\DscResources\MSFT_WaitForAll\MSFT_WaitForAll.psm1"

# Helper function at root of PSDesiredStateConfiguration module
ise "$((Get-Module PSDesiredStateConfiguration).ModuleBase)\PSDscXMachine.psm1"


# Configuration first
# Create share with everyone read
# Open firewall for SMB
Configuration StageShare
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration, cFileShare, xNetworking

    Node localhost
    {
        File BuildFolder
        {
            Ensure          = "Present"
            SourcePath      = 'C:\PShell\Demos\LogParser.zip'
            DestinationPath = 'C:\PackageShare\LogParser.zip'
            Type            = 'File'
        }

        cCreateFileShare CreateShare
        {
            ShareName = 'PackageShare'
            Path      = 'C:\PackageShare'
            Ensure    = 'Present'
            DependsOn = '[File]BuildFolder'
        }

        cSetSharePermissions SharePermissions
        {
            ShareName       = 'PackageShare'
            ReadAccessUsers = 'EVERYONE'
            Ensure          = 'Present'
            DependsOn       = '[cCreateFileShare]CreateShare'
        }

        xFirewall Firewall-SMB-In
        {
            Name         = 'FPS-SMB-In-TCP_DSC'
            DisplayName  = 'FPS-SMB-In-TCP_DSC'
            Access       = 'Allow'
            DependsOn    = '[cSetSharePermissions]SharePermissions'
            Description  = 'Created by PowerShell DSC'
            Direction    = 'Inbound'
            DisplayGroup = 'File and Printer Sharing'
            Ensure       = 'Present'
            LocalPort    = '445'
            Profile      = 'Domain'
            Protocol     = 'TCP'
            State        = 'Enabled'
        }

        xFirewall Firewall-SMB-Out
        {
            Name         = 'FPS-SMB-Out-TCP_DSC'
            DisplayName  = 'FPS-SMB-Out-TCP_DSC'
            Access       = 'Allow'
            DependsOn    = '[cSetSharePermissions]SharePermissions'
            Description  = 'Created by PowerShell DSC'
            Direction    = 'Outbound'
            DisplayGroup = 'File and Printer Sharing'
            Ensure       = 'Present'
            RemotePort   = '445'
            Profile      = 'Domain'
            Protocol     = 'TCP'
            State        = 'Enabled'
        }
    }
}

StageShare
del C:\Windows\System32\Configuration\metaconfig.mof
Publish-DscConfiguration -Path .\StageShare

# Configuration with wait
# Config will extract a zip from a share
Configuration DownloadAndInstall
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node 'ms1.contoso.com'
    {
        WaitForAll ShareIsReady
        {
            NodeName         = 'pull.contoso.com'
            ResourceName     = '[xFirewall]Firewall-SMB-Out'
            RetryCount       = 60
            RetryIntervalSec = 5
        }

        Archive ExtractZIP {
            Ensure          = 'Present'
            Path            = '\\pull.contoso.com\PackageShare\LogParser.zip'
            Destination     = 'C:\DSCTemp\logparser\'
            Force           = $true
            DependsOn       = '[WaitForAll]ShareIsReady'
        }

        Package InstallLogParser {
            Ensure          = 'Present'
            Name            = 'Log Parser 2.2'
            Path            = 'C:\DSCTemp\logparser\logparser.msi'
            ProductId       = '4AC23178-EEBC-4BAF-8CC0-AB15C8897AC9'
            DependsOn       = '[Archive]ExtractZIP'
        }
    }
}

DownloadAndInstall

# Reset LCM on ms1
Invoke-Command -ComputerName ms1 -ScriptBlock {
    del C:\Windows\System32\Configuration\metaconfig.mof
}
Publish-DscConfiguration -Path .\DownloadAndInstall -Force

# Console Window 1
# Push WaitForAll to Node 1

# Console Window 2
# Push config to Node 2

# Trigger them simulataneously
$cim = New-CimSession -ComputerName 'ms1.contoso.com','pull.contoso.com'
Start-DscConfiguration -UseExisting -CimSession $cim -Wait -Verbose -Force

Get-DscConfigurationStatus -CimSession $cim
Test-DscConfiguration -CimSession $cim -Detailed

Remove-CimSession $cim






# RESET

$sb1 = {
    msiexec /uninstall "4AC23178-EEBC-4BAF-8CC0-AB15C8897AC9" /quiet
    Remove-Item -Path c:\DSCTemp -Recurse -Force -Verbose -Confirm:$false
    Remove-DscConfigurationDocument -Stage Current
}

$sb2 = {
    msiexec /uninstall "4AC23178-EEBC-4BAF-8CC0-AB15C8897AC9" /quiet
    Remove-Item -Path c:\DSCTemp -Recurse -Force -Verbose -Confirm:$false
    Get-NetFirewallRule -Name "*DSC" | Remove-NetFirewallRule -Verbose
    Remove-Item -Path c:\PackageShare -Recurse -Force -Verbose -Confirm:$false
    Remove-SmbShare -Name PackageShare -Force -Confirm:$false -Verbose
    Remove-DscConfigurationDocument -Stage Current
}

Invoke-Command -ComputerName ms1.contoso.com -ScriptBlock $sb1
