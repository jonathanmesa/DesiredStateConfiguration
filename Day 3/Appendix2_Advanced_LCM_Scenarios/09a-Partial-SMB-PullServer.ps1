break
cls

Set-Location C:\PShell\Demos


# Create pull share on Pull2 server
# Grant 'Domain Computers' group read-only access
Invoke-Command -ComputerName ms2.contoso.com -ScriptBlock {
    md C:\SMBPullShare
    New-SmbShare -Path C:\SMBPullShare -Name SMBPullShare -ReadAccess 'CONTOSO\Domain Computers' -FullAccess 'CONTOSO\Domain Admins'
}

# Verify
Start \\ms2\SMBPullShare




# Reset

Invoke-Command -ComputerName ms2.contoso.com -ScriptBlock {
    Remove-SmbShare -Name SMBPullShare -Confirm:$false
    rd C:\SMBPullShare -Recurse -Confirm:$false
}
