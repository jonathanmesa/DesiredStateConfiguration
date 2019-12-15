break
cls

Set-Location C:\PShell\Demos\


# Unit testing
# View and run the test cases in the comments at the bottom
ise .\06d-CONTOSO_contosoTextFile.psm1



# LCM debug mode in WMF 5.0 and WMF 4.0 KB3000850
# Requires resources from previous examples
Configuration LCMv4
{
    Node localhost
    {
        LocalConfigurationManager
        {
            RefreshMode = 'Disabled'
        }
    }
}
LCMv4
Set-DscLocalConfigurationManager -Path .\LCMv4
Get-DscLocalConfigurationManager | ft DebugMode, RefreshMode -AutoSize


# Class-based resources will error at this time
Invoke-DscResource -Module contosoClassResources -Name FileTextResource -Method Test -Property @{Ensure='Present';Path='C:\DropZone\test.txt';Value='Hello, world.'}

# Traditional line
Invoke-DscResource -Module contosoResources -Name contosoTextFile -Method Test -Property @{Ensure='Present';Path='C:\DropZone\test.txt';Value='Hello, world.'}

# Splatting is easier to read
# Note use of Verbose and Debug
$Splat = @{
    Verbose  = $true
    Debug    = $true
    Module   = 'contosoResources'
    Name     = 'contosoTextFile'
    Method   = 'Test'
    Property = @{
        Ensure='Present'
        Path='C:\DropZone\test.txt'
        Value='Hello, world.'
    }
}
Invoke-DscResource @Splat

# Set Present
$Splat = @{
    Verbose  = $true
    Module   = 'contosoResources'
    Name     = 'contosoTextFile'
    Method   = 'Set'
    Property = @{
        Ensure='Present'
        Path='C:\DropZone\test.txt'
        Value='Hello, world.'
    }
}
Invoke-DscResource @Splat

# Test
$Splat = @{
    Verbose  = $true
    Module   = 'contosoResources'
    Name     = 'contosoTextFile'
    Method   = 'Test'
    Property = @{
        Ensure='Present'
        Path='C:\DropZone\test.txt'
        Value='Hello, world.'
    }
}
Invoke-DscResource @Splat

# Set Absent
$Splat = @{
    Verbose  = $true
    Module   = 'contosoResources'
    Name     = 'contosoTextFile'
    Method   = 'Set'
    Property = @{
        Ensure='Absent'
        Path='C:\DropZone\test.txt'
        Value='Hello, world.'
    }
}
Invoke-DscResource @Splat




# Test file resource
$Splat = @{
    Verbose  = $true
    Module   = 'PSDesiredStateConfiguration'
    Name     = 'File'
    Method   = 'Test'
    Property = @{
        Ensure='Absent'
        DestinationPath='C:\DropZone\test.txt'
        Type='File'
        Contents='Hello, world.'
    }
}
Invoke-DscResource @Splat



# Reset LCM
[DscLocalConfigurationManager()]
Configuration LCMv5
{
    Node localhost
    {
        Settings
        {
            DebugMode   = 'None'
            RefreshMode = 'Push'
        }
    }
}
LCMv5
Set-DscLocalConfigurationManager -Path .\LCMv5
Get-DscLocalConfigurationManager | ft DebugMode, RefreshMode -AutoSize
