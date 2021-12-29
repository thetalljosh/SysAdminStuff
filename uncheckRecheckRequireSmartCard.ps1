
$users = (get-content "C:\Users\joshua.lambert.da\Desktop\usrtargets.txt") #put a list of user's last name here
$results = @()
foreach($user in $users) {

$results += (Get-ADUser -Filter * -SearchBase "OU=Standard Users,OU=SEC,DC=SEC,DC=local" -Properties Name, samaccountname | where {$_.name -like "*$user*"} | select -ExcludeProperty SAMAccountName) 
    }  
#$results | ft samaccountname

#foreach($result in $results){
#$ChangeList = @(get-aduser -filter 'name -eq $result.Tostring()' -SearchBase "OU=Standard Users,OU=SEC,DC=SEC,DC=local" -properties name, SAMAccountName | select -expandproperty SAMAccountName)}
foreach($user in $results){ Set-ADUser -Identity $user -SmartcardLogonRequired $false}

sleep -Seconds 10

foreach($user in $results){ Set-ADUser -Identity $user -SmartcardLogonRequired $true}
