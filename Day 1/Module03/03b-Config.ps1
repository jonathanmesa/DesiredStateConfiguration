#Requires -RunAsAdministrator 
break
cls

# Verify that Windows Server Backup is not installed
Get-WindowsFeature -Name Windows-Server-Backup -ComputerName ms1


# Sample configuration
Configuration WindowsBackup {
param ([string[]]$ComputerName = 'localhost')
    Import-DscResource –ModuleName PSDesiredStateConfiguration
	Node $ComputerName {
		WindowsFeature Backup {
			Ensure = 'Present'
			Name   = 'Windows-Server-Backup'
		}
	}
}
WindowsBackup -ComputerName ms1.contoso.com



# Rename the file with a GUID and create the checksum
$guid = [guid]::NewGuid().Guid
$guid = (New-Guid).Guid

$source = ".\WindowsBackup\ms1.contoso.com.mof"
$dest = "C:\Program Files\WindowsPowerShell\DSCService\Configuration\$guid.mof"
Copy-Item -Path $source -Destination $dest
New-DSCChecksum $dest

Get-ChildItem "C:\Program Files\WindowsPowerShell\DSCService\Configuration\"





# Reset
Uninstall-WindowsFeature -Name Windows-Server-Backup -ComputerName ms1
