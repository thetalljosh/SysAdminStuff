#################################################################################################################
# Script to Send  Email Reminders when service accout passswords due to Expire.
#
# Requires: Windows PowerShell Module for Active Directory
##################################################################################################################
# Please Configure the following variables....
$smtpServer="155.154.226.8"
$expireindays = 7
$from = "DREN Active Directory <ADAlert@seceis.army.mil>"
$logging = "Enabled" # Set to Disabled to Disable Logging
$logFile = "c:\temp\PWChangeScriptLog.csv" # ie. c:\mylog.csv
$testing = "Enabled" # Set to Disabled to Email Users
$testRecipient = "usarmy.lee.sec.list.sec-eisd-issb-itsb@army.mil"
#
###################################################################################################################

# Check Logging Settings
if (($logging) -eq "Enabled")
{
    # Test Log File Path
    $logfilePath = (Test-Path $logFile)
    if (($logFilePath) -ne "True")
    {
        # Create CSV File and Headers
        New-Item $logfile -ItemType File
        Add-Content $logfile "Date,Name,EmailAddress,DaystoExpire,ExpiresOn,Notified"
    }
} # End Logging Check

# System Settings
$textEncoding = [System.Text.Encoding]::UTF8
$date = Get-Date -format ddMMyyyy
# End System Settings

# Get Users From AD who are Enabled, Passwords Expire and are Not Currently Expired
Import-Module ActiveDirectory
$users = get-aduser -filter 'name -like "*svc*"' -properties Name, PasswordNeverExpires, PasswordExpired, PasswordLastSet, EmailAddress |where {$_.Enabled -eq "True"} | where { $_.PasswordNeverExpires -eq $false } | where { $_.passwordexpired -eq $false }
$DefaultmaxPasswordAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge

# Process Each User for Password Expiry
foreach ($user in $users)
{
    $Name = $user.Name
    $emailaddress = $user.emailaddress
    $passwordSetDate = $user.PasswordLastSet
    $PasswordPol = (Get-AduserResultantPasswordPolicy $user)
    $sent = "" # Reset Sent Flag
    # Check for Fine Grained Password
    if (($PasswordPol) -ne $null)
    {
        $maxPasswordAge = ($PasswordPol).MaxPasswordAge
    }
    else
    {
        # No FGP set to Domain Default
        $maxPasswordAge = $DefaultmaxPasswordAge
    }


    $expireson = $passwordsetdate + $maxPasswordAge
    $today = (get-date)
    $daystoexpire = (New-TimeSpan -Start $today -End $Expireson).Days

    # Set Greeting based on Number of Days to Expiry.

    # Check Number of Days to Expiry
    $messageDays = $daystoexpire

    if (($messageDays) -gt "1")
    {
        $messageDays = "in " + "$daystoexpire" + " days."
    }
    else
    {
        $messageDays = "today."
    }

    # Email Subject Set Here
    $subject="Password for $name will expire $messageDays"

    # Email Body Set Here, Note You can use HTML, including Images.
    $body ="
    Notice:
    <p> The Password for SEC\$name will expire $messageDays<br>
    </P>" 


    # If Testing Is Enabled - Email Administrator
    if (($testing) -eq "Enabled")
    {
        $emailaddress = $testRecipient
    } # End Testing

    # If a user has no email address listed
    if (($emailaddress) -eq $null)
    {
        $emailaddress = $testRecipient
    }# End No Valid Email

    # Send Email Message
    if (($daystoexpire -ge "0") -and ($daystoexpire -lt $expireindays))
    {
        $sent = "Yes"
        # If Logging is Enabled Log Details
        if (($logging) -eq "Enabled")
        {
            Add-Content $logfile "$date,$Name,$emailaddress,$daystoExpire,$expireson,$sent"
        }
        # Send Email Message
        Send-Mailmessage -smtpServer $smtpServer -from $from -to $emailaddress -subject $subject -body $body -bodyasHTML -priority High -Encoding $textEncoding

    } # End Send Message
    else # Log Non Expiring Password
    {
        $sent = "No"
        # If Logging is Enabled Log Details
        if (($logging) -eq "Enabled")
        {
            Add-Content $logfile "$date,$Name,$emailaddress,$daystoExpire,$expireson,$sent"
        }
    }

} # End User Processing



# End