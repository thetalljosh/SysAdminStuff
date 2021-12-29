$list = (get-content C:\dev\targets.txt)

foreach($PC in $list){
write-host "Inventorying $PC"
Invoke-Command -ComputerName $PC -ScriptBlock {(Get-WmiObject -Query "Select * FROM WMIMonitorID" -Namespace root\wmi | 
    Select -ExpandProperty SerialNumberID | 
    foreach {[char]$_}) -join ""} -ErrorAction SilentlyContinue|
    Tee-Object c:\dev\Monitors.csv
    }