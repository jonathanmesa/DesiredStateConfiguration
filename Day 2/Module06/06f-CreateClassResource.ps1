break
cls

Set-Location C:\PShell\Demos


#region Create resource module

md contosoClassResources
cd .\contosoClassResources

New-Item -ItemType File -Name contosoClassResources.psm1

New-ModuleManifest -PowerShellVersion '5.0' -DscResourcesToExport FileResource,FileTextResource `
    -RootModule contosoClassResources.psm1 -Path contosoClassResources.psd1 `
    -ModuleVersion '1.0' | Out-Null

# Notice no extra folders or schema.mof
dir

# Note the DscResourcesToExport key
ise contosoClassResources.psd1

#endregion


# Review and edit the .psm1 file
# A single file with two resources
ise contosoClassResources.psm1


#region Move the module into the PSModulePath for discovery

Copy-Item $Home\Documents\WorkshopDemos\contosoClassResources $Env:ProgramFiles\WindowsPowerShell\Modules -Recurse -Force
dir $Env:ProgramFiles\WindowsPowerShell\Modules\contosoClassResources

#endregion


#region Test the resource

configuration ContosoResourceTest
{
    Import-DscResource -ModuleName contosoClassResources

    node localhost
    {
        FileTextResource TestTextFile
        {
           Ensure = 'Present'
           Path   = 'C:\DropZone\Sample.txt'
           Value  = "This came from the class resource."
        }
    }
}

ContosoResourceTest
Start-DscConfiguration -Path .\ContosoResourceTest -Wait -Verbose

# View and change the file
notepad C:\DropZone\Sample.txt
Start-DscConfiguration -Path .\ContosoResourceTest -Wait -Verbose


# Set to absent
configuration ContosoResourceTest
{
    Import-DscResource -ModuleName contosoClassResources

    node localhost
    {
        FileTextResource TestTextFile
        {
           Ensure = 'Absent'
           Path   = 'C:\DropZone\Sample.txt'
           Value  = "This came from the class resource."
        }
    }
}

ContosoResourceTest
Start-DscConfiguration -Path .\ContosoResourceTest -Wait -Verbose

#endregion




#region Reset DO NOT RUN

cd ..
Remove-Item $Env:ProgramFiles\WindowsPowerShell\Modules\contosoClassResources -Recurse -Force
Remove-Item $Home\Documents\WorkshopDemos\contosoClassRes* -Recurse -Force

#endregion


<#
NOTE: This class resource example code has a logic error.
When set to Absent, it will only remove the file if its
content matches. Fix this later.
#>
