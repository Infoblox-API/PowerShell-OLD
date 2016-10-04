<#
    .Synopsis
        Encodes the search URI
    .Description
        Specific characters must be replaced with hex values or WAPI (or PowerShell) may choke.
    .Parameter uri_string
        A string in WAPI URI compatible format.
    .Outputs
        Encoded version of the string
    .Example
        ConvertTo-URIEncodedFormat $my_searchString
#>
function script:ConvertTo-URIEncodedFormat {
    Param (
        [Parameter(Mandatory=$true,Position=0)]
            [string]$uri_string
    )
    BEGIN {
        Write-Debug "[DEBUG:ConvertTo-URIEncodedFormat] Begin"
    }
    PROCESS {
        # Make a copy of the string
        $uri = $uri_string
        # Replace the <SPACE> with a "%20"
        $uri = $uri -replace ' ', "%20"
        # Replace the <EXCLAMATION> with a "%21"
        $uri = $uri -replace '!', "%21"
        # Replace the <ASTERISK> with a "%2A"
        #$uri = $uri -replace '*', "%2A"
        # Replace the <PLUS> with a "%2B"
        $uri = $uri -replace '\+', "%2B"

        Write-Debug "[DEBUG:ConvertTo-URIEncodedFormat] Original: '$uri_string'"
        Write-Debug "[DEBUG:ConvertTo-URIEncodedFormat] New     : '$uri'"
    }
    END {
        return $uri
    }
}