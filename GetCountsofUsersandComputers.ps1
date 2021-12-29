$Computers = (Get-ADComputer  -filter {(Enabled -eq $True)}).count
$Workstations = (Get-ADComputer -LDAPFilter "(&(objectClass=Computer)(!operatingSystem=*server*)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))" -Searchbase (Get-ADDomain).distinguishedName).count
$Servers = (Get-ADComputer -LDAPFilter "(&(objectClass=Computer)(operatingSystem=*server*)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))" -Searchbase (Get-ADDomain).distinguishedName).count
$StandardUsers = (Get-ADUser -searchbase 'OU=Standard Users,OU=SEC,DC=SEC,DC=local' -filter {(Enabled -eq $True)}).count
$PriviledgedUsers = (Get-ADUser -searchbase 'OU=Privileged Users,OU=SEC,DC=SEC,DC=local' -filter {(Enabled -eq $True)}).count
$dtg = get-date

Write-Host "Report requested on $dtg." -ForegroundColor White
Write-Host "All Systems =       "$Computers -ForegroundColor Green
Write-Host "Workstions =        "$Workstations -ForegroundColor Green
Write-Host "Servers =           "$Servers -ForegroundColor Green
Write-Host "Standard Users =    "$StandardUsers -ForegroundColor Green
Write-Host "Priviledged Users = "$PriviledgedUsers -ForegroundColor Green