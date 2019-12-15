Configuration myWebServer {
Param ( 
        [String[]]$ComputerName = $env:COMPUTERNAME
       )

   Import-DSCResource -ModuleName PSDesiredStateConfiguration

   Node $ComputerName 
   {
        WindowsFeature 'Web-Mgmt-Service' 
        {
            Name   = 'Web-Mgmt-Service'
            Ensure = 'Present'
        }
           
        WindowsFeature 'Web-Server'
        {
            Name   = 'Web-Server'
            Ensure = 'Present'
        }
    }
}

myWebServer -ComputerName ms1 -Verbose
psedit .\myWebServer\ms1.mof
