break

## Reset LCM to push on all nodes
Invoke-Command -ComputerName ms1,ms2,pull -ScriptBlock {
    del C:\windows\system32\Configuration\MetaConfig.mof
}

## Looking at the LCM and Configurations

$CN = 'ms1'
Test-Wsman -ComputerName $CN

$CS = New-CimSession -ComputerName $CN
$CS

# LCM
Get-DscLocalConfigurationManager -CimSession $CS

Get-ChildItem -Path "\\$CN\c$\windows\System32\Configuration"
Invoke-Command -ComputerName $CN -ScriptBlock {dir c:\windows\System32\Configuration}
Invoke-Command -ComputerName $CN -ScriptBlock {dir C:\windows\System32\Configuration\ConfigurationStatus}

# WMIexplorer V4 vs V5
\\PSOBJECT.COM\shares\Tools\WMIExplorer2.exe

# CIM

$CIM = @{ 
    Namespace   = 'root/Microsoft/Windows/DesiredStateConfiguration' 
    ClassName   = 'MSFT_DSCLocalConfigurationManager' 
    MethodName  = 'PerformRequiredConfigurationChecks' 
    Arguments   = @{Flags= [uint32]1}
    ErrorAction = 'Stop'
    Verbose     = $true
    ComputerName= 'ms1'
    } 

 Invoke-CimMethod @CIM

