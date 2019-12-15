break
cls

Set-Location "C:\PShell\Demos"

$node = 'ms1.contoso.com'


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

$Source = 'C:\Program Files\WindowsPowerShell\Modules\[xc]*'
$Dest   = 'C:\Program Files\WindowsPowerShell\Modules\'

$pss = New-PSSession $node
#Invoke-Command -Session $pss -ScriptBlock {del $using:Source -Confirm:$false -Recurse}


Copy-Item -Path $Source -ToSession $pss -Destination $Dest -Recurse -Force -Verbose
Invoke-Command -Session $pss -ScriptBlock {dir $using:Dest}
Invoke-Command -Session $pss -ScriptBlock {dir $using:Dest -Recurse}
Remove-PSSession $pss

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

