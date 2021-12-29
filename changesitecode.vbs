sSiteCode = "SEC"
sMachine = "localhost"
set oCCMNamespace = GetObject("winmgmts://" & sMachine & "/root/ccm")
Set oInstance = oCCMNamespace.Get("SMS_Client")
set oParams = oInstance.Methods_("SetAssignedSite").inParameters.SpawnInstance_()
oParams.sSiteCode = sSiteCode
oCCMNamespace.ExecMethod "SMS_Client", "SetAssignedSite", oParams 