break
cls

# Notice similarities and differences of folder structure
cd 'C:\Program Files\WindowsPowerShell\Modules\'
tree /f /a

# A simple resource example
cd 'C:\Program Files\WindowsPowerShell\Modules\xDisk'
tree /f /a

# Collapse the function regions for an overview
# Walk through each function
ise .\1.0\DSCResources\MSFT_xDisk\MSFT_xDisk.psm1

# The resource MOF
ise .\DSCResources\MSFT_xDisk\MSFT_xDisk.schema.mof

