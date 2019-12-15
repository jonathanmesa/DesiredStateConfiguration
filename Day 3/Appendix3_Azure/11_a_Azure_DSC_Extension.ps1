#region 1
Get-Module -Name Azure -ListAvailable | ft -AutoSize

Get-Command -Module azure -noun AzureSubscription,AzurePublishSettingsFile | ft -AutoSize

# download the certificate from the Azure Portal
Get-AzurePublishSettingsFile
#endregion

#region 2
#Import-AzurePublishSettingsFile -PublishSettingsFile $home\desktop\azure_contoso.publishsettings

Get-AzureSubscription | ft -AutoSize

Get-AzureVM

Get-AzureVMAvailableExtension | Out-GridView
Get-AzureVMAvailableExtension -ExtensionName DSC | select Publisher, Label, Version, PublishedDate

Get-Command *dsc* -Module Azure | ft -AutoSize

#endregion


#region 3
Get-AzureVMDscExtension

Get-Command Publish-AzureVMDscConfiguration -Syntax

@'
configuration AdminDesktop {
param (
    [String]$ComputerName
)

# Do not upload the default module PSDesiredStateConfiguration 
#Import-DSCResource -ModuleName PSDesiredStateConfiguration
Import-DSCResource -ModuleName xDisk

Node $ComputerName
{
    WindowsFeature RSAT
    {
       Name   = 'RSAT'
       Ensure = 'Present'
       IncludeAllSubFeature = $true 
    }

    xDisk FDrive
    {
        DiskNumber  = 2
        DriveLetter = 'F'
    }

}#Node
}#AdminDesktop
'@ | set-content -Path F:\azure\AdminDesktop.ps1

psedit F:\azure\AdminDesktop.ps1


$Params = @{
    ConfigurationPath        = 'F:\azure\AdminDesktop.ps1'
    ConfigurationArchivePath = 'F:\azure\AdminDesktop.ps1.zip'
    Force                    = $true
    Verbose                  = $true
    }

Publish-AzureVMDscConfiguration @Params

Invoke-Item 'F:\azure\AdminDesktop.ps1.zip'


$StorageContext = @{
    StorageAccountName = (Get-AzureSubscription).CurrentStorageAccountName 
    StorageAccountKey  = Get-Content -Path F:\Azure\storagekey.txt
    }

$AzureStorageContext = New-AzureStorageContext @StorageContext

$DSCConfiguration = @{
    ConfigurationPath = 'F:\azure\AdminDesktop.ps1.zip' 
    StorageContext    = $AzureStorageContext 
    Force             = $true
    Verbose           = $true
    }

Publish-AzureVMDscConfiguration @DSCConfiguration

#endregion


#region 4
$VM = 'web05'
Get-WindowsFeature -ComputerName $VM -Name *RSAT*
Get-Disk -CimSession $VM 
Get-AzureVM -Name $VM -ServiceName $MyService -OutVariable MyVM  
               
$DSCExtension = @{
    # ConfigurationArgument: supported types for values include: 
    #            primitive types, string, array and PSCredential
    ConfigurationArgument = @{ComputerName = 'localhost'}
    ConfigurationName     = 'AdminDesktop'
    ConfigurationArchive  = 'AdminDesktop.ps1.zip'
    Force                 = $True
    Verbose               = $True
    }


$MyVM | Set-AzureVMDSCExtension @DSCExtension | Update-AzureVM

$MyVM | Get-AzureVMDscExtension

Get-AzureVM -Name $VM -ServiceName $MyService -OutVariable MyVM

# DSC Configuration Status
$MyVM.ResourceExtensionStatusList
$MyVM.ResourceExtensionStatusList[1].ExtensionSettingStatus
$MyVM.ResourceExtensionStatusList[1].ExtensionSettingStatus.FormattedMessage

Get-WindowsFeature -ComputerName $VM -Name *RSAT*
Get-Disk -CimSession $VM 


# Now view the status, Logs and settings
Get-DscConfiguration -CimSession $VM
Get-DscLocalConfigurationManager -CimSession $VM
Test-DscConfiguration -CimSession $VM -Detailed

Update-xDscEventLogStatus -ComputerName $VM -Channel Analytic -Status Enabled
Update-xDscEventLogStatus -ComputerName $VM -Channel Debug -Status Enabled

# External function to view eventlogs
Get-LCMEventHistory -ComputerName $VM



# Removing the DSCExtension

Remove-AzureVMDscExtension -VM $MyVM -Verbose

$MyVM | Get-AzureVMDscExtension

#endregion
