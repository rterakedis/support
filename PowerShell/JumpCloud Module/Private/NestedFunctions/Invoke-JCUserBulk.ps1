Function Invoke-JCUserBulk ()
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, Position = 0)][ValidateSet('Create', 'Update')][string]$Action,
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, Position = 0)][string]$Json
    )
    Begin
    {
        Write-Verbose 'Verifying JCAPI Key'
        If ($JCAPIKEY.length -ne 40) {Connect-JCOnline}
        Write-Verbose 'Populating API headers'
        $hdrs = @{
            'Content-Type' = 'application/json'
            'Accept'       = 'application/json'
            'X-API-KEY'    = $JCAPIKEY
        }
        If ($JCOrgID)
        {
            $hdrs.Add('x-org-id', "$($JCOrgID)")
        }
        $Url_Template_BulkUsers = '{0}/api/v2/bulk/users'
        $Url_Template_BulkUsersResults = '{0}/api/v2/bulk/users/{1}/results'
    }
    Process
    {
        $JsonBody = $Json
        Switch ($Action)
        {
            'Create' {$Method = 'POST'; }
            'Update'
            {
                $Method = 'PATCH';
                $JsonObject = $Json | ConvertFrom-Json
                $JsonRecords = @()
                ForEach ($JsonRecord In $JsonObject)
                {
                    If ($JsonObject | Get-Member | Where-Object {$_.Name -eq '_id'})
                    {
                        $JsonRecords += $JsonRecord
                    }
                    Else
                    {
                        $JCUser = Get-JCUser -username:($JsonRecord.username)
                        If ($JCUser)
                        {
                            $JsonRecords += $JsonRecord | Select-Object *, @{Name = 'id'; Expression = {$JCUser._id}}
                        }
                        Else
                        {
                            Write-Error ('JC User does not exist:' + $JsonRecord.username + "`r`n" + 'Please run Get-JCUser to get a list of all existing users.')
                        }
                    }
                }
                $JsonBody = $JsonRecords | ConvertTo-Json -Depth 10
            }
        }
        # Start job to create new users.
        $Uri_BulkUsers = $Url_Template_BulkUsers -f $JCUrlBasePath
        Write-Verbose ('Connecting to: ' + $Uri_BulkUsers + "`r`n" + 'Sending body: ' + $JsonBody)
        $Results_BulkUsers = Invoke-RestMethod -Method:($Method) -Uri:($Uri_BulkUsers) -Header:($hdrs) -Body:($JsonBody)
        If ($Results_BulkUsers.jobId)
        {
            # Review job status.
            $Uri_BulkUsersResults = $Url_Template_BulkUsersResults -f $JCUrlBasePath, $Results_BulkUsers.jobId
            Write-Verbose ('Connecting to: ' + $Uri_BulkUsersResults)
            $Results_BulkUsersResults = Invoke-JCApiGet -Url:($Uri_BulkUsersResults)
            # Results to output.
            $Results = $Results_BulkUsersResults
            If ($Results.status -ne 'finished')
            {
                Write-Error ('Bulk new user import ' + $Results.status + '. See results below.')
            }
        }
        Else
        {
            Write-Error ('No job id returned from API call.')
        }
    }
    End
    {
        Return $Results
    }
}