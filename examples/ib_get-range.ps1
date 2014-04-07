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
    [string]$outfile     = "get-range.csv",
    [string]$wapi_ver    = "v1.2",
    [string]$max_results = "_max_results=10000",
    [switch]$ask_pw,
    [switch]$json,
    [switch]$debug,
	[string]$x,
    [string]$fields
)
Write-Output ""

$dbg_time_elapsed = [System.Diagnostics.Stopwatch]::StartNew()

##########
# Set defaults
$def_rfields = "network,start_addr,end_addr,comment,network_view"

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

if (!$x) {
	$x = $( Read-Host -Prompt "Enter a valid search string" )
}

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

# Search for the object reference
$uri_search = "search"+'?'+"objtype=range&search_string~=$x"
$uri        = "$uri_base/$uri_search"
try {
    $results = Invoke-RestMethod -Uri $uri -Credential $credential -Method Get -SessionVariable ib_session
} catch {
    write-host $_.ErrorDetails
    exit 1
}  

# Get just the references and then loop to grab the data
$my_results = $results | Select "_ref"

$count = $results.count
Write-Output "Authenticating as: $username"
Write-Output "Base URI         : $uri_base"
Write-Output "Search URI       : $uri_search"
Write-Output "Full URI         : $uri"

foreach ($record in $my_results) {
    $ref = $( $record._ref )
    if ($fields) {
        $rfields = "$def_rfields,$fields"
    } else {
        $rfields = $def_rfields
    }
    $uri = "$uri_base/$ref"+'?'+"_return_fields=$rfields"
    Write-Output "Object URI   : $uri"
	$results = Invoke-RestMethod -Uri "$uri" -Method Get -Websession $ib_session

    if ((!$debug) -and ($count -gt 0)) {
	    if ($json) {
		    $results | Out-File -FilePath $outfile -Append
	    } else {
		    $results | Export-Csv $outfile -NoTypeInformation -Encoding UTF8
	    }
    } else {
        $results
    }
}

Write-Output ""

if ($debug) {
	Write-Host "Total time elapsed: $($dbg_time_elapsed.Elapsed.ToString())"
}
