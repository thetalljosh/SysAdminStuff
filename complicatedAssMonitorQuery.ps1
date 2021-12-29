<#
.SYNOPSIS
	Generate a report in multiple formats (if requested) of monitors that are connected to computers.
.DESCRIPTION
	This script will take a list of computers (from a txt file or from AD) and will
	query each computer through WMI, asking what the serial number and manufacturer is. 
	It can then generate multiple types of reports, CSV, HTML, or e-mail the HTML as the body of the message.
.PARAMETER CSVReport
	Switch, used to define wether you want a CSV report generated or not.
.PARAMETER CSVOutputFile
	The location where you want the CSV report to be stored, if the CSVReport switch is true.
.PARAMETER HTMLReport
	Switch, used to define wether you want an HTML report generated or not.
.PARAMETER HTMLOutputFile
	The location where you want the HTML report to be stored, if the HTMLReport switch is true.
.PARAMETER EmailReportAsHTML
	Switch, used to indicate weather you want to send the report via e-mail with the body formatted as HTML.
.PARAMTER LinkToComputer
	Switch, this is a work in progress (I am figuring out the API's to call to make this work), essentially it
	will be used in conjunction with the ImportToSpiceworks switch and it will define wether you want to link
	the monitors found, to the computers that they were found to be connected to.
.PARAMETER FromAD
	Switch, used to define wether you want to use AD to define the array or computers to scan if monitors are
	connected to them or not.
.PARAMTER FromFile
	Switch, used to define wether you want to use a txt file to define the array list of computers to be
	scanned if there is a monitor connected or not.
.PARAMETER FromFileLocation
	The location where the txt file is located that has the list of computers to be scanned for monitors attached.
	This file should have 1 computer name of each new row.
.PARAMETER Test
	Switch, this switch is used to test the functionality of the script, against the localhost only.
.EXAMPLE
	Get-AttachedMoritorInventory.ps1 -FromFile -FromFileLocation "C:\Test\Servers.txt" -HTMLReport -HTMLOutputFile "C:\Test\AttachedMonitors.html"
.EXAMPLE
	Get-AttachedMoritorInventory.ps1 -FromAD -CSVReport -CSVOutputFile "C:\Test\AttachedMonitors.csv"
.EXAMPLE
	Get-AttachedMoritorInventory.ps1 -FromAD -EmailReportAsHTML
.NOTES
	Author:         Matt Bergeron
	Spiceworks:     Chamele0n
	Blog:           www.chamele0n.com
	
	Changelog:
		1.4			Better detection of Virtual Machines, to support Microsoft Surface tablets.
		1.3         Fix bug for displaying year of manufacture
		1.2         Fixed bug where it was prompting for credentials where it shouldn't have been.
		1.1         Fixed bug that caused -Test parameter not to work.
		1.0         Initial  release
.LINK
	http://community.spiceworks.com/scripts/show/2962-inventory-monitors-connected-to-physical-computers
#>
Param(
	[switch]$CSVReport,
	[string]$CSVOutputFile = "C:\Test\AttachedMonitors.csv",
	[switch]$HTMLReport = $true,
	[string]$HTMLOutputFile = "C:\Test\AttachedMonitors.htm",
	[switch]$EmailReportAsHTML,
	[switch]$FromAD,
	[switch]$FromFile,
	[string]$FromFileLocation = "C:\Test\Servers.txt",
	[switch]$Test
)
### SMTP Mail Settings
$SMTPProperties = @{
	To = "ToUser@domain.com"
	From = "FromUser@Domain.com"
	Subject = "Monitor Inventory"
	SMTPServer = "mail.domain.com"
}

$Results = @()
$Count = 0

if ($FromAD)
{	### Attempts to Import ActiveDirectory Module. Produces error if fails.
	Try { Import-Module ActiveDirectory -ErrorAction Stop }
	Catch { Write-Host "Unable to load Active Directory module, is RSAT installed?"; Break }
}

### HTML Header	
$Header = @"
<center>
	<style>
		TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;margin-left: auto;margin-right: auto;}
		TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #808080;}
		TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
		.odd  { background-color:#ffffff; }
		.even { background-color:#dddddd; }
	</style>
</center>
<title>
	Attached Monitor Inventory Report
</title>
"@


Function ConvertTo-Char ($Array)
{
	$Output = ""
	ForEach($char in $Array)
	{	$Output += [char]$char -join ""
	}
	return $Output
}

Function Detect-VirtualMachine
{
	Param (
		[string]$ComputerName
	)
	$VMModels = @("Virtual Machine","VMware Virtual Platform","Xen","VirtualBox")
	$CheckPhysicalOrVMQuery = Get-WmiObject -ComputerName $ComputerName -Query "Select * FROM Win32_ComputerSystem" -Namespace "root\CIMV2" -ErrorAction Stop
	if ($VMModels -contains $CheckPhysicalOrVMQuery.Model)
	{	$IsVM = $True
	}
	Else
	{	$IsVM = $False
	}
	Return $IsVM
}

Function Set-AlternatingRows
{
	<#
	.SYNOPSIS
		Simple function to alternate the row colors in an HTML table
	.DESCRIPTION
		This function accepts pipeline input from ConvertTo-HTML or any
		string with HTML in it.  It will then search for <tr> and replace 
		it with <tr class=(something)>.  With the combination of CSS it
		can set alternating colors on table rows.
		
		CSS requirements:
		.odd  { background-color:#ffffff; }
		.even { background-color:#dddddd; }
		
		Classnames can be anything and are configurable when executing the
		function.  Colors can, of course, be set to your preference.
		
		This function does not add CSS to your report, so you must provide
		the style sheet, typically part of the ConvertTo-HTML cmdlet using
		the -Head parameter.
	.PARAMETER Line
		String containing the HTML line, typically piped in through the
		pipeline.
	.PARAMETER CSSEvenClass
		Define which CSS class is your "even" row and color.
	.PARAMETER CSSOddClass
		Define which CSS class is your "odd" row and color.
	.EXAMPLE $Report | ConvertTo-HTML -Head $Header | Set-AlternateRows -CSSEvenClass even -CSSOddClass odd | Out-File HTMLReport.html
	
		$Header can be defined with a here-string as:
		$Header = @"
		<style>
		TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
		TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #6495ED;}
		TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
		.odd  { background-color:#ffffff; }
		.even { background-color:#dddddd; }
		</style>
		"@
		
		This will produce a table with alternating white and grey rows.  Custom CSS
		is defined in the $Header string and included with the table thanks to the -Head
		parameter in ConvertTo-HTML.
	.NOTES
		Author:         Martin Pugh
		Twitter:        @thesurlyadm1n
		Spiceworks:     Martin9700
		Blog:           www.thesurlyadmin.com
		
		Changelog:
			1.0         Initial function release
	.LINK
		http://community.spiceworks.com/scripts/show/1745-set-alternatingrows-function-modify-your-html-table-to-have-alternating-row-colors
	#>
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$True,ValueFromPipeline=$True)]
		[string]$Line,
	   
		[Parameter(Mandatory=$True)]
		[string]$CSSEvenClass,
	   
		[Parameter(Mandatory=$True)]
		[string]$CSSOddClass
	)
	Begin {
		$ClassName = $CSSEvenClass
	}
	Process {
		If ($Line.Contains("<tr><td>"))
		{	$Line = $Line.Replace("<tr>","<tr class=""$ClassName"">")
			If ($ClassName -eq $CSSEvenClass)
			{	$ClassName = $CSSOddClass
			}
			Else
			{	$ClassName = $CSSEvenClass
			}
		}
		Return $Line
	}
}# End Set-AlternatingRows Function

if ($FromAD){ $Computers = Get-ADComputer -Filter * -Properties Name }
if ($FromFile){ $Computers = Get-Content $FromFileLocation }

ForEach ($Computer in $Computers)
{
	$progress = @{
		Activity = "Querying Connected Monitors on $ComputerName"
		Status = "$Count of $($Computers.Count) completed"
		PercentComplete = $Count / $($Computers.Count) * 100
		Id = 0
	}
	Write-Progress @progress
	
	$Count++
	
	if ($FromAD)
	{	$ComputerName = $Computer.DNSHostName
	}
	ElseIf ($FromFile)
	{	$ComputerName = $Computer
	}
	ElseIf ($Test)
	{	Write-Host "Test Mode Enabled" -ForegroundColor Yellow
		$ComputerName = $Env:ComputerName
	}
	Try
	{
		if (-not ($Test))
		{	$IsPhysicalMachine = Detect-VirtualMachine -ComputerName $ComputerName
		}
		Else
		{	$IsPhysicalMachine = Detect-VirtualMachine -ComputerName "localhost"
		}
	}
	Catch
	{
		if (-not ($Test))
		{	Write-Host "ComputerName: $($ComputerName), caught an error checking if the computer was physical or virtual: $($Error[0])" -ForegroundColor Red -BackgroundColor Black
		}
		Else
		{	Write-Host "ComputerName: $($ComputerName), caught an error checking if the computer was physical or virtual: $($Error[0])" -ForegroundColor Red -BackgroundColor Black
		}
		$Results += New-Object PSObject -Property @{
			ComputerName = $ComputerName
			Active = "N/A"
			Manufacturer = "N/A"
			UserFriendlyName = "N/A"
			SerialNumber = "N/A"
			WeekOfManufacture = "N/A"
			YearOfManufacture = "N/A"
			Status = "2 - Warning"
			Message = "There was a problem checking if the computer was physical or virtual: $($Error[0])"
		}
		Continue
	}
	If ($IsPhysicalMachine -eq $false)
	{
		Try
		{
			if (-not ($Test))
			{	$Query = Get-WmiObject -ComputerName $ComputerName -Query "Select * FROM WMIMonitorID" -Namespace root\wmi -ErrorAction Stop
			}
			Else
			{	$Query = Get-WmiObject -Query "Select * FROM WMIMonitorID" -Namespace root\wmi -ErrorAction Stop
			}

			ForEach ($Monitor in $Query)
			{    
				$Results += New-Object PSObject -Property @{
					ComputerName = $ComputerName
					Active = $Monitor.Active
					Manufacturer = ConvertTo-Char($Monitor.ManufacturerName)
					UserFriendlyName = ConvertTo-Char($Monitor.userfriendlyname)
					SerialNumber = ConvertTo-Char($Monitor.serialnumberid)
					WeekOfManufacture = $Monitor.WeekOfManufacture
					YearOfManufacture = $Monitor.YearOfManufacture
					Status = "0 - OK"
					Message = "N/A"
				}
			}
			Continue
		}
		Catch
		{
			$Results += New-Object PSObject -Property @{
				ComputerName = $ComputerName
				Active = "N/A"
				Manufacturer = "N/A"
				UserFriendlyName = "N/A"
				SerialNumber = "N/A"
				WeekOfManufacture = "N/A"
				YearOfManufacture = "N/A"
				Status = "1 - Error"
				Message = "Error: $($Error[0])"
			}
		}
	}
	Else
	{	Write-Host "ComputerName: $($ComputerName) was a virtual machine. Skipping monitor inventory." -ForegroundColor Yellow
		$Results += New-Object PSObject -Property @{
			ComputerName = $ComputerName
			Active = $false
			Manufacturer = "N/A"
			UserFriendlyName = "N/A"
			SerialNumber = "N/A"
			WeekOfManufacture = "N/A"
			YearOfManufacture = "N/A"
			Status = "N/A - Informational"
			Message = "Virtual Machine, skipped monitor inventory."
		}
	}
}

### Debugging to make sure there are results.
#Write-Host "Results Count: $($Results.count)"

If ($Results.count -gt 0)
{	$Results = $Results | Select ComputerName,Active,Manufacturer,UserFriendlyName,SerialNumber,WeekOfManufacture,YearOfManufacture,Status,Message
	if ($CSVReport)
	{	$Results | Sort Status,ComputerName | Export-CSV -Path $CSVOutputFile -NoTypeInformation
	}
	if ($HTMLReport)
	{	$Results | Sort Status,ComputerName | ConvertTo-HTML -Head $Header | Out-File $HTMLOutputFile
	}
	if ($EmailReportAsHTML)
	{	$Body = $Results | Sort Status,ComputerName | ConvertTo-HTML -Head $Header | Out-String
		Send-MailMessage @SMTPProperties -Body $Body -BodyAsHTML
	}
}
Else
{	Write-Output "There were 0 results in the `$Results array."
}