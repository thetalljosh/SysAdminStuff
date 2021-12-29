<#
.SYNOPSIS
    .
.DESCRIPTION
    This script will find unathorized local users and disable/remove them from local administrators group.

.NOTES
    Based on Local user to CSV script originally authored by:
    Original Author: Mahdi Tehrani
    Original Date  : February 18, 2017   

    Modification: Joshua Lambert
    Modification Date: December 29, 2021
#>

Set-ExecutionPolicy Bypass -Scope CurrentUser -Force
Clear-Host
function Remove-UnauthorizedLocalAdmin {
    Param(
            #$Path          = (Get-ADDomain).DistinguishedName,   
            #$ComputerName  = (Get-ADComputer -Filter * -Server (Get-ADDomain).DNsroot -SearchBase $Path -Properties Enabled | Where-Object {$_.Enabled -eq "True"})
            #$ComputerName = (get-content C:\dev\AllDomainComputers.txt)
            $ComputerName = $env:COMPUTERNAME
         )


    $Date       = Get-Date -Format MM_dd_yyyy_HH_mm_ss
    $FolderName = "LocalAdminsReport("+ $Date + ")"
    New-Item -Path ".\$FolderName" -ItemType Directory -Force | Out-Null

        try
            {
                $row = $null
                $members =[ADSI]"WinNT://Administrators"
                $members = @($members.psbase.Invoke("Members"))
                $members | foreach {
                            $User = $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)
                                if($user -like 'S-*'){
                                    $sidString = $user.ToString()
                                    #write-host "Converting $sidString to name"
                                    $sid = new-object System.Security.Principal.SecurityIdentifier($sidString)
                                    $sb = "get-localuser -sid $sidString"
                                    $StringToSB = $ExecutionContext.InvokeCommand.NewScriptBlock($sb)
                                    $unresolvedSID = invoke-command -computername $ComputerName -scriptblock $stringToSB
                                    $sidrow += $sidString
                                    $sidrow += " ; "
                                 }
                                  elseif($user -like 'X_Admin' -or $user -like 'DoD_Admin' -or $user -like 'AFMISHMFIC' -or $user -like 'CIFMHSIMFA' -or $user -like 'afmis*' -or $user -like 'admin*' -or $user -like 'RKIMBL3MD'){
                                    $sharedUsers += $user
                                    $sharedUsers += " ; "
                                    if($user.enabled){
                                        Disable-LocalUser $User
                                    }
                                    
                                    
                                 }
                                 elseif($user -like 'SEC.*' -or $user -like 'SECLAN*' -or $user -like 'SVC.*'){
                                    $domainGroups += $user
                                    $domainGroups += " ; "
                                 }
                                else{

                                        $row += $User
                                        $row += " ; "
                                        Remove-LocalGroupMember -Group Administrators -Member $user

                                    }
                                }
                
                $obj = New-Object -TypeName PSObject -Property @{
                                "Name"           = $ComputerName
                                "LocalAdmins"    = $Row
                                "DomainGroups"   = $domainGroups
                                "SharedUserAccts"= $sharedUsers
                                "UnresolvedSIDs" = $sidrow
                                                    }
                $Table += $obj
            }

            catch
            {
            
            Add-Content -Path ".\$FolderName\ErrorLog.txt" "$ComputerName"
            }

            
        
        try
        {
            $Table  | Sort Name | Select Name,LocalAdmins,DomainGroups,SharedUserAccts,UnresolvedSIDs | Export-Csv -path ".\$FolderName\Report.csv" -Append -NoTypeInformation
        }
        catch
        {
            Write-Warning $_
        }
}
Remove-UnauthorizedLocalAdmin    