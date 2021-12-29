$users = Get-ChildItem c:\users | ?{ $_.PSIsContainer }
foreach ($user in $users){

    $ODAppDatapath = "C:\Users\$user\AppData\Local\Microsoft\OneDrive"
    Try{
        If(Test-Path $ODAppDatapath){
            $lockedfiles = (gci $ODAppDatapath -Recurse -filter 'FileSyncShell*').FullName 
            Foreach($lockedFile in $lockedfiles){
                Add-Content -Value "Attempting to Delete $lockedFile" -path C:\errors.txt 
                Get-Process | foreach{$processVar = $_;$_.Modules | foreach{if($_.FileName -eq $lockedFile){$processVar.Name + " PID:" + $processVar.id}}} | Stop-Process $_ -force
                }
        RMDIR $ODAppDatapath -Recurse -ErrorVariable errs -ErrorAction SilentlyContinue -force
        Start-Process Explorer.exe
            Foreach($lockedFile in $lockedfiles){If(test-path $lockedFile){Add-Content -value "Unable to remove $lockedFile" -Path C:\errors.txt}}
    }
    } 
    catch {
        "$errs" | Out-File C:\errors.txt -append
    }
    
}