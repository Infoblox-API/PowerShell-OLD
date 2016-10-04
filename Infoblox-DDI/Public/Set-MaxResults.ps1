<#
    .Synopsis
        Allows changing maximum number of results returned from a query.

    .Description
        Used to change the maximum number of records/results returned from a NIOS query.

    .Parameter max_results
        Requires a positive number value to be provided.

    .Outputs
        Updated max results value

    .Example
        Set-MaxResults 10000

        MaxResults: '10000'

#>

function script:Set-MaxResults {
    Param (
        [Parameter(Mandatory=$true,Position=0)]
            [int]$max_results
    )

    BEGIN {
        Write-Debug "[DEBUG:Set-MaxResults] Begin"
        $okay = $false
    }

    PROCESS {
        # Validate that the string was submitted correctly
        if (($max_results -gt 0) -and ($max_results -lt 1000001)) {
            Write-Debug "[DEBUG:Set-MaxResults] Changing max results from '$script:ib_max_results' to '$max_results'"
            $okay = $true
        } else {
            Write-Error "[ERROR:Set-MaxResults] You must enter a value >0 and <=1000000."
        }
    }

    END {
        if ($okay) {
            $script:ib_max_results = $max_results
            Write-Host "MaxResults  : '$script:ib_max_results'"
        }
    }
}
