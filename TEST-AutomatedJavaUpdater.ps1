<# 
 
.SYNOPSIS 
Java Update
 
.NOTES 

Warn users before executing the script 
 
#> 
 
$ComputerName = "localhost"
function JavaInstall 
   { 
      #Get Java version(s) installed 
      $java = Get-WmiObject -Class win32_product -ComputerName $ComputerName -Filter "Name like '%Java%Update %'" | ForEach-Object {$_.Name} 
      $java | if(!($java = Null)){ 
 
            #Terminate all Java instances 
            $javaPath = (Get-WmiObject -Class win32_process -ComputerName $ComputerName -Filter "ExecutablePath like '%java%'") | ForEach-Object {$_.ProcessId} 
            $javaPath | ForEach-Object {(Get-WmiObject -Class win32_process -ComputerName $ComputerName -Filter "ProcessId='$_'").terminate() | Out-Null} 
             
            $oraclePath = (Get-WmiObject -Class win32_process -ComputerName $ComputerName -Filter "ExecutablePath like '%oracle%'") | ForEach-Object {$_.ProcessId} 
            $oraclePath | ForEach-Object {(Get-WmiObject -Class win32_process -ComputerName $ComputerName -Filter "ProcessId='$_'").terminate() | Out-Null}        
             
            #Terminate IEXPLORER, but only if Java is beeing used 
            if ($javaPath -or $oraclePath)  
                {                 
                    $exeIE = (Get-WmiObject -Class win32_process -ComputerName $ComputerName -Filter "Name='iexplore.exe'") | ForEach-Object {$_.ProcessId} 
                    $exeIE | ForEach-Object {(Get-WmiObject -Class win32_process -ComputerName $ComputerName -Filter "ProcessId='$_'").Terminate() | Out-Null}                    
                } 
 
            #Uninstall Java old version(s) 
            $java | ForEach-Object { 
                                   # Write-Host "$ComputerName : Uninstalling $_" -ForegroundColor White 
                                    (Get-WmiObject -Class win32_product -Filter "Name='$_'" -ComputerName $ComputerName).Uninstall() | Out-Null                             
                                    } 
 
            #Create the temp directory and copy file 
            $temp= [WMICLASS]"\\$ComputerName\ROOT\CIMV2:win32_Process"  
            $temp.Create("cmd.exe /c md c:\temp") | Out-Null 
         
            Copy-Item -Path "\\fs\share02\Java\msi\jre151.msi" -Destination "\\$ComputerName\c$\temp\" -Force 
 
            #Install the application 
          #  Write-Host "$ComputerName : Installing   Java 8 Update" -foregroundcolor White 
            $product= [WMICLASS]"\\$ComputerName\ROOT\CIMV2:win32_Product" 
            $product.Install("c:\temp\jre151.msi") | Out-Null        
      
            #Query new Java version(s) 
            $newJava = Get-WmiObject -Class Win32_Product -ComputerName $ComputerName -Filter "Name like '%Java%'" | Foreach-Object {$_.Name} 
            $newJava | Foreach-Object {Write-Host "$ComputerName : New Java is  $_" -foregroundcolor Green}                      
        } 
    else { 
            $input= "n" 
            Write-Host "$ComputerName : Operation has been canceled!" -foregroundcolor Red 
         } 
    } 
function Main 
    {               
        if (Test-Connection -ComputerName $ComputerName -Quiet -Count 1) 
        { 
          
            JavaInstall 
        } 
        else  
        { 
            exit
        } 
    } 
Main