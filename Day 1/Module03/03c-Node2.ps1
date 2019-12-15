[DSCLocalConfigurationManager()]
configuration PullClientConfigID
{
    Node @('ms1','ms2')
    {
        Settings
        {
            RefreshMode = 'Pull'
            ConfigurationID = $ConfigID
            RefreshFrequencyMins = 30 
            RebootNodeIfNeeded = $true
        }
        ConfigurationRepositoryWeb PullServer
        {
            ServerURL = 'http://PULL.contoso.com:8080/PSDSCPullServer.svc'
        }      
    }
}
PullClientConfigID

Set-DscLocalConfigurationManager -Path .\PullClientConfigID -Verbose


Invoke-Command -ScriptBlock {del C:\Windows\System32\Configuration\*.mof} -ComputerName ms1,ms2








[DSCLocalConfigurationManager()]
configuration PullClientRegKey
{
    Node @('ms1','ms2')
    {
        Settings
        {
            RefreshMode = 'Pull'
            RefreshFrequencyMins = 30 
            RebootNodeIfNeeded = $true
        }
        ConfigurationRepositoryWeb PullServer
        {
            ServerURL = 'https://PULL.contoso.com:8080/PSDSCPullServer.svc'
            RegistrationKey = $RegKey
            ConfigurationNames = @('ClientConfig')
        }      
    }
}
PullClientRegKey



Get-DscLocalConfigurationManager -CimSession ms1,ms2
Set-DscLocalConfigurationManager -Path .\PullClientRegKey -Verbose
Get-DscLocalConfigurationManager -CimSession ms1,ms2
(Get-DscLocalConfigurationManager -CimSession ms1,ms2).ConfigurationDownloadManagers





Get-CimInstance -Namespace root/Microsoft/Windows/DesiredStateConfiguration -ClassName MSFT_DSCLocalConfigurationManager