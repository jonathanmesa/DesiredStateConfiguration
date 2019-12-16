break
cls

Set-Location C:\PShell\Demos


#region  Publish module v1
Function Publish-DscResourcePull {
Param (
    [string[]]
    $Module
)
    ForEach ($ModuleName in $Module) {

        $ModuleVersion = (Get-Module $ModuleName -ListAvailable).Version

        # New cmdlet in WMF 5.0
        Compress-Archive -Update `
         -Path "$Env:PROGRAMFILES\WindowsPowerShell\Modules\$ModuleName" `
         -DestinationPath "$Env:PROGRAMFILES\WindowsPowerShell\DscService\Modules\$($ModuleName)_$($ModuleVersion).zip"

        New-DSCCheckSum "$Env:PROGRAMFILES\WindowsPowerShell\DscService\Modules\$($ModuleName)_$($ModuleVersion).zip"
    }
}

# Our earlier script-based resource module
Get-Module contosoResources -ListAvailable
dir "$Env:PROGRAMFILES\WindowsPowerShell\Modules\contosoResources"

# Not yet published for pull
dir "$Env:PROGRAMFILES\WindowsPowerShell\DscService\Modules\cont*"

# Publish it
Publish-DscResourcePull -Module contosoResources
dir "$Env:PROGRAMFILES\WindowsPowerShell\DscService\Modules\cont*"

#endregion



#region  Publish configuration

configuration ContosoResourceTest
{
Param ($ComputerName)

    Import-DscResource -ModuleName contosoResources

    Node $ComputerName
    {
        contosoTextFile TestTextFile
        {
           Ensure = 'Present'
           Path = 'C:\DropZone\Sample.txt'
           Value = @'
Simple text test.
Multiple line text.
'@
        }
    }
}

ContosoResourceTest -ComputerName ms1.contoso.com

$GUID = [guid]::NewGuid().Guid

$source = ".\ContosoResourceTest\ms1.contoso.com.mof"
$dest = "C:\Program Files\WindowsPowerShell\DSCService\Configuration\$guid.mof"
Copy-Item -Path $source -Destination $dest
New-DSCChecksum $dest

Get-ChildItem "C:\Program Files\WindowsPowerShell\DSCService\Configuration\"

# View MOF with module version
notepad $dest

#endregion



#region  Configure LCM on pull node

###
### LCM AllowModuleOverWrite must be set to true to pull new module version
###
[DscLocalConfigurationManager()]
Configuration LCMPullv5
{
Param (
    $ComputerName,
    $GUID
)
    Node $ComputerName
    {
        Settings
        {
            ActionAfterReboot              = 'ContinueConfiguration'
            AllowModuleOverWrite           = $True
            ConfigurationID                = $GUID
            ConfigurationMode              = 'ApplyAndMonitor'
            RebootNodeIfNeeded             = $True
            RefreshMode                    = 'Pull'
        }
        ConfigurationRepositoryWeb PullServer
        {
            ServerURL                = "https://pull.contoso.com:8080/PSDSCPullServer.svc"
            AllowUnsecureConnection  = $false
        }
    }
}

LCMPullv5 -ComputerName ms1.contoso.com -GUID $GUID

# Note that the module is not present on the node
Invoke-Command -ComputerName ms1.contoso.com -ScriptBlock {Get-Module contosoResources -ListAvailable}

# Connect to node
$cim = New-CimSession -ComputerName ms1.contoso.com

# Configure LCM
Set-DSCLocalConfigurationManager -Path .\LCMPullv5 -CimSession $cim

# Confirm LCM
Get-DSCLocalConfigurationManager -CimSession $cim
(Get-DSCLocalConfigurationManager -CimSession $cim).ConfigurationDownloadManagers

# Trigger pull of configuration
Update-DscConfiguration -CimSession $cim -Wait -Verbose

# This forced the node to pull our new module
# Check the module version on the node
Invoke-Command -ComputerName ms1.contoso.com -ScriptBlock {Get-Module contosoResources -ListAvailable}

#endregion





#region  Edit the module and increment version

ise 'C:\Program Files\WindowsPowerShell\Modules\contosoResources\DSCResources\CONTOSO_contosoTextFile\CONTOSO_contosoTextFile.psm1'

