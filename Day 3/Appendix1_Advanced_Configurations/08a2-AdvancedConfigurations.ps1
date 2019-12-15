Configuration myWebServer {
Param ( 
        [String[]]$ComputerName = $env:COMPUTERNAME, 
        
        [Parameter(Mandatory)]
        [String[]]$WindowsFeature
       )

   Import-DSCResource -ModuleName PSDesiredStateConfiguration

   Node $ComputerName 
   {
        foreach ($Feature in $WindowsFeature)
        {
            Write-Verbose -Message $Feature
            WindowsFeature $Feature 
            {
                Name   = $Feature
                Ensure = 'Present'
            }
        }
    }
}

$WebFeatures = 'Web-Server','Web-Mgmt-Service'
myWebServer -ComputerName ms1 -WindowsFeature $WebFeatures
psedit .\myWebServer\ms1.mof
