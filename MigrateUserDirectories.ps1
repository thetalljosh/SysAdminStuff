$FoldersToCopy = @(
    'Desktop'
    'Downloads'
    'Favorites'
    'Documents'
    'Pictures'
    'Videos'
    'AppData\Local\Google'
    'AppData\Local\Mozilla'
    )
$ConfirmSrcComp = $null
$ConfirmUser = $null
$ConfirmDestComp = $null

while( $ConfirmSrcComp -ne 'y' ){
    $SrcComputer = Read-Host -Prompt 'Enter the computer to copy from'

    if( -not ( Test-Connection -ComputerName $SrcComputer -Count 2 -Quiet ) ){
        Write-Warning "$SrcComputer is not online. Please enter another computer name."
        continue
        }

    $ConfirmSrcComp = Read-Host -Prompt "The entered computer name was:`t$SrcComputer`r`nIs this correct? (y/n)"
    }

while( $ConfirmUser -ne 'y' ){
    $User = Read-Host -Prompt 'Enter the user profile to copy from'

    if( -not ( Test-Path -Path "\\$SrcComputer\c$\Users\$User" -PathType Container ) ){
        Write-Warning "$User could not be found on $SrcComputer. Please enter another user profile."
        continue
        }

    $ConfirmUser = Read-Host -Prompt "The entered user profile was:`t$User`r`nIs this correct? (y/n)"
    }

while( $ConfirmDestComp -ne 'y' ){
    $DestComputer = Read-Host -Prompt 'Enter the computer to migrate to'
    <#
    if( -not ( Test-Connection -ComputerName $DestComputer -Count 2 -Quiet ) ){
        Write-Warning "$DestComputer is not online. Please confirm computer is online and try again."
        continue
        }
        #>
    $ConfirmDestComp = Read-Host -Prompt "The entered computer name was:`t$DestComputer`r`nIs this correct? (y/n)"
    }

$SourceRoot      = "\\$SrcComputer\C$\Users\$User"
$DestinationRoot = "\\$DestComputer\C$\Users\$User"

foreach( $Folder in $FoldersToCopy ){
    $Source      = Join-Path -Path $SourceRoot -ChildPath $Folder
    $Destination = Join-Path -Path $DestinationRoot -ChildPath $Folder

    if( -not ( Test-Path -Path $Source -PathType Container ) ){
        Write-Warning "Could not find path`t$Source"
        continue
        }

    Robocopy.exe $Source $Destination /E /log+:$DestinationRoot\MigrationLog.txt /TEE /MT:8
    }

