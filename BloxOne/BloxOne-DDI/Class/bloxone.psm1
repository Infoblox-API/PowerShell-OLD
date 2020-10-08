#Requires -Version 7.0


# Define the complete list of valid application API URLs
enum appUrls {
    host_app
    ddi 
    dns_data #likely an invalid value (converting to ddi.dns.data below per current documentation)
    anycast
    #atcfw
    #atcep
    #atcdfp
    #atclad
}

class BloxOne {
    # Hide these from general display because of the API key
    hidden [string] $apiKey
    hidden [hashtable] $headers

    [string] $apiVersion
    [string] $baseUrl

    [appUrls] $appUrl
    [string] $objectUrl = $null
    [psobject] $result = $null

    ################################################
    # Hidden constructors to set defaults where applicable
    hidden Init(
        [appUrls]$appUrl
    ) {
        $this.appUrl = $appUrl
    }

    ################################################
    # CONSTRUCTORS

    # Default constructor
    BloxOne() {
        $this.baseUrl = "https://csp.infoblox.com"
        $this.apiVersion = "v1"
    }

    # Constructor with specific values provided
    BloxOne(
        [string]$apiKey,
        [string]$baseUrl,
        [string]$apiVersion
    )
    {
        $this.SetBaseValues($apiKey, $baseUrl, $apiVersion)
    }

    # Constructor with config file and section provided
    BloxOne(
        [string]$configFile = "bloxone.ini",
        [string]$configSection = "BloxOne"
    )
    {
        [hashtable]$iniConfig = Get-ConfigInfo -configFile $configFile

        # Define the header information
        if ($iniConfig.ContainsKey($configSection)) {
            $this.SetBaseValues($iniConfig[$configSection].api_key, $iniConfig[$configSection].url, $iniConfig[$configSection].api_Version)
        } else {
            Write-Warning "The section '$configSection' was not found."
        }
    }

    # Method to set or update values of key fields
    [void] SetBaseValues (
        [string]$apiKey,
        [string]$baseUrl,
        [string]$apiVersion
    )
    {
        $this.apiKey = $apiKey
        $this.headers = @{"content-type" = "application/json"; "Authorization" = "Token $($this.apiKey)"}
        $this.baseUrl = $baseUrl
        $this.apiVersion = $apiVersion
    }

    # Method override for ToString()
    [string] ToString ()
    {
        return "baseUrl: " + $this.baseUrl + ", apiVersion: " + $this.apiVersion
    }

    # Perform a GET request without arguments or payload
    [boolean] GetRequest ([string] $obj)
    {
        [string] $urlArgs = $null
        [string] $jsonBody = $null

        return $this.GetRequest($obj, $urlArgs, $jsonBody)
    }

    # Perform a GET request with arguments
    [boolean] GetRequest ([string] $obj, [string] $urlArgs = $null)
    {
        [string] $jsonBody = $null

        return $this.GetRequest($obj, $urlArgs, $jsonBody)
    }

    # Perform a GET request with arguments and a payload
    [boolean] GetRequest ([string] $obj, [string] $urlArgs = $null, [string] $jsonBody = $null)
    {
        # Clear/initialize the result buffer
        $this.result = @{}

        # Make sure we have an app API to use
        if ([string]::IsNullOrEmpty($this.appUrl)) {
            # Eventually change this to an error
            Write-Warning "appUrl does not have a value"
            return $false
        }

        # Verify $obj begins with a "/"
        if ($obj -match '^/') {
            Write-Verbose "$obj begins with '/'"
        } else {
            $obj = "/" + $obj
            Write-Verbose "$obj updated to include leading '/'"
        }

        # Build the object URL or what we are looking for
        $this.objectUrl = $this.baseUrl + "/api/" + $this.appUrl + "/" + $this.apiVersion + "$obj"

        # Add the arguments to the URL
        if ([string]::IsNullOrEmpty($urlArgs) -ne $true) {
            if ($urlArgs -match '^\?') {
                Write-Verbose "$urlArgs begins with '?'"
            } else {
                $urlArgs = "?" + $urlArgs
                $this.objectUrl = $this.objectUrl + $urlArgs
                Write-Verbose "$urlArgs updated to include leading '?'"
            }
        } else {
            Write-Verbose "no arguments passed (null or empty)"
        }

        Write-Verbose "objectUrl = $($this.objectUrl)"

        # This is for an inherited object but it may be something custom as well
        if ([string]::IsNullOrEmpty($this.objectUrl) -ne $true ) {

            try {
                #[PSObject] $data  = Invoke-RestMethod -Method Get -Uri $this.objectUrl -Headers $this.headers -ContentType "application/json"
                # Branch here if we have a payload to include in the request
                [PSObject] $data  = Invoke-RestMethod -Method Get -Uri $this.objectUrl -Headers $this.headers

                # Some results are "result" and some are "results"
                if ($data.result.length) {
                    $this.result = $data.result
                } elseif ($data.results.length) {
                    $this.result = $data.results
                }

            } catch {
                # Get the actual message from the provider
                $reasonPhrase = $_.Exception.Message
                Write-Error $reasonPhrase
                return $false
            }
            Write-Verbose "# of results: $($this.result.length)"

            return $true
        }
        Write-Verbose "objectUrl was empty or null"
        return $false
    }

