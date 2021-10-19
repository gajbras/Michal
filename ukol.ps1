$json = Get-Content -Path .\test.json 
$object = $json | ConvertFrom-Json
#$object.zadani
$object.timestamp.ToString($null)
$time = [datetime]::ParseExact($object.timestamp.ToString($null),"yyyyMMddHHmmss",$null)
$time
$object.data | foreach{
    #$name = $_.psobject.properties.Value #- vypise jmena objekta
    $obj_true = $_.psobject.properties.Value | where status -eq "true" 
    $obj_true = Get-Alias | measure
    $obj_true.Count
    $garbage = $_.psobject.properties.Value | where status -eq "true" | Measure-Object garbage -Character
    $garbage
    }
#$object.data.psobject.Properties #- vypise properties objektu


#test1: 3 = 49
