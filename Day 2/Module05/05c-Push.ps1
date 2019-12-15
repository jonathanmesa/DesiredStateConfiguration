break
cls

Set-Location "C:\PShell\Demos"

$node = 'ms1.contoso.com'

Install-Module -Name xRemoteDesktopAdmin, xNetworking


#region Configuration using Resource Kit module


$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = $node
            PSDscAllowPlainTextPassword = $true
         }
    )
}

Configuration AllowRemoteDesktopAdminConnections
{
param(
        [Parameter(Mandatory)] 
        [PSCredential]
        $Credential
    )
    
    Import-DscResource -Module PSDesiredStateConfiguration, xRemoteDesktopAdmin, xNetworking

    Node $AllNodes.NodeName
    {
        LocalConfigurationManager
        {
            RefreshMode = 'Push'
        }

        xRemoteDesktopAdmin RemoteDesktopSettings
        {
           Ensure = 'Present'
           UserAuthentication = 'Secure'
        }

        xFirewall AllowRDP
        {
            Name = 'DSC - Remote Desktop Admin Connections'
            DisplayGroup = "Remote Desktop"
            Ensure = 'Present'
            State = 'Enabled'
            Access = 'Allow'
            Profile = 'Domain'
        }

        Group RDPGroup
        {
           Ensure = 'Present'
           GroupName = 'Remote Desktop Users'
           Members = 'contoso\ericlang'
           Credential = $Credential
        }
         
    }
}

# Create MOF with configuration data
AllowRemoteDesktopAdminConnections -ConfigurationData $ConfigData `
    -Credential (Get-Credential -UserName contoso\ericlang -Message "Credentials to read AD users")

# Configure push mode
Set-DscLocalConfigurationManager .\AllowRemoteDesktopAdminConnections

# Apply the configuration
Start-DscConfiguration -Wait -Force -Verbose -Path .\AllowRemoteDesktopAdminConnections

# Notice error of missing resources

#endregion



#region Push resource modules manually

# Later we can try this with the new "Copy-Item -FromSession -ToSession"
Invoke-Command -ComputerName $node -ScriptBlock {
    Get-NetFirewallRule FPS-SMB* | Enable-NetFirewallRule
}

$Source = 'C:\Program Files\WindowsPowerShell\Modules\[xc]*'
$Dest   = "\\$node\C$\Program Files\WindowsPowerShell\Modules\"

dir $Source
dir $Dest

Copy-Item -Path $Source -Destination $Dest -Recurse -ErrorAction SilentlyContinue

dir $Dest

#endregion



# Apply configuration with resources present

# Apply the configuration
Start-DscConfiguration -Wait -Force -Verbose -Path .\AllowRemoteDesktopAdminConnections

#endregion











### Reset demo ###


Invoke-Command -ComputerName $node -ScriptBlock {
    net localgroup "Remote Desktop Users" /delete contoso\ericlang
}

# Apply the configuration
Start-DscConfiguration -Wait -Force -Verbose -Path .\AllowRemoteDesktopAdminConnections

Remove-Item -Recurse -Force -Path .\AllowRemoteDesktopAdminConnections

Remove-Item "$Dest\[xc]*" -Recurse -Force





### DOES NOT WORK YET ###


#region  Copy-Item with PSSession (no SMB firewall)

$node2 = 'ms2.contoso.com'

$s = New-PSSession -ComputerName $node2

$Source = 'C:\Program Files\WindowsPowerShell\Modules\xNetworking'
# Notice local path in remote session
$Dest   = "C:\Program Files\WindowsPowerShell\Modules\"

dir $Source
Invoke-Command -Session $s -ScriptBlock {dir $Using:Dest}

# -ToSession
Copy-Item -Path $Source -Destination $Dest -ToSession $s -Recurse -ErrorAction SilentlyContinue

Invoke-Command -Session $s -ScriptBlock {dir $Using:Dest}
Invoke-Command -Session $s -ScriptBlock {dir "$($Using:Dest)xNetworking" -Recurse}

Invoke-Command -Session $s -ScriptBlock {dir $Using:Dest}

Remove-PSSession $s


#endregion
