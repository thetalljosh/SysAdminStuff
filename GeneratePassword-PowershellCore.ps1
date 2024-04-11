$symbols = '!@#$%^&*'.ToCharArray()
$characterList = 'a'..'z' + 'A'..'Z' + '0'..'9' + $symbols
function GeneratePassword {
    param(
        [Parameter(Mandatory = $false)]
        [ValidateRange(12, 256)]
        [int] 
        $length = 14
    )
    
    $passwordBuilder = New-Object System.Text.StringBuilder
    do {
        $passwordBuilder.Clear()
        for ($i = 0; $i -lt $length; $i++) {
            $randomIndex = [System.Security.Cryptography.RandomNumberGenerator]::GetInt32(0, $characterList.Length)
            $passwordBuilder.Append($characterList[$randomIndex]) | Out-Null
        }

        $password = $passwordBuilder.ToString()
        $charChecks = @{
            'Lowercase' = $password -cmatch '[a-z]'
            'Uppercase' = $password -cmatch '[A-Z]'
            'Digit'     = $password -match '[0-9]'
            'Symbol'    = $password.IndexOfAny($symbols) -ne -1
        }

    }
    until ($charChecks.Values.Where({$_}).Count -ge 3)
    
    $password | ConvertTo-SecureString -AsPlainText
}
