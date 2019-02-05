Function Import-JCUsersFromCSV ()
{
    [CmdletBinding(DefaultParameterSetName = 'GUI')]
    param
    (
        [Parameter(Mandatory,
            position = 0,
            ParameterSetName = 'GUI')]
        [ValidateScript( { Test-Path -Path $_ -PathType Leaf})]
        [ValidatePattern( '\.csv$' )]

        [Parameter(Mandatory,
            position = 0,
            ParameterSetName = 'force')]
        [ValidateScript( { Test-Path -Path $_ -PathType Leaf})]
        [ValidatePattern( '\.csv$' )]

        [string]$CSVFilePath,

        [Parameter(
            ParameterSetName = 'force')]
        [Switch]
        $force


    )

    begin
    {
        $UserParams = @{}

        # New Users

        $NewUsers = Import-Csv -Path $CSVFilePath

        # Hash table of user params

        # Capture Customer Attributes From New User Import Object

        $CustomAttributes = $NewUsers | Get-Member | Where-Object Name -Like "*Attribute*" | Select-Object Name

        # Add Custom Attributes To UserParams Hash

        foreach ($attr in $CustomAttributes )
        {
            $UserParams.Add($attr.name, $attr.name)
        }

        # Add All JumpCloud User Attributes To UserParams Hash

        $UserParams.Add("Username", "Username")
        $UserParams.Add("FirstName", "FirstName")
        $UserParams.Add("LastName", "LastName")
        $UserParams.Add("Email", "Email")
        $UserParams.Add("Password", "Password")
        $UserParams.Add("middlename", "middlename")
        $UserParams.Add("preferredName", "preferredName")
        $UserParams.Add("jobTitle", "jobTitle")
        $UserParams.Add("employeeIdentifier", "employeeIdentifier")
        $UserParams.Add("department", "department")
        $UserParams.Add("costCenter", "costCenter")
        $UserParams.Add("company", "company")
        $UserParams.Add("employeeType", "employeeType")
        $UserParams.Add("description", "description")
        $UserParams.Add("location", "location")
        $UserParams.Add("work_streetAddress", "work_streetAddress")
        $UserParams.Add("work_poBox", "work_poBox")
        $UserParams.Add("work_locality", "work_locality")
        $UserParams.Add("work_region", "work_region")
        $UserParams.Add("work_city", "work_city")
        $UserParams.Add("work_state", "work_state")
        $UserParams.Add("work_postalCode", "work_postalCode")
        $UserParams.Add("work_country", "work_country")
        $UserParams.Add("home_poBox", "home_poBox")
        $UserParams.Add("home_locality", "home_locality")
        $UserParams.Add("home_region", "home_region")
        $UserParams.Add("home_city", "home_city")
        $UserParams.Add("home_state", "home_state")
        $UserParams.Add("home_postalCode", "home_postalCode")
        $UserParams.Add("home_country", "home_country")
        $UserParams.Add("home_streetAddress", "home_streetAddress")
        $UserParams.Add("mobile_number", "mobile_number")
        $UserParams.Add("home_number", "home_number")
        $UserParams.Add("work_number", "work_number")
        $UserParams.Add("work_mobile_number", "work_mobile_number")
        $UserParams.Add("work_fax_number", "work_fax_number")
        $UserParams.Add("account_locked", "account_locked")
        $UserParams.Add("allow_public_key", "allow_public_key")
        $UserParams.Add("enable_managed_uid", "enable_managed_uid")
        $UserParams.Add("enable_user_portal_multifactor", "enable_user_portal_multifactor")
        $UserParams.Add("externally_managed", "externally_managed")
        $UserParams.Add("ldap_binding_user", "ldap_binding_user")
        $UserParams.Add("passwordless_sudo", "passwordless_sudo")
        $UserParams.Add("sudo", "sudo")
        $UserParams.Add("unix_guid", "unix_guid")
        $UserParams.Add("password_never_expires", "password_never_expires")




        Write-Verbose "$($PSCmdlet.ParameterSetName)"

        if ($PSCmdlet.ParameterSetName -eq 'GUI')
        {
            Write-Verbose 'Verifying JCAPI Key'
            if ($JCAPIKEY.length -ne 40) {Connect-JCOnline}

            $Banner = @"
       __                          ______ __                   __
      / /__  __ ____ ___   ____   / ____// /____   __  __ ____/ /
 __  / // / / // __  __ \ / __ \ / /    / // __ \ / / / // __  /
/ /_/ // /_/ // / / / / // /_/ // /___ / // /_/ // /_/ // /_/ /
\____/ \____//_/ /_/ /_// ____/ \____//_/ \____/ \____/ \____/
                       /_/
                                                  User Import
"@

            Clear-Host
            Write-Host $Banner -ForegroundColor Green
            Write-Host ""



            Write-Host ""
            Write-Host -BackgroundColor Green -ForegroundColor Black "Validating $($NewUsers.count) Usernames"

            $ExistingUsernameCheck = $NewUsers | Confirm-UniqueUsername

            foreach ($User in $ExistingUsernameCheck)
            {
          
                Write-Warning "A user with username: $($User.Username) already exists this user will not be created. To resolve create user with a unique username." 
                
            }

            $UsernameDupCSVCheck = $NewUsers | Group-Object Username

            ForEach ($U in $UsernameDupCSVCheck )
            {
                if ($U.count -gt 1)
                {
                    Write-Warning "Duplicate username for username $($U.name) in import file. Usernames must be unique. To resolve eliminate the duplicate username and then retry import."
                }
            }

            Write-Host -BackgroundColor Green -ForegroundColor Black "Username check complete"
            Write-Host ""

            Write-Host -BackgroundColor Green -ForegroundColor Black "Validating $($NewUsers.count) Emails Addresses"

            $ExistingEmailCheck =  $NewUsers | Confirm-UniqueEmail

            foreach ($User in $NewUsers)
            {
              
                Write-Warning "The email address: $($User.email) is use.  To resolve create user with a unique email address."
               
            }

            $EmailDup = $NewUsers | Group-Object Email

            ForEach ($U in $EmailDup)
            {
                if ($U.count -gt 1)
                {

                    Write-Warning "Duplicate email for email $($U.name) in import file. Emails must be unique. To resolve eliminate the duplicate emails." 
                }
            }

            Write-Host -BackgroundColor Green -ForegroundColor Black "Email check complete"

            $employeeIdentifierCheck = $NewUsers | Where-Object {($_.employeeIdentifier -ne $Null) -and ($_.employeeIdentifier -ne "")}

            if ($employeeIdentifierCheck.Count -gt 0)
            {
                Write-Host ""
                Write-Host -BackgroundColor Green -ForegroundColor Black "Validating $($employeeIdentifierCheck.employeeIdentifier.Count) employeeIdentifiers"

                $ExistingEmployeeIdentifierCheck = $NewUsers | Confirm-UniqueEmployeeID

                foreach ($User in $ExistingEmployeeIdentifierCheck)
                {
       
                    Write-Warning "The employeeIdentifier $($User.employeeIdentifier) is in use.  To resolve update user with a unique employeeIdentifier."
                    
                }

                $employeeIdentifierDup = $employeeIdentifierCheck | Group-Object employeeIdentifier

                ForEach ($U in $employeeIdentifierDup)
                {
                    if ($U.count -gt 1)
                    {

                        Write-Warning "Duplicate employeeIdentifier: $($U.name) in import file. employeeIdentifier must be unique. To resolve eliminate the duplicate employeeIdentifiers."
                    }
                }

                Write-Host -BackgroundColor Green -ForegroundColor Black "employeeIdentifier check complete"
            }

            $SystemCount = $NewUsers.SystemID | Where-Object Length -gt 1 | Select-Object -unique

            if ($SystemCount.count -gt 0)
            {
                Write-Host ""
                Write-Host -BackgroundColor Green -ForegroundColor Black "Validating $($SystemCount.count) Systems"
                $SystemCheck = Get-Hash_SystemID_HostName
                foreach ($User in $SystemCount)
                {
                    if (($User.SystemID).length -gt 1)
                    {
                        if ($SystemCheck.ContainsKey($User.SystemID))
                        {
                            Write-Verbose "$($User.SystemID) exists"
                        }
                        else
                        {
                            Write-Warning "A system with SystemID: $($User.SystemID) does not exist and will not be bound to user $($User.Username)" 
                        }
                    }
                    else {Write-Verbose "No system"}
                }
                $Permissions = $NewUsers.Administrator | Where-Object Length -gt 1 | Select-Object -unique
                foreach ($Value in $Permissions)
                {
                    if ( ($Value -notlike "*true" -and $Value -notlike "*false") )
                    {
                        Write-Warning "Administrator must be a boolean value and set to either '`$True/True' or '`$False/False' please correct value: $Value " 
                    }
                }

                Write-Host -BackgroundColor Green -ForegroundColor Black "System check complete"
                Write-Host ""
                #Group Check
            }

            $GroupArrayList = New-Object System.Collections.ArrayList

            ForEach ($User in $NewUsers)
            {

                $Groups = $User | Get-Member -Name Group* | Select-Object Name

                foreach ($Group in $Groups)
                {
                    $CheckGroup = [pscustomobject]@{
                        Type  = 'GroupName'
                        Value = $User.($Group.Name)
                    }

                    if ($CheckGroup.Value.Length -gt 1)
                    {

                        $GroupArrayList.Add($CheckGroup) | Out-Null

                    }

                    else {}

                }

            }

            $UniqueGroups = $GroupArrayList | Select-Object Value -Unique

            if ($UniqueGroups.count -gt 0)
            {
                Write-Host -BackgroundColor Green -ForegroundColor Black "Validating $($UniqueGroups.count) Groups"
                $GroupCheck = Get-Hash_UserGroupName_ID

                foreach ($GroupTest in $UniqueGroups)
                {
                    if ($GroupCheck.ContainsKey($GroupTest.Value))
                    {
                        Write-Verbose "$($GroupTest.Value) exists"
                    }
                    else
                    {
                        Write-Host "The JumpCloud Group:" -NoNewLine
                        Write-Host " $($GroupTest.Value)" -ForegroundColor Yellow -NoNewLine
                        Write-Host " does not exist. Users will not be added to this Group."
                    }
                }

                Write-Host -BackgroundColor Green -ForegroundColor Black "Group check complete"
                Write-Host ""
            }



            $ResultsArrayList = New-Object System.Collections.ArrayList

            $NumberOfNewUsers = $NewUsers.email.count

            $title = "Import Summary:"

            $menu = @"

    Number Of Users To Import = $NumberOfNewUsers

    Would you like to import these users?

"@

            Write-Host $title -ForegroundColor Red
            Write-Host $menu -ForegroundColor Yellow


            while ($Confirm -ne 'Y' -and $Confirm -ne 'N')
            {
                $Confirm = Read-Host "Press Y to confirm or N to quit"
            }

            if ($Confirm -eq 'Y')
            {

                Write-Host ''
                Write-Host "Hang tight! Creating your users. " -NoNewline
                Write-Host "DO NOT shutdown the console." -ForegroundColor Red
                Write-Host ''
                Write-Host "Feel free to watch your user count increase in the JumpCloud admin console!"
                Write-Host ''
                Write-Host "It takes ~ 1 minute per 100 users."

            }

            elseif ($Confirm -eq 'N')
            {
                break
            }

        }

        elseif ($PSCmdlet.ParameterSetName -eq 'force')
        {
            Write-Verbose 'Verifying JCAPI Key'
            if ($JCAPIKEY.length -ne 40) {Connect-JCOnline}
            $ResultsArrayList = New-Object System.Collections.ArrayList
            $NumberOfNewUsers = $NewUsers.email.count

        }

        $BulkUpdateUserArray = New-Object System.Collections.ArrayList

    } #begin block end

    process
    {
        [int]$ProgressCounter = 0

        foreach ($UserAdd in $NewUsers)
        {
            ## Select only CSV columns that contain values

            $UpdateParamsRaw = $UserAdd.psobject.properties | Where-Object {($_.Value -ne $Null) -and ($_.Value -ne "")} | Select-Object Name, Value

            $UpdateParams = @{}

            foreach ($Param in $UpdateParamsRaw)
            {
                ## Validate and add user creation parameters from column data (Not group / System information)

                if ($UserParams.$($Param.name))
                {
                    $UpdateParams.Add($Param.name, $Param.value)
                }
            }

            $CustomAttributes = $UserAdd | Get-Member | Where-Object Name -Like "*Attribute*" | Where-Object {$_.Definition -NotLike "*=" -and $_.Definition -NotLike "*null"} | Select-Object Name

            Write-Verbose $CustomAttributes.name.count

            if ($CustomAttributes.name.count -gt 1)
            { 
                $NumberOfCustomAttributes = ($CustomAttributes.name.count) / 2

                $UpdateParams.Add("NumberOfCustomAttributes", $NumberOfCustomAttributes)
            }
            
            $UserObject = [pscustomobject]$UpdateParams | Transform-JCUserImportCSVToJSON

            $BulkUpdateUserArray.Add($UserObject) | Out-Null

        }

        $JSONBulkData = $BulkUpdateUserArray | ConvertTo-Json -Depth 5
            

            <#
            
             $ProgressCounter++

            $GroupAddProgressParams = @{

                Activity        = "Adding $($UserAdd.username)"
                Status          = "User import $ProgressCounter of $NumberOfNewUsers"
                PercentComplete = ($ProgressCounter / $NumberOfNewUsers) * 100

            }

            Write-Progress @GroupAddProgressParams
            
            #>

           

            $NewUser = $Null
            $Status = $Null
            $UserGroupArrayList = $Null
            $SystemAddStatus = $Null
            $FormatGroupOutput = $Null
            $CustomGroupArrayList = $Null


            #################
            #################
            #################

            


     
            <#
                $JSONParams = $UpdateParams | ConvertTo-Json
                Write-Verbose "$($JSONParams)"
                $NewUser = New-JCUser @UpdateParams


                if ($NewUser._id)
                {
                    $Status = 'User Created'
                }
                elseif (-not $NewUser._id)
                {
                    $Status = 'User Not Created'
                }
                try #User is created
                {
                    if ($UserAdd.SystemID)
                    {
                        if ($UserAdd.Administrator)
                        {
                            Write-Verbose "Admin set"
                            if ($UserAdd.Administrator -like "*True")
                            {
                                Write-Verbose "Admin set to true"
                                try
                                {
                                    $SystemAdd = Add-JCSystemUser -SystemID $UserAdd.SystemID -UserID $NewUser._id -Administrator $true
                                    $SystemAddStatus = $SystemAdd.Status
                                }
                                catch
                                {
                                    $SystemAddStatus = $_.ErrorDetails
                                }
                            }
                            elseif ($UserAdd.Administrator -like "*False")
                            {
                                Write-Verbose "Admin set to false"
                                try
                                {
                                    $SystemAdd = Add-JCSystemUser -SystemID $UserAdd.SystemID -UserID $NewUser._id -Administrator $false
                                    $SystemAddStatus = $SystemAdd.Status
                                }
                                catch
                                {
                                    $SystemAddStatus = $_.ErrorDetails
                                }
                            }
                        }
                        else
                        {
                            Write-Verbose "No admin set"
                            try
                            {
                                $SystemAdd = Add-JCSystemUser -SystemID $UserAdd.SystemID -UserID $NewUser._id
                                Write-Verbose  "$($SystemAdd.Status)"
                                $SystemAddStatus = $SystemAdd.Status
                            }
                            catch
                            {
                                $SystemAddStatus = $_.ErrorDetails
                            }
                        }
                    }
                    $CustomGroupArrayList = New-Object System.Collections.ArrayList
                    $CustomGroups = $UserAdd | Get-Member | Where-Object Name -Like "*Group*" | Where-Object {$_.Definition -NotLike "*=" -and $_.Definition -NotLike "*null"} | Select-Object Name
                    foreach ($Group in $CustomGroups)
                    {
                        $GetGroup = [PSCustomObject]@{
                            Type  = 'GroupName'
                            Value = $UserAdd.($Group.Name)
                        }
                        $CustomGroupArrayList.Add($GetGroup) | Out-Null
                    }
                    $UserGroupArrayList = New-Object System.Collections.ArrayList
                    foreach ($Group in $CustomGroupArrayList)
                    {
                        try
                        {
                            $GroupAdd = Add-JCUserGroupMember -ByID -UserID $NewUser._id -GroupName $Group.value
                            $FormatGroupOutput = [PSCustomObject]@{
                                'Group'  = $Group.value
                                'Status' = $GroupAdd.Status
                            }
                            $UserGroupArrayList.Add($FormatGroupOutput) | Out-Null
                        }
                        catch
                        {
                            $FormatGroupOutput = [PSCustomObject]@{
                                'Group'  = $Group.value
                                'Status' = $_.ErrorDetails
                            }
                            $UserGroupArrayList.Add($FormatGroupOutput) | Out-Null
                        }
                    }
                }
                catch
                {
                }
                $FormattedResults = [PSCustomObject]@{
                    'Username'  = $NewUser.username
                    'Status'    = $Status
                    'UserID'    = $NewUser._id
                    'GroupsAdd' = $UserGroupArrayList
                    'SystemID'  = $UserAdd.SystemID
                    'SystemAdd' = $SystemAddStatus

                }
            }
            catch
            {
                $Status = $_.ErrorDetails
                $FormattedResults = [PSCustomObject]@{
                    'Username'  = $UserAdd.username
                    'Status'    = "Not created, CSV format issue? $Status"
                    'UserID'    = $Null
                    'GroupsAdd' = $Null
                    'SystemID'  = $Null
                    'SystemAdd' = $Null
                }
            }
            $ResultsArrayList.Add($FormattedResults) | Out-Null
            $SystemAddStatus = $null
        }

#>
          
    }
    end

    
    {
        return $BulkUpdateUserArray
        # return $ResultsArrayList
    }
}

#Import-JCUsersFromCSV -CSVFilePath '/Users/sreed/Desktop/JCUserImport - Demo .csv' -force

$PSObj = Import-JCUsersFromCSV -CSVFilePath '/Users/sreed/Git/support/PowerShell/JumpCloud Module/test/csv_files/import/ImportExample_Pester_Tests_1.1.0.csv'-force

$JSONOb = $PSObj | ConvertTo-Json -Depth 5

Invoke-JCUserBulk -Json $JSONOb