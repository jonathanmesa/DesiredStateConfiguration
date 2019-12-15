cd C:\PandoraTemp

Install-Module xPSDesiredStateConfiguration

configuration Sample_xDscWebService 
{ 
    param  
    ( 
            [string[]]$NodeName = 'localhost', 

            #[ValidateNotNullOrEmpty()] 
            #[string] $certificateThumbPrint,

            [Parameter(Mandatory)]
            [ValidateNotNullOrEmpty()]
            [string] $RegistrationKey 
     ) 


     Import-DSCResource -ModuleName xPSDesiredStateConfiguration -ModuleVersion '3.9.0.0'
     Import-DSCResource -ModuleName PSDesiredStateConfiguration

     Node $NodeName 
     { 
         WindowsFeature DSCServiceFeature 
         { 
             Ensure = "Present" 
             Name   = "DSC-Service"             
         } 

         xDscWebService PSDSCPullServer 
         { 
             Ensure                  = "Present" 
             EndpointName            = "PSDSCPullServer" 
             Port                    = 8080 
             PhysicalPath            = "$env:SystemDrive\inetpub\PSDSCPullServer" 
             CertificateThumbPrint   = "AllowUnencryptedTraffic"  #$certificateThumbPrint          
             ModulePath              = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules" 
             ConfigurationPath       = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"             
             State                   = "Started" 
             DependsOn               = "[WindowsFeature]DSCServiceFeature"                         
         } 

        File RegistrationKeyFile
        {
            Ensure          ='Present'
            Type            = 'File'
            DestinationPath = "$env:ProgramFiles\WindowsPowerShell\DscService\RegistrationKeys.txt"
            Contents        = $RegistrationKey
        }
    }
}

$RegKey = (New-Guid).Guid
Sample_xDscWebService -RegistrationKey $RegKey

Start-DscConfiguration -Path .\Sample_xDscWebService -Wait -Verbose -Force

Start-Process 'http://PULL:8080/PSDSCPullServer.svc'
