Function Get-GitLabJob {
    [cmdletbinding(DefaultParameterSetName='ByProject')]
    [OutputType("GitLab.Project.Job")]
    param(

        [Parameter(Mandatory=$true)]
        [int]$ProjectId,

        [Parameter(Mandatory=$true,ParameterSetName='ByPipeline')]
        [int]$PipelineId,

        [Parameter(Mandatory=$true,ParameterSetName='Single')]
        [int]$Id,

        [Parameter(Mandatory=$false,ParameterSetName='ByProject')]
        [Parameter(Mandatory=$false,ParameterSetName='ByPipeline')]
        [ValidateSet('created','pending','running','failed','success','canceled','skipped','manual','all')]
        $Scope = 'all'
    )

    $Project = Get-GitlabProject -Id $ProjectId

    Write-Verbose -Message "Returning a job(s) for the project $($Project.Name) and id $($Project.Id)"

    if($PSCmdlet.ParameterSetName -ne 'Single') {

        if ($Scope -ne 'all')
        {
            $GetUrlParameters += @{scope=$Scope}
        }

        $URLParameters = GetMethodParameters -GetURLParameters $GetUrlParameters

    }

    $Request = @{
        URI = ''
        Method = 'GET'
    }

    switch ($PSCmdlet.ParameterSetName) {
        ByProject { $Request.URI = "/projects/$($Project.id)/jobs$URLParameters"; break; }
        ByPipeline { $Request.URI = "/projects/$($Project.id)/pipelines/$PipelineId/jobs$URLParameters"; break; }
        Single { $Request.URI = "/projects/$($Project.id)/jobs/$Id"; break; }
        default { Write-Error "Incorrect parameter set."; break; }
    }

    Write-Verbose -Message "A prepared API request: $($($Request.URI).ToString())"

    QueryGitLabAPI -Request $Request -ObjectType 'GitLab.Project.Job'

}
