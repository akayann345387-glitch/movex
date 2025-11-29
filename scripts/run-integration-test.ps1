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

# helper: resolve a service container id from docker compose or docker ps
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
    # fallback: try docker ps by compose label (most robust), then by name patterns, then by image
    try {
        $byLabel = (& docker ps --filter "label=com.docker.compose.service=$serviceName" --format "{{.ID}}") -join "" | Trim
        if (-not [string]::IsNullOrEmpty($byLabel)) { return $byLabel }
    } catch {
    }
    try {
        # common pattern: projectname_service_1 or project-service-1, try partial matches
        $pattern1 = "${serviceName}"
        $byName = (& docker ps --filter "name=$pattern1" --format "{{.ID}}") -join "" | Trim
        if (-not [string]::IsNullOrEmpty($byName)) { return $byName }
    } catch {
    }
    try {
        $projPattern = (Get-ChildItem -Name .. | Where-Object { $_ -eq 'infra' } | Out-Null) ;
        $byProjName = (& docker ps --format "{{.ID}} {{.Names}} {{.Image}}" | Select-String -Pattern "$serviceName" | ForEach-Object { ($_ -split ' ')[0] }) -join "" | Trim
        if (-not [string]::IsNullOrEmpty($byProjName)) { return $byProjName }
    } catch {
    }
    try {
        # try image name
        $byImage = (& docker ps --filter "ancestor=postgres:15" --format "{{.ID}}") -join "" | Trim
        if (-not [string]::IsNullOrEmpty($byImage)) { return $byImage }
    } catch {
    }
    return $null
}

# Wait for Postgres to accept connections (useful to avoid ride-service DB connect failures)
$pgContainer = Get-ComposeServiceContainerId -serviceName 'postgres'
if ($pgContainer) {
    Write-Host "Waiting for Postgres container $pgContainer to accept connections..."
    $pgMax = 30
    $pgAttempt = 0
    $pgReady = $false
    while ($pgAttempt -lt $pgMax) {
        $pgAttempt++
        try {
            $out = & docker exec $pgContainer pg_isready -U movex -d movex 2>&1
            if ($LASTEXITCODE -eq 0) { $pgReady = $true; break }
            Write-Host ([string]::Format("pg_isready attempt {0}/{1}: {2}", $pgAttempt, $pgMax, $out))
        } catch {
            Write-Host "pg_isready attempt $pgAttempt failed: $_" -ForegroundColor Yellow
        }
        Start-Sleep -Seconds 2
    }
    if (-not $pgReady) {
        Write-Error "Postgres did not become ready within timeout"
        if (-not $NoCleanup) { Write-Host 'Cleaning up...'; & docker compose @composeArgs down -v }
        exit 2
    }
    Write-Host "Postgres is accepting connections"
} else {
    Write-Warning "Could not determine Postgres container id; continuing (ride-service may fail to connect)"
}

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
    Write-Warning "ride-service did not become healthy via localhost within timeout — trying container-internal health check (useful for CI compose without published ports)"

    # Try health check from inside the ride-service container (fallback for CI compose w/o host ports)
    $rideContainer = Get-ComposeServiceContainerId -serviceName 'ride-service'
    if ($rideContainer) {
        $maxInner = 30
        $inner = 0
        while ($inner -lt $maxInner) {
            try {
                $inner++
                Write-Host "Checking ride-service health from inside container (attempt $inner/$maxInner)..."
                $out = & docker exec $rideContainer sh -c "curl -sS http://localhost:8080/health || true"
                if ($out) {
                    try {
                        $parsed = $out | ConvertFrom-Json -ErrorAction Stop
                        if ($parsed.status -eq 'ok') { Write-Host 'ride-service healthy (container-internal)'; break }
                    } catch {
                        # not JSON — continue
                    }
                }
            } catch {
                Start-Sleep -Seconds 2
            }
            Start-Sleep -Seconds 2
        }
        if ($inner -ge $maxInner) {
            Write-Error "ride-service did not become healthy within container checks"
            if (-not $NoCleanup) { Write-Host 'Cleaning up...'; & docker compose @composeArgs down -v }
            exit 2
        }
    } else {
        Write-Error "ride-service did not become healthy within timeout and container id could not be determined"
        if (-not $NoCleanup) { Write-Host 'Cleaning up...'; & docker compose @composeArgs down -v }
        exit 2
    }
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
