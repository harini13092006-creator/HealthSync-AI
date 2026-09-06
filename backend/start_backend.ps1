$ErrorActionPreference = 'Stop'

$port = 8000
$localIp = Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object {
        $_.IPAddress -notlike '127.*' -and
        $_.IPAddress -notlike '169.254.*' -and
        $_.PrefixOrigin -ne 'WellKnown'
    } |
    Select-Object -First 1 -ExpandProperty IPAddress

if (-not $localIp) {
    $localIp = 'YOUR_COMPUTER_LAN_IP'
}

Write-Host "HealthSync AI backend: http://127.0.0.1:$port"
Write-Host "Phone/LAN API:         http://$localIp`:$port"
Write-Host "API docs:              http://$localIp`:$port/api/docs/"
Write-Host "Keep this window open while devices use the backend."

python manage.py runserver 0.0.0.0:$port
