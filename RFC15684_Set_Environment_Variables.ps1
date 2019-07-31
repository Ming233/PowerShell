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
write-host "PRISM_SSIS_FTP_HOST:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_FTP_HOST", "Machine"))
write-host "PRISM_SSIS_FTP_USER:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_FTP_USER", "Machine"))
write-host "PRISM_SSIS_FTP_PASS:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_FTP_PASS", "Machine"))
write-host "PRISM_SSIS_JOIN_CHARGES_OEXTRACT_PATH:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_JOIN_CHARGES_OEXTRACT_PATH", "Machine"))
write-host "PRISM_SSIS_JOIN_REFERENCE_FILE_PATH:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_JOIN_REFERENCE_FILE_PATH", "Machine"))
write-host "PRISM_SSIS_PRISM_EXTRACT_DESTINATION:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_PRISM_EXTRACT_DESTINATION", "Machine"))
write-host "PRISM_SSIS_JOIN_FILE_OEXTRACT_PATH:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_JOIN_FILE_OEXTRACT_PATH", "Machine"))
write-host "PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_PATH:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_PATH", "Machine"))
write-host "#######################################"

if($environment -eq "DEV")
{
    if($rollback -eq "Y")
    {
        $PRISM_SSIS_FTP_HOST = ""
        $PRISM_SSIS_FTP_USER = ""
        $PRISM_SSIS_FTP_PASS = ""
        $PRISM_SSIS_JOIN_CHARGES_OEXTRACT_PATH = "ATJNPRS.DEVL.JNKC260E"
        $PRISM_SSIS_JOIN_REFERENCE_FILE_PATH = "ATJNPRS.ACCP.JNKC280E"
        $PRISM_SSIS_PRISM_EXTRACT_DESTINATION = "ATJNPRS.CONV.JNKC250U"
        $PRISM_SSIS_JOIN_FILE_OEXTRACT_PATH = "ATJNPRS.DEVL.JNKC270E"
        $PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_PATH = "ATJNPRS.CONV.RFC9898"
    }
    else
    {
        $PRISM_SSIS_FTP_HOST = "join-dev.protect.ds"
        $PRISM_SSIS_FTP_USER = "FTP-JOIN-PRISM"
        $PRISM_SSIS_FTP_PASS = "Alberta@2015@"
        $PRISM_SSIS_JOIN_CHARGES_OEXTRACT_PATH = "DEV\atjnprs\fromJOIN\Charges\"
        $PRISM_SSIS_JOIN_REFERENCE_FILE_PATH = "DEV\atjnprs\fromJOIN\Reference\"
        $PRISM_SSIS_PRISM_EXTRACT_DESTINATION = "DEV\atjnprs\toJOIN\"
        $PRISM_SSIS_JOIN_FILE_OEXTRACT_PATH = "DEV\atjnprs\fromJOIN\Files\"
        $PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_PATH = "DEV\atjnprs\toJOIN\"
    }    
}
elseif($Environment -eq "UAT")
{
    if($rollback -eq "Y")
    {
        $PRISM_SSIS_FTP_HOST = ""
        $PRISM_SSIS_FTP_USER = ""
        $PRISM_SSIS_FTP_PASS = ""
        $PRISM_SSIS_JOIN_CHARGES_OEXTRACT_PATH = "ATJNPRS.ACCP.JNKC260E"
        $PRISM_SSIS_JOIN_REFERENCE_FILE_PATH = "ATJNPRS.ACCP.JNKC280E"
        $PRISM_SSIS_PRISM_EXTRACT_DESTINATION = "ATJNPRS.ACCP.JNKC250U"
        $PRISM_SSIS_JOIN_FILE_OEXTRACT_PATH = "ATJNPRS.ACCP.JNKC270E"
        $PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_PATH = "ATJNPRS.ACCP.RFC9898"
    }
    else
    {
        $PRISM_SSIS_FTP_HOST = "join-uat.protect.ds"
        $PRISM_SSIS_FTP_USER = "FTP-JOIN-PRISM"
        $PRISM_SSIS_FTP_PASS = "Alberta@2015@"
        $PRISM_SSIS_JOIN_CHARGES_OEXTRACT_PATH = "UAT\atjnprs\fromJOIN\Charges\"
        $PRISM_SSIS_JOIN_REFERENCE_FILE_PATH = "UAT\atjnprs\fromJOIN\Reference\"
        $PRISM_SSIS_PRISM_EXTRACT_DESTINATION = "UAT\atjnprs\toJOIN\"
        $PRISM_SSIS_JOIN_FILE_OEXTRACT_PATH = "UAT\atjnprs\fromJOIN\Files\"
        $PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_PATH = "UAT\atjnprs\toJOIN\"
    }   
}
elseif($Environment -eq "PROD" -or $Environment -eq "PROD_2")
{
    if($rollback -eq "Y")
    {
        $PRISM_SSIS_FTP_HOST = ""
        $PRISM_SSIS_FTP_USER = ""
        $PRISM_SSIS_FTP_PASS = ""
        $PRISM_SSIS_JOIN_CHARGES_OEXTRACT_PATH = "ATJNPRS.PROD.JNKC260E"
        $PRISM_SSIS_JOIN_REFERENCE_FILE_PATH = "ATJNPRS.PROD.JNKC280E"
        $PRISM_SSIS_PRISM_EXTRACT_DESTINATION = "ATJNPRS.PROD.JNKC250U"
        $PRISM_SSIS_JOIN_FILE_OEXTRACT_PATH = "ATJNPRS.PROD.JNKC270E"
        $PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_PATH = "ATJNPRS.PROD.RFC9898"
    }
    else
    {
        $PRISM_SSIS_FTP_HOST = "join.protect.ds"
        $PRISM_SSIS_FTP_USER = "FTP-JOIN-PRISM"
        $PRISM_SSIS_FTP_PASS = "Alberta@2015@"
        $PRISM_SSIS_JOIN_CHARGES_OEXTRACT_PATH = "PROD\atjnprs\fromJOIN\Charges\"
        $PRISM_SSIS_JOIN_REFERENCE_FILE_PATH = "PROD\atjnprs\fromJOIN\Reference\"
        $PRISM_SSIS_PRISM_EXTRACT_DESTINATION = "PROD\atjnprs\toJOIN\"
        $PRISM_SSIS_JOIN_FILE_OEXTRACT_PATH = "PROD\atjnprs\fromJOIN\Files\"
        $PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_PATH = "PROD\atjnprs\toJOIN\"
    }   
}



