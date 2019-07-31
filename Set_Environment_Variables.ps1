param([string]$Environment = "", $rollback = "")


function ExitWithCode($value)
{ 
    $global:returnvalue = $value
    exit
} 

if($environment -ne "DEV" -and $environment -ne "UAT" -and $environment -ne "PROD" -and $environment -ne "PROD_2")
{
    write-host "ERROR! The Environment command line parameter must be set to DEV, UAT, PROD, or PROD_2. It is set to <$environment>." -ForegroundColor red
    ExitWithCode -1
}


write-host "Environment is: $environment ---- rollback is: $rollback"

write-host "#### Environment Variables BEFORE ####"
write-host "PRISM_SSIS_CONNECTIONS:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_CONNECTIONS"))
write-host "PRISM_SSIS_FTP_HOST:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_FTP_HOST", "Machine"))
write-host "PRISM_SSIS_FTP_PASS:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_FTP_PASS", "Machine"))
write-host "PRISM_SSIS_FTP_PowerShell_Script_Path:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_FTP_PowerShell_Script_Path", "Machine"))
write-host "PRISM_SSIS_FTP_USE_SFTP:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_FTP_USE_SFTP", "Machine"))
write-host "PRISM_SSIS_FTP_USER:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_FTP_USER", "Machine"))
write-host "PRISM_SSIS_GetFTPFileOfficers:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_GetFTPFileOfficers", "Machine"))
write-host "PRISM_SSIS_JOIN_CHARGES_OEXTRACT_PATH:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_JOIN_CHARGES_OEXTRACT_PATH", "Machine"))
write-host "PRISM_SSIS_JOIN_FILE_OEXTRACT_PATH:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_JOIN_FILE_OEXTRACT_PATH", "Machine"))
write-host "PRISM_SSIS_JOIN_REFERENCE_FILE_PATH:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_JOIN_REFERENCE_FILE_PATH", "Machine"))
write-host "PRISM_SSIS_PATH:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_PATH", "Machine"))
write-host "PRISM_SSIS_PRISM_EXTRACT_DESTINATION:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_PRISM_EXTRACT_DESTINATION", "Machine"))
write-host "PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_FILENAME:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_FILENAME", "Machine"))
write-host "PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_PATH:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_PATH", "Machine"))
write-host "#######################################"

