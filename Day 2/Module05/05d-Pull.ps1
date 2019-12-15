break
cls


#region Helper function to publish modules for pull

Function Publish-DscResourcePull {
Param (
    [string[]]
    $Module
)
    ForEach ($ModuleName in $Module) {

        $ModuleVersion = (Get-Module $ModuleName -ListAvailable).Version

        # New cmdlet in WMF 5.0
        Compress-Archive -Update `
         -Path "$Env:PROGRAMFILES\WindowsPowerShell\Modules\$ModuleName" `
         -DestinationPath "$Env:PROGRAMFILES\WindowsPowerShell\DscService\Modules\$($ModuleName)_$($ModuleVersion).zip"

        New-DSCCheckSum "$Env:PROGRAMFILES\WindowsPowerShell\DscService\Modules\$($ModuleName)_$($ModuleVersion).zip" -Force
    }
}


# View the folders before publishing for pull
dir "$Env:PROGRAMFILES\WindowsPowerShell\Modules\[xc]*"
dir "$Env:PROGRAMFILES\WindowsPowerShell\DscService\Modules\*"

# Publish the modules for pull
# Review the code above
Publish-DscResourcePull -Module ((dir "$Env:PROGRAMFILES\WindowsPowerShell\Modules\[xc]*").name)

# View the published modules
dir "$Env:PROGRAMFILES\WindowsPowerShell\DscService\Modules\"

#endregion



#region Verify modules not present on node. Delete them.

$node = 'ms1.contoso.com'
$Dest   = "\\$node\C$\Program Files\WindowsPowerShell\Modules\"
dir $Dest
Remove-Item "$Dest\[xc]*" -Recurse -Force

#end region



#region Pull a configuration and its published modules

$guid = (New-Guid).Guid

$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = $node
            PSDscAllowPlainTextPassword = $false
            CertificateFile = "C:\publicKeys\$node.EncryptionCertificate.cer"
            Thumbprint = (Get-PfxCertificate -FilePath "C:\publicKeys\$node.EncryptionCertificate.cer").Thumbprint
            GUID = $guid
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
 			ConfigurationMode = 'ApplyAndMonitor'
			ConfigurationID = $node.GUID
			RefreshMode = 'Pull'
            RebootNodeIfNeeded = $true
			DownloadManagerName = 'WebDownloadManager'
			DownloadManagerCustomData = @{
				ServerUrl = 'https://pull.contoso.com:8080/PSDSCPullServer.svc';
				AllowUnsecureConnection = 'false' }
           CertificateId = $node.Thumbprint
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
    -Credential (Get-Credential -UserName Contoso\EricLang -Message "Credentials to read AD users")

# Publish pull configuration
Copy-Item -Path ".\AllowRemoteDesktopAdminConnections\$node.mof" `
    -Destination "$Env:ProgramFiles\WindowsPowerShell\DscService\Configuration\$guid.mof"
New-DSCCheckSum "$Env:ProgramFiles\WindowsPowerShell\DscService\Configuration\$guid.mof"
dir "$Env:ProgramFiles\WindowsPowerShell\DscService\Configuration\"

# Configure pull mode on the remote node
Set-DscLocalConfigurationManager .\AllowRemoteDesktopAdminConnections

# Apply the configuration immediately
Update-DscConfiguration -ComputerName $node -Wait -Verbose

# Notice the pull at the beginning of the verbose stream

#endregion



#region View the module path to see the downloaded modules

# Notice only the modules required for the configuration
# Plus some other default modules optionally
dir $Dest

#endregion







# Reset

Remove-Item "$Env:PROGRAMFILES\WindowsPowerShell\DscService\Modules\*.zip*"
Remove-Item "$Dest\[xc]*" -Recurse -Force

Invoke-Command -ComputerName $node -ScriptBlock {
    net localgroup "Remote Desktop Users" /delete contoso\ericlang
}
