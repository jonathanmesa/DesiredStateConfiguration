Configuration AppConfigAll {

Import-DscResource -ModuleName PSDesiredStateConfiguration

   #-----------------------------------------------
   Node $AllNodes.Where{$_.Role -eq 'Dev'}.NodeName 
   {
        foreach ($Feature in $Node.Features)
        {...}
        
        foreach ($File in $Node.Files)
        {...}
   }#Dev

   Node $AllNodes.Where{$_.Role -eq 'QA'}.NodeName 
   {...}#QA

   Node $AllNodes.Where{$_.Role -eq 'Prod'}.NodeName 
   {...}#Prod

}#AppConfigAll

AppConfigAll -ConfigurationData $ConfigData
