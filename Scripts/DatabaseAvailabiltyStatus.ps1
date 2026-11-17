param(
	[Parameter(Mandatory = $true)]
	[string]$ServerInstance,

	[string]$Database,

	[ValidateRange(1, 300)]
	[int]$ConnectionTimeout = 15
)

$connectionString = "Server=$ServerInstance;Database=master;Integrated Security=True;Connect Timeout=$ConnectionTimeout;"
$connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)

try {
	$connection.Open()

	$command = $connection.CreateCommand()
	$command.CommandTimeout = $ConnectionTimeout

	if ([string]::IsNullOrWhiteSpace($Database)) {
		$command.CommandText = @'
SELECT name AS DatabaseName, state_desc AS Status
FROM sys.databases
ORDER BY name;
'@
	}
	else {
		$command.CommandText = @'
SELECT name AS DatabaseName, state_desc AS Status
FROM sys.databases
WHERE name = @DatabaseName;
'@
		$null = $command.Parameters.Add('@DatabaseName', [System.Data.SqlDbType]::NVarChar, 128)
		$command.Parameters['@DatabaseName'].Value = $Database
	}

	$reader = $command.ExecuteReader()
	$found = $false
	while ($reader.Read()) {
		$found = $true
		[PSCustomObject]@{
			Server       = $ServerInstance
			Database     = $reader['DatabaseName']
			Status       = $reader['Status']
			IsOnline     = ($reader['Status'] -eq 'ONLINE')
		}
	}
	$reader.Close()

	if (-not $found) {
		if ([string]::IsNullOrWhiteSpace($Database)) {
			Write-Error 'No databases were returned. Check the connection and permissions.'
		}
		else {
			Write-Error "Database '$Database' was not found or is not visible to this account."
		}
		exit 1
	}
}
catch {
	Write-Error "Unable to check database status on '$ServerInstance': $($_.Exception.Message)"
	exit 1
}
finally {
	if ($connection.State -ne [System.Data.ConnectionState]::Closed) {
		$connection.Close()
	}
	$connection.Dispose()
}
#script ends here
# no here
#Rebase
#merge
#rebase and Merge