    # Perform a POST request with a payload
    [boolean] CreateRequest ([string] $obj, [string] $jsonBody)
    {
        # Clear/initialize the result buffer
        $this.result = @{}

        # Make sure we have object data to send
        if ([string]::IsNullOrEmpty($jsonBody)) {
            # Eventually change this to an error
            Write-Warning "object data was not supplied (jsonBody)"
            return $false
        }

        # Make sure we have an app API to use
        if ([string]::IsNullOrEmpty($this.appUrl)) {
            # Eventually change this to an error
            Write-Warning "appUrl does not have a value"
            return $false
        }

        # Verify $obj begins with a "/"
        if ($obj -match '^/') {
            Write-Verbose "$obj begins with '/'"
        } else {
            $obj = "/" + $obj
            Write-Verbose "$obj updated to include leading '/'"
        }

        # Build the object URL or what we are looking for
        $this.objectUrl = $this.baseUrl + "/api/" + $this.appUrl + "/" + $this.apiVersion + "$obj"

        Write-Verbose "objectUrl = $($this.objectUrl)"

        # This is for an inherited object but it may be something custom as well
        if ([string]::IsNullOrEmpty($this.objectUrl) -ne $true ) {

            try {
                #[PSObject] $data  = Invoke-RestMethod -Method Get -Uri $this.objectUrl -Headers $this.headers -ContentType "application/json"
                # Branch here if we have a payload to include in the request
                [PSObject] $data  = Invoke-RestMethod -Method POST -Uri $this.objectUrl -Headers $this.headers -Body $jsonBody

                # Some results are "result" and some are "results"
                if ($data.result.length) {
                    $this.result = $data.result
                } elseif ($data.results.length) {
                    $this.result = $data.results
                }

            } catch {
                # Get the actual message from the provider
                $reasonPhrase = $_.Exception.Message
                Write-Error $reasonPhrase
                return $false
            }
            Write-Verbose "# of results: $($this.result.length)"

            return $true
        }
        Write-Verbose "objectUrl was empty or null"
        return $false
    }

    # Perform a PATCH request with a payload
    [boolean] UpdateRequest ([string] $obj, [string] $jsonBody)
    {
        # Clear/initialize the result buffer
        $this.result = @{}

        # Make sure we have object data to send
        if ([string]::IsNullOrEmpty($jsonBody)) {
            # Eventually change this to an error
            Write-Warning "object data was not supplied (jsonBody)"
            return $false
        }

        # Make sure we have an app API to use
        if ([string]::IsNullOrEmpty($this.appUrl)) {
            # Eventually change this to an error
            Write-Warning "appUrl does not have a value"
            return $false
        }

        # Verify $obj begins with a "/"
        if ($obj -match '^/') {
            Write-Verbose "$obj begins with '/'"
        } else {
            $obj = "/" + $obj
            Write-Verbose "$obj updated to include leading '/'"
        }

        # Build the object URL or what we are looking for
        $this.objectUrl = $this.baseUrl + "/api/" + $this.appUrl + "/" + $this.apiVersion + "$obj"

        Write-Verbose "objectUrl = $($this.objectUrl)"

        # This is for an inherited object but it may be something custom as well
        if ([string]::IsNullOrEmpty($this.objectUrl) -ne $true ) {

            try {
                #[PSObject] $data  = Invoke-RestMethod -Method Get -Uri $this.objectUrl -Headers $this.headers -ContentType "application/json"
                # Branch here if we have a payload to include in the request
                [PSObject] $data  = Invoke-RestMethod -Method PATCH -Uri $this.objectUrl -Headers $this.headers -Body $jsonBody

                # Some results are "result" and some are "results"
                if ($data.result.length) {
                    $this.result = $data.result
                } elseif ($data.results.length) {
                    $this.result = $data.results
                }

            } catch {
                # Get the actual message from the provider
                $reasonPhrase = $_.Exception.Message
                Write-Error $reasonPhrase
                return $false
            }
            Write-Verbose "# of results: $($this.result.length)"

            return $true
        }
        Write-Verbose "objectUrl was empty or null"
        return $false
    }