#Add line to Test-TargetResource
#    Write-Verbose " *** THIS IS MODULE VERSION NEXT *** "

ise 'C:\Program Files\WindowsPowerShell\Modules\contosoResources\contosoResources.psd1'

#endregion



#region  Publish module v2

Get-Module contosoResources -ListAvailable

dir "$Env:PROGRAMFILES\WindowsPowerShell\DscService\Modules\cont*"

Publish-DscResourcePull -Module contosoResources

dir "$Env:PROGRAMFILES\WindowsPowerShell\DscService\Modules\cont*"

#endregion



#region  Must version configuration to trigger checksum change
# The module version in the build should be enough to trigger
# a new checksum.

configuration ContosoResourceTest
{
Param ($ComputerName)

    Import-DscResource -ModuleName contosoResources

    Node $ComputerName
    {
        contosoTextFile TestTextFile
        {
           Ensure = 'Present'
           Path = 'C:\DropZone\Sample.txt'
           Value = @'
Simple text test.Multiple line text.
'@
        }
    }
}

ContosoResourceTest -ComputerName ms1.contoso.com

$source = ".\ContosoResourceTest\ms1.contoso.com.mof"
$dest = "C:\Program Files\WindowsPowerShell\DSCService\Configuration\$guid.mof"
Copy-Item -Path $source -Destination $dest

# FORCE new checksum to overwrite previous
New-DSCChecksum $dest -Force

# See new version in the MOF
notepad $dest

Get-ChildItem "C:\Program Files\WindowsPowerShell\DSCService\Configuration\"

# Trigger pull
# Notice the different checksum
Update-DscConfiguration -CimSession $cim -Wait -Verbose

# Check the module version on the node
Invoke-Command -ComputerName ms1.contoso.com -ScriptBlock {Get-Module contosoResources -ListAvailable}

#endregion



#region  Roll back the module

# Delete the current module version
Get-ChildItem "C:\Program Files\WindowsPowerShell\DSCService\Modules\contosoResources_1.1.zip*"
Remove-Item "C:\Program Files\WindowsPowerShell\DSCService\Modules\contosoResources_1.1.zip*"

# Must uninstall v1.1 module from target node
Invoke-Command -ComputerName ms1.contoso.com -ScriptBlock {Get-Module -Name contosoResources -ListAvailable | %{Remove-Item -Path $_.ModuleBase -Force -Recurse}}
Invoke-Command -ComputerName ms1.contoso.com -ScriptBlock {Get-Module contosoResources -ListAvailable}

# Notice that local module version is in the MOF
notepad $dest

# Must roll back local copy of module used to compile the MOF
ise 'C:\Program Files\WindowsPowerShell\Modules\contosoResources\DSCResources\CONTOSO_contosoTextFile\CONTOSO_contosoTextFile.psm1'
#Remove line from Test-TargetResource
#    Write-Verbose " *** THIS IS MODULE VERSION NEXT *** "
ise 'C:\Program Files\WindowsPowerShell\Modules\contosoResources\contosoResources.psd1'


# Update the configuration
configuration ContosoResourceTest
{
Param ($ComputerName)

    Import-DscResource -ModuleName contosoResources

    Node $ComputerName
    {
        contosoTextFile TestTextFile
        {
           Ensure = 'Present'
           Path = 'C:\DropZone\Sample.txt'
           Value = @'
Simple text test.
Multiple line text.
'@
        }
    }
}

ContosoResourceTest -ComputerName ms1.contoso.com

$source = ".\ContosoResourceTest\ms1.contoso.com.mof"
$dest = "C:\Program Files\WindowsPowerShell\DSCService\Configuration\$guid.mof"
Copy-Item -Path $source -Destination $dest

# FORCE new checksum to overwrite previous
New-DSCChecksum $dest -Force

Get-ChildItem "C:\Program Files\WindowsPowerShell\DSCService\Configuration\"

# Trigger pull
Update-DscConfiguration -CimSession $cim -Wait -Verbose

# Check the module version on the node
Invoke-Command -ComputerName ms1.contoso.com -ScriptBlock {Get-Module contosoResources -ListAvailable}


#endregion


Remove-CimSession $cim
