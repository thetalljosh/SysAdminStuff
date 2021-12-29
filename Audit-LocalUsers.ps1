<#
.SYNOPSIS
    .
.DESCRIPTION
    This script will find local administrators of client computers in your
    domain and will same them as CSV file in current directory.

.PARAMETER Path
    This will be the DN of the OU or searchscope. Simply copy the DN of OU
    in which you want to query for local admins. If not defined, the whole
    domain will be considered as search scope.

.PARAMETER ComputerName
    This parametr defines the computer account in which the funtion will
    run agains. If not specified, all computers will be considered as search
    scope and consequently this function will get local admins of all 
    computers. You can define multiple computers by utilizing comma (,).

.EXAMPLE
    C:\PS> Audit-LocalUsers
    
    This command will get local admins of all computers in the domain.

    C:\PS> Audit-LocalUsers -ComputerName PC1,PC2,PC3

    This command will get local admins of PC1,PC2 and PC3.

    C:\PS> Audit-LocalUsers -Path "OU=Computers,DC=Contoso,DC=com"

.NOTES
    Based on Local user to CSV script originally authored by:
    Original Author: Mahdi Tehrani
    Original Date  : February 18, 2017   

    Modification: Joshua Lambert
    Modification Date: December 14, 2021
#>

Set-ExecutionPolicy Bypass -Scope CurrentUser
Import-Module activedirectory
Clear-Host
function Audit-LocalUsers {
    Param(
            $Path          = (Get-ADDomain).DistinguishedName,   
            $ComputerName  = (Get-ADComputer -Filter * -Server (Get-ADDomain).DNsroot -SearchBase $Path -Properties Enabled | Where-Object {$_.Enabled -eq "True"})
            #$ComputerName = (get-content C:\dev\AllDomainComputers.txt)
         )

    begin{
        [array]$Table = $null
        $Counter = 0
         }
    
    process
    {
    $Date       = Get-Date -Format MM_dd_yyyy_HH_mm_ss
    $FolderName = "LocalAdminsReport("+ $Date + ")"
    New-Item -Path ".\$FolderName" -ItemType Directory -Force | Out-Null

        foreach($Computer in $ComputerName)
        {
            try
            {
                $PC      = Get-ADComputer $Computer
                $Name    = $PC.Name
                $CountPC = @($ComputerName).count
            }

            catch
            {
                Write-Host "Cannot retrieve computer $Computer" -ForegroundColor Yellow -BackgroundColor Red
                Add-Content -Path ".\$FolderName\ErrorLog.txt" "$Name"
                continue
            }

            finally
            {
                $Counter ++
            }

            Write-Progress -Activity "Connecting PC $Counter/$CountPC " -Status "Querying ($Name)" -PercentComplete (($Counter/$CountPC) * 100)

            try
            {
                $row = $null
                $members =[ADSI]"WinNT://$Name/Administrators"
                $members = @($members.psbase.Invoke("Members"))
                $members | foreach {
                            $User = $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)
                                if($user -like 'S-*'){
                                    $sidString = $user.ToString()
                                    write-host "Converting $sidString to name"
                                    $sid = new-object System.Security.Principal.SecurityIdentifier($sidString)
                                    $sb = "get-localuser -sid $sidString"
                                    $StringToSB = $ExecutionContext.InvokeCommand.NewScriptBlock($sb)
                                    $unresolvedSID = invoke-command -computername $Name -scriptblock $stringToSB
                                    $sidrow += $sidString
                                    $sidrow += " ; "
                                 }
                                 elseif($user -like 'X_Admin' -or $user -like 'DoD_Admin' -or $user -like 'AFMISHMFIC' -or $user -like 'CIFMHSIMFA' -or $user -like 'afmis*' -or $user -like 'admin*' -or $user -like 'RKIMBL3MD'){
                                    $sharedUsers += $user
                                    $sharedUsers += " ; "
                                    
                                    
                                 }
                                 elseif($user -like 'SEC.*' -or $user -like 'SECLAN*' -or $user -like 'SVC.*'){
                                    $domainGroups += $user
                                    $domainGroups += " ; "
                                 }
                                else{

                                        $row += $User
                                        $row += " ; "
                                    }
                                }
                write-host "Computer ($Name) has been queried and exported." -ForegroundColor Green -BackgroundColor black 
                
                $obj = New-Object -TypeName PSObject -Property @{
                                "Name"           = $Name
                                "LocalAdmins"    = $Row
                                "DomainGroups"   = $domainGroups
                                "SharedUserAccts"= $sharedUsers
                                "UnresolvedSIDs" = $sidrow
                                                    }
                $Table += $obj
            }

            catch
            {
            Write-Host "Error accessing ($Name)" -ForegroundColor Yellow -BackgroundColor Red
            Add-Content -Path ".\$FolderName\ErrorLog.txt" "$Name"
            }

            
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

    end{}
   }
Audit-LocalUsers    