<#
Runs a simple integration test for the MoveX dev stack.

What it does:
- Starts the infra via `docker compose up -d --build` in `monorepo/infra`
- Waits until `ride-service` responds on `http://localhost:8080/health`
- Posts a test ride to `/rides`
- Verifies the ride row exists in Postgres by running `psql` inside the postgres container

Usage: Run from PowerShell (may require elevated privileges for docker):
#>
param(
    [switch]$NoCleanup
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "Integration test: starting infra and verifying ride persistence"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$infraDir = Join-Path $scriptRoot '..\infra'
Set-Location $infraDir

# Build compose arguments if COMPOSE_FILE env var is provided
$composeArgs = @()
if ($env:COMPOSE_FILE) {
    $composeArgs += '-f'
    $composeArgs += $env:COMPOSE_FILE
} else {
    # fallback to CI compose if present in infra (useful when running locally to reproduce CI)
    $ciCompose = Join-Path $infraDir 'docker-compose.ci.yml'
    if (Test-Path $ciCompose) {
        $composeArgs += '-f'
        $composeArgs += './docker-compose.ci.yml'
        Write-Host "No COMPOSE_FILE env var set — falling back to './docker-compose.ci.yml'"
    }
}

Write-Host "Bringing up docker-compose stack (this may take a minute)..."
& docker compose @composeArgs up -d --build

# Wait for ride-service health endpoint
$healthUrl = 'http://localhost:8080/health'
$maxAttempts = 60
$attempt = 0
while ($attempt -lt $maxAttempts) {
    try {
        $attempt++
        Write-Host "Checking ride-service health (attempt $attempt/$maxAttempts)..."
        $resp = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 3
        if ($resp -and $resp.status -eq 'ok') { break }
    } catch {
        Start-Sleep -Seconds 5
    }
}

if ($attempt -ge $maxAttempts) {
    Write-Error "ride-service did not become healthy within timeout"
    if (-not $NoCleanup) { Write-Host 'Cleaning up...'; & docker compose @composeArgs down -v }
    exit 2
}

Write-Host "ride-service is healthy. Creating a test ride..."

$testPassenger = 'integration-test'
$body = @{ passenger = $testPassenger } | ConvertTo-Json
try {
    $createResp = Invoke-RestMethod -Uri 'http://localhost:8080/rides' -Method Post -Body $body -ContentType 'application/json' -TimeoutSec 10
} catch {
    Write-Error "Failed to POST /rides: $_"
    if (-not $NoCleanup) { Write-Host 'Cleaning up...'; & docker compose @composeArgs down -v }
    exit 3
}

if (-not $createResp.id) {
    Write-Error "Ride creation response missing id"
    if (-not $NoCleanup) { Write-Host 'Cleaning up...'; & docker compose @composeArgs down -v }
    exit 4
}

$rideId = $createResp.id
Write-Host "Created ride with id: $rideId"

Start-Sleep -Seconds 2

function Get-ComposeServiceContainerId {
    param(
        [string]$serviceName
    )
    try {
        $id = (& docker compose @composeArgs ps -q $serviceName) -join "" | Trim
        if (-not [string]::IsNullOrEmpty($id)) { return $id }
    } catch {
        # ignore and try alternate lookup
    }
    # fallback: try to find a container with 'postgres' in its name
    try {
        $fallback = (& docker ps --filter "name=postgres" --format "{{.ID}}") -join "" | Trim
        if (-not [string]::IsNullOrEmpty($fallback)) { return $fallback }
    } catch {
    }
    return $null
}

# Verify in Postgres container (with retries)
$psqlSql = "SELECT passenger FROM rides WHERE uuid = '$rideId'::uuid;"
Write-Host "Querying Postgres inside container for ride id $rideId"
$pgContainer = Get-ComposeServiceContainerId -serviceName 'postgres'
if (-not $pgContainer) {
    Write-Error "Could not determine Postgres container id via 'docker compose ps -q postgres' or docker ps"
    if (-not $NoCleanup) { Write-Host 'Cleaning up...'; & docker compose @composeArgs down -v }
    exit 5
}

$maxDbAttempts = 6
$dbAttempt = 0
$psqlOutTrim = ''
while ($dbAttempt -lt $maxDbAttempts) {
    try {
        $dbAttempt++
        Write-Host "Postgres query attempt $dbAttempt/$maxDbAttempts..."
        $psqlOut = & docker exec $pgContainer psql -U movex -d movex -t -A -c $psqlSql
        $psqlOutTrim = ($psqlOut -as [string]).Trim()
        if ($psqlOutTrim -ne '') { break }
    } catch {
        Write-Host "Query attempt $dbAttempt failed: $_" -ForegroundColor Yellow
    }
    Start-Sleep -Seconds 2
}

if ($psqlOutTrim -eq $testPassenger) {
    Write-Host "Integration test PASSED: passenger in DB matches '$testPassenger'"
    if (-not $NoCleanup) {
        Write-Host "Cleaning up test ride row from Postgres..."
        $deleteSql = "DELETE FROM rides WHERE uuid = '$rideId'::uuid;"
        try {
            & docker exec $pgContainer psql -U movex -d movex -c $deleteSql | Out-Host
        } catch {
            Write-Warning "Failed to delete test ride row id ${rideId}: $_"
        }
        Write-Host 'Cleaning up...'
        & docker compose @composeArgs down -v
    } else {
        Write-Host "NoCleanup flag set; leaving test ride row in Postgres."
    }
    exit 0
} else {
    Write-Error "Integration test FAILED: expected passenger '$testPassenger' but DB returned: '$psqlOutTrim'"
    Write-Host "Dumping recent Postgres logs for diagnosis:"
    & docker compose @composeArgs logs --no-color --tail 200 postgres
    if (-not $NoCleanup) { Write-Host 'Cleaning up...'; & docker compose @composeArgs down -v }
    exit 6
}
