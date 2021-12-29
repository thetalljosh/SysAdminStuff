$list = (Get-Content c:\dev\targets.txt)
foreach($PC in $list ){

write-host "Querying BDCEdit on $PC"
get-WmiObject -ComputerName $PC Win32_OperatingSystem |
  Select-Object PSComputerName, DataExecutionPrevention_SupportPolicy |
  Export-Csv -Path c:\dev\DEP.csv -Append -NoTypeInformation

}