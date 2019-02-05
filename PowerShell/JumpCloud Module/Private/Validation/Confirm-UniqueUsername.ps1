function Confirm-UniqueUsername {
    [CmdletBinding(
    )]
    param (
        [Parameter(Mandatory,
        ValueFromPipelineByPropertyName = $True)]
    [string]
    $username
        
    )
    begin {

        $ExistingUsernameCheck = Get-Hash_UserName_ID

        $resultsArrayList = New-Object System.Collections.ArrayList
    
    }
    
    process {

        if ($ExistingUsernameCheck.ContainsKey($Username))
        {
            $Duplicate = [PSCustomObject]@{
                'Username'  = $Username
                'Duplicate' = $True
            }

            $resultsArrayList.add($Duplicate) | Out-Null
            
        }


    }
    
    end {
        return $resultsArrayList
    }
}

