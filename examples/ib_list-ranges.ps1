#requires -version 3

##########
#
# Author:  Don Smith
# Email :  don@infoblox.com
#       :  smithdonalde@gmail.com
# This script is provided as is.  Use at your own risk.

##########
#
# Remember to enable powershell scripts to run on your system
#    example >> Set-ExecutionPolicy -ExecutionPolicy Unrestricted
#

##########
# Default values and command line parameters
#    switch ask_pw will securely prompt for the password
#    Standardize the following options:
#       g = grid_master, u = username, p = password, a = ask_pw, d = debug
#    Assume all other options would need fully qualification
Param (
    [string]$grid_master = "192.168.1.2",
    [string]$username    = "admin",
    [string]$password    = "infoblox",
    [string]$outfile     = "list-ranges.csv",
    [string]$wapi_ver    = "v1.0",
    [string]$max_results = "_max_results=10000",
    [switch]$ask_pw,
    [switch]$json,
    [switch]$debug
)
Write-Output ""

$dbg_time_elapsed = [System.Diagnostics.Stopwatch]::StartNew()

##########
# Set defaults

##########
# Build the values that need built
if ($ask_pw) {
    $secure_pw = $( Read-Host -Prompt "Enter password" -AsSecureString )
    Write-Output ""
} else {
    $secure_pw = ConvertTo-SecureString $password -AsPlainText -Force
}
$credential = New-Object System.Management.Automation.PSCredential ($username, $secure_pw)
$uri_base = "https://$grid_master/wapi/$wapi_ver"


##########
# Do the following to ignore self-signed certificates
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

##########################
########## MAIN ##########
##########################

$currentScriptName = $MyInvocation.MyCommand.Name
write-host "script: $currentScriptName"


# Request the transaction (GET request for data)
$uri = "$uri_base/range"
try {
    $results = Invoke-RestMethod -Uri $uri -Credential $credential -Method Get -SessionVariable ib_session
} catch {
    write-host $_.ErrorDetails
    exit 1
}  

$count = $results.count
Write-Output "Authenticating as          : $username"
Write-Output "Full URI                   : $uri"
Write-Output "Number of records retrieved: $count"

if ((!$debug) -and ($count -gt 0)) {
    if ($json) {
        $results | Out-File -FilePath $outfile #-NoClobber
    } else {
        $results | Export-Csv $outfile -NoTypeInformation -Encoding UTF8 #-NoClobber
    }

    Write-Output "Saved file to              : $outfile"
} else {
    $results
}
Write-Output ""

if ($debug) {
	Write-Host "Total time elapsed: $($dbg_time_elapsed.Elapsed.ToString())"
}
