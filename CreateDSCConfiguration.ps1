configuration MemberServer
{
    param
    (
        [parameter()]
        [string]
        $NodeName = 'AZURW4FH11A0MG1'
    )

    Import-DscResource -ModuleName PowerStig

    Node $NodeName
    {
        WindowsServer Settings
        {
            OsVersion   = '2016'
            OsRole      = 'MS'
            StigVersion = '1.9'
            OrgSettings = "\\fs\Share02\Josh\PowerSTIG\WindowsServer-2016-MS-1.9.org.MG1_01162020.xml"
            #DomainName  = 'SEC.local'
            #ForestName  = 'SEC.local'
            
        }
    }
}

MemberServer -OutputPath \\fs\Share02\Josh\PowerSTIG\


#### Install-Module DSCEA -scope CurrentUser

#### Import-Module dscea

#### Start-DSCEAscan -MofFile "\\fs\Share02\Josh\PowerSTIG\AZURW4FH11A1DC1_DNS.mof" -ComputerName AZURW4FH11A1DC1 -OutputPath \\fs\Share02\Josh\PowerSTIG\DSCEA