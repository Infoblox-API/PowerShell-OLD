Function Get-ConfigInfo {
    <#
    .Synopsis
        Reads the config info from the provided INI file

    .Description
        Accepts a passed INI file or will read the bloxone.ini file in the current directory.
        If [Private] is found with a path key, the one additional INI file will be read.

    .Notes
        Author      : Don Smith <dsmith@infoblox.com>
        Version     : 1.0 - 2020-07-30 - Initial release

    .Inputs
        configFile as System.String

    .Outputs
        iniConfig as System.Collections.Specialized.OrderedDictionary

    .Parameter iniFileName
        Specifies the filename of the INI file to read
        Defaults to ".\bloxone.ini"

    .Example
        $iniConfig = Get-ConfigInfo "custom.ini"
        -----------
        Description
        Reads the custom.ini file in the local directory

    .Example
        $iniConfig = Get-ConfigInfo
        -----------
        Description
        Reads the bloxone.ini file in the local directory

    .Link
        Get-ConfigInfo
    #>

    [CmdletBinding()]
    Param(

        [Parameter(ValueFromPipeline=$True,Mandatory=$False,Position=0)]
        [string]$configFile = "bloxone.ini",

        # Tells us not to create the INI file if we don't find it
        [switch]
        $DoNotCreate
    )

    BEGIN {
        Write-Debug "PsBoundParameters:"
        $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Debug $_ }
        if ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }
        Write-Debug "DebugPreference: $DebugPreference"
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"

        # Check to make sure the file exists
        if (Test-Path $configFile) {
            Write-Debug "$($MyInvocation.MyCommand.Name):: Found $configFile"

            [hashtable]$iniConfig = Get-IniContent $configFile

            # See if we need to load an additional INI file
            if ($iniConfig.Contains("Private")) {
                # Make sure the file exists that we are looking for
                $privateFileName = $iniConfig["Private"].path
                if (Test-Path $privateFileName) {
                    Write-Verbose "$($MyInvocation.MyCommand.Name):: Attempting to load alternate INI file $privateFileName"
                    [hashtable]$privateConfig = (Get-IniContent $privateFileName)

                    # Combine the results from the two files but use the second file as a authoritative value set
                    Write-Verbose "$($MyInvocation.MyCommand.Name):: Combining INI configs ($configFile and $privateFileName)"
                    foreach ($key in $privateConfig.Keys) {
                        $iniConfig[$key] = $privateConfig[$key]
                    }
                    $iniConfig.Remove("Private")
                } else {
                    Write-Debug "Alternate INI file specified not found"
                }
            }
        } else {
            Write-Warning "$configFile was not found"

            if (!$DoNotCreate) {
                # Create a template INI file since one did not exist
                $iniSection = @{“url”=”https://csp.infoblox.com”;”api_version”=”v1”;"api_key"="<your_personal_account_api_key_here>"}
                $iniContent = @{“BloxOne”=$iniSection}
                Out-IniFile -InputObject $iniContent -FilePath $configFile -Loose -Pretty

                $iniConfig = Get-ConfigInfo $configFile -DoNotCreate
            }
        }
    }

    PROCESS {
        #Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing"
    }

    END {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"
        return $iniConfig
    }
}
