### Example configuration referencing the new composite resource
Configuration WebServerComposite {
    
Import-DscResource -ModuleName PSDSCHelper

    Node $allnodes.nodename
    {   
        
        NewDirectory Dir
        {
           Config = $Node.DirectoryPresent 
        }
        
        NewArchive ArchivePresent
        {
            Config    = $Node.ArchivePresent
            DependsOn = '[NewDirectory]Dir'
        }

        NewWindowsFeature NewFeatures
        {
            Config = $Node.WindowsFeaturePresent
            SourcePath = $ConfigurationData.NonNode.WindowsFeatureSource
        }
        
        NewWebSiteDeploy MyWebapp
        {
            WebSiteAbsent  = $Node.WebSiteAbsent
            AppPoolPresent = $Node.WebAppPoolPresent
            WebSitePresent = $Node.WebSitePresent
            DependsOn      = '[NewWindowsFeature]NewFeatures'
        }

        EnableIISRemote IISAdminRMOT
        {
            DependsOn = '[NewWebSiteDeploy]MyWebapp'
        }

    }
}#WebServerComposite


$Destination = 'F:\Source'
$WebSiteDirectory = 'F:\Website\FourthCoffee'
$COMPUTERNAME = 'ms1'

# Bindings Absent -------------------------------------------------------------------------------------------------------                    
$bindingAbsentFourthCoffee = @{HostHeader = '' ; IPAddress = '*' ; Name = 'FourthCoffee'        ; Port = 80 ; Protocol = 'http'}

# Bindings Present -------------------------------------------------------------------------------------------------------                      
$bindingPresentFourthCoffee = @{HostHeader = "$COMPUTERNAME" ; IPAddress = '*' ; Name = 'FourthCoffee' ; Port = 443 ; Protocol = 'https'},
                              @{HostHeader = "$COMPUTERNAME" ; IPAddress = '*' ; Name = 'FourthCoffee' ; Port = 80  ; Protocol = 'http' } 
$ConfigData = @{
   AllNodes = @(
      @{
         Nodename             = $COMPUTERNAME
         Role                 = 'WebServer'
         Environment          = 'Production'
         
         WindowsFeaturePresent= 'Web-Server','Web-Asp-Net45','Web-Mgmt-Console','Web-Scripting-Tools'
         
         DirectoryPresent     = $Destination,$WebSiteDirectory
         
         ArchivePresent       = @{Destination = $Destination ; Path = "\\$env:USERDNSDOMAIN\shares\dsc\Packages\WebArchive.zip"},
                                @{Destination = $WebSiteDirectory ; Path = "\\$env:USERDNSDOMAIN\shares\dsc\Packages\BakeryWebsite.zip"}

         WebAppPoolPresent    = @{Name = 'FourthCoffee'}
                 
         # Website ------------------------------------------------------------------------------------------------------
         WebSiteAbsent        = @{Name = 'Default Web Site'}
         
         WebSitePresent       = @{Name = 'FourthCoffee'; ApplicationPool = 'FourthCoffee' ; PhysicalPath = $WebSiteDirectory; 
                                   BindingPresent = $bindingPresentFourthCoffee ; BindingAbsent = $bindingAbsentFourthCoffee}
      }            
   )#AllNodes
   NonNode = @{
         WindowsFeatureSource = "\\$Env:USERDOMAIN\shares\Source\en_windows_server_2012_r2_with_update_x64_dvd_4065220\sources\sxs"
         WebPiCmdPath         = "$env:ProgramFiles\Microsoft\Web Platform Installer\WebPiCmd.exe"
         Source               = $Destination
         Secure               = $false
   }#NonNodeData 
}
#endregion
break
WebServerComposite -ConfigurationData $ConfigData


$Config = 'WebServerComposite'
Start-DeployDSCLCMConfigPullSMB -ComputerName $COMPUTERNAME
Start-DeployDSCConfig -Verbose -ComputerName $ComputerName -ConfigurationName $Config -ConfigurationData $ConfigData -Force

start http://ms1/
