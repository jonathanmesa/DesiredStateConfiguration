#Requires -RunAsAdministrator 
Break

Set-Location C:\PShell\Demos\

Get-Command -Module PSDesiredStateConfiguration

# Engine status
Get-DscLocalConfigurationManager

# No configuration applied
Get-DscConfiguration


Configuration MyFirstConfig
{
    Import-DscResource –ModuleName PSDesiredStateConfiguration

    Node localhost
    {
        Registry AssetTag {
            Key = 'HKLM:\Software\Contoso'
            ValueName = 'AssetTag'
            ValueData = '420042'
            ValueType = 'DWORD'
            Ensure = 'Present'
        }

        Registry DecomStatus {
            Key = 'HKLM:\Software\Contoso'
            ValueName = 'Decom'
            ValueType = 'String'
            Ensure = 'Absent'
        }

        Service Bits {
            Name = 'Bits'
            State = 'Running'
        }

    }
}

# Generate the MOF
MyFirstConfig

# View the MOF
notepad .\MyFirstConfig\localhost.mof

# Check state manually
Get-ItemProperty HKLM:\Software\Contoso\
Get-Service BITS

# Sets it the first time
Start-DscConfiguration -Wait -Verbose -Path .\MyFirstConfig

# Check state manually
Get-Item HKLM:\Software\Contoso\
Get-Service BITS

# View the config of the system
Get-DscConfiguration

# Check state with cmdlet
Test-DscConfiguration

# Change the state
Set-ItemProperty HKLM:\Software\Contoso\ -Name AssetTag -Value 12
New-ItemProperty HKLM:\Software\Contoso\ -Name Decom -Value True
Stop-Service Bits

# Check state manually
Get-Item HKLM:\Software\Contoso\
Get-Service BITS

# Do I have the registry key? Is the value correct?
Test-DscConfiguration -Verbose
Test-DscConfiguration -Detailed

# Reset the state
Start-DscConfiguration -Wait -Verbose -Path .\MyFirstConfig

# Check state with cmdlet
Test-DscConfiguration







# Reset demo
# Reset
del C:\windows\System32\Configuration\*.mof
Remove-Item HKLM:\Software\Contoso\ -Recurse -Force
Stop-Service BITS
Remove-Item .\MyFirstConfig -Recurse -Force -Confirm:$false
