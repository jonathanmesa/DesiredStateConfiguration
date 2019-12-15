<#-----------------------------------------------------------------------------
Ashley McGlone, Microsoft Premier Field Engineer
April 2016
-------------------------------------------------------------------------------
LEGAL DISCLAIMER
This Sample Code is provided for the purpose of illustration only and is not
intended to be used in a production environment.  THIS SAMPLE CODE AND ANY
RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  We grant You a
nonexclusive, royalty-free right to use and modify the Sample Code and to
reproduce and distribute the object code form of the Sample Code, provided
that You agree: (i) to not use Our name, logo, or trademarks to market Your
software product in which the Sample Code is embedded; (ii) to include a valid
copyright notice on Your software product in which the Sample Code is embedded;
and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and
against any claims or lawsuits, including attorneys’ fees, that arise or result
from the use or distribution of the Sample Code.
 
This posting is provided "AS IS" with no warranties, and confers no rights. Use
of included script samples are subject to the terms specified
at http://www.microsoft.com/info/cpyright.htm.
-----------------------------------------------------------------------------#>

#region Harvest Certificates ##################################################


$nodes = 'pull','ms1','ms2'

# Verify that each node has autoenrolled a certificate
Invoke-Command -ComputerName $nodes -ScriptBlock {dir Cert:\LocalMachine\My -DocumentEncryptionCert}
#Invoke-Command -ScriptBlock {certutil -pulse;dir Cert:\LocalMachine\My -DocumentEncryptionCert} -ComputerName ms1,ms2

md C:\PublicKeys -ErrorAction SilentlyContinue
del C:\PublicKeys\*.* -Force -ErrorAction SilentlyContinue

ForEach ($node in $nodes) {
    $pss = New-PSSession $node
    $return = Invoke-Command -Session $pss -ScriptBlock {
        md C:\MyPublicKeys -ErrorAction SilentlyContinue | Out-Null
        # Cert verify fails remotely due to Kerberos Double Hop
        #$cert = Get-ChildItem Cert:\LocalMachine\My -DocumentEncryptionCert | Where-Object {$_.Verify()} | Select-Object -Last 1
        $cert = Get-ChildItem Cert:\LocalMachine\My -DocumentEncryptionCert | Select-Object -Last 1
        Export-Certificate -Cert $cert -FilePath "C:\MyPublicKeys\$Env:COMPUTERNAME.cer" -Force | Out-Null
        $cert.Thumbprint
    }
    Copy-Item -FromSession $pss -Path "C:\MyPublicKeys\$node.cer" -Destination C:\PublicKeys -Force

    [PSCustomObject]@{
        Node = $node
        Path = "C:\PublicKeys\$node.cer"
        Thumbprint = $return
    } | Export-Csv -Path C:\PublicKeys\index.csv -Append -NoTypeInformation

    Remove-PSSession $pss
}

Import-Csv C:\PublicKeys\index.csv

#endregion ####################################################################


#region Install the resource modules ##########################################

Install-Module xRemoteDesktopAdmin,xNetworking -Force

#endregion ####################################################################



#region Configurations ########################################################

Configuration EnableRDP
{
Param(
    [pscredential]$Credential
)
    Import-DscResource -ModuleName PSDesiredStateConfiguration, xRemoteDesktopAdmin, xNetworking

    Node $AllNodes.NodeName
    {
        xRemoteDesktopAdmin RemoteDesktopSettings
        {
           Ensure = 'Present'
           UserAuthentication = 'Secure'
        }

        xFirewall AllowRDP
        {
            Name = 'DSC - Remote Desktop Admin Connections'
            Group = "Remote Desktop"
            Ensure = 'Present'
            Enabled = $true
            Action = 'Allow'
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

#endregion ####################################################################



#region LCM ###################################################################

[DscLocalConfigurationManager()]
Configuration LCMDecrypt
{
    Node $AllNodes.NodeName
    {
        Settings
        {
            CertificateID = $Node.Thumbprint
        }
    }
}

#endregion ####################################################################



#region DYNAMIC CONFIGURATION DATA ############################################

$nodes = Import-Csv C:\PublicKeys\index.csv

$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = "*"
            PSDscAllowDomainUser = $true
        }
    )
}

ForEach ($node in $nodes) {
    $ConfigData.AllNodes += @{
        NodeName        = $node.Node
        CertificateFile = $node.Path
        Thumbprint      = $node.Thumbprint
    }
}

$ConfigData.Values

#endregion ####################################################################



#region GENERATE MOF AND META.MOF #############################################

cd C:\PShell\Labs\Lab08

EnableRDP  -ConfigurationData $ConfigData -Credential (Get-Credential -UserName 'CONTOSO\Administrator' -Message 'Enter the password')
LCMDecrypt -ConfigurationData $ConfigData

Get-ChildItem .\EnableRDP\*.mof  | ForEach-Object {psEdit $_.FullName}
Get-ChildItem .\LCMDecrypt\*.mof | ForEach-Object {psEdit $_.FullName}

#endregion ####################################################################



Set-DscLocalConfigurationManager -Path .\LCMDecrypt -Verbose
Publish-DSCModuleAndMof -Source .\EnableRDP -ModuleNameList xRemoteDesktopAdmin,xNetworking

