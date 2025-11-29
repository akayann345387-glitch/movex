<#
Runs a simple integration test for the MoveX dev stack.

What it does:
- Starts the infra via `docker compose up -d --build` in `monorepo/infra`
- Waits until `ride-service` responds on `http://localhost:8080/health`
- Posts a test ride to `/rides`
- Verifies the ride row exists in Postgres by running `psql` inside the postgres container

Usage: Run from PowerShell (may require elevated privileges for docker):
param(
    [switch]$NoCleanup
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "Integration test: starting infra and verifying ride persistence"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$infraDir = Join-Path $scriptRoot '..\infra'
Set-Location $infraDir

Write-Host "Bringing up docker-compose stack (this may take a minute)..."
& docker compose up -d --build

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
    if (-not $NoCleanup) { Write-Host 'Cleaning up...'; & docker compose down -v }
    exit 2
}

Write-Host "ride-service is healthy. Creating a test ride..."

$testPassenger = 'integration-test'
$body = @{ passenger = $testPassenger } | ConvertTo-Json
try {
    $createResp = Invoke-RestMethod -Uri 'http://localhost:8080/rides' -Method Post -Body $body -ContentType 'application/json' -TimeoutSec 10
} catch {
    Write-Error "Failed to POST /rides: $_"
    if (-not $NoCleanup) { Write-Host 'Cleaning up...'; & docker compose down -v }
    exit 3
}

if (-not $createResp.id) {
    Write-Error "Ride creation response missing id"
    if (-not $NoCleanup) { Write-Host 'Cleaning up...'; & docker compose down -v }
    exit 4
}

$rideId = $createResp.id
Write-Host "Created ride with id: $rideId"

Start-Sleep -Seconds 2

# Verify in Postgres container
$psqlSql = "SELECT passenger FROM rides WHERE id = $rideId;"
Write-Host "Querying Postgres inside container for ride id $rideId"
try {
    $psqlOut = & docker exec infra-postgres-1 psql -U movex -d movex -t -A -c $psqlSql
} catch {
    Write-Error "Failed to execute psql inside postgres container: $_"
    if (-not $NoCleanup) { Write-Host 'Cleaning up...'; & docker compose down -v }
    exit 5
}

$psqlOutTrim = $psqlOut -as [string]
if ($null -eq $psqlOutTrim) { $psqlOutTrim = '' }
$psqlOutTrim = $psqlOutTrim.Trim()

if ($psqlOutTrim -eq $testPassenger) {
    Write-Host "Integration test PASSED: passenger in DB matches '$testPassenger'"
    if (-not $NoCleanup) { Write-Host 'Cleaning up...'; & docker compose down -v }
    exit 0
} else {
    Write-Error "Integration test FAILED: expected passenger '$testPassenger' but DB returned: '$psqlOutTrim'"
    Write-Host "Dumping recent Postgres logs for diagnosis:"
    & docker compose logs --no-color --tail 200 postgres
    if (-not $NoCleanup) { Write-Host 'Cleaning up...'; & docker compose down -v }
    exit 6
}
if ($psqlOutTrim -eq $testPassenger) {
    Write-Host "Integration test PASSED: passenger in DB matches '$testPassenger'"
    if (-not $NoCleanup) {
        Write-Host "Cleaning up test ride row from Postgres..."
        $deleteSql = "DELETE FROM rides WHERE id = $rideId;"
        try {
            & docker exec infra-postgres-1 psql -U movex -d movex -c $deleteSql | Out-Host
        } catch {
            Write-Warning "Failed to delete test ride row id $rideId: $_"
        }
    } else {
        Write-Host "NoCleanup flag set; leaving test ride row in Postgres."
    }
    exit 0
} else {
    Write-Error "Integration test FAILED: expected passenger '$testPassenger' but DB returned: '$psqlOutTrim'"
    Write-Host "Dumping recent Postgres logs for diagnosis:"
    & docker compose logs --no-color --tail 200 postgres
    exit 6
}
