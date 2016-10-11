<#
    .Synopsis
        Sets the value of an EA to the value passed

    .Description
        Used to set the value for an EA

    .Parameter name
        The name of the extensible attribute (EA) to set a value for

    .Parameter value
        The value of the extensible attribute

    .Outputs
        Hash object with the EA set to the appropriate value

    .Example
        # Sets the State to VA
        Set-ExtensibleAttribute "State" "VA"
#>

function script:Set-ExtensibleAttribute {
    Param (
        [Parameter(Mandatory=$true,Position=0)]
            [string]$name,
        [Parameter(Mandatory=$true,Position=1)]
            [string]$value
    )

    BEGIN {
        Write-Debug "[DEBUG:Set-ExtensibleAttribute] Begin"
        $eaHash = @{}
    }

    PROCESS {
        # Define a hash for the current pair of objects
        $myEA = @{}

        #### Does not currently handle a multi-value EA
        # Add the value to the 'value' key
        $myEA.Add("value", $value)

        # Now add the key ('name') and add the value object
        $eaHash.Add($name, $myEA)
    }

    END {
        Write-Debug "[DEBUG:Set-ExtensibleAttribute] End"
        return $eaHash
    }
}