[Environment]::SetEnvironmentVariable("PRISM_SSIS_FTP_HOST", $PRISM_SSIS_FTP_HOST, "Machine")
[Environment]::SetEnvironmentVariable("PRISM_SSIS_FTP_USER", $PRISM_SSIS_FTP_USER, "Machine")
[Environment]::SetEnvironmentVariable("PRISM_SSIS_FTP_PASS", $PRISM_SSIS_FTP_PASS, "Machine")
[Environment]::SetEnvironmentVariable("PRISM_SSIS_JOIN_CHARGES_OEXTRACT_PATH", $PRISM_SSIS_JOIN_CHARGES_OEXTRACT_PATH, "Machine")
[Environment]::SetEnvironmentVariable("PRISM_SSIS_JOIN_REFERENCE_FILE_PATH", $PRISM_SSIS_JOIN_REFERENCE_FILE_PATH, "Machine")
[Environment]::SetEnvironmentVariable("PRISM_SSIS_PRISM_EXTRACT_DESTINATION", $PRISM_SSIS_PRISM_EXTRACT_DESTINATION, "Machine")
[Environment]::SetEnvironmentVariable("PRISM_SSIS_JOIN_FILE_OEXTRACT_PATH", $PRISM_SSIS_JOIN_FILE_OEXTRACT_PATH, "Machine")
[Environment]::SetEnvironmentVariable("PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_PATH", $PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_PATH, "Machine")


write-host ""
write-host "#### Environment Variables AFTER ####"
write-host "PRISM_SSIS_FTP_HOST:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_FTP_HOST", "Machine"))
write-host "PRISM_SSIS_FTP_USER:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_FTP_USER", "Machine"))
write-host "PRISM_SSIS_FTP_PASS:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_FTP_PASS", "Machine"))
write-host "PRISM_SSIS_JOIN_CHARGES_OEXTRACT_PATH:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_JOIN_CHARGES_OEXTRACT_PATH", "Machine"))
write-host "PRISM_SSIS_JOIN_REFERENCE_FILE_PATH:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_JOIN_REFERENCE_FILE_PATH", "Machine"))
write-host "PRISM_SSIS_PRISM_EXTRACT_DESTINATION:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_PRISM_EXTRACT_DESTINATION", "Machine"))
write-host "PRISM_SSIS_JOIN_FILE_OEXTRACT_PATH:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_JOIN_FILE_OEXTRACT_PATH", "Machine"))
write-host "PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_PATH:"([Environment]::GetEnvironmentVariable("PRISM_SSIS_PRISM_FILE_LIST_EXTRACT_PATH", "Machine"))
write-host "#######################################"

ExitWithCode 0
