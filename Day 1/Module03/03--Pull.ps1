configuration DscPullServer_HTTP
{ 
    param  
    ( 
        [string[]]$NodeName = 'localhost'
     ) 

     Import-DSCResource -ModuleName xPSDesiredStateConfiguration
     Import-DSCResource –ModuleName PSDesiredStateConfiguration

     Node $NodeName 
     { 
         WindowsFeature DSCServiceFeature 
         { 
             Ensure = 'Present'
             Name   = 'DSC-Service'             
         } 

         xDscWebService PSDSCPullServer 
         { 
             Ensure                   = 'Present' 
             EndpointName             = 'PSDSCPullServer' 
             Port                     = 8080 
             PhysicalPath             = "$env:SystemDrive\inetpub\PSDSCPullServer" 
             CertificateThumbPrint    = 'AllowUnencryptedTraffic'          
             ModulePath               = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules" 
             ConfigurationPath        = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration" 
             State                    = 'Started'
             DependsOn                = '[WindowsFeature]DSCServiceFeature'     
             UseSecurityBestPractices = $false
         } 

    }
}

DscPullServer_HTTP

Start-DscConfiguration -Path .\DscPullServer_HTTP -Wait -Verbose

Start-Process 'http://pull.contoso.com:8080/PSDSCPullServer.svc'
