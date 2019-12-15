break
cls

Set-Location C:\PShell\Demos

# REBOOT REQUIRED BY THIS INSTALL

# Note the DependsOn properties
Configuration DependsOnExample {

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node localhost {

        File DSCTempFolder {
            DestinationPath = 'C:\DSCTemp\'
            Ensure          = 'Present' 
            Type            = 'Directory'
        }

        Archive ExtractZIP {
            Ensure          = 'Present'
            Path            = 'C:\PShell\Demos\LogParser.zip'
            Destination     = 'C:\DSCTemp\logparser\'
            Force           = $true
            DependsOn       = '[File]DSCTempFolder'
        }

        Package InstallLogParser {
            Ensure          = 'Present'
            Name            = 'Log Parser 2.2'
            Path            = 'C:\DSCTemp\logparser\logparser.msi'
            ProductId       = '4AC23178-EEBC-4BAF-8CC0-AB15C8897AC9'
            DependsOn       = '[Archive]ExtractZIP'
        }

    }
}

DependsOnExample
Start-DscConfiguration .\DependsOnExample -Wait -Verbose

# Show app installed
dir C:\DSCTemp
Get-CimInstance Win32_Product
# Show Start menu



# Uninstall
Configuration DependsOnExample {

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node localhost {

        Package InstallLogParser {
            Ensure          = 'Absent'
            Name            = 'Log Parser 2.2'
            Path            = 'C:\DSCTemp\logparser\logparser.msi'
            ProductId       = '4AC23178-EEBC-4BAF-8CC0-AB15C8897AC9'
        }
    }
}
DependsOnExample
Start-DscConfiguration .\DependsOnExample -Wait -Verbose
