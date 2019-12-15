configuration MyFirstConfig
{
    Import-DscResource -ModuleName PsDesiredStateConfiguration

    node ('localhost','ms1','ms2')
    {
        Registry Owner
        {
            Key = 'HKLM:\SOFTWARE\Contoso\'
            ValueName = 'Owner'
            Ensure = 'Present'
            ValueData = 'Jimmy'
            ValueType = 'String'
        }

        Registry AssetTag
        {
            Key = 'HKLM:\Software\Contoso'
            ValueName = 'AssetTag'
            ValueData = '42'
            ValueType = 'DWORD'
            Ensure = 'Present'
        }

    }
}

cd 'C:\PShell\Demos'
MyFirstConfig

Start-DscConfiguration -Path .\MyFirstConfig -Wait -Verbose

