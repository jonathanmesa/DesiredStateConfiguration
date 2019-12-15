break
cls

Set-Location C:\PShell\Demos


# Use CTRL+J to insert a configuration template


# Review the list of resources to find what you need
Get-DscResource | ogv

# Get resource syntax. Copy/paste into configuration. Edit.
Get-DscResource Registry -Syntax



# Completed example
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

