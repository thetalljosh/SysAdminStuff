#$AppSearch = "Microsoft.Microsoft3DViewer"
function RemoveApp([string]$AppSearch) {
   Write-Host "Removing $AppSearch"
   Write-Host "- for All Users"
   Get-AppxPackage -AllUsers $AppSearch | Remove-AppxPackage
   Write-Host "- for All (New) Users (Provisioned)"
   Get-AppxProvisionedPackage -online | Where-Object {$_.PackageName -like '$AppSearch'} | Remove-AppxProvisionedPackage -online
}
RemoveApp("Microsoft.Microsoft3DViewer")