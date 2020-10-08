Function Get-DDIUrls {
  <#
    .Synopsis
      Constructs the BaseURL for all BloxOne API calls

    .Description
      Creates the base URL for all application specific API calls

    .Notes
      Author    : Don Smith <dsmith@infoblox.com>
      Version   : 1.0 - 2020-07-29 - Initial release
                : 1.1 - 2020-08-04 - Cleaned up notes
                : 1.2 - 2020-08-05 - Added 'anycastUrl' as an additional return item

    .Inputs
      CSP Hostname URI as String
      API Version as String
      iniConfig as hashtable
      iniSection as String

    .Outputs
      System.Collections.Specialized.OrderedDictionary

    .Parameter cspBaseUrl
      Specifies the URI paths for all APIs to the Cloud Services Portal (CSP).
      Defaults to "https://csp.infoblox.com"

    .Parameter apiVersion
      Specifies the API version
      Defaults to "v1"

    .Parameter iniConfig
      Provides the Config hashtable
      Requires iniSection to be provided as well

    .Parameter iniSection
      Specifies the section in the config hashtable to use
      Requires iniConfig to be provided as well

    .Example
      [hashtable]$cspUrls = Get-DDIUrls "https://csp.infoblox.com/" "v1"
      -----------
      Description
      Accesses the production CSP system, all applications, using API version 1

    .Example
      $cspUrls = Get-DDIUrls
      -----------
      Description
      Accesses the production CSP system, all applications, using API version 1

    .Example
      $cspUrls = Get-DDIUrls -iniConfig $iniConfig -iniSection "Sample"
      -----------
      Description
      Accesses the production CSP system, all applications, using API version 1

    .Link
      Get-DDIUrls
  #>

  [CmdletBinding()]
    Param(
      [Parameter(ValueFromPipeline=$True,Mandatory=$False,Position=0)]  
      [string]$cspBaseUrl = "https://csp.infoblox.com",

      [Parameter(ValueFromPipeline=$True,Mandatory=$False,Position=1)]  
      [string]$apiVersion = "v1",

      [Parameter(Mandatory=$False)]
      [hashtable]$iniConfig,

      [Parameter(Mandatory=$False)]
      [string]$iniSection
    )

  BEGIN {
    Write-Debug "PsBoundParameters:"
    $PSBoundParameters.GetEnumerator() | ForEach-Object { Write-Debug $_ }
    if ($PSBoundParameters['Debug']) {
        $DebugPreference = 'Continue'
    }
    Write-Debug "DebugPreference: $DebugPreference"
    Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"


    # Build the list of apps that will be needed for creating the URLs
    [hashtable]$cspApps = @{ipamUrl = "ddi"; dnsAppUrl = "ddi.dns.data"; hostAppUrl = "host_app"; anycastUrl = "anycast"}

    # See if we were passed an INI file and section
    if (($PSBoundParameters.ContainsKey('iniConfig') -eq $True) -and ($PSBoundParameters.ContainsKey('iniSection') -eq $True)) {
      # Look for the section inside the config to grab the cspHostname and apiVersion
      Write-Verbose "$($MyInvocation.MyCommand.Name):: iniConfig and iniSection provided"
      if ($iniConfig.Contains($iniSection) -eq $True) {

        # The section exists, now grab the values temporarily
        $tempUrl = $iniConfig.($iniSection).url
        $tempApiVersion = $iniConfig.($iniSection).api_version
        Write-Verbose "$($MyInvocation.MyCommand.Name)>> config section variables { $tempUrl, $tempApiVersion }"

        # If explicitly passed, we will use the cspHostname provided
        if ($PsBoundParameters.ContainsKey('cspBaseUrl') -eq $False) {
          Write-Verbose "$($MyInvocation.MyCommand.Name):: Updating cspBaseUrl with $tempUrl"
          $cspBaseUrl = $tempUrl
        }

        # If explicitly passed, we will use the apiVersion provided
        if ($PsBoundParameters.ContainsKey('apiVersion') -eq $False) {
          Write-Verbose "$($MyInvocation.MyCommand.Name):: Updating apiVersion with $tempApiVersion"
          $apiVersion = $tempApiVersion
        }

      } else {
        # The section does not exist
        Write-Error "$iniSection does not exist in the INI Config data"
      }
    } else {
      Write-Verbose "$($MyInvocation.MyCommand.Name):: no iniConfig and/or iniSection"
    }

    # Loop through the apps and create the Url
    [hashtable]$hashUrl = @{}

    $cspApps.GetEnumerator() | ForEach-Object {
      # Store the values to work with later
      $keyName = $_.Name
      $appName = $_.Value

      # Build the URL for the specific app
      Write-Debug "calling out to Get-BaseUrl"
      $appUrl = Get-BaseUrl -cspBaseUrl $cspBaseUrl -cspApp $appName -apiVersion $apiVersion
      Write-Debug "returned from Get-BaseUrl"
      Write-Verbose "$($MyInvocation.MyCommand.Name)>> key = $keyName, app = $appName, url = $appUrl"

      # Add the app URL to the app so we can index it later
      $hashUrl[$keyName] = $appUrl
    }

  }

  PROCESS {
    #Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing"
  }

  END {
    Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"
    return [hashtable]$hashUrl;
  }

}
