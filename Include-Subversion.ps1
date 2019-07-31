### Variables ###
$svnUser = "readonly"
$svnPwd = "readonly"

$svnDllPath = "$PSScriptRoot\SharpSVN\SharpSvn.dll"
$svnServer = "https://p-svr-mfs001/svn/PRISM/"

### Load SharpSVN ###
if (!(Test-Path $svnDllPath)){
    Write-Error "Could not locate $svnDLLPath. Check if present and rerun"
    exit
}
$currentScriptDirectory = Get-Location
#[System.IO.Directory]::SetCurrentDirectory($currentScriptDirectory)
$a = [Reflection.Assembly]::LoadFile($svnDllPath)

# Setup Variables
$mode = [System.IO.FileMode]::Create
$access = [System.IO.FileAccess]::Write
$sharing = [IO.FileShare]::Read

# Create SharpSVN Client Object
$svnClient = New-Object SharpSvn.SvnClient
$svnClient.Authentication.DefaultCredentials = New-Object System.Net.NetworkCredential($svnUser, $svnPwd) 

# Ignore Certificate errors.
$svnClient.Authentication.add_SslServerTrustHandlers({
        $_.AcceptedFailures = $_.Failures
        $_.Save = $True
    })

function SVN-Download-File($svnPath, $localPath, $revision){
    $retval = 0
    $errmessage = ""

    # Build SVN URL 
    if($revision -eq "head")
    {
        $revision = $svnClient.SvnRevision.Head
    }

    [string]$svnUrl = $svnServer + $svnPath 
    $repoUri = New-Object SharpSvn.SvnUriTarget($svnUrl, $revision)

    Write-Host "$repoUri..." -ForegroundColor Green -NoNewline      
	
    try {
        [SharpSvn.SvnInfoEventArgs] $svnInfoEventArgs = $null; 
        $fileexists = $svnClient.GetInfo($repoUri, [ref] $svnInfoEventArgs ); 
    }
    catch {
        $Exception = $_.Exception;
        while ($Exception.Message -ne $null)
        { 
          # Write-Error $Exception.Message;
           $retval = 0
           $fileexists = $false
           $errmessage = $errmessage + $Exception.Message + "; "
           $Exception = $Exception.InnerException;
        }
    }


    if($fileexists)
    {
        # create the FileStream and StreamWriter objects 
        $fs = New-Object IO.FileStream($localPath, $mode, $access, $sharing)
        $res = $svnClient.Write($repoUri, $fs)
	
        if ($res -eq "True"){
            #Write-Host "Done" -ForegroundColor Green
        }else{
            Write-Warning "Failed"
        }
        $fs.Dispose()

        $retval = 1
    }
    else
    {
        $retval = 0
        $errmessage = "The file does not exist at the location: $svnUrl for revision: $revision"
    }

    return $retval, $errmessage
}

function SVN-Checkout-Folder($svnDir, $localDir){
    # Build SVN URL 
    [string]$svnUrl = $svnServer + $svnDir 
    $repoUri = New-Object SharpSvn.SvnUriTarget($svnUrl)
	
    # Write-Host "$repoUri..." -ForegroundColor Green -NoNewline
	
    $res = $svnClient.Checkout($repoUri, $localDir)
	
    if ($res -eq "True"){
        Write-Host "Done" -ForegroundColor Green
    }else{
        Write-Warning "Failed" 
    }
}
