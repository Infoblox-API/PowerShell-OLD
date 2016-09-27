<#
	.SYNOPSIS
		Uses the JavaScript serializer object.   
#>
function script:ConvertFrom-JSON {
    Param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)] 
            $json
    )

    BEGIN {
        Write-Verbose '[convert-from-json] Begin'
        $ser  = New-Object System.Web.Script.Serialization.JavaScriptSerializer
        $data_array = @()
    }

    PROCESS {
        $data = $ser.DeSerializeObject($json)
        $data_array += $data
    }

    END {
        return $data_array
    }
}
