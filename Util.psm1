function MostraLog
{
    Param (
        [Parameter(Mandatory=$true)][string] $caminhoAbsolutoArquivoLog,
        [Parameter(Mandatory=$true)][string] $log,
        [bool] $ocultaTimeStamp
    )
    if (!$ocultaTimeStamp) {$logFinal = '[' + (Get-Date | ForEach-Object {$_.ToString('yyyy-MM-ddTHH:mm:ss.fff')}) + '] '};
    $logFinal += $log;

    if ($caminhoAbsolutoArquivoLog -match '^.*\.txt$') {Add-content -Path $caminhoAbsolutoArquivoLog -Value $logFinal};
    Write-Host $logFinal;
}

function PegaProperties {
    param (
        [string] $caminhoAbsolutoScript
    )
    $caminhoAbsolutoArquivoProperties = $caminhoAbsolutoScript -replace ('.ps1','.properties');

    if (!(Test-Path -Path $caminhoAbsolutoArquivoProperties)) {
        return $null;
    } else {
        return (Get-Content -Path $caminhoAbsolutoArquivoProperties | ConvertFrom-Json);
    }
}

function BuscaValorParametro {
    param (
        $jsonProperties,
        [string] $codigoParametro
    )
    $valorParametro = '';

    foreach ($jsonParameters in $jsonProperties.parameters.Where({$_.environment -eq $jsonProperties.execution})) {
        foreach ($jsonValues in $jsonParameters.values.Where({$_.parameter -eq $codigoParametro})) {
            $valorParametro = $jsonValues.value;
            break;
        }
        if (!$valorParametro -eq '') {
            break;
        }
    }

    return $valorParametro;
}

function ValidaDiretorio {
    param (
        [string]$caminhoAbsoultoDiretorio
    )
    $existe = $true;
    try {
        if (!(Test-Path -Path ($caminhoAbsoultoDiretorio))) {
            $existe = $false;
        }
    } catch {
        $existe = $false;
    }
    return $existe;
}

function ExecutaComandoSql() {
    Param (
        [Parameter(Mandatory=$true)][string]$Server,
        [Parameter(Mandatory=$true)][string]$Database,
        [Parameter(Mandatory=$true)][string]$Username,
        [Parameter(Mandatory=$true)][string]$Password,
        [Parameter(Mandatory=$true)][string]$Query
    )
    
    #build connection string
    $connstring = "Server=$Server; Database=$Database; User ID=$username; Password=$password;";
    
    #connect to database
    $connection = New-Object System.Data.SqlClient.SqlConnection($connstring);
    $connection.Open();
    
    #build query object
    $command = $connection.CreateCommand();
    $command.CommandText = $Query;
    $command.CommandTimeout = $CommandTimeout;
    
    #run query
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command;
    $dataset = New-Object System.Data.DataSet;
    $adapter.Fill($dataset) | Out-Null;
    
    #return the first collection of results or an empty array
    If ($null -ne $dataset.Tables[0]) {
        $table = $dataset.Tables[0];
    } Else {
        If ($table.Rows.Count -eq 0) {
            $table = New-Object System.Collections.ArrayList;
        }
    }
    
    $connection.Close();
    return $table;
}

function PostSlack {
    param (
        [Parameter(Mandatory=$true)][string]$text,
        [Parameter(Mandatory=$true)][string]$channel
    )

    $url = 'https://hooks.slack.com/services/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'
    $body = '{"text": "' + $text + '", "channel": "#' + $channel + '"}'
    return Invoke-RestMethod -Method 'Post' -Uri $url -Body $body;
    
}