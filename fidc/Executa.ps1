Using Module '..\.\Util.psm1';

function ExecutaPrograma {
    param (
        $processFile,
        $processArgs
    )
    Push-Location -Path $caminhoAbsolutoDiretorioExecucao;

    MostraLog $caminhoAbsolutoArquivoLog 'INICIANDO...';

    $caminhoAbsolutoArquivoLogStdOut = $caminhoAbsolutoArquivoLog + '.stdout.txt';
    $caminhoAbsolutoArquivoLogStdErr = $caminhoAbsolutoArquivoLog + '.stderr.txt';

    Start-Process -File $processFile -ArgumentList $processArgs -RedirectStandardOutput $caminhoAbsolutoArquivoLogStdOut -RedirectStandardError $caminhoAbsolutoArquivoLogStdErr -Wait -NoNewWindow;

    MostraLog $caminhoAbsolutoArquivoLog 'StandardOutput --------------------------------------------------'
    foreach ($linha in Get-Content $caminhoAbsolutoArquivoLogStdOut) {MostraLog $caminhoAbsolutoArquivoLog $linha $true};
    MostraLog $caminhoAbsolutoArquivoLog 'StandardError ---------------------------------------------------'
    foreach ($linha in Get-Content $caminhoAbsolutoArquivoLogStdErr) {MostraLog $caminhoAbsolutoArquivoLog $linha $true};

    MostraLog $caminhoAbsolutoArquivoLog '...TERMINOU';

    Pop-Location;
}

function Principal {
    Set-Variable -Name jsonProperties -Value (PegaProperties $MyInvocation.ScriptName) -Option Constant;
    if ($null -eq $jsonProperties) {
        MostraLog '' 'Arquivo ".properties" nao localizado.';
        return;
    }

    $caminhoAbsolutoArquivoLogTemp = BuscaValorParametro $jsonProperties 'caminhoAbsolutoDiretorioLog';
    if (Test-Path $caminhoAbsolutoArquivoLogTemp) {
        $caminhoAbsolutoArquivoLogTemp += ((Get-Item -Path $MyInvocation.ScriptName | ForEach-Object {$_.Name}) -replace '.ps1','') + '_log_';
        $caminhoAbsolutoArquivoLogTemp += Get-Date | ForEach-Object {$_.ToString('yyyyMMddHHmmssfff')};
        $caminhoAbsolutoArquivoLogTemp += '.txt'
    }
    Set-Variable -Name caminhoAbsolutoArquivoLog -Value $caminhoAbsolutoArquivoLogTemp -Option Constant;
    Remove-Variable caminhoAbsolutoArquivoLogTemp -Force;

    Set-Variable -Name caminhoAbsolutoDiretorioExecucao -Value (BuscaValorParametro $jsonProperties 'caminhoAbsolutoDiretorioExecucao') -Option Constant;
    Set-Variable -Name caminhoAbsolutoArquivoJre -Value (BuscaValorParametro $jsonProperties 'caminhoAbsolutoArquivoJre') -Option Constant;
    Set-Variable -Name parametrosJre -Value (BuscaValorParametro $jsonProperties 'parametrosJre') -Option Constant;

    $podeMandarVer = $true;

    if (!(Test-Path -Path ($caminhoAbsolutoDiretorioExecucao))) {
        MostraLog $caminhoAbsolutoArquivoLog ('caminhoAbsolutoDiretorioExecucao invalido (' + $caminhoAbsolutoDiretorioExecucao + ').');
        $podeMandarVer = $false;
    }

    if (!(Test-Path -Path ($caminhoAbsolutoArquivoJre))) {
        MostraLog $caminhoAbsolutoArquivoLog ('caminhoAbsolutoArquivoJre invalido (' + $caminhoAbsolutoArquivoJre + ').');
        $podeMandarVer = $false;
    }

    if (!$podeMandarVer) {
        return;
    }

    ExecutaPrograma $caminhoAbsolutoArquivoJre @($parametrosJre);
}

Principal;