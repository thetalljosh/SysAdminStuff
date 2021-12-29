#Provides Dialog Box to select a file with list of computers.  File must contain only 1 of each of the Computer name(s) per line
Function Get-OpenFile($initialDirectory)
{ 
   [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.initialDirectory = $initialDirectory
$OpenFileDialog.filter = "All files (*.*)| *.*"
$OpenFileDialog.ShowDialog() | Out-Null
$OpenFileDialog.filename

}

Write-host "Select list of hosts"

$hosts = Get-OpenFile

Write-Host "Select update MSU"

$UpdateFile = Get-OpenFile

foreach($PC in $hosts){
    invoke-command -ComputerName $PC -ScriptBlock{Start-Process "C:\Windows\System32\wusa.exe" -argumentlist "'$UpdateFile' /quiet /norestart"}
    }
     