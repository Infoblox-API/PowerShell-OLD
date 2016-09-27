<#
	.Synopsis
		Allows changing the WAPI version.
		
	.Description
		The WAPI version may need to change for some functions that perform differently between versions
	
	.Parameter wapi_ver
		Requires the new string be entered in "vX.Y" format
	
	.Outputs
		Updated URI value
	
	.Example
		Set-WapiVersion "v3.0"
		
		URI Base    : 'https://192.168.1.2/wapi/v3.0'
		WAPI Version: 'v3.0'

#>

function script:Set-WapiVersion {
	Param (
        [Parameter(Mandatory=$true,Position=0)]
            [string]$wapi_ver
	)

	BEGIN {
		$okay = $false
	}
	
	PROCESS {
		# Validate that the string was submitted correctly
		if ($wapi_ver -match "v[1-9]{1,}\.*[0-9]*") {
			Write-Debug "[DEBUG] Changing WAPI version from '$ib_wapi_ver' to '$wapi_ver'"
			$okay = $true
		} else {
			Write-Host "[ERROR] You entered a WAPI version string in the wrong format.  Try 'v#.#' (for example, v1.3)."
		}
	}
	
	END {
		if ($okay) {
			$script:ib_wapi_ver = $wapi_ver
			$script:ib_uri_base = "https://$script:ib_grid_master/wapi/$script:ib_wapi_ver"

			Write-Host "URI Base    : '$script:ib_uri_base'"
			Write-Host "WAPI Version: '$script:ib_wapi_ver'"
		}
	}
}
