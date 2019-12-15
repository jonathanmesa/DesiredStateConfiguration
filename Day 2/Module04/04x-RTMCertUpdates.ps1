certutil /?
Get-Module *cert* -ListAvailable
$dc = New-PSSession -ComputerName dc
Get-Module -PSSession $dc -ListAvailable
Enter-PSSession $dc
Get-Command -Module ADCSAdministration,ADCSDeployment
Get-Command Add-CATemplate -Syntax
Get-Help Add-CATemplate

# https://msdn.microsoft.com/en-us/powershell/dsc/securemof
# From an elevated PowerShell session
$cert = New-SelfSignedCertificate -Type DocumentEncryptionCertLegacyCsp -DnsName 'DscEncryptionCert' 
# Export the public key certificate
$cert | Export-Certificate -FilePath "$env:temp\DscPublicKey.cer" -Force 

# Import to the my store
Import-Certificate -FilePath "$env:temp\DscPublicKey.cer" -CertStoreLocation Cert:\LocalMachine\My


Get-ADObject -SearchBase 'CN=OID,CN=Public Key Services,CN=Services,CN=Configuration,DC=contoso,DC=com' -filter * -Properties * | select name,'msPKI-Cert-Template-OID' | ft -AutoSize
Get-ADObject -SearchBase 'CN=OID,CN=Public Key Services,CN=Services,CN=Configuration,DC=contoso,DC=com' -filter * -Properties * | ogv
Get-ADObject -Identity "CN=OID,CN=Public Key Services,CN=Services,$((Get-ADRootDSE).configurationNamingContext)" -Properties msPKI-Cert-Template-OID | Select-Object -ExpandProperty msPKI-Cert-Template-OID
$TemplatePath = "CN=Certificate Templates,CN=Public Key Services,CN=Services,$((Get-ADRootDSE).configurationNamingContext)"
Get-ADObject -SearchBase $TemplatePath -Filter {Name -like "*dsc*" -or DisplayName -like "*Computer*"} -Properties * | select * | ogv
Get-ADObject -SearchBase $TemplatePath -Filter * -Properties * | select 'msPKI-Cert-Template-OID',* | ogv
Get-ADObject -SearchBase $TemplatePath -Filter {Name -like "*dsc*" -or DisplayName -like "*Computer*"} -Properties * | gm
$Template = Get-ADObject -SearchBase $TemplatePath -Filter {Name -like "psdsc*"} -Properties *
$Template | Get-Member -MemberType Property | Where-Object Definition -like "*set;*" | fl *


Function ConvertTo-HashTable {
param(
    $object,
    [switch]$AsString = $false
)

    $PropertiesToExclude = 'nTSecurityDescriptor','DistinguishedName','objectGUID','showInAdvancedViewOnly'#,'displayName'

    If ($AsString) {
        $ht = "@{`r`n"
        $object | Get-Member -MemberType Properties | Where-Object {$_.Definition -like "*set;*" -and $_.Name -notin $PropertiesToExclude} | ForEach-Object {
            If ($object.($_.Name)) {
                $datatype = ($_.Definition -split ' ')[0]
                If ($datatype -match '\[\]' -or $datatype -like '*ADPropertyValueCollection*') {
                    $ht += "`t'$($_.Name)' = [$datatype]@('$($object.($_.Name) -join ''',''')')`r`n"
                } Else {
                    $ht += "`t'$($_.Name)' = [$datatype]'$($object.($_.Name))'`r`n"
                }
            }
        }
        $ht += '}'
        $ht
    } Else {
        $ht = @{}
        $object | Get-Member -MemberType Properties | Where-Object {$_.Definition -like "*set;*" -and $_.Name -notin $PropertiesToExclude} | ForEach-Object {
            If ($object.($_.Name)) {
                $ht.Add($_.Name,$object.($_.Name))
            }
        }
        $ht
    }
}


Import-Module ActiveDirectory

'System.Byte[]' -match '\[\]'
'System.Int32' -match '\[\]'

$TemplatePath = "CN=Certificate Templates,CN=Public Key Services,CN=Services,$((Get-ADRootDSE).configurationNamingContext)"
$Template = Get-ADObject -SearchBase $TemplatePath -Filter {Name -like "psdsc*"} -Properties *
$Template | Get-Member -MemberType Property | Where-Object Definition -like "*set;*" | fl *

$TemplatePath = "CN=Certificate Templates,CN=Public Key Services,CN=Services,$((Get-ADRootDSE).configurationNamingContext)"
$Template = Get-ADObject -SearchBase 'CN=OID,CN=Public Key Services,CN=Services,CN=Configuration,DC=contoso,DC=com' -filter {displayName -like "*encr*"} -Properties *

$Template | Get-Member -MemberType Properties

ConvertTo-HashTable -object ($Template) -AsString
ConvertTo-HashTable -object ($Template)

Invoke-Expression -Command "$(ConvertTo-HashTable -object ($Template) -AsString)"
Invoke-Expression -Command "`$oa = $(ConvertTo-HashTable -object ($Template) -AsString)"

$OtherAttributes = ConvertTo-HashTable -object ($Template) -AsString


[Microsoft.ActiveDirectory.Management.ADPropertyValueCollection]'1.3.6.1.4.1.311.80.1'
[byte[]]@(34,0,45,1)

