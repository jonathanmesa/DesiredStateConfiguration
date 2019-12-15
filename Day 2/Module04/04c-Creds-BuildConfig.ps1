break
cls

Set-Location C:\PShell\Demos

# Credential handling in DSC


#region Resources with credential parameters

$r = Get-DscResource

# All credential resources
$r | % {$_; $_ | select -ExpandProperty Properties |
    ? PropertyType -eq '[PSCredential]' | ft -AutoSize}

# All mandatory credential resources
$r | % {$_; $_ | select -ExpandProperty Properties |
    ? {$_.PropertyType -eq '[PSCredential]' -and $_.IsMandatory -eq $true} | ft -AutoSize}

# Group resource
$r | ? name -eq 'Group' | % {$_; $_ | select -ExpandProperty Properties | ft -AutoSize}

#endregion



#region Unencrypted example
Configuration PlainTextPassword
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
            GroupName = 'Backup Operators'
            Members = 'contoso\ericlang'
            Ensure = 'Present'
            Credential = $Credential
        }
    }
} 

$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = "localhost"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser = $true
        }
    )
}

PlainTextPassword -ConfigurationData $ConfigData `
    -Credential (Get-Credential -Message "Enter credentials for configuration" -UserName 'contoso\administrator') 

notepad .\PlainTextPassword\localhost.mof

#endregion


#region Encrypted example
Configuration EncryptedPassword
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
            GroupName = 'Backup Operators'
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

$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = "pull"
            PSDscAllowPlainTextPassword = $false
            PSDscAllowDomainUser = $true

            # For build server encryption
            CertificateFile = "c:\publicKeys\$env:COMPUTERNAME.cer"

            # For target node LCM
            #Thumbprint = "EB6F9378991A47432863B8BA80A0693750E8D7FB"
            Thumbprint = (Get-PfxCertificate -FilePath "C:\publicKeys\$env:COMPUTERNAME.cer").Thumbprint
        }
    )
}

EncryptedPassword -ConfigurationData $ConfigData `
    -Credential (Get-Credential -Message "Enter credentials for configuration" -UserName 'contoso\administrator') 

notepad .\EncryptedPassword\pull.mof

#endregion


#region Scaled configuration example
 
$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = "*"
            PSDscAllowPlainTextPassword = $false
        }
    )
}

$Nodes = Import-CSV .\NodeList.csv

ForEach ($Node in $Nodes) {
    $ConfigData.AllNodes += @{
            NodeName        = $Node.NodeName
            Role            = $Node.Role
            CertificateFile = $Node.CertPath
            Thumbprint      = $Node.Thumbprint
            GUID            = $Node.GUID
    }
}

#endregion


# Set up LCM to decrypt credentials
Set-DscLocalConfigurationManager .\EncryptedPassword -Verbose 

# Note CertificateID
Get-DscLocalConfigurationManager

# Start configuration
Start-DscConfiguration .\EncryptedPassword -Wait -Verbose -Force

# Confirm change
net localgroup "Backup Operators"

# Remove user
net localgroup "Backup Operators" /delete contoso\ericlang
