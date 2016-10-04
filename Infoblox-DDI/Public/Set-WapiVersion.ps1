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
        # Sets the WAPI version to the value provided
        Set-WapiVersion "v2.3.1"

        WAPI Version: 'v2.3.1'
        URI Base    : 'https://192.168.1.2/wapi/v2.3.1'

    .Example
        # Automatically sets the WAPI version to the highest supported
        Set-WapiVersion

        WAPI Version: 'v2.3.1'
        URI Base    : 'https://192.168.1.2/wapi/v2.3.1'
#>

function script:Set-WapiVersion {
    Param (
        [Parameter(Mandatory=$false,Position=0)]
            [string]$wapi_ver = $null
    )

    BEGIN {
        Write-Debug "[DEBUG:Set-WapiVersion] Begin"
        $okay = $false
    }

    PROCESS {
        # Determine if we need to retrieve the WAPI version from the schema
        if ([string]::IsNullOrEmpty($wapi_ver)) {
            # Get the highest version supported by the Grid
            Write-Debug "[DEBUG:Set-WapiVersion] No version string provided. Getting latest from the schema."

            $ibschema = Get-IBSchema
            if ($ibschema -eq $false) {
                # We have some error condition; abort
                Write-Debug "[DEBUG:Set-WapiVersion] Error retrieving schema. Can't set WAPI version."
            }
            else {
                $lastItem       = $ibschema.supported_versions.Count - 1
                $highestVersion = $ibschema.supported_versions.Item($lastItem)
                $wapi_ver       = "v" + $highestVersion
                Write-Host "[Set-WapiVersion] Automatically selected '$wapi_ver' from the schema"
            }
        }

        # Validate that the string is in the correct format
        if ($wapi_ver -match "v[1-9]{1,}\.*[0-9]*") {
            Write-Debug "[DEBUG:Set-WapiVersion] '$wapi_ver' matched regex" 
            Write-Host "[Set-WapiVersion] Changing WAPI version from '$script:ib_wapi_ver' to '$wapi_ver'"
            $okay = $true
        }
        else { 
            Write-Debug "[DEBUG:Set-WapiVersion] No match on regex and not null: '$wapi_ver'"
            Write-Error "[ERROR:Set-WapiVersion] You entered a WAPI version string in the wrong format.  Try 'v#.#' (for example, v1.3)."
        }
    }

    END {
        if ($okay) {
            $script:ib_wapi_ver = $wapi_ver
            Write-Host "WAPI Version: '$script:ib_wapi_ver'"

            $script:ib_uri_base = "https://$script:ib_grid_master/wapi/$script:ib_wapi_ver"
            Write-Host "URI Base    : '$script:ib_uri_base'"
        }

        return $okay
    }
}
