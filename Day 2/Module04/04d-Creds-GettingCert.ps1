break
cls

Set-Location C:\PShell\Demos


# Via remoting:
start iexplore.exe http://blogs.msdn.com/b/powershell/archive/2014/01/31/want-to-secure-credentials-in-windows-powershell-desired-state-configuration.aspx
# Via AD CS:
start iexplore.exe http://dollarunderscore.azurewebsites.net/?p=4791

# Reset
Invoke-Command -ComputerName ms1.contoso.com -ScriptBlock {
    net localgroup "Remote Desktop Users" /delete contoso\ericlang
}

### CREDENTIAL PUSH SAMPLE ###
# Based on this post:
# http://blogs.msdn.com/b/powershell/archive/2014/01/31/want-to-secure-credentials-in-windows-powershell-desired-state-configuration.aspx


# A simple example of using credentials
Configuration CredentialEncryptionExample
{
    Param(
        [Parameter(Mandatory=$true)]
        [PsCredential]$Credential
    )

    Import-DscResource –ModuleName PSDesiredStateConfiguration

    Node $AllNodes.NodeName
    {
        Group TestGroup
        {
            GroupName = 'Remote Desktop Users'
            Members = 'contoso\ericlang'
            Ensure = 'Present'
            Credential = $Credential
        }
        
        LocalConfigurationManager
        {
           CertificateId = $node.Thumbprint
        }
    }
}

# A Helper to invoke the configuration, with the correct public key 
# To encrypt the configuration credentials
function Start-CredentialEncryptionExample
{
    [CmdletBinding()]
    param ($computerName)


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
                        };
                    );    
    }

    Write-Verbose "Generate DSC Configuration..."
    CredentialEncryptionExample -ConfigurationData $ConfigData -OutputPath .\CredentialEncryptionExample `
        -credential (Get-Credential -UserName "$env:USERDOMAIN\$env:USERNAME" -Message "Enter credentials for configuration") 

    Write-Verbose "Setting up LCM to decrypt credentials..."
    Set-DscLocalConfigurationManager .\CredentialEncryptionExample -Verbose 

    Write-Verbose "Starting Configuration..."
    Start-DscConfiguration .\CredentialEncryptionExample -wait -Verbose -Force

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

            # # # Must enable SMB share access before you can copy the certificate back off the box
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
    md "$env:SystemDrive\$script:publicKeyFolder" -ErrorAction SilentlyContinue  ###Added this line
    $destinationPath = join-path -Path "$env:SystemDrive\$script:publicKeyFolder" -childPath "$computername.EncryptionCertificate.cer"
    Copy-Item -Path (join-path -path \\$computername -childPath $returnValue[1].FullName.Replace(":","$"))  $destinationPath | Out-Null

    # Return the thumbprint
    return $returnValue[0]
}
 

#end

Start-CredentialEncryptionExample -ComputerName ms1.contoso.com

# Confirm
Invoke-Command -ComputerName ms1.contoso.com -ScriptBlock {
    net localgroup "Remote Desktop Users"
}


# View the encrypted password
notepad .\CredentialEncryptionExample\ms1.contoso.com.mof
