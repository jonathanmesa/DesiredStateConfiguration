Configuration SetRDPConfiguration {
param (
       [pscredential]$ReadADCred 
    )
   
   Import-DSCResource -ModuleName PSDSCHelper

    Node $AllNodes.NodeName 
    {
       contosoCompositeRDP EnableRDP
       {
          Members    = "$env:USERDOMAIN\HelpdeskAdmin"
          Credential = $ReadADCred
       } 
    }
}

$Node = "ms1"
$CertFile = "\\pull\pshell\ComputerCerts\$($Node).$($env:USERDNSDOMAIN).cer"
$Cert = Get-PfxCertificate -FilePath $CertFile

$ConfigData = @{
    AllNodes = @(
        @{
            NodeName        = $Node
            CertificateFile = $CertFile 
            Thumbprint      = $Cert.Thumbprint
         }
    )
}

$Cred = (Get-credential $env:USERDOMAIN\HelpdeskAdmin)
SetRDPConfiguration -ConfigurationData $ConfigData -ReadADCred $Cred
psedit .\SetRDPConfiguration\ms1.mof

