$person = ([ordered]@{
    First = "James"
    Last = "Brundage"
    Address = @{
        City = "Seattle"
        State = "Washington"
        Zip = 98102
        Street = "0 Way I Am Putting This On a Blog" 
    }
    Occupation = @{
        Industry = "Information Technology"
        Title="Software Developer In Test"
        Company="Microsoft Corporation"
    }
})

$person.Address.State = 'Texas'
$person.Address.Remove('State')
$person.Keys