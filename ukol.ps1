$json = Get-Content -Path .\Documents\test.json 
$object = $json | ConvertFrom-Json
#$object.zadani
$object.timestamp.ToString($null)
$time = [datetime]::ParseExact($object.timestamp.ToString($null),"yyyyMMddHHmmss",$null)
$time
$object.data | foreach{
    #$name = $_.psobject.properties.Name #- vypise jmena objekta
    $_.psobject.properties.Value | where status -eq "true"
}
#$object.data.psobject.Properties - vypise properties objektu

# test1: 3 = 49
