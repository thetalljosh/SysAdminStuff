
$35Days = (get-date).adddays(-35)
$daysSinceLogon = @{Name="DaysSinceLogon"; Expr={ ([timespan]((Get-Date) - ([datetime]$_.LastLogonTimestamp).AddYears(1600))).Days; }}

Write-Host "#########################"  
Write-Host "Stale User Accounts"

Get-ADUser -properties * -filter {(lastlogondate -notlike "*" -OR lastlogondate -le $35days) -AND (passwordlastset -le $35days) -AND (enabled -eq $True) -and (whencreated -le $35days)} | select-object name, SAMaccountname, passwordExpired, PasswordNeverExpires, logoncount, lastlogondate, whenCreated, PasswordLastSet, lastlogontimestamp, $daysSinceLogon | ft name, SAMaccountname, $dayssincelogon, passwordExpired, PasswordNeverExpires, logoncount, lastlogondate, whenCreated, PasswordLastSet, lastlogontimestamp | tee-object c:\stale.csv -Append


Write-Host "#########################"  
Write-Host "Stale Computer Accounts"
Get-ADComputer -Properties * -Filter {(lastlogondate -notlike "*" -OR lastlogondate -le $35days) -AND (enabled -eq $True) -AND (whencreated -le $35days) } | Select-Object SAMaccountname, whencreated, lastlogondate, lastlogontimestamp, DaysSinceLogon | FT SAMAccountName, $daysSinceLogon, whencreated, lastlogondate | tee-object c:\stale.csv -Append
Write-Host "#########################"  

