function Confirm-UniqueEmail {
    [CmdletBinding(
    )]
    param (
        [Parameter(Mandatory,
        ValueFromPipelineByPropertyName = $True)]
    [string]
    $Email
        
    )
    begin {

        $ExistingEmailCheck = Get-Hash_Email_ID

        $resultsArrayList = New-Object System.Collections.ArrayList
    
    }
    
    process {

        if ($ExistingEmailCheck.ContainsKey($Email))
        {
            $Duplicate = [PSCustomObject]@{
                'Email'  = $Email
                'Duplicate' = $True
            }

            $resultsArrayList.add($Duplicate) | Out-Null
            
        }


    }
    
    end {
        return $resultsArrayList
    }
}

