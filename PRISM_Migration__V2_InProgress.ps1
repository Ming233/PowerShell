param([string]$h = "", [string]$JSON_File = "", $StepsOutput = "", $JSON_File_svnfolder = "", $JSON_File_svnrevision = "", $working_Folder = "", $Environment = "")

try{
  stop-transcript|out-null
}
catch [System.InvalidOperationException]{}

try{
  Add-PSSnapin SqlServerCmdletSnapin120 | out-null
}
catch [System.InvalidOperationException]{}

try{
  Add-PSSnapin SqlServerProviderSnapin120 | out-null
}
catch [System.InvalidOperationException]{}

try{
    Add-Type -AssemblyName System.Web | Out-Null
}
catch [System.InvalidOperationException]{}

if($h -gt "")
{
    write-host "Parameters for this script are:"
    write-host "    -JSON_File <name of the JSON File>"
    write-host "    -JSON_File_svnfolder <SVN Folder where the JSON file can be found.>"
    write-host "    -JSON_File_svnrevision <revision number of the JSON File>"
    write-host "    -working_Folder <optional, name of the folder this script will put all of the files into for processing>"
    write-host "    -Environment <name of the environment this script is being run against. i.e. DEV or UAT or PROD>"
    write-host "    -StepsOutput <Y or N - Y will just output the steps without executing the script>"
    write-host "Example:"
    write-host ".\PRISM_Migration.ps1 -JSON_FILE myjson.json -JSON_File_svnfolder 'PRISM_DB\branches\1.13\DEPLOYMENT_SCRIPTS' -JSON_File_svnrevision head -Environment DEV -StepsOutput Y"
    exit
}

# Set up the SVN stuff.
$SVNIncludeFile = "$PSScriptRoot\Include-Subversion.ps1"
if (!(Test-Path $SVNIncludeFile)){Write-Error "Include Script Not Found: $SVNIncludeFile"; exit script}
. $SVNIncludeFile


Function Main
{

    ######################################################
    # Begin to process command line parameters etc.
    ######################################################

    if($JSON_File -eq "")
    {
        $JSON_File = Read-Host "Please provide the name of the JSON file to be processed, or just hit Enter to quit."

        if($JSON_File -eq "")
        {
            exit
        }
    }


    if($JSON_File_svnfolder -gt "")
    {
        if($working_Folder -eq "")
        {
            $i = $JSON_File.LastIndexOf(".json")
            if($i -gt 0)
            {
                $working_folder = $JSON_File.Substring(0, $i)
            }
            else
            {
                $working_Folder = $JSON_File
            }
        }

        $working_Folder = "$PSScriptRoot\$working_folder"

        Download_File_From_SVN $JSON_File $JSON_File_svnfolder $JSON_File_svnrevision $working_folder

        $JSON_File = "$working_folder\$JSON_File"
    }

    $script:master_JSON_File = $JSON_File
    $JSON_File = ""

    if(!(Test-Path($script:master_JSON_File)))
    {
        RaiseError "Can't find the json file: $script:master_JSON_File" false
    }

    $svnfolder = ""
    $svnrevision = ""

    $Script:ScriptEnvironment = ""
    $Script:Environment = $Environment
    if($Script:Environment -gt "")
    {
        Set_Environment
    }

    $Script:globalvariablesforfunctions = ""

    $Script:variablesforfunction = ""
    $pause_text = ""
    $db_to_rename = ""
    $new_db_name = ""
    $raise_error_if_rename_not_needed = ""

    $rename_database_file = "$PSScriptRoot\Rename_Database.sql"

    $CurrentDate = get-date -Format "yyyy-MM-dd-hhmmss"

    $JSON_File_Dir = (get-childitem $script:master_JSON_File -Directory).DirectoryName

    if($working_Folder -eq "")
    {
        $working_Folder = $JSON_File_Dir
    }


    $Output_Dir = $JSON_File_Dir + "\Output"
    $default_SVN_Checkout_Folder = "$JSON_File_Dir\fromSVN"
    $svn_checkout_folder = ""

    #$Script:Backup_Folder = ""

    $Script:OutPutFile = "$Output_Dir\UpgradeOutput_$CurrentDate.txt"


    # Default PRISM folder to load SSIS packages into.
    $script:Default_SSIS_Root_Folder = "MSDB\PRISM"

    Set-Location $PSScriptRoot

    ################################################################
    # Show the StepsOutput if the flag is set to Y or not set at all
    ################################################################
    if($StepsOutput -ne "N")
    {
        $Script:JSON_File_Step_Num = 0
        $Script:JSON_File_Iteration = 0

        Write_Out_JSON_File_Steps($script:master_JSON_File)

        if($stepsOutput -eq "")
        {
            write-host "If you wish to execute the script enter a command line parameter of '-stepsoutput N'" -ForegroundColor Yellow
        }

        exit
    }


    # Stop executing the script if an error occurs, unless otherwise specified.
    #$ErrorActionPreference = "Stop"

    If(!(Test-Path $Output_Dir)){
        New-Item $Output_Dir -ItemType directory | Out-Null
    }

    If (Test-Path $Script:Outputfile){
	    Remove-Item $Script:Outputfile
    }



    $Script:MessagesOutPutFile = "$Output_Dir\UpgradeMessages_$CurrentDate.txt"

    If (Test-Path $Script:MessagesOutPutFile){
	    Remove-Item $Script:MessagesOutPutFile
    }


    Start-Transcript -Path $MessagesOutPutFile

    Write-Host "OutputFile is: $OutputFile"

    # Call function to process the JSON file.
    ProcessJSONFile $script:master_JSON_File

    # Stop the transcript if it's running.
    try{
        stop-transcript|out-null
    }
    catch [System.InvalidOperationException]{}

}

Function Write_Out_JSON_File_Steps([string]$the_JSON_File)
{
    #$the_JSON_File = $the_JSON_File.Trim()

    #write-host "INSIDE write_out_json_file_steps: >$script:new_JSON_File<"

    $Script:JSON_File_Iteration = $Script:JSON_File_Iteration + 1

    $spacer = "  " * ($Script:JSON_File_Iteration - 1)

    if($Script:JSON_File_Iteration -eq 1)
    {
        Write-Host ""
        Write-Host "-------------------- Steps --------------------"
        Write-Host ""
    }

    $data = Get-Content $the_JSON_File | Out-String | ConvertFrom-Json
    $step = ""

    $JSON_File_FileName = (Get-Item $the_JSON_File).Name

    for ($i=0; $i -le $data.steps.count - 1; $i++)
    {
        $step = $data.steps[$i].step
        $environment = $data.steps[$i].environment
        $command = $data.steps[$i].command

        if($command -eq "set_environment")
        {
            $Script:Environment = $data.steps[$i].environment
            if($Script:Environment -gt "")
            {
                Set_Environment
            }
            Write-Host "$spacer---- Steps in $JSON_File_FileName for Environment [$script:ScriptEnvironment] ----"
        }

        if((($environment -eq $script:ScriptEnvironment) -or ($environment -eq "ALL")) -and $command -eq "setup_variables")
        {
            for ($x=0; $x -le $data.steps[$i].variables.count - 1; $x++)
            {
                $variablename = $data.steps[$i].variables[$x].name
                $overridevariable = $data.steps[$i].variables[$x].override

                if($overridevariable -eq "TRUE" -or (!(Test-Path "variable:script:$variablename")))
                {
                    $variablevalue = $data.steps[$i].variables[$x].value
                    $variablevalue = Replace_Var_Values($variablevalue)

                    # if the variable name and value are both set then create the variable with the value.
                    if($variablename -gt "")
                    {
                        New-Variable -Scope script -Name $variablename -Force -Value $variablevalue
                    }
                }
            }
        }

        if($command -ne "set_environment" -and $command -ne "setup_variables")
        {
            if(($environment -eq $script:ScriptEnvironment) -or ($environment -eq "ALL"))
            {
                $Script:JSON_File_Step_Num = $Script:JSON_File_Step_Num + 1

                $step = Replace_Var_Values $step

                $msg = ([String]$Script:JSON_File_Step_Num).Padleft(3, "0") + " - $step"

                Write-Host "$spacer$msg"

                for ($x=0; $x -le $data.steps[$i].variables.count - 1; $x++)
                {
                    $variablename = $data.steps[$i].variables[$x].name

                    $variablevalue = $data.steps[$i].variables[$x].value
                    $variablevalue = Replace_Var_Values($variablevalue)

                    # if the variable name and value are both set then create the variable with the value.
                    if($variablename -gt "")
                    {
                        New-Variable -Scope script -Name $variablename -Force -Value $variablevalue
                    }
                }

                if($command -eq "process_json_file")
                {
                    if($script:svnfolder -gt "" -and $script:svnrevision -gt "")
                    {
                        #read-host "stopping here: $script:svnfolder - $script:svnrevision"
                        Download_File_From_SVN $script:json_file $script:svnfolder $script:svnrevision ""
                    }

                    $script:new_JSON_File = Get_Full_Path_For_File $script:json_file

                    #if($script:new_JSON_File -ne ($script:new_JSON_File).Trim())
                    #{
                    #    write-host "trimmed version is not the same!!!!!!"
                    #}
                    if($script:new_JSON_File -gt "")
                    {
                        #write-host "about to call write_out_json_file_steps: >$script:new_JSON_File<"
                        Write_Out_JSON_File_Steps $script:new_JSON_File
                    }
                    else
                    {
                        RaiseError "Can't find the full path for the json file: $script:new_JSON_File" false
                    }
                }
            }
        }
    }

    Write-Host "$spacer---- Done Steps for $JSON_File_FileName ----"
}

