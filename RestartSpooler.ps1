Stop-Service -Name Spooler -Force
start-sleep -Seconds 30
Start-Service -Name Spooler 