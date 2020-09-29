Function QueryGitLabAPI {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true,
                   HelpMessage='A hash table used for splatting against Invoke-WebRequest.',
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        $Request,

        [Parameter(Mandatory=$false,
                   HelpMessage='Provide a datatype for the returing objects.',
                   Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$ObjectType,

        [Parameter(Mandatory=$false,
                   HelpMessage='Return the response as string')]
        [switch]$AsString,

        [Parameter(Mandatory=$false,
                   HelpMessage='Provide API version to use',
                   Position=2)]
        [ValidateNotNullOrEmpty()]
        [string]$Version = 'v4'
    )

    $GitLabConfig = ImportConfig

    if ($GitLabConfig.APIVersion) { $Version = "v$($GitLabConfig.APIVersion)" }

    $Domain = $GitLabConfig.Domain
    if ( $IsWindows -or ( [version]$PSVersionTable.PSVersion -lt [version]"5.99.0" ) ) {
        $Token = DecryptString -Token $GitLabConfig.Token
    } elseif ( $IsLinux -or $IsMacOS ) {
        $Token = $GitLabConfig.Token
    }
    $Headers = @{
        'PRIVATE-TOKEN'=$Token;
    }

    $Request.Add('Headers',$Headers)
    $Request.URI = "$Domain/api/$Version" + $Request.URI
    $Request.UseBasicParsing = $true

    try {
        #https://docs.microsoft.com/en-us/dotnet/api/system.net.securityprotocoltype?view=netcore-2.0#System_Net_SecurityProtocolType_SystemDefault
        if ($PSVersionTable.PSVersion.Major -lt 6 -and [Net.ServicePointManager]::SecurityProtocol -notmatch 'Tls12') {
            Write-Verbose "Enabling TLS 1.2"
            [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
        }
    }
    catch {
        Write-Warning -Message 'Adding TLS 1.2 to supported security protocols was unsuccessful.'
    }

    try  {
        $ProgressPreference = 'SilentlyContinue'
        Write-Verbose "URL: $($Request.URI)"
        $webContent = Invoke-WebRequest @Request
        $totalPages = if ($webContent.Headers.ContainsKey('X-Total-Pages')) {
            (($webContent).Headers['X-Total-Pages']).tostring() -as [int]
        } else { 0 }

        if ($webContent.rawcontentlength -eq 0 ) { break; }

        if ($AsString) {
            $ObjectType = 'string'
            $Results = @($webContent.RawContent -split "`r`n")
        }
        else {
            $bytes = $webContent.Content.ToCharArray() | Foreach-Object{ [byte]$_ }
            $Results = [Text.Encoding]::UTF8.GetString($bytes) | ConvertFrom-Json
            for ($i=1; $i -lt $totalPages; $i++) {
                $newRequest = $Request.PSObject.Copy()
                if ( $newRequest['URI'] -match '\?') {
                    $newRequest.URI = $newRequest.URI + "&page=$($i+1)"
                }
                else {
                    $newRequest.URI = $newRequest.URI + "?page=$($i+1)"
                }
                $Results += (Invoke-WebRequest @newRequest).Content | ConvertFrom-Json
            }
        }

    } catch {
        $GitLabErrorText = "{0} - {1}" -f $webcontent.statuscode,$webcontent.StatusDescription
        Write-Error -Message $GitLabErrorText
    }
    finally {
        $ProgressPreference = 'Continue'
        Remove-Variable -Name newRequest -ErrorAction SilentlyContinue
        Remove-Variable -Name Token
        Remove-Variable -Name Headers
        Remove-Variable -Name Request
    }

    foreach ($Result in $Results) {
        $Result.pstypenames.insert(0,$ObjectType)
        Write-Output $Result
    }

}
