Function Get-GitLabJobLog {
    [cmdletbinding(DefaultParameterSetName='Single')]
    [OutputType("string")]
    param(

        [Parameter(Mandatory=$true)]
        [int]$ProjectId,

        [Parameter(Mandatory=$true,ParameterSetName='Single')]
        [int]$Id
    )

    $Request = @{
        URI = ''
        Method = 'GET'
    }

    switch ($PSCmdlet.ParameterSetName) {
        Single { $Request.URI = "/projects/$ProjectId/jobs/$Id/trace"; break; }
        default { Write-Error "Incorrect parameter set."; break; }
    }

    Write-Verbose -Message "A prepared API request: $($($Request.URI).ToString())"

    QueryGitLabAPI -Request $Request -AsString

}
