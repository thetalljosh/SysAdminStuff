
$exclude = @("$SrcComputer\C$\`$recycle.bin\*", "$SrcComputer\C$\Documents and Settings\*","$SrcComputer\C$\Intel\*", "$SrcComputer\C$\IntelOptaneData\*", "$SrcComputer\C$\MSOCache\*", "$SrcComputer\C$\NEC\*", "$SrcComputer\C$\ProgramData\*", "$SrcComputer\C$\Quarantine\*", "$SrcComputer\C$\Recovery\*", "$SrcComputer\C$\System Volume Information\*", "$SrcComputer\C$\_SMSTaskSequence\*", "$SrcComputer\C$\AGMLogs\*", "$SrcComputer\C$\Packages\*","$SrcComputer\C$\PerfLogs\*","$SrcComputer\C$\Program Files\*","$SrcComputer\C$\Program Files (x86)\*", "$SrcComputer\C$\temp\*","$SrcComputer\C$\users\*","$SrcComputer\C$\windows\*", "$SrcComputer\C$\WindowsAzure\*")
function Copy-Directories 

#invoke as Move-Directories C:\SrcComputer \\destination
{
    param (
        [parameter(Mandatory = $true)] [string] $SrcComputer,
        [parameter(Mandatory = $true)] [string] $destComputer        
    )

    try
    {
        Get-ChildItem -Path $SrcComputer -Recurse -Force -Exclude $exclude |
            Where-Object { $_.psIsContainer -and ($_.FullName -notlike '*$Recycle.bin*')}  |
            ForEach-Object { $_.FullName -replace [regex]::Escape($SrcComputer), $destComputer } |
            ForEach-Object { $null = New-Item -ItemType Container -Path $_ -ErrorAction SilentlyContinue -Verbose}

        Get-ChildItem -Path $SrcComputer -Recurse -Force -Exclude $exclude |
            Where-Object {  (-not $_.psIsContainer) -and ($_.lastwritetime -ge (get-date) -and ($_.FullName -notlike '*$Recycle.bin')) } |
            Copy-Item -Destination { $_.FullName -replace [regex]::Escape($SrcComputer), $destComputer } -force -Verbose -ErrorAction SilentlyContinue -Exclude C:\Windows\*
    }

    catch
    {
        Write-Host "$($MyInvocation.InvocationName): $_"
    }
}