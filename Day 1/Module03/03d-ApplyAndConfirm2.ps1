
Update-DscConfiguration -Wait -Verbose -ComputerName ms1,ms2

Invoke-Command -ScriptBlock {dir c:\} -ComputerName ms1,ms2
Test-DscConfiguration -ComputerName ms1,ms2 -Detailed
Get-DscConfiguration -CimSession ms1,ms2
Get-DscConfigurationStatus -CimSession ms1,ms2

Invoke-Command -ComputerName ms1.contoso.com -ScriptBlock `
    {Get-WinEvent -LogName Microsoft-Windows-DSC/Operational -MaxEvents 30} | ogv 
