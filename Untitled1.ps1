#Script name Send-EventEmail
#this script will send an email with specified event details via SMTP relay


$event = get-eventlog -LogName Application -source "Put your source here" -newest 1
#get-help get-eventlog will show there are a handful of other options available for selecting the log entry you want.
if ($event.EntryType -eq "Error")
{
    $PCName = $env:COMPUTERNAME
    $EmailBody = $event.Message
    $EmailFrom = "Your Return Email Address <$PCName@yourdomain.com>"
    $EmailTo = "youremail@yourdomain.com" 
    $EmailSubject = "Your Event Log event was found!"
    $SMTPServer = "mailserver.yourdomain.com"
    Write-host "Sending Email"
    Send-MailMessage -From $EmailFrom -To $EmailTo -Subject $EmailSubject -body $EmailBody -SmtpServer $SMTPServer
}
else
{
    write-host "No error found"
    write-host "Here is the log entry that was inspected:"
    $event
}