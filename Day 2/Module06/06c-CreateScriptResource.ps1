break
cls

Set-Location C:\PShell\Demos

# Update the version of the designer module
Get-Module xDSCResourceDesigner -ListAvailable | Select-Object -ExpandProperty Version

Remove-Item 'C:\Program Files\WindowsPowerShell\Modules\xDSCResourceDesigner' -Recurse -Force
Install-Module xDSCResourceDesigner -Force

Get-Module xDSCResourceDesigner -ListAvailable | Select-Object -ExpandProperty Version

Get-Command -Module xDSCResourceDesigner
ise 'C:\Program Files\WindowsPowerShell\Modules\xDSCResourceDesigner\xDSCResourceDesigner.psm1'

Set-Location C:\PShell\Demos


#region Create resource


# New resource with properties
New-xDscResource -Name CONTOSO_contosoTextFile -FriendlyName contosoTextFile -ModuleName contosoResources `
 -Path . -Force -Property @(
    New-xDscResourceProperty -Name Path -Type String -Attribute Key
    New-xDscResourceProperty -Name Value -Type String -Attribute Write
    New-xDscResourceProperty -Name Ensure -Type String -Attribute Required -ValidateSet 'Present','Absent'
)

tree .\contosoResources /f /a

# Note the DscResourcesToExport key
ise .\contosoResources\contosoResources.psd1

ise .\contosoResources\DSCResources\CONTOSO_contosoTextFile\CONTOSO_contosoTextFile.schema.mof
ise .\contosoResources\DSCResources\CONTOSO_contosoTextFile\CONTOSO_contosoTextFile.psm1

#endregion


# Review and edit the .psm1 file
# .....

#region Move the module into the PSModulePath for discovery

Copy-Item C:\PShell\Demos\contosoResources $Env:ProgramFiles\WindowsPowerShell\Modules -Recurse -Force
tree $Env:ProgramFiles\WindowsPowerShell\Modules\contosoResources /f /a

#endregion

Get-DscResource contosoTextFile -Syntax


#region Test the resource

configuration ContosoResourceTest
{
    Import-DscResource -ModuleName contosoResources

    node localhost
    {
        contosoTextFile TestTextFile
        {
           Ensure = 'Present'
           Path   = 'C:\DropZone\Sample.txt'
           Value  = "Simple text test."
        }
    }
}

ContosoResourceTest
Start-DscConfiguration -Path .\ContosoResourceTest -Wait -Verbose -Force

# View and change the file
notepad C:\DropZone\Sample.txt
Start-DscConfiguration -Path .\ContosoResourceTest -Wait -Verbose


cls
Get-DscConfiguration


# Now set to Absent
configuration ContosoResourceTest
{
    Import-DscResource -ModuleName contosoResources

    node localhost
    {
        contosoTextFile TestTextFile
        {
           Ensure = 'Absent'
           Path = 'C:\DropZone\Sample.txt'
        }
    }
}

ContosoResourceTest
Start-DscConfiguration -Path .\ContosoResourceTest -Wait -Verbose

#endregion




#region Reset  DO NOT RUN

Remove-Item $Env:ProgramFiles\WindowsPowerShell\Modules\contosoResources -Recurse -Force
Remove-Item $Home\Documents\WorkshopDemos\contosoRes* -Recurse -Force

#endregion
