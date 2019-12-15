configuration PullTestConfig
{
    node localhost
    {
        File TempDir
        {
            Ensure          = "Present"
            DestinationPath = 'C:\MyTemp'
            Type            = "Directory"
        }       
    }
}

PullTestConfig

$ConfigID = (New-Guid).Guid
Copy-Item .\PullTestConfig\localhost.mof "C:\Program Files\WindowsPowerShell\DscService\Configuration\$ConfigID.mof"
New-DscChecksum "C:\Program Files\WindowsPowerShell\DscService\Configuration\$ConfigID.mof"
dir "C:\Program Files\WindowsPowerShell\DscService\Configuration\"



<#
Copy-Item .\PullTestConfig\localhost.mof "C:\Program Files\WindowsPowerShell\DscService\Configuration\ClientConfig.mof"
New-DscChecksum "C:\Program Files\WindowsPowerShell\DscService\Configuration\ClientConfig.mof"
dir "C:\Program Files\WindowsPowerShell\DscService\Configuration\"

Install-Module xPSDesiredStateConfiguration
Publish-DSCModuleAndMof -ModuleNameList @('xNetworking','xPendingReboot','xWindowsUpdate') -Source .\ -Force -Verbose

#>
