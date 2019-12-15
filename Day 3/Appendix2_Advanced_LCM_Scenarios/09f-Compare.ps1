break
cls

Set-Location C:\PShell\Demos

#Reset LCM on target nodes
Invoke-Command -ComputerName ms1,ms2,pull -ScriptBlock {
    del C:\Windows\System32\Configuration\metaconfig.mof
}


# Start with a configuration
Configuration CompareConfig
{
    Import-DscResource –ModuleName PSDesiredStateConfiguration

    Node localhost
    {
        Registry RegAssetOwner
        {
            Key = 'HKLM:\Software\Contoso\'
            ValueName = 'AssetOwner'
            Ensure = 'Present'
            ValueData = 'ericlang'
            ValueType = 'String'
        }
        Service Bits
        {
            Name = 'Bits'
            State = 'Running'
        }
    }
}
CompareConfig

# Open a CIM session to nodes for comparison
$computers = 'ms1.contoso.com','ms2.contoso.com','pull.contoso.com'
$cim = New-CimSession -ComputerName $computers

# Compare
Test-DscConfiguration -CimSession $cim -ReferenceConfiguration .\CompareConfig\localhost.mof | ft -AutoSize

# Configure one node
Start-DscConfiguration -Path .\CompareConfig -Wait -Verbose

# Compare
Test-DscConfiguration -CimSession $cim -ReferenceConfiguration .\CompareConfig\localhost.mof | ft -AutoSize

# Manually start the bits service status
Invoke-Command -Computername $computers -ScriptBlock {Start-Service bits}

# Compare
Test-DscConfiguration -CimSession $cim -ReferenceConfiguration .\CompareConfig\localhost.mof | ft -AutoSize

# Notice that not all target nodes have this reference configuration
Get-DscConfiguration -CimSession $cim
