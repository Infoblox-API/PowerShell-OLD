<#
	.Synopsis
		Show the values that are being used by the script for the active session
		
	.Description
		Show values for all of the "script" local variables that are used during various connection attempts.
		
	.Outputs
		Simple table of values

#>

function script:Show-SessionVariables {
	BEGIN {
	}
	
	PROCESS {
	}
	
	END {
		Write-Host "Grid Master : '$ib_grid_master'"
		Write-Host "Grid Name   : '$ib_grid_name'"
		Write-Host "Grid Ref    : '$ib_grid_ref'"
		Write-Host "URI Base    : '$ib_uri_base'"
		Write-Host "Username    : '$ib_username'"
		Write-Host "WAPI Version: '$ib_wapi_ver'"
	}
}
