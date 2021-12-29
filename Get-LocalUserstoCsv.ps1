$ComputerList = (Get-Content C:\Dev\AllDomainComputers.txt)
$localadminGroupWMI = (Get-WmiObject Win32_Group -Filter 'Name = "Administrators"')


Foreach($Computer in $ComputerList) {
$Computer | Tee-Object c:\dev\AllSystemLocalAdminQuery.csv -Append

Invoke-Command -ComputerName $Computer -ScriptBlock {cmd /c 'net localgroup "Administrators"'}  | Tee-Object c:\dev\AllSystemLocalAdminQuery.csv -Append


}