Function Exit_Script($retval)
{
    # Stop the transcript if it's running.
    try{
        stop-transcript|out-null
    }
    catch [System.InvalidOperationException]{}

    exit $retval
}

Function Set_Environment
{
    if($Script:Environment -gt "")
    {
        # Only set the environment if it's not already set.
        if(!($Script:ScriptEnvironment -gt ""))
        {
            $Script:ScriptEnvironment = $Script:Environment
        }
    }
}


Function RaiseError($errortext, $allowcontinue)
{
    $continue = "N"

    if($errortext -eq "" -or $errortext -eq $null)
    {
        $errortext = "An error occured."

        if($allowcontinue -eq $true)
        {
            $errortext += " Do you want to continue? (Y/N)"
        }
    }


    # Send an email if the user said they want to be informed when steps are completed and if an email_recipient has been set up.
    if($email_recipients -gt "")
    {
        $CurrentDate = get-date -Format "yyyy-MM-dd hh:mm:ss"
        Send_Email $email_recipients "Migration process step <$step> failed." "The step <$step> failed at $CurrentDate.`r`n`r`nThe error message is: <$errortext>" "HIGH"
    }

    
    $colorBefore = $Host.UI.RawUI.ForegroundColor

    $Host.UI.RawUI.ForegroundColor = "red"
    
    if($allowcontinue -eq $true)
    {
        Write-Host $errortext -ForegroundColor Red

        #$continue = Read-Host -Prompt $errortext
        # Wait for the user to say politely whether they'd like to continue or not.
        do{$answer = (Read-Host "Do you want to continue? Enter 'Yes please' or 'No thank you'").ToLower()}
            until ("yes please", "no thank you" -ccontains $answer)
        
        if($answer -eq "yes please")
        {
            $continue = "Y"
        }
    }
    else
    {
        Write-Host $errortext
    }
    
    $Host.UI.RawUI.ForegroundColor = $colorBefore

    if(($continue -ne "Y") -or ($allowcontinue -eq $false))
    {
        Exit_Script 1
    }
}

Function Replace_Var_Values($varvalue)
{
    $index = 0

    $startindex = 0

    while($varvalue -like '*$`[*`]*' -and $startindex -ge 0)
    {
        $startindex =  $varvalue.IndexOf('$[')

        if($startindex -ge 0)
        {
            $startindex = $startindex + 2
            $endindex = $varvalue.IndexOf(']', $startindex)
            $varname = $varvalue.Substring($startindex, $endindex - $startindex)

            if(Test-Path("variable:$varname"))
            {
                $tempvalue = Get-Variable -Name $varname -ValueOnly -ErrorAction Ignore
            }
            elseif(Test-Path("variable:script:$varname"))
            {
                $tempvalue = Get-Variable -Name $varname -ValueOnly -Scope Script -ErrorAction Ignore
            }

            $varvalue = $varvalue.Replace('$[' + $varname + ']', $tempvalue)
        }
    }


    return $varvalue
}

Function Get_Full_Path_For_File($filename)
{
    #read-host "inside get_full_path_for_File >$filename<" | out-null
    $fullpath = ""

    if($svn_checkout_folder -eq "")
    {
        $svn_checkout_folder = $default_SVN_Checkout_Folder
    }

    # First look for the file in the SVN Folder
    if(Test-Path "$svn_checkout_folder\$filename")
    {
        $fullpath = "$svn_checkout_folder\$filename"
    }
    # Second look for the file in the folder where the JSON file is located.
    elseif(Test-Path "$JSON_File_Dir\$filename")
    {
        $fullpath = "$JSON_File_Dir\$filename"
    }
    # Last look for the file in the root folder where the PRISM_Migration.ps1 script is located.
    elseif(Test-Path $filename)
    {
        $fullpath = (get-childitem $filename -Directory).FullName
    }

    $fullpath
}


Function Pause_Script($pause_text)
{
    $pause_text = Replace_Var_Values($pause_text)

    if($pause_text -eq "" -or $pause_text -eq $null)
    {
        $pause_text = "Press any key to continue ..."
    }

    $colorBefore = $Host.UI.RawUI.ForegroundColor

    $Host.UI.RawUI.ForegroundColor = "yellow"
    

    Write-Host $pause_text

    # Wait for the user to say politely whether they'd like to continue or not.
    do{$answer = (Read-Host "When you are ready to continue enter 'Yes please'.").ToLower()}
        until ("yes please" -ccontains $answer)

    $Host.UI.RawUI.ForegroundColor = $colorBefore
}

Function Execute_Script($private:scriptname, $private:svnfolder, $private:svnrevision)
{
    if($ScriptName -eq $null)
    {
        Write-Host "Error! A ScriptName value must be defined and provided with a value in order to run the Execute_Script step!"
    }
    else
    {

        # First attempt to download the file for SVN if the svnfolder and svnrevision are set.
        if($svnfolder -gt "" -and $svnrevision -gt "")
        {
            #write-host "downloading file: $scriptname from: $svnfolder revision: $svnrevision" -ForegroundColor Cyan
            $ScriptName_WithPath = Download_File_From_SVN $ScriptName $svnfolder $svnrevision ""

            $file_found = $false

            if($ScriptName_WithPath -gt "")
            {
                if(Test-Path $ScriptName_WithPath)
                {
                    $file_found = $true
                }
            }
            
            if(!($file_found))
            {
                write-host "FAILED!  $svn_checkout_folder\$ScriptName"
                $errortext = "The script: <$ScriptName> could not be downloaded from SVN!  The SVN folder is: $svnfolder  The SVN Revision is: $svnrevision   Do you want to continue? (Y/N)"

                RaiseError $errortext $true
            }
        }
        else
        {
            $file_found = $false

            $ScriptName_WithPath = Get_Full_Path_For_File $ScriptName
            if($ScriptName_WithPath -gt "")
            {
                if(Test-Path $ScriptName_WithPath)
                {
                    $file_found = $true
                }
            }

            if(!($file_found))
            {
                $errortext = "The script: <$ScriptName_WithPath> could not be found!  Do you want to continue? (Y/N)"

                RaiseError $errortext $true
            }
        }

        <#####################>

        if($template_script -gt ""){
            $current_script_content = Get-Content $ScriptName_WithPath | Out-String

            $ScriptRunDate = get-date -Format "yyyy-MM-dd-hhmmss"
            $ComboSQLFileName = $Output_Dir + "\" + $ScriptRunDate + "_With_Template_" + $ScriptName

            $ComboSQLFile_StreamWriter = New-Object System.IO.StreamWriter $ComboSQLFileName
            # Insert the script into the template for this script.


            $file_found = $false

            $template_scriptname_WithPath = Get_Full_Path_For_File $template_script
            if($template_scriptname_WithPath -gt "")
            {
                if(Test-Path $template_scriptname_WithPath)
                {
                    $file_found = $true
                }
            }

            if(!($file_found))
            {
                $errortext = "The template script: <$template_script> could not be found!  Do you want to continue? (Y/N)"

                RaiseError $errortext $true
            }


            
            $new_script_content = (Get-Content $template_scriptname_WithPath) | ForEach-Object {$_ -replace '\/\* *\[script_content\] *\*\/', $current_script_content} | Out-String
            $current_script_content = $new_script_content
                
            $temp_current_script_content = $current_script_content
            $current_script_content = Replace_Var_Values($temp_current_script_content)                

            #Add this script to the file...
            $ComboSQLFile_StreamWriter.Write($current_script_content)

            #Close the StreamWriter for the CombinedSQL file.        
            $ComboSQLFile_StreamWriter.Close()

            $ScriptName_WithPath = $ComboSQLFileName
        }


        <######################>


        Write-Host "Running script: <$ScriptName_WithPath>"
        
        $variables = ""

        if($Script:variablesforfunction -gt "")
        {
            $variables = $Script:variablesforfunction + ","
        }

        if($Script:globalvariablesforfunctions -gt "")
        {
            $variables += $Script:globalvariablesforfunctions
        }

        # Strip off trailing "," if it's there.
        if($variables -gt "")
        {
            if($variables.Substring($variables.Length - 1) -eq ",")
            {
                $variables = $variables.Substring(0, $variables.Length - 1)
            }
        }

        # Build sqlcmd function to run.
        $exp = 'sqlcmd -S "' + $script:ServerName + '"'
        
        if($variables -gt "")
        {
            $exp += " -v $variables "
        }

        if($script:DatabaseForScript -gt "")
        {
            $exp += " -d $script:DatabaseForScript "
        }

        $exp += ' -i "' + $ScriptName_WithPath + '" -b -y 2000 -m-1 | Out-File -FilePath $OutPutFile -Append -Width 8000 -Encoding ascii'
        
        #write-host "Expression is: $exp"

        Invoke-Expression $exp -ErrorAction Inquire

        if($LASTEXITCODE -ne 0)
        {
            $errortext = "An error occurred executing the script: <$script:ScriptName>  Do you want to continue? (Y/N)"

            RaiseError $errortext $true
        }
    }
}


