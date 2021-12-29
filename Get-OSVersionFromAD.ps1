#$searchBase = read-host "Enter OU SearchBase"

#$List = Get-ADComputer -SearchBase $searchBase -filter {enabled -eq $true} -properties OperatingSystemVersion, description

$List = Get-ADComputer -filter {enabled -eq $true} -properties OperatingSystemVersion


#Write-host "Count of Operating System Versions"
#Write-Host "==========================================================="
$groupList = (Get-ADComputer -filter {enabled -eq $true} -properties OperatingSystemVersion |group -Property OperatingSystemVersion | Select Name,Count| Sort Name ) | out-string
$groupString = ($groupList.replace('10.0 (18362)' ,'1903        ').replace('10.0 (18363)' ,'1909        ').replace('10.0 (19041)' ,'2004        ').replace('10.0 (19042)' ,'20H2        ').replace('10.0 (19043)' ,'21H1        ').replace('10.0 (19044)' ,'21H2        ').replace('10.0 (14393)' ,'Server 2016 ').replace('10.0 (17763)' ,'Server 2019 ')).ToString()


$mailBody += Write-output "Count of Operating System Versions"
$mailBody += Write-output "==========================================================="
#$mailBody += write-output $(Get-ADComputer -filter {enabled -eq $true} -properties OperatingSystemVersion |group -Property OperatingSystemVersion | Select Name,Count| Sort Name | ft -AutoSize)
$mailBody += Write-Output $groupString | out-string
$mailBody += Write-output "==========================================================="

$mailBody += Write-Output "`nList of Systems and OS Versions`n"
$mailBody += write-output ""
foreach ($System in $List) {
    if($System.OperatingSystemVersion){
    $Result = switch ($System.OperatingSystemVersion)
        {
           
           "10.0 (18362)" {'1903'}
           "10.0 (18363)" {'1909'}
           "10.0 (19041)" {'2004'}
           "10.0 (19042)" {'20H2'}
           "10.0 (19043)" {'21H1'}
           "10.0 (19044)" {'21H2'}
           "10.0 (14393)" {'Server 2016'}
           "10.0 (17763)" {'Server 2019'}

        }
        
        if($Result){

        #Write-Host $System.Name.ToString(), $System.OperatingSystemVersion.ToString(), $Result.ToString() -ErrorAction SilentlyContinue

        $mailBody += write-output "$($System.Name.ToString()), $($System.OperatingSystemVersion.ToString()), $($Result.ToString())" -ErrorAction SilentlyContinue | Out-String

        }
        elseif(!($Result)){
        #write-host $System.Name.ToString() $System.OperatingSystemVersion.ToString() -ErrorAction SilentlyContinue
        $mailBody += write-output "$($System.Name.ToString()), $($System.OperatingSystemVersion.ToString())" -ErrorAction SilentlyContinue | out-string
        }
        }

} 

$EmailBody = $mailBody | out-string
$EmailFrom = "Domain Info <DomainInfo@seceis.army.mil>"
$EmailTo = "joshua.a.lambert18.ctr@army.mil"#, "herbert.g.shaw.civ@army.mil","christopher.r.rhodes6.civ@army.mil"
$EmailSubject = "Monthly Operating System Report"
$SMTPServer = "155.154.226.8"
Send-MailMessage -From $EmailFrom -To $EmailTo -Subject $EmailSubject -body $EmailBody -SmtpServer $SMTPServer

Start-Sleep -Seconds 10
$mailBody.clear()