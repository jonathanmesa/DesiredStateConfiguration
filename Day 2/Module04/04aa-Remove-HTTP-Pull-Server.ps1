#Requires -RunAsAdministrator
Break
cls

Set-Location C:\PShell\Demos

# Brute force remove the HTTP web site
Install-WindowsFeature Web-Scripting-Tools
Get-WebSite -Name PSDSC* | Remove-Website

