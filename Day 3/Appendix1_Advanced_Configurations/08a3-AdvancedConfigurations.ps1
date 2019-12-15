Configuration myWebServer {

   Import-DSCResource -ModuleName PSDesiredStateConfiguration

   Node $AllNodes.NodeName 
   {
        foreach ($Feature in $Node.WindowsFeature)
        {
            WindowsFeature $Feature 
            {
                Name   = $Feature
                Ensure = 'Present'
            }
        }
    }
}
$ConfigData = @{
   AllNodes = @(
      @{
         Nodename       = 'ms1'
         WindowsFeature = 'Web-Server','Web-Mgmt-Service'                         
      }          
   )#AllNodes 
}

myWebServer -ConfigurationData $ConfigData
psedit .\myWebServer\ms1.mof
