$FoldersToCopy = @(
    'Desktop'
    'Downloads'
    'Favorites'
    'Documents'
    'Pictures'
    'Videos'
    'AppData\Local\Google'
    )

$ConfirmComp = $null
$ConfirmUser = $null

while( $ConfirmComp -ne 'y' ){
    $Computer = Read-Host -Prompt 'Enter the computer to copy from'

    if( -not ( Test-Connection -ComputerName $Computer -Count 2 -Quiet ) ){
        Write-Warning "$Computer is not online. Please enter another computer name."
        continue
        }

    $ConfirmComp = Read-Host -Prompt "The entered computer name was:`t$Computer`r`nIs this correct? (y/n)"
    }

while( $ConfirmUser -ne 'y' ){
    $User = Read-Host -Prompt 'Enter the user profile to copy from'

    if( -not ( Test-Path -Path "\\$Computer\c$\Users\$User" -PathType Container ) ){
        Write-Warning "$User could not be found on $Computer. Please enter another user profile."
        continue
        }

    $ConfirmUser = Read-Host -Prompt "The entered user profile was:`t$User`r`nIs this correct? (y/n)"
    }

$SourceRoot      = "\\$Computer\c$\Users\$User"
$DestinationRoot = "C:\Users\$User"

foreach( $Folder in $FoldersToCopy ){
    $Source      = Join-Path -Path $SourceRoot -ChildPath $Folder
    $Destination = Join-Path -Path $DestinationRoot -ChildPath $Folder

    if( -not ( Test-Path -Path $Source -PathType Container ) ){
        Write-Warning "Could not find path`t$Source"
        continue
        }

    Robocopy.exe $Source $Destination /E /IS /NP /NFL
    }