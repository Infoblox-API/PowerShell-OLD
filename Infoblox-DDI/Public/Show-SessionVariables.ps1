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
        Write-Debug "[DEBUG:Show-SessionVariables] Begin"
    }

    PROCESS {
    }

    END {
        Write-Host "Grid Master : '$script:ib_grid_master'"
        Write-Host "Grid Name   : '$script:ib_grid_name'"
        Write-Host "Grid Ref    : '$script:ib_grid_ref'"
        Write-Host "Max Results : '$script:ib_max_results'"
        Write-Host "URI Base    : '$script:ib_uri_base'"
        Write-Host "Username    : '$script:ib_username'"
        Write-Host "WAPI Version: '$script:ib_wapi_ver'"
    }
}
