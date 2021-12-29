 $CtrList = @(
        "\Memory\Available MBytes",
        "\Memory\Committed Bytes",
        "\Processor(*)\% Processor Time",
        "\LogicalDisk(C:)\% Free Space"
        )

$targetList = get-content c:\dev\afmisDevs.txt


Foreach($PC in $targetList){
    #start-job -scriptblock{
    #get-Counter -Counter $CtrList -SampleInterval 5 -ComputerName $PC -maxsamples 10  
    #Sort-Object -Property CookedValue -Descending |
    #Format-Table -Property Path, InstanceName, CookedValue -AutoSize
    #}
    wmic /node:$PC cpu get loadpercentage
    wmic /node:$PC OS get FreePhysicalMemory
}
