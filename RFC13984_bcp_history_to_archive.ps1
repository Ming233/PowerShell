param([string]$bcp_out_folder = "", $servername = "")

if($bcp_out_folder -eq "")
{
	Write-Host "Error! No bcp_out_folder was provided to the PowerShell script!"
	Exit 1
}

if($servername -eq "")
{
	Write-Host "Error! No bcp_out_folder was provided to the PowerShell script!"
	Exit 1
}

<#

$query = "SELECT -1 as [BATCH_ID],
	[JOIN_INTERFACE_CREATION_DATE],
	[JOIN_RECORD_COUNTER],
	[JOIN_RECORD_TOTAL],
	[JOIN_RECORD_TYPE],
	[JOIN_ACTION_CODE],
	[JOIN_FILE_ID],
	[JOIN_ACC_SEQ_NUMBER],
	[JOIN_CHARGE_COUNT_NUMBER],
	[JOIN_EVENT_SEQ_NUMBER],
	[G_JOIN_AGENCY_ID],
	[G_JOIN_AGENCY_FILE_ID],
	[A_JOIN_NEW_ACC_SEQ_NUMBER],
	[A_JOIN_ACCUSED_ID],
	[A_JOIN_NEW_ACCUSED_ID],
	[A_DATE_OF_BIRTH],
	[A_ACC_SEX_CODE],
	[A_ACC_DRIVER_LICENSE],
	[A_ACC_DRIVER_LICENSE_PROV],
	[A_ACC_DRIVER_LICENSE_EXP],
	[A_ACC_LAST_NAME],
	[A_ACC_FIRST_NAME],
	[A_ACC_OTHER_NAME],
	[A_ACC_COMPANY_NAME],
	[A_ACC_ADDRESS],
	[A_ACC_ADDRESS_PROVINCE],
	[A_ACC_ADDRESS_POSTAL_CODE],
	[A_JOIN_ACCUSED_UNIQUE_KEY],
	CONVERT(VARCHAR(24), NULL) as A_JOIN_ACCUSED_NAME_UNIQUE_KEY,
	[A_JOIN_NEW_ACCUSED_UNIQUE_KEY],
	CONVERT(VARCHAR(24), NULL) as A_JOIN_NEW_ACCUSED_NAME_UNIQUE_KEY,
	[C_JOIN_NEW_CHARGE_COUNT_NUMBER],
	[C_JOIN_CHARGE_ACT_CODE],
	[C_JOIN_CHARGE_CODE],
	[C_CHARGE_EFF_DATE],
	[C_OFFENCE_START_DATE],
	[C_OFFENCE_END_DATE],
	[C_OFFENCE_LOCATION_CODE],
	[W_WITNESS_SEQ_NUMBER],
	[W_WITNESS_TYPE_CODE],
	[W_WITNESS_LAST_NAME],
	[W_WITNESS_FIRST_NAME],
	[W_WITNESS_OTHER_NAME],
	[W_WITNESS_AGENCY_ID],
	[W_WITNESS_BADGE_NUMBER],
	[W_CIV_HOME_ADDRESS_LINE1],
	[W_CIV_HOME_ADDRESS_PROVINCE],
	[W_CIV_HOME_ADDRESS_POSTAL_CODE],
	[W_CIV_BUS_ADDRESS_LINE1],
	[W_CIV_BUS_ADDRESS_PROVINCE],
	[W_CIV_BUS_ADDRESS_POSTAL_CODE],
	[P_APRC_FROM_DATE],
	[P_APRC_TO_DATE],
	[P_APRC_TIME],
	[P_APRC_COURT_ID],
	[P_APRC_COURT_ROOM_ID],
	[P_APRC_TYPE_CODE],
	[P_APRC_COMPLETION_CODE],
	[V_EVENT_DATE],
	[V_EVENT_CODE],
	[V_EVENT_DESC],
	[V_JOIN_FILE_STATUS_ID],
	[JOIN_FILE_UNIQUE_KEY],
	[JOIN_FILE_ACCUSED_UNIQUE_KEY],
	CONVERT(VARCHAR(24), NULL) as JOIN_FILE_ACCUSED_CHARGE_UNIQUE_KEY,
	[JOIN_ADDED_USERID],
	[JOIN_ADDED_DATE],
	[JOIN_ADDED_TIME],
	[JOIN_UPDATE_USERID],
	[JOIN_UPDATE_DATE],
	[JOIN_UPDATE_TIME],
	CONVERT(INT, 1) as [PROCESSED],
	CONVERT(INT, 0) as [IGNORE],
        CONVERT(VARCHAR(400), NULL) as [COMMENTS],
        CONVERT(DATETIME, NULL) as [CREATE_DATE],
        CONVERT(DATETIME, NULL) as [PROCESSED_DATE]
FROM PRISM_STAGING..ETL_JOIN_HISTORY_ARCHIVE_2013_05_08"

bcp $query "queryout" "$bcp_out_folder\ETL_JOIN_HISTORY_ARCHIVE_2013_05_08.dat" -S $servername -T -n -m 0 -k -r\n -t ","

bcp "PRISM_STAGING_ARCHIVE..ETL_JOIN_HISTORY_ARCHIVE" "in" "$bcp_out_folder\ETL_JOIN_HISTORY_ARCHIVE_2013_05_08.dat" -S $servername -T -n -m 0 -r\n -t ","

#>

