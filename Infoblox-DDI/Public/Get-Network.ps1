<#
	.Synopsis
		Get an Infoblox network based on the reference passed.
		
	.Description
		Get the referenced network from the Grid database.
		
	.Parameter _ref
		The network reference obtained from a 'find' operation
		
	.Outputs
		An object array of name/value pairs
		
	.Example
		Get-Network $ref
	
		Get a network that has the reference indicated
		
#>

function script:Get-Network {
    Param (
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
            [string]$_ref
    )

    BEGIN {
        [hashtable[]]$data_array = $null
    }

    PROCESS {
        Write-Verbose "[get-member] $_ref"
        # Specify the extra fields to return
        $return_fields = "comment,extattrs,members"

        # Get the data being requested
        $local_results = Get-Object -_ref $_ref -_return_fields $return_fields

        # Add the data to our array
        $data_array += $local_results
    }

    END {
        return $data_array
    }
}