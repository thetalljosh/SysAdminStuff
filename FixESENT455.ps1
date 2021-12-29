$PC = (Read-Host "Enter PC Name to Repair")
if(Test-NetConnection $PC){
    if(test-path \\$PC\C$\Windows\system32\config\systemprofile\AppData\Local\TileDataLayer){
        write-host "TileDataLayer exists on $PC!"
        }
        else{
            mkdir \\$PC\C$\Windows\system32\config\systemprofile\AppData\Local\TileDataLayer
            }
    if(Test-Path \\$PC\C$\Windows\system32\config\systemprofile\AppData\Local\Database){
        write-host "Database folder exists on $PC!"}
        else{
            mkdir \\$PC\C$\Windows\system32\config\systemprofile\AppData\Local\Database
            }
    write-host "Created folders on $PC"
}
else{
write-host "Unable to reach $PC"}