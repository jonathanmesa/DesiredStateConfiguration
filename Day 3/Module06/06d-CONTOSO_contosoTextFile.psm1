function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Path,

		[parameter(Mandatory = $true)]
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

	$returnValue = @{
		Path = $Path
	}

    If (Test-Path $Path) {
 
    	Write-Verbose "File is present [$Path]"
        $returnValue.Add('Ensure','Present')
        $returnValue.Add('Value',(Get-Content $Path -Raw))

    } Else {

        Write-Verbose "File is not present [$Path]"
        $returnValue.Add('Ensure','Absent')
        $returnValue.Add('Value',$null)

    }

	$returnValue
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Path,

		[System.String]
		$Value,

		[parameter(Mandatory = $true)]
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

    If ($Ensure -eq 'Present') {

        If ($Value) {
            Write-Verbose "Creating file [$Path] with value [$Value]"
            New-Item -Force -ItemType File -Path $Path -Value $Value
        } Else {
            Write-Verbose "Creating file [$Path]"
            New-Item -Force -ItemType File -Path $Path
        }

    } Else {

        Write-Verbose "Removing file [$Path]"
        Remove-Item -Path $Path -Force

    }

}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Path,

		[System.String]
		$Value,

		[parameter(Mandatory = $true)]
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = 'Present'
	)


    If (Test-Path $Path) {
 
    	Write-Verbose "File is present [$Path]."
        $Present = $true
 
        # Was $Value passed?
        #  If ($PSBoundParameters.ContainsKey('Value'))
        # If ($Value)    <---- Returns $True when $null is strongly typed to ''
        If ([String]::IsNullOrEmpty($Value)) {

            Write-Verbose "File is present [$Path].  No value specified."
            $Match = $true

        } Else {

            If ((Get-Content $Path -Raw) -eq $Value) {
                Write-Verbose "File [$Path] contents match value [$Value]."
                $Match = $true
            } Else {
                Write-Verbose "File [$Path] contents do not match value [$Value]."
                $Match = $false
            }    
        }    

    } Else {

        Write-Verbose "File is not present [$Path]."
        $Present = $false

    }

    If ($Ensure -eq 'Present') {

        If ($Value) {
            Return ($Present -and $Match)        
        } Else {
            Return $Present        
        }

    } Else {
        Return (-not $Present)
    }

}


Export-ModuleMember -Function *-TargetResource

<#
##### Unit Testing #####

Get-TargetResource -Path C:\DropZone\test.txt -Ensure Absent
Get-TargetResource -Path C:\DropZone\test.txt -Ensure Present

Test-TargetResource -Path C:\DropZone\test.txt -Verbose -Ensure Absent
Test-TargetResource -Path C:\DropZone\test.txt -Verbose -Ensure Absent -Value "This is a test."

Test-TargetResource -Path C:\DropZone\test.txt -Verbose -Ensure Present
Test-TargetResource -Path C:\DropZone\test.txt -Verbose -Ensure Present -Value "This is a test."

Set-TargetResource -Path C:\DropZone\test.txt -Verbose -Ensure Present
Set-TargetResource -Path C:\DropZone\test.txt -Verbose -Ensure Present -Value "This is a test."

Set-TargetResource -Path C:\DropZone\test.txt -Ensure Absent

#>
