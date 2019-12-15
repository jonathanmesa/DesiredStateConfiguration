Invoke-Command -ComputerName pull,ms1,ms2 -ScriptBlock {
    'Current','Pending','Previous' | % {Remove-DscConfigurationDocument -Stage $_}
    del C:\Windows\System32\Configuration\MetaConfig*.mof
}