if($rollback -eq "Y")
{
	$PRISM_SSIS_CONNECTIONS = $null
	$PRISM_SSIS_FTP_HOST = $null
	$PRISM_SSIS_FTP_PASS = $null
	$PRISM_SSIS_FTP_PowerShell_Script_Path = $null
	$PRISM_SSIS_FTP_USE_SFTP = $null
	$PRISM_SSIS_FTP_USER = $null
	$PRISM_SSIS_GetFTPFileOfficers = $null
	$PRISM_SSIS_JOIN_CHARGES_OEXTRACT_PATH = $null
	$PRISM_SSIS_JOIN_FILE_OEXTRACT_PATH = $null
	$PRISM_SSIS_JOIN_REFERENCE_FILE_PATH = $null
	$PRISM_SSIS_PATH = $null
	$PRISM_SSIS_PRISM_EXTRACT_DESTINATION = $null
	$PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_FILENAME = $null
	$PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_PATH = $null
}
elseif($environment -eq "DEV")
{
	$PRISM_SSIS_PATH = "\\protect.ds\jss\PRISM_DEV\PRISM_SSIS"
	$PRISM_SSIS_CONNECTIONS = "%PRISM_SSIS_PATH%\ConfigFiles\SSISConnections_DEV.dtsConfig"
	$PRISM_SSIS_FTP_HOST = "join-dev.protect.ds"
	$PRISM_SSIS_FTP_PASS = "Alberta@2015@"
	$PRISM_SSIS_FTP_PowerShell_Script_Path = "\\protect.ds\jss\PRISM_DEV\PRISM_SSIS\JOIN_Interface\FTP\PRISM_FTP.ps1"
	$PRISM_SSIS_FTP_USE_SFTP = "off"
	$PRISM_SSIS_FTP_USER = "FTP-JOIN-PRISM"
	$PRISM_SSIS_GetFTPFileOfficers = "%PRISM_SSIS_PATH%\JOIN_to_PRISM_Officer_Load\ConfigFiles\GetFTPFileOfficers_DEV.dtsConfig"
	$PRISM_SSIS_JOIN_CHARGES_OEXTRACT_PATH = "DEV\atjnprs\fromJOIN\Charges\"
	$PRISM_SSIS_JOIN_FILE_OEXTRACT_PATH = "DEV\atjnprs\fromJOIN\Files\"
	$PRISM_SSIS_JOIN_REFERENCE_FILE_PATH = "DEV\atjnprs\fromJOIN\Reference\"
	$PRISM_SSIS_PRISM_EXTRACT_DESTINATION = "DEV\atjnprs\toJOIN\"
	$PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_FILENAME = "FACCCHG"
	$PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_PATH = "DEV\atjnprs\toJOIN\"
}    
elseif($Environment -eq "UAT")
{
	$PRISM_SSIS_PATH = "\\protect.ds\jss\PRISM_UAT\PRISM_SSIS"
	$PRISM_SSIS_CONNECTIONS = "%PRISM_SSIS_PATH%\ConfigFiles\SSISConnections_UAT.dtsConfig"
	$PRISM_SSIS_FTP_HOST = "join-uat.protect.ds"
	$PRISM_SSIS_FTP_PASS = "Alberta@2015@"
	$PRISM_SSIS_FTP_PowerShell_Script_Path = "\\protect.ds\jss\PRISM_UAT\PRISM_SSIS\JOIN_Interface\FTP\PRISM_FTP.ps1"
	$PRISM_SSIS_FTP_USE_SFTP = "off"
	$PRISM_SSIS_FTP_USER = "FTP-JOIN-PRISM"
	$PRISM_SSIS_GetFTPFileOfficers = "%PRISM_SSIS_PATH%\JOIN_to_PRISM_Officer_Load\ConfigFiles\GetFTPFileOfficers_UAT.dtsConfig"
	$PRISM_SSIS_JOIN_CHARGES_OEXTRACT_PATH = "UAT\atjnprs\fromJOIN\Charges\"
	$PRISM_SSIS_JOIN_FILE_OEXTRACT_PATH = "UAT\atjnprs\fromJOIN\Files\"
	$PRISM_SSIS_JOIN_REFERENCE_FILE_PATH = "UAT\atjnprs\fromJOIN\Reference\"
	$PRISM_SSIS_PRISM_EXTRACT_DESTINATION = "UAT\atjnprs\toJOIN\"
	$PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_FILENAME = "FACCCHG"
	$PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_PATH = "UAT\atjnprs\toJOIN\"
}
elseif($Environment -eq "PROD" -or $Environment -eq "PROD_2")
{
	$PRISM_SSIS_PATH = "\\protect.ds\jss\PRISM_PROD\PRISM_SSIS"
	$PRISM_SSIS_CONNECTIONS = "%PRISM_SSIS_PATH%\ConfigFiles\SSISConnections_PROD.dtsConfig"
	$PRISM_SSIS_FTP_HOST = "join.protect.ds"
	$PRISM_SSIS_FTP_PASS = "Alberta@2015@"
	$PRISM_SSIS_FTP_PowerShell_Script_Path = "\\protect.ds\jss\PRISM_PROD\PRISM_SSIS\JOIN_Interface\FTP\PRISM_FTP.ps1"
	$PRISM_SSIS_FTP_USE_SFTP = "off"
	$PRISM_SSIS_FTP_USER = "FTP-JOIN-PRISM"
	$PRISM_SSIS_GetFTPFileOfficers = "%PRISM_SSIS_PATH%\JOIN_to_PRISM_Officer_Load\ConfigFiles\GetFTPFileOfficers_PROD.dtsConfig"
	$PRISM_SSIS_JOIN_CHARGES_OEXTRACT_PATH = "PROD\atjnprs\fromJOIN\Charges\"
	$PRISM_SSIS_JOIN_FILE_OEXTRACT_PATH = "PROD\atjnprs\fromJOIN\Files\"
	$PRISM_SSIS_JOIN_REFERENCE_FILE_PATH = "PROD\atjnprs\fromJOIN\Reference\"
	$PRISM_SSIS_PRISM_EXTRACT_DESTINATION = "PROD\atjnprs\toJOIN\"
	$PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_FILENAME = "FACCCHG"
	$PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_PATH = "PROD\atjnprs\toJOIN\"
}

