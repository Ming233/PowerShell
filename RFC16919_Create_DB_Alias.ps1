param([string]$AliasName = "", $InstanceName = "", $PortNumber = "")

#$AliasName = "PRISMDB"
#$InstanceName = "DEVM12A"
#$PortNumber = 1404

function ExitWithCode($value)
{ 
    $global:returnvalue = $value
    exit
} 

if($AliasName -eq "" -or $InstanceName -eq "" -or $PortNumber -eq "")
{
    write-host "ERROR! The command line parameters must have values for AliasName, InstanceName, and PortNumber. The values passed in are:`r`n<AliasName: $aliasname>`r`n<InstanceName: $InstanceName>`r`n<PortNumber: $PortNumber>" -ForegroundColor red
    ExitWithCode -1
}


$ServerName = Get-Content Env:Computername

 
## The Aliase is stord in the registry here i'm seting the 
## REG path for the Alias 32 & 64
$Bit32 = "HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo"
$bit64 = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo"
 
## chect if the ConnectTo SubFolder 
## exist in the registry if not it will create it.
If((Test-Path -Path $Bit32)-ne $true)
    {$writable = $true
        $key = (get-item HKLM:\).OpenSubKey("SOFTWARE\Microsoft\MSSQLServer\Client", $writable).CreateSubKey("ConnectTo")
    }
    If((Test-Path -Path $Bit64)-ne $true)
    {        $key = (get-item HKLM:\).OpenSubKey("SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client", $writable).CreateSubKey("ConnectTo")
 
    }
 
## Create the TCPAlias
$TCPAliasName="DBMSSOCN,"+$ServerName+"\"+$InstanceName+","+$PortNumber
New-ItemProperty -Path $Bit32 -Name $AliasName -PropertyType string -Value $TCPAliasName
New-ItemProperty -Path $Bit64 -Name $AliasName -PropertyType string -Value $TCPAliasName 

ExitWithCode 0
