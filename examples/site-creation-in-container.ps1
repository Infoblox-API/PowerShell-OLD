#requires -version 3

##########
#
# Author:  Nicolas Jeanselme
# Email :  njeanselme@infoblox.com
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
    [string]$wapi_ver    = "v1.6",
    [string]$max_results = "_max_results=10000",
    [string]$network     = "3.0.0.0/22",
    [int]$vlan           = 1500,
    [array]$site_structure,
    [switch]$ask_pw,
    [switch]$json,
    [switch]$debug
)

$site_structure=@{"cidr"=25;"num"=2},@{"cidr"=28;"num"=16},@{"cidr"=24;"num"=2}

write-host "Parameters set"

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

#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

##########################
########## MAIN ##########
##########################

$currentScriptName = $MyInvocation.MyCommand.Name
write-host "script: $currentScriptName"


########## Get network container ref ##########


# Request the transaction (GET request for data)
$uri = "$uri_base/networkcontainer?network=$network"

try {
    $results = Invoke-RestMethod -Uri $uri -Credential $credential -Method Get -SessionVariable ib_session
} catch {
    write-host $_.ErrorDetails
    write-host $_.Exception 
    exit 1
}  

$ref = $results._ref
write-host "Authenticating as          : $username"

########## Get next available networks & create it ##########

foreach ($block in $site_structure) {

		$uri = $uri_base+"/"+$ref+"?_function=next_available_network&cidr="+$block.cidr+"&num="+$block.num

		try {
    			$results = Invoke-RestMethod -Uri $uri -Method Post -WebSession $ib_session
		} catch {
			write-host $results
   			write-host $_.ErrorDetails
            write-host $_.Exception 
         	exit 1
		}
		Write-Output "Availables: $($results.networks)"
		
		foreach ($network in $results.networks) {
			$uri = $uri_base+"/network?network="+$network

			try {
    			$results = Invoke-RestMethod -Uri $uri -Method Post -WebSession $ib_session
			} catch {
				write-host $results
   				write-host $_.ErrorDetails
                write-host $_.Exception
    		 	exit 1
			}
			Write-Output "Created successfully $network"


            ##### Handle Extensible Attributes #####
            # Now update the object with the extensible attribute data
            # This data cannot be submitted when creating the object
            $extattrs = @{
                extattrs = @{
                    Site = @{ value = "test" };
                    VLAN = @{ value = "$vlan" };
                }
            }
            $json_text = $extattrs | ConvertTo-Json
            $uri = $uri_base+"/$results"

   			try {
                $results = Invoke-RestMethod -Uri $uri -ContentType "application/json" -Body $json_text -Method PUT -WebSession $ib_session
            } catch {
                write-host $results
                Write-Host $_.ErrorDetails
                Write-Host $_.Exception
            }

		}
}

if ($debug) {
    Write-Host "Total time elapsed: $($dbg_time_elapsed.Elapsed.ToString())"
}
