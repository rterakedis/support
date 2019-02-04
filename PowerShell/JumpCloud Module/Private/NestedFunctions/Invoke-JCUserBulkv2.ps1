Function Invoke-JCUserBulk ()
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, Position = 0)][string]$Json
    )
    Begin
    {
        Function Compare-ObjectProperties
        {
            Param(
                [PSObject]$ReferenceObject,
                [PSObject]$DifferenceObject,
                [array]$Include,
                [array]$Exclude
            )
            $objprops = $ReferenceObject | Get-Member -MemberType Property, NoteProperty | ForEach-Object {$_.Name}
            $objprops += $DifferenceObject | Get-Member -MemberType Property, NoteProperty | ForEach-Object {$_.Name}
            $objprops = $objprops | Sort-Object | Select-Object -Unique
            If ($Include -eq $true -and $Exclude -eq $true)
            {
                $objprops = $objprops| Where-Object {$_ -in $Include -and $_ -notin $Exclude}
            }
            Else
            {
                If ($Include)
                {
                    $objprops = $objprops| Where-Object {$_ -in $Include}
                }
                ElseIf ($Exclude)
                {
                    $objprops = $objprops| Where-Object {$_ -notin $Exclude}
                }
            }

            $diffs = @()
            ForEach ($objprop In $objprops)
            {
                $diff = Compare-Object $ReferenceObject $DifferenceObject -Property $objprop
                If ($diff)
                {
                    $diffprops = @{
                        PropertyName = $objprop
                        RefValue     = ($diff | Where-Object {$_.SideIndicator -eq '<='} | ForEach-Object $($objprop))
                        DiffValue    = ($diff | Where-Object {$_.SideIndicator -eq '=>'} | ForEach-Object $($objprop))
                    }
                    $diffs += New-Object PSObject -Property $diffprops
                }
            }
            If ($diffs)
            {
                Return ($diffs | Select-Object PropertyName, RefValue, DiffValue)
            }
        }
        ############################################################
        ############################################################
        ############################################################
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
        $JsonRecords = @()
        $JsonObject = $Json | ConvertFrom-Json
        ForEach ($JsonRecord In $JsonObject)
        {
            $JCUser = Get-JCUser -username:($JsonRecord.username)
            If ($JCUser)
            {
                $Action = 'UPDATE'
                $Method = 'PATCH';
                $CompareResults = Compare-ObjectProperties  -ReferenceObject:($JsonRecord) -DifferenceObject:($JCUser) -Exclude:(('_id', 'created', 'mfaData'))
                If ($CompareResults)
                {
                    Write-Host ('Updating values:')
                    $CompareResults | Format-Table
                    If (!($JsonObject | Get-Member | Where-Object {$_.Name -eq '_id'}))
                    {
                        $JsonRecord = $JsonRecord | Select-Object *, @{Name = 'id'; Expression = {$JCUser._id}};
                    }
                }
                Else
                {
                    $Action = 'No Change'
                    Write-Host ('Updating values:')
                    $CompareResults | Format-Table
                    If (!($JsonObject | Get-Member | Where-Object {$_.Name -eq '_id'}))
                    {
                        $JsonRecord = $JsonRecord | Select-Object *, @{Name = 'id'; Expression = {$JCUser._id}};
                    }
                }
            }
            Else
            {
                $Action = 'CREATE'
                $Method = 'POST';
            }
            $JsonRecords += [PSCustomObject]@{
                'Method' = $Method;
                'Action' = $Action;
                'User'   = $JsonRecord;
            }
        }
        $GroupObject = ($JsonRecords | Group-Object Method)
        # $GroupObject
        # $GroupObject.Group
        $Results = @()
        ForEach ($GroupItem In $GroupObject)
        {
            $GroupName = $GroupItem.Name
            # Write-Host ($GroupName) -BackgroundColor Green
            $GroupAction = $GroupItem.Group.Action | Select-Object -Unique
            $GroupUsers = $GroupItem.Group.User
            $JsonBody = ($GroupUsers | ConvertTo-Json -Depth 10) -join ','
            # Write-Host ($GroupUsers.Count) -BackgroundColor Yellow
            If ($GroupUsers.Count -eq 1) {$JsonBody = '[' + $JsonBody + ']'}
            # Write-Host ($JsonBody) -BackgroundColor Cyan
            # Start job to create new users.
            $Uri_BulkUsers = $Url_Template_BulkUsers -f $JCUrlBasePath
            Write-Verbose ('Connecting to: ' + $Uri_BulkUsers + "`r`n" + 'Sending body: ' + $JsonBody)
            $Results_BulkUsers = Invoke-RestMethod -Method:($GroupName) -Uri:($Uri_BulkUsers) -Header:($hdrs) -Body:($JsonBody)
            If ($Results_BulkUsers.jobId)
            {
                Do
                {
                    Start-Sleep -Milliseconds:(1)
                    # Review job status.
                    $Uri_BulkUsersResults = $Url_Template_BulkUsersResults -f $JCUrlBasePath, $Results_BulkUsers.jobId
                    Write-Verbose ('Connecting to: ' + $Uri_BulkUsersResults)
                    $Results_BulkUsersResults = Invoke-JCApiGet -Url:($Uri_BulkUsersResults)
                    # Results to output.
                    $Results += $Results_BulkUsersResults | Select-Object @{Name = 'action'; Expression = {$GroupAction}}, @{Name = 'jobId'; Expression = {$Results_BulkUsers.jobId}}, *
                    If ($Results.status -ne 'finished')
                    {
                        Write-Error ('Bulk new user import ' + $Results.status + '. See results below.')
                    }
                } Until ('pending' -notin $Results.status)
            }
            Else
            {
                Write-Error ('No job id returned from API call.')
            }
        }
    }
    End
    {
        Return $Results
    }
}