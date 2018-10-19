function MostraLog
{
    Param (
        [string] $caminhoAbsolutoArquivoLog,
        [string] $log,
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