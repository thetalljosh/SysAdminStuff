$defaultFolders = ("AGMLogs" -and $_.Name -notlike "Packages" -and $_.Name -notlike "PerfLogs"  -and $_.Name -notlike "Program Files" -and $_.Name -notlike "Program Files (x86)"  -and $_.Name -notlike "temp"  -and $_.Name -notlike "users" -and $_.Name -notlike "windows"  -and $_.Name -notlike "WindowsAzure"

function Move-Directories 

#invoke as Move-Directories C:\source \\destination
{
    param (
        [parameter(Mandatory = $true)] [string] $source,
        [parameter(Mandatory = $true)] [string] $destination        
    )

    try
    {
        Get-ChildItem -Path $source -Recurse -Force |
            Where-Object { $_.psIsContainer -and ($_.Name -notlike $defaultFolders) }  |
            ForEach-Object { $_.FullName -replace [regex]::Escape($source), $destination } |
            ForEach-Object { $null = New-Item -ItemType Container -Path $_ }

        Get-ChildItem -Path $source -Recurse -Force |
            Where-Object {  (-not $_.psIsContainer) -and ($_.lastwritetime -ge (get-date)) } |
            Copy-Item -Destination { $_.FullName -replace [regex]::Escape($source), $destination } -Force 
    }

    catch
    {
        Write-Host "$($MyInvocation.InvocationName): $_"
    }
}