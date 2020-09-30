Function Restart-GitLabJob {
    [cmdletbinding(DefaultParameterSetName='Single')]
    [OutputType("GitLab.Project.Job")]
    param(

        [Parameter(Mandatory=$true)]
        [int]$ProjectId,

        [Parameter(Mandatory=$true,ParameterSetName='Single')]
        [int]$Id
    )

    $Request = @{
        URI = ''
        Method = 'POST'
    }

    switch ($PSCmdlet.ParameterSetName) {
        Single { $Request.URI = "/projects/$ProjectId/jobs/$Id/retry"; break; }
        default { Write-Error "Incorrect parameter set."; break; }
    }

    Write-Verbose -Message "A prepared API request: $($($Request.URI).ToString())"

    QueryGitLabAPI -Request $Request -ObjectType 'GitLab.Project.Job'

}
