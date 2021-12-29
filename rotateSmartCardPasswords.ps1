Add-Type -AssemblyName System.web
$minLength = 15 ## characters
$maxLength = 16 ## characters
$length = Get-Random -Minimum $minLength -Maximum $maxLength
$nonAlphaChars = 5

$users = (get-content "C:\Users\joshua.lambert.da\Desktop\usrtargets.txt") #put a list of user's last name here
$results = @()
foreach($user in $users) {

$results += (Get-ADUser -Filter * -SearchBase "OU=Standard Users,OU=SEC,DC=SEC,DC=local" -Properties Name, samaccountname | where {$_.name -like "*$user*"} | select -ExcludeProperty SAMAccountName) 
    }  

foreach($user in $results){

$clearPW = [System.Web.Security.Membership]::GeneratePassword($length, $nonAlphaChars)
$secPw = ConvertTo-SecureString -String $clearPW -AsPlainText -Force 
Set-ADUser -Identity $user -SmartcardLogonRequired $false
Sleep -Seconds 5
Set-ADAccountPassword -Identity $user -NewPassword $secPW
write-host "Password for $user has been set to $clearPW"
Sleep -Seconds 5
Set-ADUser -Identity $user -SmartcardLogonRequired $true
}