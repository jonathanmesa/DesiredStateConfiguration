enum Ensure
{
    Absent
    Present
}


### Resource #1 ###
[DscResource()]
class FileResource
{
    [DscProperty(Key)]
    [string]$Path

    [DscProperty(Mandatory)]
    [Ensure] $Ensure    
    
    [DscProperty(Mandatory)]
    [string] $SourcePath

    [DscProperty(NotConfigurable)]   
    [Nullable[datetime]] $CreationTime 

    [void] Set()
    {        
        $fileExists = $this.TestFilePath($this.Path)
        if($this.ensure -eq [Ensure]::Present)
        {
            if(-not $fileExists)
            {
                $this.CopyFile()
            }
        }
        else
        {
            if($fileExists)
            {
                Write-Verbose -Message "Deleting the file $($this.Path)"
                Remove-Item -LiteralPath $this.Path -Force
            }
        }
    }

    [bool] Test()
    {
        $present = $this.TestFilePath($this.Path)

        if($this.Ensure -eq [Ensure]::Present)
        {
            return $present
        }
        else
        {
            return -not $present
        }
    }
    
    [FileResource] Get()
    {
        $present = $this.TestFilePath($this.Path)        
        
        if ($present)
        {
            $file = Get-ChildItem -LiteralPath $this.Path
            $this.CreationTime = $file.CreationTime
            $this.Ensure = [Ensure]::Present
        }
        else
        {
            $this.CreationTime = $null
            $this.Ensure = [Ensure]::Absent
        }        

        return $this
    }

    [bool] TestFilePath([string] $location)
    {      
        $present = $true

        $item = Get-ChildItem -LiteralPath $location -ea Ignore
        if ($item -eq $null)
        {
            $present = $false            
        }
        elseif( $item.PSProvider.Name -ne "FileSystem")
        {
            throw "Path $($location) is not a file path."
        }
        elseif($item.PSIsContainer)
        {
            throw "Path $($location) is a directory path."
        }
        return $present
    }

    [void] CopyFile()
    { 
        if(-not $this.TestFilePath($this.SourcePath))
        {
            throw "SourcePath $($this.SourcePath) is not found."
        }

        [System.IO.FileInfo] $destFileInfo = new-object System.IO.FileInfo($this.Path)
        if (-not $destFileInfo.Directory.Exists)
        {
            Write-Verbose -Message "Creating directory $($destFileInfo.Directory.FullName)"

            [System.IO.Directory]::CreateDirectory($destFileInfo.Directory.FullName)
        }

        if(Test-Path -LiteralPath $this.Path -PathType Container)
        {
            throw "Path $($this.Path) is a directory path"
        }

        Write-Verbose -Message "Copying $($this.SourcePath) to $($this.Path)"

        Copy-Item -LiteralPath $this.SourcePath -Destination $this.Path -Force
    }
}


### Resource #2 ###
[DscResource()]
class FileTextResource
{
    [DscProperty(Key)]
    [string]$Path

    [DscProperty(Mandatory)]
    [Ensure] $Ensure    
    
    [DscProperty(Mandatory)]
    [string] $Value

    [DscProperty(NotConfigurable)]   
    [Nullable[datetime]] $CreationTime 

    [void] Set()
    {        
        $fileExists = $this.TestFilePath($this.Path)
        if($this.ensure -eq [Ensure]::Present)
        {
            if(-not $fileExists)
            {
                $this.CreateFile()
            }
        }
        else
        {
            if($fileExists)
            {
                Write-Verbose -Message "Deleting the file $($this.Path)"
                Remove-Item -LiteralPath $this.Path -Force
            }
        }
    }

    [bool] Test()
    {

        If ((Get-Content $this.Path -ErrorAction Ignore -Raw) -eq $this.Value) {
            $present = $true
        } else {
            $present = $false
        }

        if($this.Ensure -eq [Ensure]::Present)
        {
            return $present
        }
        else
        {
            return -not $present
        }
    }
    
    [FileTextResource] Get()
    {
        $present = $this.TestFilePath($this.Path)        
        
        if ($present)
        {
            $file = Get-ChildItem -LiteralPath $this.Path
            $this.CreationTime = $file.CreationTime
            $this.Ensure = [Ensure]::Present
            $this.Value = Get-Content $this.Path
        }
        else
        {
            $this.CreationTime = $null
            $this.Ensure = [Ensure]::Absent
        }        

        return $this
    }

    [bool] TestFilePath([string] $location)
    {      

        If ((Get-Content $this.Path -ErrorAction Ignore -Raw) -eq $this.Value) {
            $present = $true
        } else {
            $present = $false
        }

        return $present
    }

    [void] CreateFile()
    { 
        [System.IO.FileInfo] $destFileInfo = new-object System.IO.FileInfo($this.Path)
        if (-not $destFileInfo.Directory.Exists)
        {
            Write-Verbose -Message "Creating directory $($destFileInfo.Directory.FullName)"

            [System.IO.Directory]::CreateDirectory($destFileInfo.Directory.FullName)
        }

        if(Test-Path -LiteralPath $this.Path -PathType Container)
        {
            throw "Path $($this.Path) is a directory path"
        }

        Write-Verbose -Message "Creating $($this.Path)"

        New-Item -ItemType File -Path $this.Path -Value $this.Value -Force
    }
}