[Environment]::SetEnvironmentVariable("PRISM_SSIS_CONNECTIONS", $PRISM_SSIS_CONNECTIONS, "Machine")
[Environment]::SetEnvironmentVariable("PRISM_SSIS_FTP_HOST", $PRISM_SSIS_FTP_HOST, "Machine")
[Environment]::SetEnvironmentVariable("PRISM_SSIS_FTP_PASS", $PRISM_SSIS_FTP_PASS, "Machine")
[Environment]::SetEnvironmentVariable("PRISM_SSIS_FTP_PowerShell_Script_Path", $PRISM_SSIS_FTP_PowerShell_Script_Path, "Machine")
[Environment]::SetEnvironmentVariable("PRISM_SSIS_FTP_USE_SFTP", $PRISM_SSIS_FTP_USE_SFTP, "Machine")
[Environment]::SetEnvironmentVariable("PRISM_SSIS_FTP_USER", $PRISM_SSIS_FTP_USER, "Machine")
[Environment]::SetEnvironmentVariable("PRISM_SSIS_GetFTPFileOfficers", $PRISM_SSIS_GetFTPFileOfficers, "Machine")
[Environment]::SetEnvironmentVariable("PRISM_SSIS_JOIN_CHARGES_OEXTRACT_PATH", $PRISM_SSIS_JOIN_CHARGES_OEXTRACT_PATH, "Machine")
[Environment]::SetEnvironmentVariable("PRISM_SSIS_JOIN_FILE_OEXTRACT_PATH", $PRISM_SSIS_JOIN_FILE_OEXTRACT_PATH, "Machine")
[Environment]::SetEnvironmentVariable("PRISM_SSIS_JOIN_REFERENCE_FILE_PATH", $PRISM_SSIS_JOIN_REFERENCE_FILE_PATH, "Machine")
[Environment]::SetEnvironmentVariable("PRISM_SSIS_PATH", $PRISM_SSIS_PATH, "Machine")
[Environment]::SetEnvironmentVariable("PRISM_SSIS_PRISM_EXTRACT_DESTINATION", $PRISM_SSIS_PRISM_EXTRACT_DESTINATION, "Machine")
[Environment]::SetEnvironmentVariable("PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_FILENAME", $PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_FILENAME, "Machine")
[Environment]::SetEnvironmentVariable("PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_PATH", $PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_PATH, "Machine")


write-host ""
write-host "#### Environment Variables AFTER ####"
write-host "PRISM_SSIS_CONNECTIONS:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_CONNECTIONS", "Machine"))
write-host "PRISM_SSIS_FTP_HOST:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_FTP_HOST", "Machine"))
write-host "PRISM_SSIS_FTP_PASS:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_FTP_PASS", "Machine"))
write-host "PRISM_SSIS_FTP_PowerShell_Script_Path:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_FTP_PowerShell_Script_Path", "Machine"))
write-host "PRISM_SSIS_FTP_USE_SFTP:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_FTP_USE_SFTP", "Machine"))
write-host "PRISM_SSIS_FTP_USER:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_FTP_USER", "Machine"))
write-host "PRISM_SSIS_GetFTPFileOfficers:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_GetFTPFileOfficers", "Machine"))
write-host "PRISM_SSIS_JOIN_CHARGES_OEXTRACT_PATH:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_JOIN_CHARGES_OEXTRACT_PATH", "Machine"))
write-host "PRISM_SSIS_JOIN_FILE_OEXTRACT_PATH:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_JOIN_FILE_OEXTRACT_PATH", "Machine"))
write-host "PRISM_SSIS_JOIN_REFERENCE_FILE_PATH:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_JOIN_REFERENCE_FILE_PATH", "Machine"))
write-host "PRISM_SSIS_PATH:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_PATH", "Machine"))
write-host "PRISM_SSIS_PRISM_EXTRACT_DESTINATION:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_PRISM_EXTRACT_DESTINATION", "Machine"))
write-host "PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_FILENAME:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_FILENAME", "Machine"))
write-host "PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_PATH:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_PATH", "Machine"))
write-host "#######################################"

ExitWithCode 0
