#Requires -Version 7.0

class BloxOneSession {
    [string] $apiVersion = "v1"
    [string] $cspUrl = "https://csp.infoblox.com"
    [string] $baseUrl = $null
    [string] $apiKey = $null
    [hashtable] $headers = @{"content-type" = "application/json"}
    [Microsoft.PowerShell.Commands.WebRequestSession] $session = $null

    # Purpose: Establish a connection to CSP and save the session for future use
    [void] __INIT__ ($apiKey) {
        $this.apiKey = $apiKey

        $this.headers["Authorization"] = "Token $($apiKey)"
        $webSession = $null

        $this.baseUrl = $this.cspUrl + "/api/host_app/" + $this.apiVersion + "/"
        $objUrl = $this.baseUrl + "on_prem_hosts"
        $objArgs = @{"_filter" = "display_name~""/^0/"""}

        Invoke-RestMethod -Method Get -Uri $objUrl -Headers $this.headers -Body $objArgs -SessionVariable webSession
        $this.session = $webSession
    }

    BloxOneSession ($apiKey) {
        $this.__INIT__($apiKey)
    }

    BloxOneSession ($apiVersion, $cspUrl, $apiKey) {
        $this.apiVersion = $apiVersion
        $this.cspUrl = $cspUrl
        $this.__INIT__($apiKey)
    }
}
