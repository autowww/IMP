# SQLite Utility Functions for Managing Database Operations

# Ensure SQLite assembly is loaded
$SQLiteDLL = "$PSScriptRoot/../lib/System.Data.SQLite.dll"
if (!(Test-Path $SQLiteDLL)) {
    Write-Host "[ERROR] SQLite DLL is missing: $SQLiteDLL" -ForegroundColor Red
    exit
}
Add-Type -Path $SQLiteDLL

# Database Path
$DBPath = "$PSScriptRoot/../db/imp.db"

# Persistent SQLite Connection
$global:DBConnection = $null

function Initialize-Database {
    if (!(Test-Path $DBPath)) {
        Write-Host "[INFO] Creating database..."
        New-Item -ItemType File -Path $DBPath -Force | Out-Null
    }
    $global:DBConnection = New-Object System.Data.SQLite.SQLiteConnection("Data Source=$DBPath;Version=3;")
    $global:DBConnection.Open()
    Write-Host "[INFO] Database connection established."
    
    # Load schema
    $SchemaSQL = Get-Content "$PSScriptRoot/sqls/create_tables.sql" -Raw
    $Cmd = $global:DBConnection.CreateCommand()
    $Cmd.CommandText = $SchemaSQL
    [void]$Cmd.ExecuteNonQuery()  # Suppress output
    Write-Host "[INFO] Database schema verified."
    
    # Ensure schema is created or updated
    Alter-Database
}

function Alter-Database {
    Write-Host "[INFO] Checking for database schema changes..."
    try {
        # Load expected schema
        $SchemaSQLPath = "$PSScriptRoot/sqls/create_tables.sql"
        if (!(Test-Path $SchemaSQLPath)) {
            Write-Host "[ERROR] Missing schema file: $SchemaSQLPath" -ForegroundColor Red
            return
        }
        $ExpectedSchemaSQL = Get-Content $SchemaSQLPath -Raw

        # Get existing schema from SQLite
        $Cmd = $global:DBConnection.CreateCommand()
        $Cmd.CommandText = "SELECT name, sql FROM sqlite_master WHERE type IN ('table', 'index')"
        $Reader = $Cmd.ExecuteReader()

        $ExistingSchema = @{}
        while ($Reader.Read()) {
            $TableName = $Reader["name"]
            $CreateStatement = $Reader["sql"]
            if ($TableName -and $CreateStatement) {
                $ExistingSchema[$TableName] = $CreateStatement
            }
        }
        $Reader.Close()

        # Process expected schema to check for missing elements
        $Statements = $ExpectedSchemaSQL -split ";"
        foreach ($Statement in $Statements) {
            $TrimmedStatement = $Statement.Trim()
            if ($TrimmedStatement -match "CREATE TABLE (\w+)") {
                $TableName = $matches[1]
                if (-not $ExistingSchema.ContainsKey($TableName)) {
                    Write-Host "[ALTER] Creating missing table: $TableName"
                    $Cmd = $global:DBConnection.CreateCommand()
                    $Cmd.CommandText = $TrimmedStatement
                    [void]$Cmd.ExecuteNonQuery()
                }
            }
            elseif ($TrimmedStatement -match "CREATE INDEX (\w+) ON (\w+)") {
                $IndexName = $matches[1]
                $TableName = $matches[2]
                if (-not $ExistingSchema.ContainsKey($IndexName)) {
                    Write-Host "[ALTER] Creating missing index: $IndexName on $TableName"
                    $Cmd = $global:DBConnection.CreateCommand()
                    $Cmd.CommandText = $TrimmedStatement
                    [void]$Cmd.ExecuteNonQuery()
                }
            }
        }

        Write-Host "[INFO] Database schema is up to date."
    } catch {
        Write-Host "[ERROR] Failed to alter database: $_" -ForegroundColor Red
    }
}

function Close-Database {
    if ($global:DBConnection -ne $null) {
        $global:DBConnection.Close()
        Write-Host "[INFO] Database connection closed."
    }
}

