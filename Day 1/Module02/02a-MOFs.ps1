break
cls

Set-Location C:\PShell\Demos

# MOFs
dir C:\Windows\System32\Configuration

# Run the configuration again
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
MyFirstConfig

# Apply a new configuration
Start-DscConfiguration -Wait -Verbose -Path .\MyFirstConfig

# MOFs
dir C:\Windows\System32\Configuration

# Compare current.mof to what is on the box
Get-DscConfiguration

# Re-apply current configuration
Start-DscConfiguration -Wait -Verbose -UseExisting

# Publish a new configuration without applying it
# Waits for the next LCM interval
# Read the message text
New-Item -Path .\bogus\localhost.mof -ItemType File -Value "bogus" -Force
Publish-DscConfiguration -Path .\bogus

dir C:\Windows\System32\Configuration

# Pending warning
Restore-DscConfiguration -Verbose

# Remove pending
Remove-DscConfigurationDocument -Stage Pending

# Promote previous.mof to pending.mof and apply
Restore-DscConfiguration -Verbose

dir C:\Windows\System32\Configuration





# Reset
del C:\windows\System32\Configuration\*.mof
Remove-Item HKLM:\Software\Contoso\ -Recurse -Force
Stop-Service BITS
Remove-Item .\MyFirstConfig -Recurse -Force -Confirm:$false
Remove-Item .\Bogus -Recurse -Force -Confirm:$false
