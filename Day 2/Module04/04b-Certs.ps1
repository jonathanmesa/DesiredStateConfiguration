break
cls

Set-Location C:\PShell\Demos

# Certificate provider drive
cd cert:

# Dynamic parameters of Get-ChildItem
dir -
dir -Recurse

# Local machine certs for DSC
dir Cert:\LocalMachine\My

<#
# Encryption-capable and valid
dir Cert:\LocalMachine\My |
    ? {$_.PrivateKey.KeyExchangeAlgorithm -and $_.Verify()} |
    ft Subject, FriendlyName, HasPrivateKey, EnhancedKeyUsageList, Thumbprint -AutoSize

dir Cert:\LocalMachine\My -DocumentEncryptionCert

# https://msdn.microsoft.com/en-us/powershell/dsc/securemof
# From an elevated PowerShell session
New-SelfSignedCertificate -Type DocumentEncryptionCertLegacyCsp -DnsName 'DscEncryptionCert' 

Get-Command New-SelfSignedCertificate -Syntax
#>

# Manually create Cert template "PSCMS" for document encryption type,
# add Domain Computers security Read,Enroll,Autoenroll
$Req = @{
    Template          = 'PSCMS'
    Url               = 'ldap:'
    CertStoreLocation = 'Cert:\LocalMachine\My'
}
Get-Certificate @Req

dir Cert:\LocalMachine\My -DocumentEncryptionCert

$DocEncrCert = (dir Cert:\LocalMachine\My -DocumentEncryptionCert)[-1]
Protect-CmsMessage -To $DocEncrCert -Content "Encrypted with my new cert from the new template!"
Get-Process | Protect-CmsMessage -To $DocEncrCert

cd cert:

$cert = dir Cert:\LocalMachine\My -DocumentEncryptionCert
$cert

# Export the public key certificate
$cert | Export-Certificate -FilePath "$env:temp\DscPublicKey.cer" -Force 


# Capture the cert
$cert = Get-ChildItem -Path Cert:\LocalMachine\My\B57FA6247EB2FB1F3C27B41889279D02183C7592
$cert

# Export the public key
md C:\publicKeys -ErrorAction SilentlyContinue
Export-Certificate -Cert $cert -FilePath "c:\publicKeys\$env:COMPUTERNAME.cer" -Force

# Query the thumbprint
Get-PfxCertificate -FilePath "C:\publicKeys\$env:COMPUTERNAME.cer"
