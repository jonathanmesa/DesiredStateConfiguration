break
cls

Set-Location C:\PShell\Demos


# Push to localhost

configuration SimpleConfig
{
    Import-DscResource –ModuleName PSDesiredStateConfiguration

    node localhost
    {
        Registry RegAssetOwner
        {
            Key = 'HKLM:\Software\Contoso\'
            ValueName = 'AssetOwner'
            Ensure = 'Present'
            ValueData = 'ericlang'
            ValueType = 'String'
        }
    }
}

SimpleConfig
Start-DscConfiguration .\SimpleConfig -Wait -Verbose

Remove-Item .\SimpleConfig -Force -Recurse


# Push to remote node by name
configuration SimpleConfig
{
    Import-DscResource –ModuleName PSDesiredStateConfiguration

    node ms2.contoso.com
    {
        Registry RegAssetOwner
        {
            Key = 'HKLM:\Software\Contoso\'
            ValueName = 'AssetOwner'
            Ensure = 'Present'
            ValueData = 'ericlang'
            ValueType = 'String'
        }
    }
}

SimpleConfig

# Picks up computername from file and connects
Start-DscConfiguration .\SimpleConfig -Wait -Verbose

Remove-Item .\SimpleConfig -Force -Recurse


# Push to remote multiple nodes by name using a parameter
configuration SimpleConfig
{
param(
    [string[]]
    $ComputerName
)
    Import-DscResource –ModuleName PSDesiredStateConfiguration

    node $ComputerName
    {
        Registry RegAssetOwner
        {
            Key = 'HKLM:\Software\Contoso\'
            ValueName = 'AssetOwner'
            Ensure = 'Present'
            ValueData = 'ericlang'
            ValueType = 'String'
        }
    }
}

SimpleConfig -ComputerName 'ms1','ms2'

Start-DscConfiguration .\SimpleConfig -Wait -Verbose



# Can also target nodes by ComputerName or CimSession parameter on Start-DscConfiguration

dir .\SimpleConfig

# -ComputerName allows you to target specific MOFs in the config folder
Start-DscConfiguration .\SimpleConfig -Wait -Verbose -ComputerName 'ms2'

# CIM sessions can take a number of robust parameters for connectivity and authentication
$cim = New-CimSession -ComputerName 'ms1','ms2'
Start-DscConfiguration .\SimpleConfig -Wait -Verbose -CimSession $cim
Remove-CimSession $cim
