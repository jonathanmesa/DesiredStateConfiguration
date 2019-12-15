$VMName = 'N10'

# Choose the Instance Size of the Virtual Machine
[ValidateSet('ExtraSmall','Small','Medium','Large')]
[String]$InstanceSize = 'Small'

# Choose the Windows Image for the VirtualMachine
[ValidateSet('Windows Server 2008 R2 SP1','Windows Server 2012 Datacenter',
                'Windows Server 2012 R2 Datacenter','Windows Server Technical Preview')]
[String]$WindowsImage = 'Windows Server 2012 R2 Datacenter'
        
[String]$TimeZone = [System.TimeZoneInfo]::Local.Id
[String]$LocalAdminUser = 'danpark'
[pscredential]$cred = Get-Credential -Credential nouser
[Switch]$BootStrapDSC = $true

$MyImage = Get-AzureVMImage | Where-Object {$_.imagefamily -eq $WindowsImage} | 
    Sort-Object -Property PublishedDate | Select-Object -First 1

$MyImage | select ImageFamily,PublishedDate

$ProvisioningConfiguration = @{
    Windows         = $true
    AdminUsername   = $LocalAdminUser
    Password        = $Cred.GetNetworkCredential().Password
    TimeZone        = $TimeZone
    }

$MyVM = New-AzureVMConfig -Name $VMName -InstanceSize $InstanceSize -ImageName $myImage.ImageName | 
    Add-AzureProvisioningConfig @ProvisioningConfiguration | 
    Set-AzureSubnet -SubnetNames 'Internal' |
    Add-AzureDataDisk -CreateNew -DiskSizeInGB 100 -DiskLabel 'DataDisk100' -LUN 0

# ADD Admin Desktop DSC Extension to VM
if ($BootStrapDSC)
{         
    $DSCExtension = @{
        # ConfigurationArgument: supported types for values include: 
        #            primitive types, string, array and PSCredential
        ConfigurationArgument = @{ComputerName = 'localhost'}
        ConfigurationName     = 'AdminDesktop'
        ConfigurationArchive  = 'AdminDesktop.ps1.zip'
        Force                 = $True
        Verbose               = $True
        }

        $MyVM = $MyVM | Set-AzureVMDSCExtension @DSCExtension
               
}#BootStrapDSC

$MyVM.ConfigurationSets
$MyVM.ResourceExtensionReferences

New-AzureVM –ServiceName $ServiceName –VMs $MyVM
