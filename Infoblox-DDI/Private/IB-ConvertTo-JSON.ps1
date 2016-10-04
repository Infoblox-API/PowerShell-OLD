<#
    .SYNOPSIS
        Uses the JavaScript serializer object. The built-in PS ConvertTo-Json script is broken for nested extattr information.
#>
function script:IB-ConvertTo-JSON {
    Param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
            $data
    )

    BEGIN {
        Write-Debug '[DEBUG:IB-ConvertTo-JSON] Begin'
        $ser  = New-Object System.Web.Script.Serialization.JavaScriptSerializer
        $data_array = @()
    }

    PROCESS {
        $json = $ser.Serialize($data)
        $data_array += $json
    }

    END {
        return $data_array
    }
}