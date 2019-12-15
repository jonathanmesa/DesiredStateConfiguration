break
cls

# Get-DscResource

Get-DscResource

Get-DscResource Group -Syntax


# Get the built-in resources
$r = Get-DscResource -Module PSDesiredStateConfiguration
$r

# List all built-in resources with properties
$r | % {$_.Name; $_ | select -ExpandProperty Properties | ft -AutoSize}

