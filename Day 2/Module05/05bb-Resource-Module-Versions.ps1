break

<#
This demo illustrates:
-Side-by-side module installs
-Importing specific module versions in DSC
-Various errors possible with these scenarios

We begin with an error when multiple modules are installed.
Then we see properties from a former version that are incompatible with the latest version.
Then we install and import an older module version that uses the properties specified.
Finally we update the properties and module version to the latest release (2.5 as of this writing).
#>

# Note the syntax in this blog post was incorrect as of 12/3/15, using ModuleVersion instead of RequiredVersion.
Start-Process http://blogs.msdn.com/b/powershell/archive/2014/04/25/understanding-import-dscresource-keyword-in-desired-state-configuration.aspx

md C:\PShell\Demos
cd C:\PShell\Demos

Install-Module xNetworking -Force 
Install-Module xNetworking -Force -MaximumVersion '2.4' 
Get-Module xNetworking -ListAvailable | ft ModuleType, Version, Name, ModuleBase -AutoSize

Configuration ResourceVersioning
{
    Import-DscResource -Module xNetworking

    Node localhost
    {
        xFirewall AllowRDP
        {
            Name = 'DSC - Remote Desktop Admin Connections'
            DisplayGroup = "Remote Desktop"
            Ensure = 'Present'
            State = 'Enabled'
            Access = 'Allow'
            Profile = 'Domain'
        }
    }
}
 
ResourceVersioning

<#
Error Message

Multiple versions of the module 'xNetworking' were found. You can run 
'Get-DscResource -Module xNetworking' to see available versions on the system, 
and then use the fully qualified name in the following command to specify the 
desired version: 
Import-DscResource –ModuleName @{ModuleName="xNetworking";RequiredVersion="Version"}
#>


# Observe the version of xFirewall resource and property mismatch with below configuration
Get-DscResource -Module xNetworking


Configuration ResourceVersioning
{
    Import-DscResource –ModuleName @{ModuleName="xNetworking";RequiredVersion="2.4.0.0"}

    Node localhost
    {
        xFirewall AllowRDP
        {
            Name = 'DSC - Remote Desktop Admin Connections'
            DisplayGroup = "Remote Desktop"
            Ensure = 'Present'
            State = 'Enabled'
            Access = 'Allow'
            Profile = 'Domain'
        }
    }
}
 
ResourceVersioning

# Notice that our property names are not valid.
# Install and use a previous module version with these property names.

Find-Module xNetworking -AllVersions
Install-Module xNetworking -RequiredVersion '2.3.0.0' -Force
Get-Module xNetworking -ListAvailable

# Notice the different properties on the xFirewall resource...
Get-DscResource xFirewall
Get-DscResource xFirewall -Syntax

Configuration ResourceVersioning
{
    Import-DscResource –ModuleName @{ModuleName="xNetworking";RequiredVersion="2.3.0.0"}

    Node localhost
    {
        xFirewall AllowRDP
        {
            Name = 'DSC - Remote Desktop Admin Connections'
            DisplayGroup = "Remote Desktop"
            Ensure = 'Present'
            State = 'Enabled'
            Access = 'Allow'
            Profile = 'Domain'
        }
    }
}

ResourceVersioning

# View the module version inside the MOF
Get-Content .\ResourceVersioning\localhost.mof

# Update property names and module to newer version.

Configuration ResourceVersioning
{
    # This works.
    Import-DscResource -ModuleName @{ModuleName="xNetworking";RequiredVersion="2.4.0.0"}
    # This is valid syntax, but does not work.
    #Import-DscResource -ModuleName xNetworking -ModuleVersion "2.4.0.0"

    Node localhost
    {
        xFirewall AllowRDP
        {
            Name = 'DSC - Remote Desktop Admin Connections'
            DisplayGroup = "Remote Desktop"
            Ensure = 'Present'
            Enabled = $true
            Action = 'Allow'
            Profile = 'Domain'
        }
    }
}

ResourceVersioning

# View the module version inside the MOF
Get-Content .\ResourceVersioning\localhost.mof

# Clean up
Remove-Item "C:\Program Files\WindowsPowerShell\Modules\xNetworking\*" -Recurse -Force
