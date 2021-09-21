Get-ChildItem C:\transcript | Select-Object Name, Length,@{n="Size in KB"; e={($PSItem.Length/1024)}},@{n="Size in MB"; e={($PSItem.Length/1MB)}}

Get-ChildItem C:\transcript | Select-Object Name, Length,@{n="Size in KB"; e={'{0:N2}' -f ($_.Length/1024)}},@{n="Size in MB"; e={'{0:N3}' -f ($_.Length/1MB)}}


Get-WmiObject Win32_logicaldisk | Select DeviceID, MediaType, @{n="Free (%)"; e={'{0,6:PO}' -f ($_.freespace)/($_.size)}}

Get-ChildItem cert:\LocalMachine\CA | select Thumbprint, NotAfter, NotBefore

Get-ChildItem cert:\LocalMachine\CA | select Thumbprint, NotAfter, NotBefore, @{n="Computed"; e={$_.NotAfter.Subtract($_.NotBefore)}}

ls Cert:\LocalMachine\CA | Select Thumbprint,NotBefore,NotAfter,@{name='ValidDays';expression={$_.NotAfter.Subtract($_.NotBefore)}}

Get-Service | Select-Object -First 5 | ConvertTo-Csv

Get-Service | Select-Object -First 5 | ConvertTo-Csv | Out-File C:\transcript\services.csv

Get-Content C:\transcript\services.csv | ConvertFrom-Csv | Get-Member

Get-Service | Select-Object -Property Name -First 5 | ConvertTo-Csv | Out-File C:\transcript\services_only_name.csv

Import-Csv C:\transcript\services_only_name.csv

Get-ChildItem C:\Windows | Out-File C:\transcript\windows.html  | ConvertTo-Html

Get-WmiObject -Class win32_logicaldisk | Select-Object Size, FreeSpace

Get-ChildItem C:\Windows | Where-Object -Property PSIsContainer -eq -value $true

Get-Process | Where-Object {$_.ProcessName -like "chrome"}

Get-ChildItem C:\transcript -Filter "*.csv" | foreach Delete

Get-ChildItem C:\transcript -Filter "*.txt" | Foreach { $PSItem.CopyTo('c:\newfolder2\'+$PSItem.Name) } #nevytvorilo slozku automoaticky + FullyQualifiedErrorId : DirectoryNotFoundException

Get-Process | Foreach -Begin {Get-Date | Out-File -FilePath 'c:\transcript\report.txt' -Append} -Process {$PSItem | Select-Object Name, VM | Out-File 'c:\transcript\report.txt' -Append }

Get-Service|
Where { $_.Status -eq "Running" } |
ForEach -Begin { Write-Host "Services started on $(Get-Date)" } -Process { $_ }

ls C:\transcript | Format-Table Name, @{n="size in KB"; e={$_.Length/1KB};
formatString="N2"} -AutoSize


$certs = Get-ChildItem Cert:\LocalMachine\CA
$certs | foreach {$_.Thumbprint + " " + $_.Verify()}


$date = Get-Date

$date.ToString("yyyy-MM-dd")