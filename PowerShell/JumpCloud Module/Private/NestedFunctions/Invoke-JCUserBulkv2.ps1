Function Invoke-JCUserBulkv2 () {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName, Position = 0)][string]$Json,
        [Switch] $ChangeResults
    )
    Begin {
        Function Compare-ObjectProperties {
            Param(
                [PSObject]$ReferenceObject,
                [PSObject]$DifferenceObject,
                [array]$Include,
                [array]$Exclude
            )
            $objprops = $ReferenceObject | Get-Member -MemberType Property, NoteProperty | ForEach-Object {$_.Name}
            $objprops += $DifferenceObject | Get-Member -MemberType Property, NoteProperty | ForEach-Object {$_.Name}
            $objprops = $objprops | Sort-Object | Select-Object -Unique
            If ($Include -eq $true -and $Exclude -eq $true) {
                $objprops = $objprops| Where-Object {$_ -in $Include -and $_ -notin $Exclude}
            }
            Else {
                If ($Include) {
                    $objprops = $objprops| Where-Object {$_ -in $Include}
                }
                ElseIf ($Exclude) {
                    $objprops = $objprops| Where-Object {$_ -notin $Exclude}
                }
            }

            $diffs = @()
            ForEach ($objprop In $objprops) {
                $diff = Compare-Object $ReferenceObject $DifferenceObject -Property $objprop
                If ($diff) {
                    $diffprops = @{
                        PropertyName = $objprop
                        NewValue     = '"' + ($diff | Where-Object {$_.SideIndicator -eq '<='} | ForEach-Object $($objprop)) + '"'
                        OldValue     = '"' + ($diff | Where-Object {$_.SideIndicator -eq '=>'} | ForEach-Object $($objprop)) + '"'
                    }
                    $diffs += New-Object PSObject -Property $diffprops
                }
            }
            If ($diffs) {
                Return ($diffs | Select-Object PropertyName, NewValue, OldValue)
            }
        }
        Write-Verbose 'Verifying JCAPI Key'
        If ($JCAPIKEY.length -ne 40) {Connect-JCOnline}
        Write-Verbose 'Populating API headers'
        $hdrs = @{
            'Content-Type' = 'application/json'
            'Accept'       = 'application/json'
            'X-API-KEY'    = $JCAPIKEY
        }
        If ($JCOrgID) {
            $hdrs.Add('x-org-id', "$($JCOrgID)")
        }
        $Url_Template_BulkUsers = '{0}/api/v2/bulk/users'
        $Url_Template_BulkUsersResults = '{0}/api/v2/bulk/users/{1}/results'
        $Url_Template_SystemUserSearch = '{0}/api/systemusers?filter=username%3Aeq%3A{1}'
    }
    Process {
        if ($ChangeResults) {

            $JsonRecords = @()
            $JsonObject = $Json | ConvertFrom-Json
            ForEach ($JsonRecord In $JsonObject) {
                $Uri_SystemUserSearch = $Url_Template_SystemUserSearch -f $JCUrlBasePath, $JsonRecord.username
                $JCUser = (Invoke-JCApiGet -Url:($Uri_SystemUserSearch)).Results
                If ($JCUser) {
                    $JCUserName = $JCUser.UserName
                    $Action = 'UPDATE'
                    $Method = 'PATCH';
                    $CompareResults = Compare-ObjectProperties  -ReferenceObject:($JsonRecord) -DifferenceObject:($JCUser) -Exclude:(('_id', 'created', 'password', 'mfaData', 'associatedTagCount')) | Select-Object @{Name = 'UserName'; Expression = {$JCUserName}}, *
                    If ($CompareResults) {
                        $Changes = $CompareResults
                    }
                    Else {
                        $Changes = [PSCustomObject]@{
                            'UserName' = $JCUserName;
                            'Status'   = 'No Change';
                        }
                    }
                    If (!($JsonObject | Get-Member | Where-Object {$_.Name -eq '_id'})) {
                        $JsonRecord = $JsonRecord | Select-Object *, @{Name = 'id'; Expression = {$JCUser._id}};
                    }
                }
                Else {
                    $JCUserName = $JsonRecord.username
                    $Action = 'CREATE';
                    $Method = 'POST';
                    $Changes = [PSCustomObject]@{
                        'UserName' = $JCUserName;
                        'Status'   = 'N/A';
                    }
                }
                $JsonRecords += [PSCustomObject]@{
                    'Method'  = $Method;
                    'Action'  = $Action;
                    'User'    = $JsonRecord;
                    'Changes' = $Changes;
                }
            }
            $GroupObject = ($JsonRecords | Group-Object Method)
            $Results = @()
            ForEach ($GroupItem In $GroupObject) {
                $GroupName = $GroupItem.Name
                $GroupAction = $GroupItem.Group.Action | Select-Object -Unique
                $GroupUsers = $GroupItem.Group.User
                $GroupChanges = $GroupItem.Group.Changes
                # Format JSON body.
                $JsonBody = ($GroupUsers | ConvertTo-Json -Depth 10) -join ','
                If ($GroupUsers.Count -eq 1) {$JsonBody = '[' + $JsonBody + ']'}
                # Start job to create new users.
                $Uri_BulkUsers = $Url_Template_BulkUsers -f $JCUrlBasePath
                Write-Verbose ('Connecting to: ' + $Uri_BulkUsers + "`r`n" + 'Sending body: ' + $JsonBody)
                $Results_BulkUsers = Invoke-RestMethod -Method:($GroupName) -Uri:($Uri_BulkUsers) -Header:($hdrs) -Body:($JsonBody)
                If ($Results_BulkUsers.jobId) {
                    # Review job status.
                    $Uri_BulkUsersResults = $Url_Template_BulkUsersResults -f $JCUrlBasePath, $Results_BulkUsers.jobId
                    Write-Verbose ('Connecting to: ' + $Uri_BulkUsersResults)
                    Do {
                        Start-Sleep -Milliseconds:(10)
                        $Results_BulkUsersResults = Invoke-JCApiGet -Url:($Uri_BulkUsersResults)
                        # Results to output.
                        $Result = $Results_BulkUsersResults
                    } Until ('pending' -notin $Result.status)
                    # Format output object.
                    $FinalResults = @()
                    ForEach ($ResultRecord In $Result) {
                        $ResultRecordUserName = $ResultRecord.meta.SystemUser.username
                        $ResultRecordChanges = $GroupChanges | Where-Object {$_.UserName -eq $ResultRecordUserName} | Select-Object -ExcludeProperty UserName
                        $FinalResults += $ResultRecord | Select-Object @{Name = 'action'; Expression = {$GroupAction}},
                        @{Name = 'UserName'; Expression = {$ResultRecordUserName}},
                        @{Name = 'jobId'; Expression = {$Results_BulkUsers.jobId}},
                        @{Name = 'ChangeResults'; Expression = {$ResultRecordChanges}},
                        *
                    }
                    $Results += $FinalResults
                }
                Else {
                    Write-Error ('No job id returned from API call.')
                }
            }
            
        }

        else {
            
        }
        
        
    }
    End {
        If ($Results.status -ne 'finished') {
            Write-Error ('Bulk new user import ' + $Result.status + '. See results below.')
        }
        Return $Results
    }
}