function Insert-Original {
    param ([string]$FilePath)
    try {
        $Cmd = $global:DBConnection.CreateCommand()
        $InsertSQL = Get-Content "$PSScriptRoot/sqls/insert_original.sql" -Raw
        $Cmd.CommandText = $InsertSQL
        $Cmd.Parameters.Add((New-Object Data.SQLite.SQLiteParameter("@FilePath", $FilePath)))
        [void]$Cmd.ExecuteNonQuery() | Out-Null  # Suppress output
    } catch {
        Write-Host "[ERROR] Failed to insert original: $_" -ForegroundColor Red
    }
}

function Insert-Proxy {
    param ([string]$OriginalID, [string]$FilePath)
    try {
        $Cmd = $global:DBConnection.CreateCommand()
        $InsertSQL = Get-Content "$PSScriptRoot/sqls/insert_proxy.sql" -Raw
        $Cmd.CommandText = $InsertSQL
        $Cmd.Parameters.Add((New-Object Data.SQLite.SQLiteParameter("@OriginalID", $OriginalID)))
        $Cmd.Parameters.Add((New-Object Data.SQLite.SQLiteParameter("@FilePath", $FilePath)))
        [void]$Cmd.ExecuteNonQuery() | Out-Null  # Suppress output
    } catch {
        Write-Host "[ERROR] Failed to insert proxy: $_" -ForegroundColor Red
    }
}

function Load-Originals {
    if ($global:DBConnection -eq $null -or $global:DBConnection.State -ne "Open") {
        Write-Host "[ERROR] Database connection is not open!" -ForegroundColor Red
        return @()
    }

    try {
        $Cmd = $global:DBConnection.CreateCommand()
        $SelectSQLPath = "$PSScriptRoot/sqls/select_originals.sql"

        if (!(Test-Path $SelectSQLPath)) {
            Write-Host "[ERROR] Missing SQL query file: $SelectSQLPath" -ForegroundColor Red
            return @()
        }

        $SelectSQL = Get-Content $SelectSQLPath -Raw
        $Cmd.CommandText = $SelectSQL

        $Reader = $Cmd.ExecuteReader()

        if (!$Reader.HasRows) {
            Write-Host "[WARN] No original files found in the database."
            return @()
        }

        $Files = @()
        while ($Reader.Read()) {
            $FilePath = $Reader["FilePath"]
            if ($FilePath -ne $null -and $FilePath -ne "") {
                $Files += [PSCustomObject]@{ FullName = $FilePath }
            }
        }
        $Reader.Close()
        return $Files
    } catch {
        Write-Host "[ERROR] Failed to load originals: $_" -ForegroundColor Red
        return @()
    }
}

function Load-Proxies {
    if ($global:DBConnection -eq $null -or $global:DBConnection.State -ne "Open") {
        Write-Host "[ERROR] Database connection is not open!" -ForegroundColor Red
        return @()
    }

    try {
        $Cmd = $global:DBConnection.CreateCommand()
        $SelectSQLPath = "$PSScriptRoot/sqls/select_proxies.sql"

        if (!(Test-Path $SelectSQLPath)) {
            Write-Host "[ERROR] Missing SQL query file: $SelectSQLPath" -ForegroundColor Red
            return @()
        }

        $SelectSQL = Get-Content $SelectSQLPath -Raw
        $Cmd.CommandText = $SelectSQL

        $Reader = $Cmd.ExecuteReader()

        if (!$Reader.HasRows) {
            Write-Host "[WARN] No proxies found in the database."
            return @()
        }

        $Files = @()
        while ($Reader.Read()) {
            $FilePath = $Reader["FilePath"]
            if ($FilePath -ne $null -and $FilePath -ne "") {
                $Files += [PSCustomObject]@{ FullName = $FilePath }
            }
        }
        $Reader.Close()
        return $Files
    } catch {
        Write-Host "[ERROR] Failed to load proxies: $_" -ForegroundColor Red
        return @()
    }
}

# Ensure database connection is closed at script end
Register-EngineEvent PowerShell.Exiting -Action { Close-Database }
