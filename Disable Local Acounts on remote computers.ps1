$computers = @('LEEEWKSECLAAUS4','LEEEWKSECLAAUS4','LEEEWKSECLABAI2','LEEEWKSECLAHAS2','LEEEWKSECLALIN2','LEEEWKSECLAMAR2','LEEEWKSECLAMOO2','LEEEWKSECLAPAK2','LEEEWKSECLAPAR2','LEEEWKSECLAPHU2','LEEEWKSECLAPHU2','LEEEWKSECLAPRI2','LEEEWKSECLAROB2','LEEEWKSECLATHO2','LEEEWKSECLAUPD2')
$users = @('George_Robertson','Phu_Nguyen','s.bailey','lhastings','Franklin_Lingerfelt','jm','jmoore','c.pak','jcp','Phu_Nguyen','George_Robertson','npride2','George_Robertson','mikethompson','d.updike')
$i = 0
while($i -lt $computers.Length){
$comname = $computers[$i]
$uname = $users[$i]
invoke-command -computername $comname -ScriptBlock{get-localuser -name $using:uname}
invoke-command -computername $comname -ScriptBlock{Remove-LocalGroupMember -group administrator -member $using:uname}
$i++
}

