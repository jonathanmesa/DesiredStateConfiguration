$computers = 'ms1.contoso.com','ms2.contoso.com','ms2.contoso.com','pull.contoso.com'

$pss = New-PSSession -ComputerName $computers
$cim = New-CimSession -ComputerName $computers

'Current','Previous','Pending' | % {
    Remove-DscConfigurationDocument -CimSession $cim -Stage $_ -Confirm:$false -Verbose
}

$sb = {
    If (Test-Path c:\inetpub\) {
        Install-WindowsFeature Web-Scripting-Tools
        Get-WebSite -Name PSDSC* | Remove-Website
        Stop-Service w3svc -Verbose -Confirm:$false
        Uninstall-WindowsFeature Web-Server,DSC-Service  -Verbose -Confirm:$false
        Remove-Item -Path c:\inetpub\ -Recurse -Force -Verbose -Confirm:$false
        Remove-Item -Path 'C:\Program Files\WindowsPowerShell\DSCService\' -Recurse -Force -Verbose -Confirm:$false
    } Else {
        Remove-Item -Path 'C:\Program Files\WindowsPowerShell\Modules\[xc]*' -Recurse -Force -Verbose -Confirm:$false
    }
    msiexec /uninstall "4AC23178-EEBC-4BAF-8CC0-AB15C8897AC9" /quiet
    Get-NetFirewallRule -Name "*DSC" | Remove-NetFirewallRule -Verbose
    Uninstall-WindowsFeature Windows-Server-Backup -Verbose -Confirm:$false
    Stop-Service bits -Verbose -Confirm:$false
    Remove-Item -Path c:\PackageShare -Recurse -Force -Verbose -Confirm:$false
    Remove-SmbShare -Name PackageShare -Force -Confirm:$false -Verbose
    Remove-Item -Path c:\dsc* -Recurse -Force -Verbose -Confirm:$false
    Remove-Item -Path c:\drop* -Recurse -Force -Verbose -Confirm:$false
    Remove-Item -Path c:\publick* -Recurse -Force -Verbose -Confirm:$false
    Remove-Item -Path C:\Windows\System32\Configuration\MetaConfig.* -Force -Verbose -Confirm:$false
    Remove-Item -Path 'C:\Program Files\WindowsPowerShell\Modules\contoso*' -Recurse -Force -Verbose -Confirm:$false
    Remove-Item -Path 'C:\Program Files\WindowsPowerShell\Modules\MyDsc*' -Recurse -Force -Verbose -Confirm:$false
    Remove-Item -Path 'HKLM:\SOFTWARE\contoso*' -Recurse -Force -Verbose -Confirm:$false
    net localgroup "Remote Desktop Users" /delete contoso\ericlang
    net localgroup "WorldDomination" /delete
}

Invoke-Command -Session $pss -ScriptBlock $sb

Remove-PSSession $pss
Remove-CimSession $cim

Restart-Computer -ComputerName $computers -Force -AsJob