Function Execute_Multiple_Scripts
{
    if($script:scripts_array -eq $null)
    {
        Write-Host "Error! A Scripts_Array value must be defined and provided with values in order to run the Execute_Multiple_Scripts step!"
    }
    else
    {
        $CombinedSQLFileName_temp = $CombinedSQLFileName
        $CombinedSQLFileName = Replace_Var_Values($CombinedSQLFileName_temp)
        $ScriptRunDate = get-date -Format "yyyy-MM-dd-hhmmss"
        $CombinedSQLFileName = $Output_Dir + "\" + $ScriptRunDate + "_" + $CombinedSQLFileName + ".sql"

        if($script:scripts_array.count -gt 0){
            $CombinedSQLFile_StreamWriter = New-Object System.IO.StreamWriter $CombinedSQLFileName
        }

        if($master_script_header -gt ""){
            #Add the Master script header in once.


            $file_found = $false

            $master_script_header_WithPath = Get_Full_Path_For_File $master_script_header
            if($master_script_header_WithPath -gt "")
            {
                if(Test-Path $master_script_header_WithPath)
                {
                    $file_found = $true
                }
            }

            if(!($file_found))
            {
                $errortext = "The script: <$master_script_header> could not be found!  Do you want to continue? (Y/N)"

                RaiseError $errortext $true
            }


            $master_script_content = Get-Content $master_script_header_WithPath | Out-String
            $master_script_content = Replace_Var_Values($master_script_content)

            $CombinedSQLFile_StreamWriter.Write($master_script_content)
        }

        for ($i=0; $i -le $script:scripts_array.count - 1; $i++)
        {
            $scriptname = $script:scripts_array[$i].scriptname
            $template_scriptname = $script:scripts_array[$i].template_script
            
            $DatabaseForCurrentScript_temp = $script:scripts_array[$i].DatabaseForScript
            $DatabaseForCurrentScript = Replace_Var_Values($DatabaseForCurrentScript_temp)

            $script_comment = $script:scripts_array[$i].script_comment 
            $script_comment = Replace_Var_Values($script_comment)

            $svnfolder = $script:scripts_array[$i].svnfolder
            if($svnfolder -gt "")
            {
                $svnfolder = Replace_Var_Values($svnfolder)
            }

            $svnrevision = $script:scripts_array[$i].svnrevision
            if($svnrevision -gt "")
            {
                $svnrevision = Replace_Var_Values($svnrevision)
            }

            if($scriptname -gt ""){
                # Add a USE <DBNAME> line for each script.
                $CombinedSQLFile_StreamWriter.WriteLine("USE $DatabaseForCurrentScript`r`n`r`n")

                if($svnfolder -gt "" -and $svnrevision -gt "")
                {

                    $ScriptName_WithPath = Download_File_From_SVN $ScriptName $svnfolder $svnrevision ""

                    $file_found = $false

                    if($ScriptName_WithPath -gt "")
                    {
                        if(Test-Path $ScriptName_WithPath)
                        {
                            $file_found = $true
                        }
                    }
            
                    if(!($file_found))
                    {
                        write-host "FAILED!  $svn_checkout_folder\$ScriptName"
                        $errortext = "The script: <$ScriptName> could not be downloaded from SVN!  The SVN folder is: $svnfolder  The SVN Revision is: $svnrevision   Do you want to continue? (Y/N)"

                        RaiseError $errortext $true
                    }

                }
                else
                {

                    $file_found = $false

                    $scriptname_WithPath = Get_Full_Path_For_File $scriptname
                    if($scriptname_WithPath -gt "")
                    {
                        if(Test-Path $scriptname_WithPath)
                        {
                            $file_found = $true
                        }
                    }

                    if(!($file_found))
                    {
                        $errortext = "The script: <$scriptname> could not be found!  Do you want to continue? (Y/N)"

                        RaiseError $errortext $true
                    }
                }

                $current_script_content = Get-Content $scriptname_WithPath | Out-String

                if($template_scriptname -gt ""){
                    # Insert the script into the template for this script.

                    $file_found = $false

                    $template_scriptname_WithPath = Get_Full_Path_For_File $template_scriptname
                    if($template_scriptname_WithPath -gt "")
                    {
                        if(Test-Path $template_scriptname_WithPath)
                        {
                            $file_found = $true
                        }
                    }

                    if(!($file_found))
                    {
                        $errortext = "The template script: <$template_scriptname> could not be found!  Do you want to continue? (Y/N)"

                        RaiseError $errortext $true
                    }


                    $new_script_content = (Get-Content $template_scriptname_WithPath) | ForEach-Object {$_ -replace '\/\* *\[script_content\] *\*\/', $current_script_content} | Out-String
                    $current_script_content = $new_script_content
                }
                
                $temp_current_script_content = $current_script_content
                $current_script_content = Replace_Var_Values($temp_current_script_content)                

                #Add this script to the file...
                $CombinedSQLFile_StreamWriter.Write($current_script_content)
            }
        }

        if($master_script_footer -gt ""){
            #Add the Master script footer in once.

            if(Test-Path $master_script_footer)
            {
                $master_script_footer_WithPath = $master_script_footer
            }
            elseif(Test-Path "$JSON_File_Dir\$master_script_footer")
            {
                $master_script_footer_WithPath = "$JSON_File_Dir\$master_script_footer"
            }
            else
            {
                $errortext = "The script: <$master_script_footer> could not be found!  Do you want to continue? (Y/N)"

                RaiseError $errortext $true
            }

            $master_script_footer_content = Get-Content $master_script_footer_WithPath | Out-String
            $master_script_footer_content = Replace_Var_Values($master_script_footer_content)

            $CombinedSQLFile_StreamWriter.Write($master_script_footer_content)
        }

        #Close the StreamWriter for the CombinedSQL file.        
        $CombinedSQLFile_StreamWriter.Close()

        #Execute the CombinedSQLFileName
        $scriptname = $CombinedSQLFileName

        Execute_Script $scriptname "" ""
    }
}


