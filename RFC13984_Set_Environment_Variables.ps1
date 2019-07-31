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
write-host "PRISM_SSIS_FTP_PowerShell_Script_Path:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_FTP_PowerShell_Script_Path", "Machine"))
write-host "PRISM_SSIS_FTP_USE_SFTP:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_FTP_USE_SFTP", "Machine"))
write-host "#######################################"

if($environment -eq "DEV")
{
    if($rollback -eq "Y")
    {
        $PRISM_SSIS_FTP_PowerShell_Script_Path = ""
        $PRISM_SSIS_FTP_USE_SFTP = ""
    }
    else
    {
        $PRISM_SSIS_FTP_PowerShell_Script_Path = "\\protect.ds\jss\PRISM_DEV\PRISM_SSIS\JOIN_Interface\FTP\PRISM_FTP.ps1"
        $PRISM_SSIS_FTP_USE_SFTP = "off"
    }    
}
elseif($Environment -eq "UAT")
{
    if($rollback -eq "Y")
    {
        $PRISM_SSIS_FTP_PowerShell_Script_Path = ""
        $PRISM_SSIS_FTP_USE_SFTP = ""
    }
    else
    {
        $PRISM_SSIS_FTP_PowerShell_Script_Path = "\\protect.ds\jss\PRISM_UAT\PRISM_SSIS\JOIN_Interface\FTP\PRISM_FTP.ps1"
        $PRISM_SSIS_FTP_USE_SFTP = "off"
    }   
}
elseif($Environment -eq "PROD" -or $Environment -eq "PROD_2")
{
    if($rollback -eq "Y")
    {
        $PRISM_SSIS_FTP_PowerShell_Script_Path = ""
        $PRISM_SSIS_FTP_USE_SFTP = ""
    }
    else
    {
        $PRISM_SSIS_FTP_PowerShell_Script_Path = "\\protect.ds\jss\PRISM_PROD\PRISM_SSIS\JOIN_Interface\FTP\PRISM_FTP.ps1"
        $PRISM_SSIS_FTP_USE_SFTP = "off"
    }   
}



[Environment]::SetEnvironmentVariable("PRISM_SSIS_FTP_PowerShell_Script_Path", $PRISM_SSIS_FTP_PowerShell_Script_Path, "Machine")
[Environment]::SetEnvironmentVariable("PRISM_SSIS_FTP_USE_SFTP", $PRISM_SSIS_FTP_USE_SFTP, "Machine")


write-host ""
write-host "#### Environment Variables AFTER ####"
write-host "PRISM_SSIS_FTP_PowerShell_Script_Path:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_FTP_PowerShell_Script_Path", "Machine"))
write-host "PRISM_SSIS_FTP_USE_SFTP:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_FTP_USE_SFTP", "Machine"))
write-host "#######################################"

ExitWithCode 0
