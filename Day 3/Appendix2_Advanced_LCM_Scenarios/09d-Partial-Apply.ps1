break
cls

Set-Location C:\PShell\Demos

$Node = 'ms1.contoso.com'
$cim = New-CimSession -ComputerName $Node


#region ##### Set LCM #####

Set-DscLocalConfigurationManager -Path .\LCMPartial -CimSession $cim -Verbose

# Explore partials
Get-DscLocalConfigurationManager -CimSession $cim
(Get-DscLocalConfigurationManager -CimSession $cim).ConfigurationDownloadManagers
(Get-DscLocalConfigurationManager -CimSession $cim).PartialConfigurations

#endregion



#region ##### Web PULL SMB #####

$source = ".\Web\$Node.mof"
$dest = "\\ms2\SMBPullShare\Web.$GUID.mof"

Copy-Item -Path $source -Destination $dest
New-DSCChecksum $dest -Force

Get-ChildItem "\\ms2\SMBPullShare\"

#endregion



#region ##### InfoSec PULL HTTPS #####


$source = ".\InfoSec\$Node.mof"
$dest = "C:\Program Files\WindowsPowerShell\DSCService\Configuration\InfoSec.$guid.mof"

Copy-Item -Path $source -Destination $dest
New-DSCChecksum $dest -Force

Get-ChildItem "C:\Program Files\WindowsPowerShell\DSCService\Configuration\"

#endregion



#region ##### MAKE IT SO #####

# This will error due to BaseOS PUSH dependency not present
Update-DscConfiguration -CimSession $cim -Wait -Verbose

#endregion



#region ##### BaseOS PUSH #####

Publish-DscConfiguration -CimSession $cim -Path .\BaseOS -Verbose
#Copy-Item -Path .\BaseOS\ms1.contoso.com.mof -Destination \\ms1\c$\Windows\System32\Configuration\pending.mof

# View the BaseOS push partial configuration
Invoke-Command -ComputerName $Node -ScriptBlock {dir C:\Windows\System32\Configuration}
Invoke-Command -ComputerName $Node -ScriptBlock {Get-Content C:\Windows\System32\Configuration\pending.mof}
Invoke-Command -ComputerName $Node -ScriptBlock {dir C:\Windows\System32\Configuration\PartialConfigurations}

#endregion



#region ##### MAKE IT SO #####

#Update-DscConfiguration -CimSession $cim -Wait -Verbose
Start-DscConfiguration -CimSession $cim -Wait -Verbose -UseExisting

# Explore the configuration folder
Invoke-Command -ComputerName $Node -ScriptBlock {dir C:\Windows\System32\Configuration}
Invoke-Command -ComputerName $Node -ScriptBlock {dir C:\Windows\System32\Configuration\PartialConfigurations}

Get-DscConfiguration -CimSession $cim
Get-DscConfigurationStatus -CimSession $cim

#endregion

# View the consolidated configuration document
psedit '\\ms1\c$\Windows\System32\Configuration\current.mof'


Remove-CimSession $cim





# RESET

$sb = {
    Remove-Item C:\Windows\System32\Configuration\Partial* -Force -Confirm:$false
    Remove-Item C:\Windows\System32\Configuration\PartialConfigurations\* -Force -Confirm:$false
    Uninstall-WindowsFeature -Name Web-Server,Windows-Server-Backup
    net localgroup 'InfoSecBackDoor' /delete
    Restart-Computer -Force
}
Invoke-Command -ComputerName $Node -ScriptBlock $sb

