break
cls

# All loaded DSC classes
Get-CimClass -Namespace 'root\Microsoft\Windows\DesiredStateConfiguration' | Sort CimClassName

# The xDSCWebService loaded to maintain the pull server configuration
Get-CimClass -Namespace 'root\Microsoft\Windows\DesiredStateConfiguration' -ClassName MSFT_xDSCWebService | fl *

# Properties of that class
(Get-CimClass -Namespace 'root\Microsoft\Windows\DesiredStateConfiguration' -ClassName MSFT_xDSCWebService).CimClassProperties | Sort Qualifiers, Name | ft -AutoSize

# Compare this with the resource MOF
ise 'C:\Program Files\WindowsPowerShell\Modules\xPSDesiredStateConfiguration\DSCResources\MSFT_xDSCWebService\MSFT_xDSCWebService.Schema.mof'
