
$outputDirectory = "C:\Dev\Performance Counters" #Directory where the restult file will be stored.
$ComputerList = (get-content 'C:\dev\DiskPerfList.txt')

$sampleInterval = 15 #Collection interval in seconds.
$maxSamples = 360 #How many samples should be collected at the interval specified. Set to 0 for continuous collection. 720 at 5 seconds would be an hour of collection
 
#Check to see if the output directory exists. If not, create it. 
if (-not(Test-Path $outputDirectory))
    {
        Write-Host "Output directory does not exist. Directory will be created."
        $null = New-Item -Path $outputDirectory -ItemType "Directory"
        Write-Host "Output directory created."
    }
 
#Strip the \ off the end of the directory if necessary. 
if ($outputDirectory.EndsWith("\")) {$outputDirectory = $outputDirectory.Substring(0, $outputDirectory.Length - 1)}


#Create the name of the output file in the format of "computer date time.csv".
$outputFile = "$outputDirectory\AFMISDev $(Get-Date -Format "yyyy_MM_dd HH_mm_ss").csv"

#Specify the list of performance counters to collect.
$counters =
    @(`
    "\Processor(_Total)\% Processor Time" `
    ,"\Memory\Available MBytes" `
    ,"\Paging File(_Total)\% Usage" `
    ,"\LogicalDisk(*)\% Free Space" `
    ,"\PhysicalDisk(*)\% Disk Read Time" `
    ,"\PhysicalDisk(*)\% Disk Time" `
    ,"\PhysicalDisk(*)\% Disk Write Time" `
    ,"\PhysicalDisk(*)\% Idle Time" `
    ,"\PhysicalDisk(*)\Current Disk Queue Length" `
    ,"\PhysicalDisk(*)\Disk Reads/sec" `
    ,"\PhysicalDisk(*)\Disk Writes/sec" `
    ,"\PhysicalDisk(*)\Split IO/Sec" 

    )
 
#Set the variables for the Get-Counter cmdlet.
$variables = @{
    SampleInterval = $sampleInterval
    Counter = $counters
}
     
#Either set the sample interval or specify to collect continuous.
if ($maxSamples -eq 0) {$variables.Add("Continuous",1)}
else {$variables.Add("MaxSamples","$maxSamples")}

#Write the parameters to the screen.
Write-Host "
 
Collecting counters from $ComputerList...
Press Ctrl+C to exit."


#Show the variables then execute the command while storing the results in a file.
$variables

Get-Counter @Variables -ComputerName $ComputerList| Export-Counter -FileFormat csv -Path $outputFile -Force
