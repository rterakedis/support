.('{Path}/support/PowerShell/JumpCloud Module/Private/NestedFunctions/Invoke-JCUserBulkv2.ps1')
.('{Path}/support/PowerShell/JumpCloud Module/Private/NestedFunctions/Invoke-JCApiGet.ps1')

$JsonPreUpdate = @'
[
    {
        "username": "deleteme1",
        "email": "deleteme@PreUpdate1.com",
        "employeeIdentifier": "employeeIdentifier123456721PreUpdate1",
        "password": "somepassword",
        "account_locked": false,
        "activated": true,
        "addresses": [
            {
                "country": "work_countryPreUpdate1",
                "locality": "work_cityPreUpdate1",
                "poBox": "work_poBoxPreUpdate1",
                "region": "work_statePreUpdate1",
                "streetAddress": "work_streetAddressPreUpdate1",
                "type": "work",
                "postalCode": "work_PostalCodePreUpdate1"
            },
            {
                "country": "home_countryPreUpdate1",
                "locality": "home_cityPreUpdate1",
                "poBox": "home_poBoxPreUpdate1",
                "region": "home_statePreUpdate1",
                "streetAddress": "home_streetAddressPreUpdate1",
                "type": "home",
                "postalCode": "home_PostalCodePreUpdate1"
            }
        ],
        "allow_public_key": true,
        "attributes": [
            {
                "name": "CustomAttributeNamePreUpdate1",
                "value": "CustomAttributeValuePreUpdate1"
            },
            {
                "name": "CustomAttributeNamePreUpdate2",
                "value": "CustomAttributeValuePreUpdate2"
            }
        ],
        "company": "companyPreUpdate1",
        "costCenter": "costCenterPreUpdate1",
        "department": "departmentPreUpdate1",
        "description": "decriptionPreUpdate1",
        "displayname": "displayNamePreUpdate1",
        "employeeType": "employeeTypePreUpdate1",
        "enable_managed_uid": false,
        "enable_user_portal_multifactor": false,
        "externally_managed": false,
        "firstname": "PreUpdate1",
        "jobTitle": "jobTitlePreUpdate1",
        "lastname": "PreUpdate1",
        "ldap_binding_user": false,
        "location": "locationPreUpdate1",
        "middlename": "middleNamePreUpdate1",
        "password_never_expires": false,
        "passwordless_sudo": false,
        "phoneNumbers": [
            {
                "number": "mobile_numberPreUpdate1",
                "type": "mobile"
            },
            {
                "number": "work_fax_numberPreUpdate1",
                "type": "work_fax"
            },
            {
                "number": "work_numberPreUpdate1",
                "type": "work"
            },
            {
                "number": "home_numberPreUpdate1",
                "type": "home"
            },
            {
                "number": "work_mobile_numberPreUpdate1",
                "type": "work_mobile"
            }
        ],
        "samba_service_user": false,
        "ssh_keys": [],
        "sudo": false,
        "unix_guid": 5079,
        "unix_uid": 5079,
        "password_expired": false,
        "totp_enabled": false
    },
    {
        "username": "deleteme2",
        "email": "deleteme@PreUpdate2.com",
        "employeeIdentifier": "employeeIdentifier123456721PreUpdate2",
        "password": "somepassword",
        "account_locked": false,
        "activated": true,
        "addresses": [
            {
                "country": "work_countryPreUpdate2",
                "locality": "work_cityPreUpdate2",
                "poBox": "work_poBoxPreUpdate2",
                "region": "work_statePreUpdate2",
                "streetAddress": "work_streetAddressPreUpdate2",
                "type": "work",
                "postalCode": "work_PostalCodePreUpdate2"
            },
            {
                "country": "home_countryPreUpdate2",
                "locality": "home_cityPreUpdate2",
                "poBox": "home_poBoxPreUpdate2",
                "region": "home_statePreUpdate2",
                "streetAddress": "home_streetAddressPreUpdate2",
                "type": "home",
                "postalCode": "home_PostalCodePreUpdate2"
            }
        ],
        "allow_public_key": true,
        "attributes": [
            {
                "name": "CustomAttributeNamePreUpdate1",
                "value": "CustomAttributeValuePreUpdate1"
            },
            {
                "name": "CustomAttributeNamePreUpdate2",
                "value": "CustomAttributeValuePreUpdate2"
            },
        ],
        "company": "companyPreUpdate2",
        "costCenter": "costCenterPreUpdate2",
        "department": "departmentPreUpdate2",
        "description": "decriptionPreUpdate2",
        "displayname": "displayNamePreUpdate2",
        "employeeType": "employeeTypePreUpdate2",
        "enable_managed_uid": false,
        "enable_user_portal_multifactor": false,
        "externally_managed": false,
        "firstname": "PreUpdate2",
        "jobTitle": "jobTitlePreUpdate2",
        "lastname": "PreUpdate2",
        "ldap_binding_user": false,
        "location": "locationPreUpdate2",
        "middlename": "middleNamePreUpdate2",
        "password_never_expires": false,
        "passwordless_sudo": false,
        "phoneNumbers": [
            {
                "number": "mobile_numberPreUpdate2",
                "type": "mobile"
            },
            {
                "number": "work_fax_numberPreUpdate2",
                "type": "work_fax"
            },
            {
                "number": "work_numberPreUpdate2",
                "type": "work"
            },
            {
                "number": "home_numberPreUpdate2",
                "type": "home"
            },
            {
                "number": "work_mobile_numberPreUpdate2",
                "type": "work_mobile"
            }
        ],
        "samba_service_user": false,
        "ssh_keys": [],
        "sudo": false,
        "unix_guid": 5079,
        "unix_uid": 5079,
        "password_expired": false,
        "totp_enabled": false
    }
]
'@

$JobStatus = @()
($JsonPreUpdate | ConvertFrom-Json) | % {Get-JCUser -Username:($_.UserName) | Remove-JCUser -f}
$JobStatus += Invoke-JCUserBulk -Json:($JsonPreUpdate)
$JobStatus += Invoke-JCUserBulk -Json:($JsonPreUpdate)
Remove-JCUser -Username:((($JsonPreUpdate | ConvertFrom-Json).UserName)[1]) -f
$JobStatus += Invoke-JCUserBulk -Json:($JsonPreUpdate.Replace('employeeIdentifier123456721PreUpdate1', 'employeeIdentifier123456721PreUpdate1Something'))

$JobStatus | Format-Table




# POST validates uniqueness on these fields
#     "username": "deleteme1",
#     "email": "deleteme@pleasedelete.comm",
#     "employeeIdentifier": "employeeIdentifier1234567211",
# POST ignores these fields.
#     "badLoginAttempts": 0,
#     "created": "2019-01-11T22:04:15.099Z",
#     "_id": "5c3912df6b6cfc4920051280"
#     "id": "5c3912df6b6cfc4920051280",
#     "organization": "5c0fdc3c6ea02c7aba661026",
# POST does not allow these fields.
#     "mfaData": {"exclusion": true,"exclusionUntil": "2019-02-08T17:23:45.362Z"},
#     "relationships": [],
#     "addresses": [{"_id": "5c3912df6b6cfc4920051282"}]
#     "phoneNumbers": [{"_id": "5c3912df6b6cfc4920051287"}]
# PATCH requires these fields
#     "id": "5c3912df6b6cfc4920051280"