[System.Byte[]]@('0','128','114','14','93','194','253','255')


$oa = @{
	'flags' = [System.Int32]'131680'
	'msPKI-Cert-Template-OID' = [System.String]'1.3.6.1.4.1.311.21.8.11489019.14294623.5588661.594850.12204198.151.14822902.8000595'
	'msPKI-Certificate-Application-Policy' = [Microsoft.ActiveDirectory.Management.ADPropertyValueCollection]@('1.3.6.1.4.1.311.80.1')
	'msPKI-Certificate-Name-Flag' = [System.Int32]'134217728'
	'msPKI-Enrollment-Flag' = [System.Int32]'32'
	'msPKI-Minimal-Key-Size' = [System.Int32]'2048'
	'msPKI-Private-Key-Flag' = [System.Int32]'16842752'
	'msPKI-Template-Minor-Revision' = [System.Int32]'2'
	'msPKI-Template-Schema-Version' = [System.Int32]'2'
    'msPKI-RA-Signature' = [System.Int32]'0'
    'pKIMaxIssuingDepth' = [System.Int32]'0'
	'ObjectClass' = [System.String]'pKICertificateTemplate'
	'pKICriticalExtensions' = [Microsoft.ActiveDirectory.Management.ADPropertyValueCollection]@('2.5.29.15')
	'pKIDefaultCSPs' = [Microsoft.ActiveDirectory.Management.ADPropertyValueCollection]@('1,Microsoft RSA SChannel Cryptographic Provider')
	'pKIDefaultKeySpec' = [System.Int32]'1'
	'pKIExpirationPeriod' = [System.Byte[]]@('0','128','114','14','93','194','253','255')
	'pKIExtendedKeyUsage' = [Microsoft.ActiveDirectory.Management.ADPropertyValueCollection]@('1.3.6.1.4.1.311.80.1')
	'pKIKeyUsage' = [System.Byte[]]@('160','0')
	'pKIOverlapPeriod' = [System.Byte[]]@('0','128','166','10','255','222','255','255')
	'revision' = [System.Int32]'100'
}

New-ADObject -Path $TemplatePath -OtherAttributes $oa -Name TestDscEncrTemplate3 -DisplayName TestDscEncrTemplate3 -Type pKICertificateTemplate


@{
	'DisplayName' = [System.String]'PSDSCPwdEncr'
	'flags' = [System.Int32]'131680'
	'msPKI-Cert-Template-OID' = [System.String]'1.3.6.1.4.1.311.21.8.11489019.14294623.5588661.594850.12204198.151.14822902.8000595'
	'msPKI-Certificate-Application-Policy' = [Microsoft.ActiveDirectory.Management.ADPropertyValueCollection]@('1.3.6.1.4.1.311.80.1')
	'msPKI-Certificate-Name-Flag' = [System.Int32]'134217728'
	'msPKI-Enrollment-Flag' = [System.Int32]'32'
	'msPKI-Minimal-Key-Size' = [System.Int32]'2048'
	'msPKI-Private-Key-Flag' = [System.Int32]'16842752'
	'msPKI-Template-Minor-Revision' = [System.Int32]'2'
	'msPKI-Template-Schema-Version' = [System.Int32]'2'
	'ObjectClass' = [System.String]'pKICertificateTemplate'
	'pKICriticalExtensions' = [Microsoft.ActiveDirectory.Management.ADPropertyValueCollection]@('2.5.29.15')
	'pKIDefaultCSPs' = [Microsoft.ActiveDirectory.Management.ADPropertyValueCollection]@('1,Microsoft RSA SChannel Cryptographic Provider')
	'pKIDefaultKeySpec' = [System.Int32]'1'
	'pKIExpirationPeriod' = [System.Byte[]]@('0','128','114','14','93','194','253','255')
	'pKIExtendedKeyUsage' = [Microsoft.ActiveDirectory.Management.ADPropertyValueCollection]@('1.3.6.1.4.1.311.80.1')
	'pKIKeyUsage' = [System.Byte[]]@('160','0')
	'pKIOverlapPeriod' = [System.Byte[]]@('0','128','166','10','255','222','255','255')
	'revision' = [System.Int32]'100'
}




$TemplatePath        = 'AD:\CN=WebServer,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=contoso,DC=com'
$acl                 = Get-ACL $TemplatePath
$account             = New-Object System.Security.Principal.NTAccount('CONTOSO\Domain Computers')
$sid                 = $account.Translate([System.Security.Principal.SecurityIdentifier])
$ObjectType          = [GUID]'0e10c968-78fb-11d2-90d4-00c04f79dc55'
$InheritedObjectType = [GUID]'00000000-0000-0000-0000-000000000000'
$ace                 = New-Object System.DirectoryServices.ActiveDirectoryAccessRule `
    $sid, 'ExtendedRight', 'Allow', $ObjectType, 'None', $InheritedObjectType
$acl.AddAccessRule($ace)
Set-ACL $TemplatePath -AclObject $acl


$DisplayName             = 'PSCMS8'
$TemplatePath            = "AD:\CN=$DisplayName,CN=Certificate Templates,CN=Public Key Services,CN=Services,CN=Configuration,DC=contoso,DC=com"
(Get-ACL $TemplatePath).Access | gm
