break
cls

# Find-DscResource from the online PowerShell Gallery or other repository
# First time you will get the NuGet.exe install prompt

Find-DscResource

Find-DscResource -Repository PSGallery

Find-DscResource -Name xDisk | fl *

Install-Module -Name xDisk

dir 'C:\Program Files\WindowsPowerShell\Modules\xDisk' -Recurse


# List all other DSC Resource Kit resources installed
Start-Process http://aka.ms/dscrk
#Unblock-File "$Home\Downloads\DSC Resource Kit Wave 10 04012015.zip"
#explorer "$Home\Downloads\DSC Resource Kit Wave 10 04012015.zip\All Resources"

dir 'C:\Program Files\WindowsPowerShell\Modules\'

Expand-Archive -Path 'C:\PShell\DSC Resource Kit Wave 10 04012015.zip' `
    -DestinationPath 'C:\Program Files\WindowsPowerShell\Modules\'

Move-Item -Path 'C:\Program Files\WindowsPowerShell\Modules\All Resources\*' `
    -Destination 'C:\Program Files\WindowsPowerShell\Modules\' -Force

Remove-Item -Path 'C:\Program Files\WindowsPowerShell\Modules\All Resources'

dir 'C:\Program Files\WindowsPowerShell\Modules\'
