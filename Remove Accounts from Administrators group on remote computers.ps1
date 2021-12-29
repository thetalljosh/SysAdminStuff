$userCriteria = '1*'

foreach($computer in (get-content "C:\dev\afmisWK.txt")){
 $members =[ADSI]"WinNT://$computer/Administrators"
 $members = @($members.psbase.Invoke("Members"))
 $members | foreach{
 
    $User = $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)
    $User
    <#
        if($user -like $userCriteria ){
            write-host $user "is a domain user in the admin group on $computer!"
            #Uncomment the line below to remove the users found in $user
            #Invoke-Command -ComputerName $computer -ScriptBlock {Remove-LocalGroupMember -Group Administrators -Member $using:user}
        }
        #>
    }


}