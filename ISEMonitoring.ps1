#Powershell doesn't trust the ISE certificate. This bit of C++ will make it ignore that
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

#This Function is for logging. We like logging. 

function Write-Log() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias("LogContent")]
        [string]$message,
        [Parameter(Mandatory=$false)]
        [Alias('LogPath')]
        [string]$path = "$env:windir\!AuditEventAlerts.log",
        [Parameter(Mandatory=$false)]
        [ValidateSet("Error","Warn","Info")]
        [string]$level = "Info"
    )
    Begin {
        # Set VerbosePreference to Continue so that verbose messages are displayed.
        $verbosePreference = 'Continue'
    }
    Process {
		if ((Test-Path $Path)) {
			$logSize = (Get-Item -Path $Path).Length/1MB
			$maxLogSize = 5
		}
        # Check for file size of the log. If greater than 5MB, it will create a new one and delete the old.
        if ((Test-Path $Path) -AND $LogSize -gt $MaxLogSize) {
            Write-Error "Log file $Path already exists and file exceeds maximum file size. Deleting the log and starting fresh."
            Remove-Item $Path -Force
            $newLogFile = New-Item $Path -Force -ItemType File
        }
        # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path.
        elseif (-NOT(Test-Path $Path)) {
            Write-Verbose "Creating $Path."
            $newLogFile = New-Item $Path -Force -ItemType File
        }
        else {
            # Nothing to see here yet.
        }
        # Format Date for our Log File
        $formattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        # Write message to error, warning, or verbose pipeline and specify $LevelText
        switch ($level) {
            'Error' {
                Write-Error $message
                $levelText = 'ERROR:'
            }
            'Warn' {
                Write-Warning $Message
                $levelText = 'WARNING:'
            }
            'Info' {
                Write-Verbose $Message
                $levelText = 'INFO:'
            }
        }
        # Write log entry to $Path
        "$formattedDate $levelText $message" | Out-File -FilePath $path -Append
    }
    End {
    }
}

$PingResponse = (Test-NetConnection -ComputerName 155.154.200.122 -CommonTCPPort HTTP)
$WebResponse = (Invoke-WebRequest -Uri https://155.154.200.122/admin/login.jsp).StatusCode 

If ($PingResponse -and ($WebResponse.ToString() -eq "200"))
{
#write-host "things are up, hooray" -ForegroundColor Green
    write-log -message "things are up, hooray" -level Info
    $allGood = $true
    $bodyMsg = "This is a test of the ISE uptime monitoring script. Receiving this message DOES NOT mean the ISE is down."
}

elseif($PingResponse -and ($WebResponse.ToString() -ne "200")){
#write-host "we can ping it, but the portal is down" -ForegroundColor Yellow
    write-log -message "we can ping it, but the portal is down. Web portal status code is $WebResponse." -level Warn
    $portalDown = $true
    $bodyMsg = "Device responsive to ping, but web portal may be down. Web portal status code is $WebResponse."

}

elseif(!($PingResponse -and ($WebResponse.ToString() -ne "200"))){
#write-host "ISE is down" -ForegroundColor Red
    Write-Log -message "ISE is down. Web portal status code is $WebResponse." -level Error
    $ISEDown = $true
    $bodyMsg = "Device appears to be offline. Unresponsive to ping and the web portal is down."
}

else
{
    write-log -message "Script Failed"
    }
#let's write an email
start-sleep -Seconds 30
if($portalDown -or $ISEDown)
{
    $PCName = 'LEEEW4FH11B6ISE'
    $EmailBody = $bodyMsg
    $EmailFrom = "Domain Event Alert <EventAlert@seceis.army.mil>"
    $EmailTo = "joshua.a.lambert18.ctr@mail.mil", "herbert.g.shaw.civ@mail.mil", "mario.j.wells2.ctr@mail.mil", "christopher.r.rhodes6.civ@mail.mil" 
    $EmailSubject = "ISE Downtime Alert!"
    $SMTPServer = "155.154.226.8"
    #Write-host "Sending Email"
    Write-log -message "Sending Alert to $EmailTo - Event entry $EmailSubject"
    Send-MailMessage -From $EmailFrom -To $EmailTo -Subject $EmailSubject -body $EmailBody -SmtpServer $SMTPServer
}
