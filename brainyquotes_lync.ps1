#Load Assembly
$assemblyPath = “C:\Program Files (x86)\Microsoft Office 2013\LyncSDK\Assemblies\Desktop\Microsoft.Lync.Model.DLL”
Import-Module $assemblyPath
$client = [Microsoft.Lync.Model.LyncClient]::GetClient()

#Get Qoute of the Day
$url = "http://feeds.feedburner.com/brainyquote/QUOTEBR"
$data = Invoke-RestMethod -Uri $url
$qotd = $data[0].description

#Publish QoTD to Note 
$instanceSelf = $Client.Self 
$noteInfo = New-Object 'System.Collections.Generic.Dictionary[Microsoft.Lync.Model.PublishableContactInformationType, object]' 
$noteInfo.Add([Microsoft.Lync.Model.PublishableContactInformationType]::PersonalNote, $qotd)
$Publishnote = $instanceSelf.BeginPublishContactInformation($noteInfo, $null, $null) 
$instanceself.EndPublishContactInformation($Publishnote)