$query = "SELECT -1 as [BATCH_ID]
	  ,[JOIN_INTERFACE_CREATION_DATE]
          ,[JOIN_RECORD_COUNTER]
          ,[JOIN_RECORD_TOTAL]
          ,[JOIN_RECORD_TYPE]
          ,[JOIN_ACTION_CODE]
          ,[JOIN_FILE_ID]
          ,[JOIN_ACC_SEQ_NUMBER]
          ,[JOIN_CHARGE_COUNT_NUMBER]
          ,[JOIN_EVENT_SEQ_NUMBER]
          ,[G_JOIN_AGENCY_ID]
          ,[G_JOIN_AGENCY_FILE_ID]
          ,[A_JOIN_NEW_ACC_SEQ_NUMBER]
          ,[A_JOIN_ACCUSED_ID]
          ,[A_JOIN_NEW_ACCUSED_ID]
          ,[A_DATE_OF_BIRTH]
          ,[A_ACC_SEX_CODE]
          ,[A_ACC_DRIVER_LICENSE]
          ,[A_ACC_DRIVER_LICENSE_PROV]
          ,[A_ACC_DRIVER_LICENSE_EXP]
          ,[A_ACC_LAST_NAME]
          ,[A_ACC_FIRST_NAME]
          ,[A_ACC_OTHER_NAME]
          ,[A_ACC_COMPANY_NAME]
          ,[A_ACC_ADDRESS]
          ,[A_ACC_ADDRESS_PROVINCE]
          ,[A_ACC_ADDRESS_POSTAL_CODE]
          ,[A_JOIN_ACCUSED_UNIQUE_KEY]
          ,[A_JOIN_ACCUSED_NAME_UNIQUE_KEY]
          ,[A_JOIN_NEW_ACCUSED_UNIQUE_KEY]
          ,[A_JOIN_NEW_ACCUSED_NAME_UNIQUE_KEY]
          ,[C_JOIN_NEW_CHARGE_COUNT_NUMBER]
          ,[C_JOIN_CHARGE_ACT_CODE]
          ,[C_JOIN_CHARGE_CODE]
          ,[C_CHARGE_EFF_DATE]
          ,[C_OFFENCE_START_DATE]
          ,[C_OFFENCE_END_DATE]
          ,[C_OFFENCE_LOCATION_CODE]
          ,[W_WITNESS_SEQ_NUMBER]
          ,[W_WITNESS_TYPE_CODE]
          ,[W_WITNESS_LAST_NAME]
          ,[W_WITNESS_FIRST_NAME]
          ,[W_WITNESS_OTHER_NAME]
          ,[W_WITNESS_AGENCY_ID]
          ,[W_WITNESS_BADGE_NUMBER]
          ,[W_CIV_HOME_ADDRESS_LINE1]
          ,[W_CIV_HOME_ADDRESS_PROVINCE]
          ,[W_CIV_HOME_ADDRESS_POSTAL_CODE]
          ,[W_CIV_BUS_ADDRESS_LINE1]
          ,[W_CIV_BUS_ADDRESS_PROVINCE]
          ,[W_CIV_BUS_ADDRESS_POSTAL_CODE]
          ,[P_APRC_FROM_DATE]
          ,[P_APRC_TO_DATE]
          ,[P_APRC_TIME]
          ,[P_APRC_COURT_ID]
          ,[P_APRC_COURT_ROOM_ID]
          ,[P_APRC_TYPE_CODE]
          ,[P_APRC_COMPLETION_CODE]
          ,[V_EVENT_DATE]
          ,[V_EVENT_CODE]
          ,[V_EVENT_DESC]
          ,[V_JOIN_FILE_STATUS_ID]
          ,[JOIN_FILE_UNIQUE_KEY]
          ,[JOIN_FILE_ACCUSED_UNIQUE_KEY]
          ,[JOIN_FILE_ACCUSED_CHARGE_UNIQUE_KEY]
          ,[JOIN_ADDED_USERID]
          ,[JOIN_ADDED_DATE]
          ,[JOIN_ADDED_TIME]
          ,[JOIN_UPDATE_USERID]
          ,[JOIN_UPDATE_DATE]
          ,[JOIN_UPDATE_TIME]
          ,CONVERT(INT, 1) as [PROCESSED]
          ,CONVERT(INT, 0) as [IGNORE]
          ,CONVERT(VARCHAR(400), NULL) as [COMMENTS]
          ,CONVERT(DATETIME, NULL) as [CREATE_DATE]
          ,CONVERT(DATETIME, NULL) as [PROCESSED_DATE]
    FROM PRISM_STAGING..ETL_JOIN_HISTORY etl with(nolock)
    WHERE JOIN_INTERFACE_CREATION_DATE < DATEADD(d, -30, GETDATE())
      AND NOT EXISTS (SELECT 1
                        FROM PRISM_STAGING..ETL_ERRORS err
                       WHERE err.JOIN_FILE_UNIQUE_KEY = etl.JOIN_FILE_UNIQUE_KEY)
    ORDER BY 1, 2"

bcp $query "queryout" "$bcp_out_folder\ETL_JOIN_HISTORY.dat" -S $servername -T -n -m 0 -k -r\n -t ","

bcp "PRISM_STAGING_ARCHIVE..ETL_JOIN_HISTORY_ARCHIVE" "in" "$bcp_out_folder\ETL_JOIN_HISTORY.dat" -S $servername -T -n -m 0 -r\n -t ","

