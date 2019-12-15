# Ensure the Composite Resource has been extracted
Expand-Archive -Path C:\PShell\Demos\PSDSCHelper.zip -DestinationPath $env:ProgramFiles\windowspowershell\modules\ -Verbose

Configuration myWebServer {

   Import-DSCResource -ModuleName PSDSCHelper

   Node $AllNodes.NodeName 
   {
        NewWindowsFeature WindowsFeature
        {
            Config = $Node.WindowsFeature
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
