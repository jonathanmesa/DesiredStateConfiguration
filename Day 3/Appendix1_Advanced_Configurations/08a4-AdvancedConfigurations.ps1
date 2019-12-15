Configuration myWebServer {

   Import-DSCResource -ModuleName PSDesiredStateConfiguration

   Node $AllNodes.NodeName 
   {
        foreach ($Feature in $Node.WindowsFeature)
        {
            WindowsFeature $Feature.Name 
            {
                Name   = $Feature.Name
                Ensure = $Feature.Ensure
            }
        }
    }
}

$ConfigData = @{
   AllNodes = @(
      @{
         Nodename       = 'ms1'
         WindowsFeature = @{Name = 'Web-Server';       Ensure = 'Present'},
                          @{Name = 'Web-Mgmt-Service'; Ensure = 'Present'},
                          @{Name = 'Web-Ftp-Server';   Ensure = 'Absent'}
      }            
   )#AllNodes 
}

myWebServer -ConfigurationData $ConfigData
psedit .\myWebServer\ms1.mof