    # Perform a DELETE request
    [boolean] DeleteRequest ([string] $obj)
    {
        # Clear/initialize the result buffer
        $this.result = @{}

        # Make sure we have an app API to use
        if ([string]::IsNullOrEmpty($this.appUrl)) {
            # Eventually change this to an error
            Write-Warning "appUrl does not have a value"
            return $false
        }

        # Verify $obj begins with a "/"
        if ($obj -match '^/') {
            Write-Verbose "$obj begins with '/'"
        } else {
            $obj = "/" + $obj
            Write-Verbose "$obj updated to include leading '/'"
        }

        # Build the object URL or what we are looking for
        $this.objectUrl = $this.baseUrl + "/api/" + $this.appUrl + "/" + $this.apiVersion + "$obj"

        Write-Verbose "objectUrl = $($this.objectUrl)"

        # This is for an inherited object but it may be something custom as well
        if ([string]::IsNullOrEmpty($this.objectUrl) -ne $true ) {

            try {
                #[PSObject] $data  = Invoke-RestMethod -Method Get -Uri $this.objectUrl -Headers $this.headers -ContentType "application/json"
                # Branch here if we have a payload to include in the request
                [PSObject] $data  = Invoke-RestMethod -Method DELETE -Uri $this.objectUrl -Headers $this.headers

                # Some results are "result" and some are "results"
                if ($data.result.length) {
                    $this.result = $data.result
                } elseif ($data.results.length) {
                    $this.result = $data.results
                }

            } catch {
                # Get the actual message from the provider
                $reasonPhrase = $_.Exception.Message
                Write-Error $reasonPhrase
                return $false
            }
            Write-Verbose "# of results: $($this.result.length)"

            return $true
        }
        Write-Verbose "objectUrl was empty or null"
        return $false
    }

}

class OPH : BloxOne {
    # Default constructor
    OPH() : base() {
        $this.Init("host_app")
    }

    # Constructor with specific values provided
    OPH([string]$apiKey, [string]$baseUrl, [string]$apiVersion) : base($apiKey, $baseUrl, $apiVersion)
    {
        $this.Init("host_app")
    }

    # Constructor with config file and section provided
    OPH([string]$configFile, [string]$configSection) : base($configFile, $configSection)
    {
        $this.Init("host_app")
    }
}

class DDI : BloxOne {
    # Default constructor
    DDI() : base() {
        $this.Init("ddi")
    }

    # Constructor with specific values provided
    DDI([string]$apiKey, [string]$baseUrl, [string]$apiVersion) : base($apiKey, $baseUrl, $apiVersion)
    {
        $this.Init("ddi")
    }

    # Constructor with config file and section provided
    DDI([string]$configFile, [string]$configSection) : base($configFile, $configSection)
    {
        $this.Init("ddi")
    }
}

class DNS : BloxOne {
    # Default constructor
    DNS() : base() {
        #$this.Init("dns_data")
        $this.Init("ddi")
    }

    # Constructor with specific values provided
    DNS([string]$apiKey, [string]$baseUrl, [string]$apiVersion) : base($apiKey, $baseUrl, $apiVersion)
    {
        #$this.Init("dns_data")
        $this.Init("ddi")
    }

    # Constructor with config file and section provided
    DNS([string]$configFile, [string]$configSection) : base($configFile, $configSection)
    {
        #$this.Init("dns_data")
        $this.Init("ddi")
    }
}