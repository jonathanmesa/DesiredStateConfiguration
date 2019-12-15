break
cls

Set-Location C:\PShell\Demos


Get-DscLocalConfigurationManager

# WMF 4.0

Configuration HTTPSExample
{
    Node $AllNodes.NodeName
    {
        LocalConfigurationManager
        {
            ConfigurationID = $node.GUID
            CertificateId = $node.Thumbprint
            RefreshMode = 'Pull'
            RebootNodeIfNeeded = $true
            DownloadManagerName = 'WebDownloadManager'
            DownloadManagerCustomData = @{
                ServerUrl = 'https://pull.contoso.com:8080/PSDSCPullServer.svc'
                AllowUnsecureConnection = 'false' }
        }
    }
} 


# WMF 5.0

[DscLocalConfigurationManager()]
Configuration HTTPSExample
{
    Node $AllNodes.NodeName
    {
        Settings
        {
            ConfigurationID = $node.GUID
            CertificateId = $node.Thumbprint
            RefreshMode = 'Pull'
        }
        ConfigurationRepositoryWeb PullServer
        {
            ServerUrl = 'https://pull.contoso.com:8080/PSDSCPullServer.svc'
        }
    }
} 

HTTPSExample -ConfigurationData $ConfigData
Set-DscLocalConfigurationManager -Path .\HTTPSExample -Verbose



### CREDENTIAL SAMPLE WITH HTTPS PULL ###
# Modified from:
#    http://blogs.msdn.com/b/powershell/archive/2014/01/31/want-to-secure-credentials-in-windows-powershell-desired-state-configuration.aspx

# A simple example of using credentials
configuration CredentialEncryptionExample
{
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [PsCredential] $credential
        )
    
    Import-DscResource –ModuleName PSDesiredStateConfiguration

    Node $AllNodes.NodeName
    {
        Group TestGroup
        {
            GroupName = 'WorldDomination'
            Members = 'contoso\ericlang'
            Ensure = 'Present'
            Credential = $credential
        }
        
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
    }
}

# A Helper to invoke the configuration, with the correct public key 
# To encrypt the configuration credentials
function Start-CredentialEncryptionExample
{
    [CmdletBinding()]
    param ($computerName,$guid)

    [string] $thumbprint = Get-EncryptionCertificate -computerName $computerName -Verbose
    Write-Verbose "using cert: $thumbprint"

    $certificatePath = join-path -Path "$env:SystemDrive\$script:publicKeyFolder" -childPath "$computername.EncryptionCertificate.cer"         

    $ConfigData=    @{
        AllNodes = @(     
                        @{  
                            # The name of the node we are describing
                            NodeName = "$computerName"

                            # The path to the .cer file containing the
                            # public key of the Encryption Certificate
                            CertificateFile = "$certificatePath"

                            # The thumbprint of the Encryption Certificate
                            # used to decrypt the credentials
                            Thumbprint = $thumbprint

                            # Pull GUID
                            GUID = $guid
                        };
                    );    
    }

    Write-Verbose "Generate DSC Configuration..."
    CredentialEncryptionExample -ConfigurationData $ConfigData -OutputPath .\CredentialEncryptionExample `
        -credential (Get-Credential -UserName "$env:USERDOMAIN\$env:USERNAME" -Message "Enter credentials for configuration") 

    # Rename the file with a GUID and create the checksum
    $source = ".\CredentialEncryptionExample\$computerName.mof"
    $dest = "C:\Program Files\WindowsPowerShell\DSCService\Configuration\$guid.mof"
    Copy-Item -Path $source -Destination $dest
    New-DSCChecksum $dest

    Write-Verbose "Setting up LCM to pull configuration and decrypt credentials..."
    Set-DscLocalConfigurationManager .\CredentialEncryptionExample -Verbose 

    Write-Verbose "Starting Configuration..."
    #Start-DscConfiguration .\CredentialEncryptionExample -wait -Verbose -Force   ### Added -Force
    # Trigger client pull

    ### Can trigger pull this way on PSv4 target:
    # Get-ScheduledTask Consistency -CimSession $cim | Start-ScheduledTask -CimSession $cim
    ### Trigger pull in v5
    Update-DSCConfiguration -ComputerName $computername -Wait -Verbose
    ### From v4 to v5
    #Invoke-Command -ComputerName $computername -ScriptBlock {Update-DSCConfiguration -Wait}

}


#region HelperFunctions

# The folder name for the exported public keys
$script:publicKeyFolder = "publicKeys"

# Get the certificate that works for encryptions
function Get-EncryptionCertificate
{
    [CmdletBinding()]
    param ($computerName)
    $returnValue= Invoke-Command -ComputerName $computerName -ScriptBlock {

            # # # Must enable SMB share access before you can copy the certificate off the box
            Get-NetFirewallRule fps-smb* | Enable-NetFirewallRule

            $certificates = dir Cert:\LocalMachine\my

            $certificates | %{
                    # Verify the certificate is for Encryption and valid
                    if ($_.PrivateKey.KeyExchangeAlgorithm -and $_.Verify())
                    {
                        # Create the folder to hold the exported public key
                        $folder= Join-Path -Path $env:SystemDrive\ -ChildPath $using:publicKeyFolder
                        if (! (Test-Path $folder))
                        {
                            md $folder | Out-Null
                        }

                        # Export the public key to a well known location
                        $certPath = Export-Certificate -Cert $_ -FilePath (Join-Path -path $folder -childPath "EncryptionCertificate.cer") 

                        # Return the thumbprint, and exported certificate path
                        return @($_.Thumbprint,$certPath);
                    }
                  }
        }
    Write-Verbose "Identified and exported cert..."
    # Copy the exported certificate locally
    md "$env:SystemDrive\$script:publicKeyFolder" -ErrorAction SilentlyContinue
    $destinationPath = join-path -Path "$env:SystemDrive\$script:publicKeyFolder" -childPath "$computername.EncryptionCertificate.cer"
    Copy-Item -Path (join-path -path \\$computername -childPath $returnValue[1].FullName.Replace(":","$"))  $destinationPath | Out-Null

    # Return the thumbprint
    return $returnValue[0]
}
 

#end

Start-CredentialEncryptionExample -computerName ms1.contoso.com -guid ([guid]::NewGuid().ToString())

# View pull MOFs
dir "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"

# View encrypted credential
notepad (dir "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration" | sort lastwritetime)[-2].FullName


# Confirm LCM configuration: Pull, HTTPS, CertificateID
$cim = New-CimSession ms1.contoso.com
Get-DscLocalConfigurationManager -CimSession $cim
(Get-DscLocalConfigurationManager -CimSession $cim).DownloadManagerCustomData

# Confirm configuration
Test-DscConfiguration -CimSession $cim

Get-DscConfiguration -CimSession $cim

Invoke-Command -ComputerName ms1.contoso.com -ScriptBlock {
    net localgroup "WorldDomination"
}

# View the remote encrypted creds
notepad \\ms1\c$\windows\system32\configuration\current.mof

Remove-CimSession $cim







Invoke-Command -ComputerName ms1.contoso.com -ScriptBlock {
    net localgroup "WorldDomination" /delete
}
