$Systems = Get-content "c:\dev\allsystems.txt"
$date = Get-date -Format ddMMyyyy

foreach ($PC in $Systems){
  Write-Host "Testing Connection to $PC"
  if (Test-Connection -ComputerName $PC -Count 1 -ErrorAction SilentlyContinue){
    Add-Content C:\dev\AllSystemsTestNetConn_$date.csv "$PC - up"
  }
  else{
    Add-Content C:\dev\AllSystemsTestNetConn_$date.csv "$PC - down"
  }
}