Function Backup_Database
{
    if($script:db_to_backup -eq $null)
    {
        RaiseError "Error! A variable named: db_to_backup must be defined and provided with a value in order to do a database backup!" $false
    }
    else
    {
        while(($Script:Backup_Folder -eq $null) -or ($Script:Backup_Folder -eq "") -or (-not(Test-Path($Script:Backup_Folder))))
        {
            $colorBefore = $Host.UI.RawUI.ForegroundColor

            $Host.UI.RawUI.ForegroundColor = "yellow"

            $Script:Backup_Folder = Read-Host "Please enter the full path to the backup folder" 

            $Host.UI.RawUI.ForegroundColor = $colorBefore

            if(-not(Test-Path($Script:Backup_Folder)))
            {
                Write-Host "The path <$Script:Backup_Folder> was not found." -ForegroundColor Red
            }
        }


        $CurrentDate = get-date -Format "yyyy-MM-dd-hhmmss"

        if(-not($Script:Backup_Folder.EndsWith("\")))
        {
            $Script:Backup_Folder += "\"
        }

        $BackupFile = $Script:Backup_Folder
        if($filePrefix -gt "")
        {
            $BackupFile += $filePrefix + "_"
        } 
#        $BackupFile += $script:db_to_backup + "_" + $CurrentDate + '.bak'
#
#        Write-Host "Backing up <$script:db_to_backup> to file: <$BackupFile>"
#
#        Invoke-Sqlcmd -ServerInstance $script:ServerName -Variable db="$script:db_to_backup", bakfile=$BackupFile -Query "USE master; BACKUP DATABASE [`$(db)] TO DISK='`$(bakfile)'; " -QueryTimeout 600 -OutputSqlErrors $true -ErrorAction Inquire

        # Create backup file name without the .bak extension yet, because we're going to split the backups into 4 separate
        # files for performance reasons.
        $BackupFile += $script:db_to_backup + "_" + $CurrentDate

        Write-Host ("Backing up <$script:db_to_backup> to files: <$BackupFile" + "_1.bak, " + $BackupFile + "_2.bak, " + $BackupFile + "_3.bak, " + $BackupFile + "_4.bak>")

        $backupSQL = "USE master; BACKUP DATABASE [`$(db)] TO "
        
        $backupSQL += " DISK = N'" + $BackupFile + "_1.BAK', "
        $backupSQL += " DISK = N'" + $BackupFile + "_2.BAK', "
        $backupSQL += " DISK = N'" + $BackupFile + "_3.BAK', "
        $backupSQL += " DISK = N'" + $BackupFile + "_4.BAK' "
        $backupSQL += " WITH COPY_ONLY, NOFORMAT, NOINIT, SKIP, NOREWIND, NOUNLOAD, STATS = 10"

        Invoke-Sqlcmd -ServerInstance $script:ServerName -Variable db="$script:db_to_backup" -Query $backupSQL -QueryTimeout 1200 -OutputSqlErrors $true -ErrorAction Inquire

    }
}


Function Restore_Database($db_to_restore, $file_to_restore_from, $move_data_from_name, $move_data_to_name, $move_log_From_name, $move_log_to_name)
{
    if($db_to_restore -eq $null -or $db_to_restore -eq "")
    {
        RaiseError "Error! A variable named: <db_to_restore> must be defined and provided with a value in order to do a database backup!" $false
    }
    elseif($file_to_restore_from -eq $null -or $file_to_restore_from -eq "")
    {
        RaiseError "Error! A variable named: <file_to_restore_from> must be defined and provided with a value in order to do a database backup!" $false
    }
    else
    {
        if($db_to_restore -eq "PRISM_PROD"){
            Write-Host "ERROR! You can not use this script to restore the PRISM_PROD database!" -ForegroundColor Red
            Pause_Script "Manually do the restore and then press any key when you wish to continue..."
        }
        else
        {
            # If the environment is not DEV then confirm the user is sure they want to do the restore.
            # If it is DEV just go ahead and do it.
            if($Script:ScriptEnvironment -ne "DEV")
            {
                $colorBefore = $Host.UI.RawUI.ForegroundColor

                $Host.UI.RawUI.ForegroundColor = "red"

                Write-Host "Are you sure you want to restore the database: <$db_to_restore> from the file: <$file_to_restore_from>?" -ForegroundColor Red

                # Wait for the user to say politely whether they'd like to continue or not.
                do{$answer = (Read-Host "Enter 'Yes please' or 'No thank you'").ToLower()}
                    until ("yes please", "no thank you" -ccontains $answer)

                if($answer -eq "yes please")
                {
                    $restore_confirm = "Y"
                }

                $Host.UI.RawUI.ForegroundColor = $colorBefore
            }
            else
            {
                $restore_confirm = "Y"
            }

            if($restore_confirm -eq "Y")
            {
                Write-Host "Restoring Database <$db_to_restore> from file: <$file_to_restore_from>"

                if($file_to_restore_from.Contains('*'))
                {
                    $restorestring = ""
                    foreach ($file in (gci $file_to_restore_from | sort FullName).FullName)
                    {
                        $restorestring = $restorestring + "DISK = '" + $file + "',"
                    }
                    $restorestring = $restorestring.Substring(0, $restorestring.Length - 1)
                }
                else
                {
                    $file_to_restore_from = "'" + $file_to_restore_from + "'"
                    $restoresstring = "DISK = $file_to_restore_from"
                }
                
                $querystring = "USE master; RESTORE DATABASE $db_to_restore FROM $restorestring WITH RECOVERY, REPLACE"

                if($move_data_from_name -gt "" -and $move_data_to_name -gt "" -and $move_log_From_name -gt "" -and $move_log_to_name -gt "")
                {
                    $querystring += ", MOVE N'" + $move_data_from_name + "' TO N'" + $move_data_to_name + "', MOVE N'" + $move_log_From_name + "' TO N'" + $move_log_to_name + "'"
                }

                $querystring += "; "


                Invoke-Sqlcmd -ServerInstance $script:ServerName -Query $querystring -QueryTimeout 3600 -OutputSqlErrors $true -ErrorAction Inquire
            }
            else
            {
                Write-Host "Skipping Step <$step>. Not performing the database restore." -ForegroundColor Yellow
            }
        }
    }
}

Function Restore_DEV_From_Last_PRISM_Backup
{
    if($prism_db -eq $null -or $prism_db -eq "")
    {
        RaiseError "Error! A variable named: <prism_db> must be defined and provided with a value in order to do a database restore!" $false
    } 

    if($staging_db -eq $null -or $staging_db -eq "")
    {
        RaiseError "Error! A variable named: <staging_db> must be defined and provided with a value in order to do a database restore!" $false
    } 

    if($PROD_Backup_Folder -eq $null -or $PROD_Backup_Folder -eq "")
    {
        RaiseError "Error! A variable named: <PROD_Backup_Folder> must be defined and provided with a value in order to do a database restore!" $false
    }

    if($STAGING_Backup_Folder -eq $null -or $STAGING_Backup_Folder -eq "")
    {
        RaiseError "Error! A variable named: <STAGING_Backup_Folder> must be defined and provided with a value in order to do a database restore!" $false
    }

    ############## HARD-CODED VALUE #############
    $staging_archive_db = "PRISM_STAGING_ARCHIVE"
    #############################################

    # Check for existence of $prism_db database
    $query = "SELECT DB_ID('" + $prism_db + "') as db_id"
    $query_result = Invoke-Sqlcmd -ServerInstance $script:ServerName -Database 'master' -Query $query -QueryTimeout 3600 -OutputSqlErrors $true -ErrorAction Inquire
    if($query_result.db_id -eq $null -or $query_result.db_id -eq ""){
        $error_msg = "Error! A database named '" + $prism_db + "' cannot be found on server named '" + $script:ServerName + "; cannot continue with restores!"
        RaiseError $error_msg $false
    }

    # Check for existence of $staging_db database
    $query = "SELECT DB_ID('" + $staging_db + "') as db_id"
    $query_result = Invoke-Sqlcmd -ServerInstance $script:ServerName -Database 'master' -Query $query -QueryTimeout 3600 -OutputSqlErrors $true -ErrorAction Inquire
    if($query_result.db_id -eq $null -or $query_result.db_id -eq ""){
        $error_msg = "Error! A database named '" + $staging_db + "' cannot be found on server named '" + $script:ServerName + "; cannot continue with restores!"
        RaiseError $error_msg $false
    }

    # Will restore the staging archive database if the STAGING_Archive_Backup_Folder variable is set. If set, check for existence of $staging_archive_db database
	if($STAGING_Archive_Backup_Folder -gt "")
    {
        # Check for existence of $staging_archive_db database
        $query = "SELECT DB_ID('" + $staging_archive_db + "') as db_id"
        $query_result = Invoke-Sqlcmd -ServerInstance $script:ServerName -Database 'master' -Query $query -QueryTimeout 3600 -OutputSqlErrors $true -ErrorAction Inquire
        if($query_result.db_id -eq $null -or $query_result.db_id -eq ""){
            $error_msg = "Error! A database named '" + $staging_archive_db + "' cannot be found on server named '" + $script:ServerName + "; cannot continue with restores!"
            RaiseError $error_msg $false
        }
    }

    # Restore PRISM_PROD backup file to database.
    $file_to_restore_from = (gci $PROD_Backup_Folder -Filter *.bak | sort LastWriteTime | Select -last 1).FullName
    # Remove the last 5 characters from the file name because PRISM backups are done in 4 files now.
    # Each file has _1.bak, _2.bak, etc. at the end. 
    $file_to_restore_from = $file_to_restore_from.Substring(0, $file_to_restore_from.Length - 5) + "*.bak"

    Restore_Database $prism_db $file_to_restore_from '' '' '' ''

    # Restore PRISM_STAGING backup file to database.
    $file_to_restore_from = (gci $STAGING_Backup_Folder -Filter *.bak | sort LastWriteTime | Select -last 1).FullName
    # Remove the last 5 characters from the file name because PRISM backups are done in 4 files now.
    # Each file has _1.bak, _2.bak, etc. at the end. 
    $file_to_restore_from = $file_to_restore_from.Substring(0, $file_to_restore_from.Length - 5) + "*.bak"

    Restore_Database $staging_db $file_to_restore_from '' '' '' ''

	# Only restore the staging archive database if the STAGING_Archive_Backup_Folder variable is set. This allows the developer to choose not to restore this db.
	if($STAGING_Archive_Backup_Folder -gt "")
    {
		# Restore PRISM_STAGING_ARCHIVE backup file to database.
		$file_to_restore_from = (gci $STAGING_Archive_Backup_Folder -Filter *.bak | sort LastWriteTime | Select -last 1).FullName
		# Remove the last 5 characters from the file name because PRISM backups are done in 4 files now.
		# Each file has _1.bak, _2.bak, etc. at the end. 
		$file_to_restore_from = $file_to_restore_from.Substring(0, $file_to_restore_from.Length - 5) + "*.bak"

		Restore_Database $staging_archive_db $file_to_restore_from
	}
	
    # blank out variables after function is called.
    $file_to_restore_from = ""
    $error_msg = ""
}

Function Restore_PRISM_TRN_From_Last_PRISM_Backup
{
    if($prism_db -eq $null -or $prism_db -eq "")
    {
        RaiseError "Error! A variable named: <prism_db> must be defined and provided with a value in order to do a database restore!" $false
    }

    if($Backup_Folder -eq $null -or $Backup_Folder -eq "")
    {
        RaiseError "Error! A variable named: <prism_db> must be defined and provided with a value in order to do a database restore!" $false
    }
     
    # Restore PRISM_PROD backup file to database.
    $file_to_restore_from = (gci $Backup_Folder -Filter *.bak | sort LastWriteTime | Select -last 1).FullName
    # Remove the last 5 characters from the file name because PRISM backups are done in 4 files now.
    # Each file has _1.bak, _2.bak, etc. at the end. 
    $file_to_restore_from = $file_to_restore_from.Substring(0, $file_to_restore_from.Length - 5) + "*.bak"
    $db_to_restore = $prism_db

    Restore_Database $db_to_restore $file_to_restore_from '' '' '' ''

    # blank out variables after function is called.
    $db_to_restore = ""
    $file_to_restore_from = ""
    $Backup_Folder = ""
}

Function Get_Rename_Database_File
{
    # TODO: Change this to get the database rename sql file from source control so it doesn't have to be hard-coded or put into the folder with this script.
    Return $rename_database_file
}

Function Rename_Database($db_to_rename, $new_db_name, $raise_error_if_rename_not_needed, $confirm_rename)
{
    do # Check that both parameters are set. If they're not allow the user to enter them now if they'd like.
    {
        if($db_to_rename -eq $null -or $db_to_rename -eq "")
        {
            RaiseError "Error! A variable named: <db_to_rename> must be defined and provided with a value in order to do a database rename! Would you like to provide a database name now? (Y/N)" $true
            $colorBefore = $Host.UI.RawUI.ForegroundColor
            $Host.UI.RawUI.ForegroundColor = "yellow"
            $db_to_rename = Read-Host "Enter the name of the database you wish to rename:"
            $Host.UI.RawUI.ForegroundColor = $colorBefore
        }

        if($new_db_name -eq $null -or $new_db_name -eq "")
        {
            RaiseError "Error! A variable named: <new_db_name> must be defined and provided with a value in order to do a database rename! Would you like to provide a new database name now? (Y/N)" $true
            $colorBefore = $Host.UI.RawUI.ForegroundColor
            $Host.UI.RawUI.ForegroundColor = "yellow"
            $new_db_name = Read-Host "Enter the new name for the database you are renaming:"
            $Host.UI.RawUI.ForegroundColor = $colorBefore
        }

        if($raise_error_if_rename_not_needed -eq $null -or $raise_error_if_rename_not_needed -eq "")
        {
            RaiseError "Error! A variable named: <raise_error_if_rename_not_needed> must be defined and provided with a value in order to do a database rename! Would you like to provide the value now? (Y/N)" $true
            $colorBefore = $Host.UI.RawUI.ForegroundColor
            $Host.UI.RawUI.ForegroundColor = "yellow"
            $new_db_name = Read-Host "Enter the value for the raise_error_if_rename_not_needed variable (Y or N):"
            $Host.UI.RawUI.ForegroundColor = $colorBefore
        }
    }
    while(($db_to_rename -eq $null -or $db_to_rename -eq "") -or ($new_db_name -eq $null -or $new_db_name -eq "") -or ($raise_error_if_rename_not_needed -eq $null -or $raise_error_if_rename_not_needed -eq ""))

    # if the json file doesn't specify whether a DB rename should be confirmed, then confirm it.
    if($confirm_rename -eq $null -or $confirm_rename -eq "")
    {
        $confirm_rename = "Y"
    }

    # At this point both variables that are required should be set.

    # Can't automatically rename PRISM_PROD. Safety feature.
    if($db_to_rename -eq "PRISM_PROD"){
        Write-Host "ERROR! You can not use this script to rename the PRISM_PROD database!" -ForegroundColor Red
        Pause_Script "Manually do the rename and then press any key when you wish to continue..."
    }
    else
    {
        if($confirm_rename -eq "Y")
        {
            $colorBefore = $Host.UI.RawUI.ForegroundColor

            $Host.UI.RawUI.ForegroundColor = "red"

            #$rename_confirmed = Read-Host -Prompt "Are you sure you want to rename the database: <$db_to_rename> to: <$new_db_name>? (Y/N)"

            Write-Host "Are you sure you want to rename the database: <$db_to_rename> to: <$new_db_name>?" -ForegroundColor Red

            # Wait for the user to say politely whether they'd like to continue or not.
            do{$answer = (Read-Host "Enter 'Yes please' or 'No thank you'").ToLower()}
                until ("yes please", "no thank you" -ccontains $answer)
        
            if($answer -eq "yes please")
            {
                $rename_confirmed = "Y"
            }

            $Host.UI.RawUI.ForegroundColor = $colorBefore
        }
        else
        {
            $rename_confirmed = "Y"
        }
        
        if($rename_confirmed -eq "Y")
        {
            Write-Host "Renaming Database <$db_to_rename> to: <$new_db_name>"

            $rename_database_file = Get_Rename_Database_File

            Invoke-Sqlcmd -ServerInstance $script:ServerName -Variable db_to_rename="$db_to_rename", new_db_name="$new_db_name", raise_error_if_rename_not_needed="$raise_error_if_rename_not_needed" -InputFile "$rename_database_file" -QueryTimeout 60 -OutputSqlErrors $true -ErrorAction Inquire
        }
        else
        {
            Write-Host "Skipping Step <$step>. Not performing the database rename." -ForegroundColor Yellow
        }
    }
}

Function Send_Email($email_recipients, $email_subject, $email_body, $email_importance)
{
    if($email_recipients -eq $null -or $email_recipients -eq "")
    {
        RaiseError "Error! A variable named: email_recipients must be defined and provided with a value in order to send an email!" $true
    }

    if($email_subject -eq $null -or $email_subject -eq "")
    {
        RaiseError "Error! A variable named: email_subject must be defined and provided with a value in order to send an email!" $true
    }

    if($email_body -eq $null -or $email_body -eq "")
    {
        RaiseError "Error! A variable named: email_body must be defined and provided with a value in order to send an email!" $true
    }

    $email_body = [System.Web.HttpUtility]::HtmlEncode($email_body)

    if($email_importance -eq $null -or $email_importance -eq "")
    {
        $email_importance = "NORMAL"
    }

    $CurrentDate = get-date -Format "yyyy-MM-dd-hhmmss"


    Write-Host "Sending email to <$email_recipients> with the subject <$email_subject>."

    #Invoke-Sqlcmd -ServerInstance $ServerName -Variable email_recipients="$email_recipients", email_importance="$email_importance", email_subject="$email_subject", email_body="$email_body" -Query "exec msdb.dbo.sp_send_dbmail @profile_name='JustOperations', @recipients='`$(email_recipients)', @importance='`$(email_importance)', @subject ='`$(email_subject)', @body='`$(email_body)', @body_format='HTML';" -QueryTimeout 30 -OutputSqlErrors $true -ErrorAction Inquire
    Invoke-Sqlcmd -ServerInstance $script:ServerName -Query "exec msdb.dbo.sp_send_dbmail @profile_name='JustOperations', @recipients='$email_recipients', @importance='$email_importance', @subject ='$email_subject', @body='$email_body', @body_format='HTML';" -QueryTimeout 30 -OutputSqlErrors $true -ErrorAction Inquire
}


Function Execute_Verification_SQL($db_to_use, $sql_to_use, $sql_script_to_use, $svnfolder, $svnrevision, $comparison_return_value, $comparison_operator, $data_type, $stop_if_not_matching)
{
    if($db_to_use -eq $null -or $db_to_use -eq "")
    {
        RaiseError "Error! A variable named: db_to_use must be defined and provided with a value in order to execute verification SQL! Continue processing? (Y/N)" $true
    }

    if(($sql_to_use -eq $null -or $sql_to_use -eq "") -and ($sql_script_to_use -eq $null -or $sql_script_to_use -eq ""))
    {
        RaiseError "Error! A variable named: sql_to_use or sql_script_to_use must be defined and provided with a value in order to execute verification SQL! Continue processing? (Y/N)" $true
    }

    if($comparison_return_value -eq $null -or $comparison_return_value -eq "")
    {
        RaiseError "Error! A variable named: comparison_return_value must be defined and provided with a value in order to execute verification SQL! Continue processing? (Y/N)" $true
    }

    if($comparison_operator -eq $null -or $comparison_operator -eq "")
    {
        Write-Host "Warning! No value provided for variable <comparison_operator>! A default of '=' will be used." -ForegroundColor Yellow
        $comparison_operator = "="
    }
    if($data_type -eq $null -or $data_type -eq "")
    {
        RaiseError "Error! A variable named: data_type must be defined and provided with a value in order to execute verification SQL! Continue processing? (Y/N)" $true
    }
    if($stop_if_not_matching -eq $null -or $stop_if_not_matching -eq "")
    {
        Write-Host "Warning! No value provided for variable <stop_if_not_matching>! A default of 'Y' will be used." -ForegroundColor Yellow
        $stop_if_not_matching = "Y"
    }


    if($sql_to_use -gt "")
    {
        Write-Host "Executing verification SQL against the database <$script:db_to_use>.`r`nSQL is: <$script:sql_to_use>`r`nExpected return value is: <$script:comparison_return_value>`r`nComparison Operator is: <$script:comparison_operator>"

        # Execute the SQL from the command and get the result.
        $queryresult = Invoke-Sqlcmd -ServerInstance $script:ServerName -Database $script:db_to_use -Query $script:sql_to_use -QueryTimeout 600 -OutputSqlErrors $true -ErrorAction Inquire
    }
    else
    {
        if($svnfolder -gt "" -and $svnrevision -gt "")
        {
            Download_File_From_SVN $script:sql_script_to_use $script:svnfolder $script:svnrevision ""

            $sql_script_to_use_WithPath = Get_Full_Path_For_File($script:sql_script_to_use)

            if($sql_script_to_use_WithPath -gt "")
            {
                if(Test-Path $sql_script_to_use_WithPath)
                {
                    $file_found = $true
                }
            }

            if(!($file_found))
            {
                $errortext = "The script: <$script:sql_script_to_use> could not be downloaded from SVN!  The SVN folder is: $script:svnfolder  The SVN Revision is: $script:svnrevision   Do you want to continue? (Y/N)"

                RaiseError $errortext $true
            }
        }
        else
        {
            $file_found = $false

            $sql_script_to_use_WithPath = Get_Full_Path_For_File $script:sql_script_to_use
            if($sql_script_to_use_WithPath -gt "")
            {
                if(Test-Path $sql_script_to_use_WithPath)
                {
                    $file_found = $true
                }
            }

            if(!($file_found))
            {
                $errortext = "The script: <$script:sql_script_to_use> could not be found!  Do you want to continue? (Y/N)"

                RaiseError $errortext $true
            }
        }
        Write-Host "Executing verification SQL against the database <$script:db_to_use>.`r`nSQL Script is: <$sql_script_to_use_WithPath>`r`nExpected return value is: <$script:comparison_return_value>`r`nComparison Operator is: <$script:comparison_operator>"

        # Execute the SQL from the file and get the result.
        $queryresult = Invoke-Sqlcmd -ServerInstance $script:ServerName -Database $script:db_to_use -InputFile $sql_script_to_use_WithPath -QueryTimeout 600 -OutputSqlErrors $true -ErrorAction Inquire
    }

    $return_value = $queryresult[0]

    $matching = $false

    switch($data_type)
    {
        "STRING" {
                    $return_value = [string]$return_value
                    $script:comparison_return_value = [string]$script:comparison_return_value
                }
        "INT" {
                    $return_value = [int]$return_value
                    $script:comparison_return_value = [int]$script:comparison_return_value
              }
        "DECIMAL" {
                    $return_value = [decimal]$return_value
                    $script:comparison_return_value = [decimal]$script:comparison_return_value
                  }
        "DEFAULT" {
                    $return_value = [string]$return_value
                    $script:comparison_return_value = [string]$script:comparison_return_value
                  }
    }

    switch($comparison_operator)
    {
        "=" {
                if($return_value -eq $script:comparison_return_value){$matching = $true}
            }
        ">" {
                if($return_value -gt $script:comparison_return_value){$matching = $true}
            }
        "<" {
                if($return_value -lt $script:comparison_return_value){$matching = $true}
            }
        ">=" {
                if($return_value -ge $script:comparison_return_value){$matching = $true}
             }
        "<=" {
                if($return_value -le $script:comparison_return_value){$matching = $true}
             }
        "default"{RaiseError "Comparison Operator for the Execute_Verification_SQL function was not set properly!"}
    }

    if($matching -eq $false)
    {
        if($script:stop_if_not_matching -eq "Y")
        {
            $errmsg = "The value: " + [string]$return_value + " is NOT $script:comparison_operator the comparison value: " + [string]$script:comparison_return_value

            RaiseError $errmsg $false
        }
        # Stop_If_Not_Matching = "M" (Maybe). Ask the user if they want to stop or not.
        elseif($script:stop_if_not_matching -eq "M")
        {
            $errmsg = "The value: " + [string]$return_value + " is NOT $script:comparison_operator the comparison value: " + [string]$script:comparison_return_value + "  Do you want to continue?"
            
            if($script:email_recipients -gt "")
            {
                $CurrentDate = get-date -Format "yyyy-MM-dd hh:mm:ss"
                Send_Email $script:email_recipients "Migration process step <$step> requires response." "The step <$step> requires a response at $CurrentDate.`r`n`r`nThe message is: <$errmsg>" "HIGH"
            }

            $colorBefore = $Host.UI.RawUI.ForegroundColor

            $Host.UI.RawUI.ForegroundColor = "red"

            #$exit_script = Read-Host -Prompt $errmsg

            Write-Host $errmsg -ForegroundColor Red

            # Wait for the user to say politely whether they'd like to continue or not.
            do{$answer = (Read-Host "Enter 'Yes please' or 'No thank you'").ToLower()}
                until ("yes please", "no thank you" -ccontains $answer)

            if($answer -eq "yes please")
            {
                $continue_script = "Y"
            }

            $Host.UI.RawUI.ForegroundColor = $colorBefore

            if($continue_script -ne "Y")
            {
                RaiseError "User chose to stop the script due to a SQL Verification error." $false
            }
        }
        else
        {
            Write-Host "The value: <$return_value> is NOT $script:comparison_operator the comparison value: <$script:comparison_return_value>" -ForegroundColor DarkYellow
        }
    }
    else
    {
        Write-Host "The value: <$return_value> is $script:comparison_operator the comparison value <$script:comparison_return_value>" -ForegroundColor Green
    }
    
}

Function Load_SSIS_Packages($private:manifest_file, $private:load_to_folder, $private:svnfolder, $private:svnrevision)
{
    $instancename = $script:servername.Substring(0, $script:servername.IndexOf('\'))

    [Reflection.Assembly]::LoadWithPartialName("Microsoft.SQLServer.ManagedDTS") | out-null

    $app = New-Object Microsoft.SqlServer.Dts.Runtime.Application


    $file_found = $false


    if($svnfolder -gt "" -and $svnrevision -gt "")
    {
        Download_File_From_SVN $manifest_file $svnfolder $svnrevision ""

        $manifest_file_withPath = Get_Full_Path_For_File $manifest_file

        if($manifest_file_withPath -gt "")
        {
            if(Test-Path $manifest_file_withPath)
            {
                $file_found = $true
            }
        }
    }
    else
    {
        $manifest_file_withPath = Get_Full_Path_For_File $manifest_file
        if($manifest_file_withPath -gt "")
        {
            if(Test-Path $manifest_file_withPath)
            {
                $file_found = $true
            }
        }
    }


    if(!($file_found))
    {
        $errortext = "The manifest file for SSIS deployment $manifest_file can't be found. The SSIS packages can't be automatically loaded, but if you manually load them you may continue. Continue? (Y/N)"

        RaiseError $errortext $true
    }
    else
    {
        Write-Host "Loading SSIS packages from the file: $manifest_file into the folder: $load_to_folder"

        # If the SSIS_Root_Folder variable hasn't been set elsewhere (in the .json file)
        # Then default it to the Default_SSIS_Root_Folder set at the top of this PS Script.
        $private:My_SSIS_Folder = ""
        if($script:SSIS_Root_Folder)
        {
            if($script:SSIS_Root_Folder -gt "")
            {
                $private:My_SSIS_Folder = $script:SSIS_Root_Folder
            }
        }

        if($private:My_SSIS_Folder -eq "")
        {
            $private:My_SSIS_Folder = $script:Default_SSIS_Root_Folder
        }

        # If the root SSIS folder doesn't exist on the server then create it.
        if(!($app.FolderExistsOnDtsServer("$private:My_SSIS_Folder", $instancename)))
        {
            $SSISFolderRoot = $private:My_SSIS_Folder.Substring(0, $private:My_SSIS_Folder.IndexOf('\'))
            $SSISChildFolder = $private:My_SSIS_Folder.Substring($private:My_SSIS_Folder.IndexOf('\') + 1)

            $app.CreateFolderOnDtsServer($SSISFolderRoot, $SSISChildFolder, $instancename)
        }


        # If the folder we are loading to is a subfolder to the My_SSIS_Folder then we can rename it as a backup.
        # If the packages are going in the root folder then we can't.
        if($load_to_folder -gt "")
        {
            # If the folder already exists on the server then rename it as a backup folder for easy backouts.
            if($app.FolderExistsOnDtsServer("$private:My_SSIS_Folder\$load_to_folder", $instancename))
            {
                $backupfolder = $load_to_folder + "_" + (get-date -Format "yyyy_MM_dd_HHmm")
                $app.RenameFolderOnDtsServer($private:My_SSIS_Folder, $load_to_folder, $backupfolder, $instancename)
            }
        }

        # Create a new folder with the folder name.
        if(!($app.FolderExistsOnDtsServer("$private:My_SSIS_Folder\$load_to_folder", $instancename)))
        {
            $app.CreateFolderOnDtsServer($private:My_SSIS_Folder, $load_to_folder, $instancename)
        }

        $ManifestFileFolder =  (Get-Item -Path $manifest_file_withPath) | Split-Path -Parent

        [xml] $PackageList = Get-Content $manifest_file_withPath

        foreach($package in $PackageList.DTSDeploymentManifest.Package)
        {
            $file_found = $false

            # Get package from SVN if folder and revision were specified.
            if($svnfolder -gt "" -and $svnrevision -gt "")
            {
                Download_File_From_SVN $package $svnfolder $svnrevision ""

                $package_withPath = Get_Full_Path_For_File $package

                if($package_withPath -gt "")
                {
                    if(Test-Path $package_withPath)
                    {
                        $file_found = $true
                    }
                }
            }
            # Try to find the package in the same folder as the manifest file.
            if(!($file_found))
            {
               if(Test-Path "$ManifestFileFolder\$package")
               {
                    $package_withPath = "$ManifestFileFolder\$package"
                    $file_found = $true
               }
            }
            if(!($file_found))
            {
                $package_withPath = Get_Full_Path_For_File $package

                if($package_withPath -gt "")
                {
                    if(Test-Path $package_withPath)
                    {
                        $file_found = $true
                    }
                }
            }

            if(!($file_found))
            {
                $errortext = "The Package file for SSIS deployment $package can't be found. The SSIS package can't be automatically loaded, but if you manually load it you may continue. Continue? (Y/N)"

                RaiseError $errortext $true
            }

            #$fullyQualifiedPackage = JOIN-Path -Path $ManifestFileFolder -ChildPath $package
            $PackageNameWithNoExtension = [System.IO.Path]::GetFileNameWithoutExtension($package)

            if($private:My_SSIS_Folder.StartsWith("MSDB\"))
            {
                $private:My_SSIS_Folder = $private:My_SSIS_Folder.Substring(5)
            }

            # If the $load_to_folder is empty then the package is at the root level. 
            # We couldn't rename the folder to back it up, so we'll back up each package that's being reloaded instead.
            if($load_to_folder -eq "" -or $load_to_folder -eq $null)
            {
                if($app.ExistsOnDtsServer("MSDB\$private:My_SSIS_Folder\$PackageNameWithNoExtension", $instancename))
                {
                    $oldpackage = $app.LoadFromDtsServer("MSDB\$private:My_SSIS_Folder\$PackageNameWithNoExtension", $instancename, $null)

                    $backuppackagename = $PackageNameWithNoExtension + "_" + (get-date -Format "yyyy_MM_dd_HHmm")

                    $app.SaveToSQLServerAs($oldpackage, $null, "$private:My_SSIS_Folder\$backuppackagename", $script:servername, $null, $null)
                }
            }

            $loadedpackage = $app.LoadPackage($package_withPath, $null)

            $app.SaveToSQLServerAs($loadedpackage, $null, "$private:My_SSIS_Folder\$load_to_folder\$PackageNameWithNoExtension", $script:servername, $null, $null)
        }
    }
}

Function Execute_SSIS_Package($package_name, $package_folder)
{
    if($package_folder.substring($package_folder.Length - 1) -ne "\")
    {
        $package_folder += "\"
    }
    $package_name = $package_folder + $package_name

    $instancename = $script:servername.Substring(0, $script:servername.IndexOf('\'))

    Write-Host "Executing the package: $package_name on the Server Instance: $instancename"

    [Reflection.Assembly]::LoadWithPartialName("Microsoft.SQLServer.ManagedDTS") | out-null

    $app = New-Object Microsoft.SqlServer.Dts.Runtime.Application
    $package = $app.LoadFromDtsServer($package_name, $instancename, $null)
    $package.Execute()
}

Function Execute_Batch_File($batch_file_name)
{
    $file_found = $false

    $batch_file_name_withPath = Get_Full_Path_For_File $batch_file_name
    if($batch_file_name_withPath -gt "")
    {
        if(Test-Path $batch_file_name_withPath)
        {
            $file_found = $true
        }
    }

    if(!($file_found))
    {
        $errortext = "The batch file: <$batch_file_name> could not be found!  Do you want to continue? (Y/N)"

        RaiseError $errortext $true
    }

    if(!($batch_file_name.EndsWith(".bat")))
    {
        RaiseError "The batch_file_name $batch_file_name doesn't end with '.bat'." $true
    }
    else
    {
        $a = Start-Process -FilePath $batch_file_name_withPath -Wait -passthru -WindowStyle Hidden
        $ret = $a.ExitCode
        if($ret -ne 0)
        {
            RaiseError "The batch file $batch_file_name failed with an exitcode of $ret." $true
        }
    }
}

Function Execute_Powershell_Script($script_command, $script_commandline, $svnfolder, $svnrevision)
{
    if($script_command -eq "")
    {
        RaiseError "Error! A variable named: script_command must be defined and provided with a value in order to execute a PowerShell Script! Continue processing? (Y/N)" $true
    }

    $file_found = $false

    if($svnfolder -gt "" -and $svnrevision -gt "")
    {
        Download_File_From_SVN $script_command $svnfolder $svnrevision ""
    }

    $script_command_withPath = Get_Full_Path_For_File $script_command
    if($script_command_withPath -gt "")
    {
        if(Test-Path $script_command_withPath)
        {
            $file_found = $true
        }
    }

    if(!($file_found))
    {
        $errortext = "The Powershell script: <$script_command> could not be found!  Do you want to continue? (Y/N)"

        RaiseError $errortext $true
    }

    write-host "script_command_withPath = $script_command_withPath"
    write-host "script_commandline = $script_commandline"
    $script_command_with_command_line = '"' + $script_command_withPath + '" ' + $script_commandline
    write-host "script_command = `"$script_command_withPath`" $script_commandline"

    $Global:returnvalue = 0
    Invoke-Expression "& `"$script_command_withPath`" $script_commandline" | write-host

    if($Global:returnvalue -ne 0)
    {
        RaiseError "Error executing PowerShell script <$script_command>." true
    }
}

Function Move_File($sourcefile, $destinationfile, $svnfolder, $svnrevision)
{
    if($sourcefile -eq $null -or $sourcefile -eq "")
    {
        RaiseError "The variable 'sourcefile' must be specified and given a value." true
    }

    if($destinationfile -eq $null -or $destinationfile -eq "")
    {
        RaiseError "The variable 'destinationfile' must be specified and given a value." true
    }

    if($svnfolder -gt "" -and $svnrevision -gt "")
    {
        Download_File_From_SVN $sourcefile $svnfolder $svnrevision ""
    }

    $sourcefile_withPath = Get_Full_Path_For_File $sourcefile

    if($sourcefile_withPath -eq "" -or $sourcefile_withPath -eq $null)
    {
        RaiseError "The source file $sourcefile is not found! The Move File function will not be processed." $true
    }
    elseif (!(Test-Path $sourcefile_withPath))
    {
        RaiseError "The source file $sourcefile is not found! The Move File function will not be processed." $true
    }
    else
    {
        if(Test-Path $destinationfile)
        {
            $bakDestinationFile = $destinationfile + "_" + (get-date -Format "yyyy-MM-dd-hhmmss") + "_.bak"

            Write-Host "The destination file $destinationfile already exists! Renaming file to $bakDestinationFile." $true
            Move-Item $destinationfile $bakDestinationFile
        }

        $destinationDir = Split-Path $destinationfile -Parent

        If(!(Test-Path $destinationDir))
        {
            New-Item $destinationDir -ItemType directory | Out-Null
        }

        If(Test-Path $destinationfile)
        {
            Remove-Item $destinationfile
        }

        Write-Host "Moving file: $sourcefile_withPath to $destinationfile"
	    Move-Item $sourcefile_withPath $destinationfile
    }
}

Function Create_Folder($foldername)
{
    if($foldername -eq $null -or $foldername -eq "")
    {
        RaiseError "The variable 'foldername' must be specified and given a value." true
    }


    If(!(Test-Path $foldername))
    {
        New-Item $foldername -ItemType directory | Out-Null
    }
}


Function Step_Complete
{
    # Send an email if the user said they want to be informed when steps are completed and if an email_recipient has been set up.
    if(($email_after_step_completes -eq "Y" -or $email_after_every_step_completes -eq "Y") -and $email_recipients -gt "")
    {
        $CurrentDate = get-date -Format "yyyy-MM-dd hh:mm:ss"
        Send_Email $email_recipients "Migration process step <$step> completed." "The step <$step> completed processing at $CurrentDate." "NORMAL"
    }

    $script:email_after_step_completes = "N"
}

Function ProcessJSONFile($the_JSON_File, $JSON_File_svnfolder, $JSON_File_svnrevision)
{
    Try
    {
        if($JSON_File_svnfolder -gt "" -and $JSON_File_svnrevision -gt "")
        {
            #read-host "downloading $the_JSON_File from SVN"
            Download_File_From_SVN $the_JSON_File $JSON_File_svnfolder $JSON_File_svnrevision ""
        }

        #write-host "------------------------"
        #write-host "------------------------"
        #write-host ">$the_JSON_File<"
        $the_JSON_File_withPath = Get_Full_Path_For_File $the_JSON_File
        #write-host "------------------------"
        #write-host ">$the_JSON_File_withPath<"
        #write-host "------------------------"
        #write-host "------------------------"
    
        $file_found = $false

        if($the_JSON_File_withPath -gt "")
        {
            if(Test-Path $the_JSON_File_withPath)
            {
                $file_found = $true
            }
        }

        if(!($file_found))
        {
            RaiseError "Can't find the json file: $the_JSON_File" false
        }

        $data = ""
        $data = Get-Content $the_JSON_File_withPath | Out-String | ConvertFrom-Json
        $step = ""

        for ($i=0; $i -le $data.steps.count - 1; $i++)
        {
            $step = $data.steps[$i].step
            $step = Replace_Var_Values($step)

            $command = $data.steps[$i].command
            $Script:Environment = $data.steps[$i].environment
            $DatabaseForScript = ""

            if($Script:ScriptEnvironment -gt "")
            {
                if($Script:ScriptEnvironment -eq $Script:Environment -or $Script:Environment -eq "ALL")
                {
                    Write-Host "Processing Step <$step>"
                }else
                {
                    Write-Host "Skipping Step <$step>. Environment for step ($Script:Environment) does not match the Environment set for this script ($Script:ScriptEnvironment)." -ForegroundColor Cyan
                }
            }

            $Script:variablesforfunction = ""

            # Only setup variables for commands that are set for this environment or set to the environment value of "ALL".
            if($Script:ScriptEnvironment -eq $Script:Environment -or $Script:Environment -eq "ALL" -or $Script:Environment -eq $null)
            {
                for ($x=0; $x -le $data.steps[$i].variables.count - 1; $x++)
                {
                    $variablename = $data.steps[$i].variables[$x].name

                    if($command -eq "setup_variables")
                    {
                        $overridevariable = $data.steps[$i].variables[$x].override
                    }
                    else
                    {
                        $overridevariable = "TRUE"
                    }

                    # if the variable name is set then create the variable with the value,
                    if($variablename -gt "")
                    {
                        # Only create the variable if it doesn't already exist, or if the override variable has been set to TRUE.
                        if($overridevariable -eq "TRUE" -or (!(Test-Path "variable:script:$variablename")))
                        {
                            $variablevalue = $data.steps[$i].variables[$x].value

                            $variablevalue = Replace_Var_Values($variablevalue)

                            $passvariabletofunctions = $data.steps[$i].variables[$x].pass_to_functions

                            if($variablevalue -gt "")
                            {
                                New-Variable -Scope script -Name $variablename -Force -Value $variablevalue
                            }
                            else
                            {
                                # If the variable is not yet created, then create it with no value.
                                if (-not(Get-Variable -Scope script -name $variablename -ErrorAction Ignore))
                                {
                                    New-Variable -Scope script -Name $variablename
                                }
                            }
                        }
                    }

                    if($passvariabletofunctions -eq "TRUE")
                    {
                        $variablevalue = Get-Variable -Scope script -Name $variablename -ValueOnly

                        $Script:variablesforfunction += $variablename + "='" + '"' + "'" + $variablevalue + "'" + '"' + "',"
                        if($command -eq "setup_variables")
                        {
                            $Script:globalvariablesforfunctions += $variablename + "='" + '"' + "'" + $variablevalue + "'" + '"' + "',"
                        }
                    }
                }
            }

            # Strip of the trailing "," if there is one.
            if($Script:variablesforfunction -gt "")
            {
                if($Script:variablesforfunction.Substring($Script:variablesforfunction.Length - 1) -eq ",")
                {
                    $Script:variablesforfunction = $Script:variablesforfunction.Substring(0, $Script:variablesforfunction.Length - 1)
                }
            }

            # Strip of the trailing "," if there is one.
            if($Script:globalvariablesforfunctions -gt "")
            {
                if($Script:globalvariablesforfunctions.Substring($Script:globalvariablesforfunctions.Length - 1) -eq ",")
                {
                    $Script:globalvariablesforfunctions = $Script:globalvariablesforfunctions.Substring(0, $Script:globalvariablesforfunctions.Length - 1)
                }
            }

            # Only run commands that are set for this environment or set to the environment value of "ALL".
            if($command -eq "set_environment")
            {
                # Call the Set_Environment function.
                Set_Environment
            }
            elseif(($Script:ScriptEnvironment -eq $Script:Environment) -or ($Script:Environment -eq "ALL"))
            {
                switch($command)
                {
                    "setup_variables" 
                    {
                        Write-Host "Executing scripts for Databases:"
                        Write-Host "	PRISM_DB: $script:PRISM_DB"
                        Write-Host "	STAGING_DB: $script:STAGING_DB"
                        Write-Host "On the server:"
                        Write-Host "	$script:ServerName"
                        #$Script:Backup_Folder = $Backup_Folder
                        Write-Host "Backup folder:"
                        Write-Host "	$Script:Backup_Folder"
                    }
                    "process_json_file"
                    {
                        $tmpJSON_File = $script:JSON_File
                        $tmpsvnfolder = $script:svnfolder
                        $tmpsvnrevision = $script:svnrevision
                        $script:JSON_File = ""
                        $script:svnfolder = ""
                        $script:svnrevision = ""
                        ProcessJSONFile $tmpJSON_File $tmpsvnfolder $tmpsvnrevision
                        Step_Complete
                        # blank out variables after function is called.
                        $tmpJSON_File = ""
                        $tmpsvnfolder = ""
                        $tmpsvnrevision = ""
                    }
                    "backup_database" {
                                            Backup_Database
                                            Step_Complete
                                      }
                    "execute_script" {
                                        Execute_Script $script:scriptname $script:svnfolder $script:svnrevision
                                        Step_Complete
                                        # blank out variables after function is called.
                                        $script:scriptname = ""
                                        $script:svnfolder = ""
                                        $script:svnrevision = ""
                                        $script:template_script = ""
                                     }
                    "execute_multiple_scripts" {
                                        $script:scripts_array = $data.steps[$i].scripts_array
                                        Execute_Multiple_Scripts
                                        Step_Complete
                                     }
                    "pause_script" {
                                        Pause_Script $script:pause_text
                                        # blank out variables after function is called.
                                        $script:pause_text = ""
                                    }
                    "restore_database" {
                                            Restore_Database $script:db_to_restore $script:file_to_restore_from $script:move_data_from_name $script:move_data_to_name $script:move_log_From_name $script:move_log_to_name
                                            Step_Complete
                                            # blank out variables after function is called.
                                            $script:db_to_restore = ""
                                            $script:file_to_restore_from = ""
                                            $script:move_data_from_name = ""
                                            $script:move_data_to_name = ""
                                            $script:move_log_From_name = ""
                                            $script:move_log_to_name = ""
                                        }
                    "rename_database" {
                                            Rename_Database $script:db_to_rename $script:new_db_name $script:raise_error_if_rename_not_needed $script:confirm_rename
                                            Step_Complete
                                            # blank out variables after function is called.
                                            $script:db_to_rename = ""
                                            $script:new_db_name = ""
                                            $script:raise_error_if_rename_not_needed = ""
                                            $script:confirm_rename = ""
                                      }
                    "execute_verification_sql" {
                                            Execute_Verification_SQL $script:db_to_use $script:sql_to_use $script:sql_script_to_use $script:svnfolder $script:svnrevision $script:comparison_return_value $script:comparison_operator $script:data_type $script:stop_if_not_matching
                                            Step_Complete
                                            # blank out variables after function is called.
                                            $script:db_to_use = ""
                                            $script:sql_to_use = ""
                                            $script:sql_script_to_use = ""
                                            $script:svnfolder = ""
                                            $script:svnrevision = ""
                                            $script:comparison_return_value = ""
                                            $script:comparison_operator = "="
                                            $script:data_type = ""
                                            $script:stop_if_not_matching = "Y"
                                      }
                    "load_ssis_packages" {
                                            Load_SSIS_Packages $script:manifest_file $script:load_to_folder $script:svnfolder $script:svnrevision
                                            Step_Complete
                                            # blank out variables after function is called.
                                            $script:manifest_file = ""
                                            $script:load_to_folder = ""
                                            $script:svnfolder = ""
                                            $script:svnrevision = ""

                                         }
                    "execute_ssis_package" {
                                            Execute_SSIS_Package $script:package_name $script:package_folder
                                            Step_Complete
                                            # blank out variables after function is called.
                                            $script:package_name = ""
                                            $script:package_folder = ""
                                           }
                    "download_file_from_svn" {
                                            Download_File_From_SVN $script:filename $script:svnfolder $script:svnrevision $script:destinationfolder
                                            Step_Complete
                                            # blank out variables after function is called.
                                            $script:filename = ""
                                            $script:svnfolder = ""
                                            $script:svnrevision = ""
                                            $script:destinationfolder = ""
                                           }
                    "execute_batch_file"
                                {
                                    Execute_Batch_File $script:batch_file_name
                                    Step_Complete
                                    # blank out variables after function is called.
                                    $script:batch_file_name = ""
                                }
                    "move_file"
                                {
                                    Move_File $script:sourcefile $script:destinationfile $script:svnfolder $script:svnrevision
                                    Step_Complete
                                    # blank out variables after function is called.
                                    $script:sourcefile = ""
                                    $script:destinationfile = ""
                                    $script:svnfolder = ""
                                    $script:svnrevision = ""
                                }
                    "create_folder"
                                {
                                    Create_Folder $script:foldername
                                    Step_Complete
                                    # blank out variables after function is called.
                                    $script:foldername = ""
                                }
                    "execute_powershell_script"
                                {
                                    Execute_PowerShell_Script $script:script_command $script:script_commandline $script:svnfolder $script:svnrevision
                                    Step_Complete
                                    $script:script_command = ""
                                    $script:script_commandline = ""
                                    $script:svnfolder = ""
                                    $script:svnrevision = ""
                                }
                    "send_email" {
                                    Send_Email $script:email_recipients $script:email_subject $script:email_body $script:email_importance
                                 }
                    "Restore_DEV_From_Last_PRISM_Backup"
                                {
                                    Restore_DEV_From_Last_PRISM_Backup
                                    Step_Complete
                                }
                    "Restore_PRISM_TRN_From_Last_PRISM_Backup"
                                {
                                    Restore_PRISM_TRN_From_Last_PRISM_Backup
                                    Step_Complete
                                    $script:Backup_Folder = ""
                                }
                    Default {Write-Host "Command ($command) does not match any functions in script. Step $step skipped." -ForegroundColor Cyan}
                }
            }

        }

        if((Get-ChildItem $the_JSON_File_withPath).FullName -eq (Get-ChildItem $script:master_json_file).FullName)
        {
            if($script:email_recipients -gt "")
            {
                Send_Email $script:email_recipients "Migration Process Complete" "The migration process is complete.`r`n`r`nOutput can be found in the files:`r`n`t$Script:OutPutFile`r`n`t$Script:MessagesOutPutFile" "NORMAL"
            }
        }
    }
    CATCH
    {
        $errormessage = "Caught an exception!! The message is:" 
        $errormessage += $_.Exception.Message
        RaiseError $errormessage $false
    }
}


Function Download_File_From_SVN($filename, $svnfolder, $svnrevision, $destinationfolder)
{
    if($destinationfolder -eq "")
    {
        if(!($svn_checkout_folder -gt ""))
        {
            $svn_checkout_folder = $default_SVN_Checkout_Folder
        }

        $destinationfolder = $svn_checkout_folder
    }

    if($svnfolder.StartsWith("\"))
    {
        # If the folder starts with a backslash then chop it off.
        $svnfolder = $svnfolder.Substring(1)
    }

    if(!($svnfolder.EndsWith("\")))
    {
        # If the folder doesn't end with a backslash then add it.
        $svnfolder = $svnfolder + "\"
    }

    if(!(Test-Path($destinationfolder)))
    {
        New-Item -Path $destinationfolder -ItemType Directory | Out-Null
    }

    if(Test-Path("$destinationfolder\$filename"))
    {
        Remove-Item "$destinationfolder\$filename"
    }

    $retval, $errmessage = SVN-Download-File "$svnfolder$filename" "$destinationfolder\$filename" $svnrevision
    
    if($retval -ne 1)
    {
        if($errmessage -eq "")
        {
            $errmessage = "An error occurred calling SVN-Download-File."
        }

        RaiseError $errmessage $true
    }

    if(Test-Path("$destinationfolder\$filename"))
    {
        $returnPath = "$destinationfolder\$filename"
    }
    else
    {
        $returnPath = ""
    }

    $returnPath
}




# Call Main function to start processing.
Main
