Using Module '..\.\Util.psm1';

function Disponibiliza {
    param (
        [bool] $arquivoCompactado,
        $arquivo,
        [string] $caminhoAbsolutoDiretorioEnviados
    )
    if ($null -eq $arquivo) {
        return 0;
    }
    if (!(ValidaDiretorio $caminhoAbsolutoDiretorioEnviados)) {
        return 0;
    }

    MostraLog $caminhoAbsolutoArquivoLog 'DISPONIBILIZACAO:';

    $foi = $false;

    if ($arquivoCompactado) {
        $caminhoAbsolutoArquivoLogStdOut = $caminhoAbsolutoArquivoLog + '.stdout_' + (Get-Date | ForEach-Object {$_.ToString('yyyyMMddHHmmssfff')}) + '.txt';
        $caminhoAbsolutoArquivoLogStdErr = $caminhoAbsolutoArquivoLog + '.stderr_' + (Get-Date | ForEach-Object {$_.ToString('yyyyMMddHHmmssfff')}) + '.txt';

        Start-Process -File $caminhoAbsolutoArquivo7zip -ArgumentList @('e', $arquivo.FullName, ('-o' + $caminhoAbsolutoDiretorioCarga), '-aoa') -RedirectStandardOutput $caminhoAbsolutoArquivoLogStdOut -RedirectStandardError $caminhoAbsolutoArquivoLogStdErr -Wait -NoNewWindow;

        foreach ($linha in Get-Content $caminhoAbsolutoArquivoLogStdOut) {MostraLog $caminhoAbsolutoArquivoLog $linha $true};
        foreach ($linha in Get-Content $caminhoAbsolutoArquivoLogStdErr) {MostraLog $caminhoAbsolutoArquivoLog $linha $true};

        Remove-Item -Path $caminhoAbsolutoArquivoLogStdOut -Force;
        Remove-Item -Path $caminhoAbsolutoArquivoLogStdErr -Force;

        Move-Item -Path $arquivo.FullName -Destination $caminhoAbsolutoDiretorioEnviados -Force;

        $foi = $true;

    } else {
        $caminhoAbsolutoArquivoDisponibilizado = $caminhoAbsolutoDiretorioCarga + $arquivo.Name;

        Copy-Item -Path $arquivo.FullName -Destination $caminhoAbsolutoArquivoDisponibilizado -Force;

        if (!(ValidaDiretorio $caminhoAbsolutoArquivoDisponibilizado)) {
            MostraLog $caminhoAbsolutoArquivoLog $caminhoAbsolutoArquivoDisponibilizado;
            $foi = $true;
        }
    }

    if ($foi) {
        Move-Item -Path $arquivo.FullName -Destination $caminhoAbsolutoDiretorioEnviados -Force;
        return 1;
    }
}

function ProcuraArquivos {
    param (
        [string] $caminhoAbsolutoDiretorio,
        [string] $caminhoAbsolutoDiretorioEnviados,
        [string] $pattern,
        [bool] $arquivoCompactado
    )
    if (!(ValidaDiretorio $caminhoAbsolutoDiretorio)) {
        return 0;
    }
    if (!(ValidaDiretorio $caminhoAbsolutoDiretorioEnviados)) {
        return 0;
    }

    $diretorio = Get-Item -Path $caminhoAbsolutoDiretorio;

    ForEach-Object -InputObject $diretorio.GetFiles($pattern) {
        foreach ($arquivo in $_) {
            MostraLog $caminhoAbsolutoArquivoLog ($arquivo.FullName);

            if ($arquivoCompactado) {
                $caminhoAbsolutoArquivoLogStdOut = $caminhoAbsolutoArquivoLog + '.stdout_' + (Get-Date | ForEach-Object {$_.ToString('yyyyMMddHHmmssfff')}) + '.txt';
                $caminhoAbsolutoArquivoLogStdErr = $caminhoAbsolutoArquivoLog + '.stderr_' + (Get-Date | ForEach-Object {$_.ToString('yyyyMMddHHmmssfff')}) + '.txt';

                Start-Process -File $caminhoAbsolutoArquivo7zip -ArgumentList @('t', $arquivo.FullName, '*.*', '-r') -RedirectStandardOutput $caminhoAbsolutoArquivoLogStdOut -RedirectStandardError $caminhoAbsolutoArquivoLogStdErr -Wait -NoNewWindow;

                MostraLog $caminhoAbsolutoArquivoLog 'VALIDACAO:';
                foreach ($linha in Get-Content $caminhoAbsolutoArquivoLogStdOut) {MostraLog $caminhoAbsolutoArquivoLog $linha $true};
                foreach ($linha in Get-Content $caminhoAbsolutoArquivoLogStdErr) {MostraLog $caminhoAbsolutoArquivoLog $linha $true};

                if (Select-String -Pattern 'Everything is Ok' -Path $caminhoAbsolutoArquivoLogStdOut) {
                    $quantidadeMovida += Disponibiliza $true $arquivo $caminhoAbsolutoDiretorioEnviados;
                }

                Remove-Item -Path $caminhoAbsolutoArquivoLogStdOut -Force;
                Remove-Item -Path $caminhoAbsolutoArquivoLogStdErr -Force;
            } else {
                $quantidadeMovida += Disponibiliza $false $arquivo $caminhoAbsolutoDiretorioEnviados;
            }
        }
    }

    return $quantidadeMovida;
}

function Principal {
    Set-Variable -Name jsonProperties -Value (PegaProperties $MyInvocation.ScriptName) -Option ReadOnly;
    if ($null -eq $jsonProperties) {
        MostraLog '' 'Arquivo ".properties" nao localizado.';
        return;
    }
    
    #Limpa conteúdo das variáveis de configuração (Prenchidas lendo arquivo .properties)
    Remove-Variable -Name 'caminhoAbsolutoArquivoLog' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'caminhoAbsolutoDiretorioCarga' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'caminhoAbsolutoDiretorioCnab' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'patternCnab' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'arquivoCnabCompactado' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'caminhoAbsolutoDiretorioCnabEnviados' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'caminhoAbsolutoDiretorioRetorno' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'patternRetorno' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'arquivoRetornoCompactado' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'arquivoRetornoCompactado' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'caminhoAbsolutoDiretorioRetornoEnviados' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'caminhoAbsolutoDiretorioEdi' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'patternEdi' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'arquivoEdiCompactado' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'caminhoAbsolutoDiretorioEdiEnviados' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'caminhoAbsolutoArquivo7zip' -Force -ErrorAction 'SilentlyContinue';

    #Preenche variáveis de configuração (Prenchidas lendo arquivo .properties)
    $caminhoAbsolutoArquivoLogTemp = BuscaValorParametro $jsonProperties 'caminhoAbsolutoDiretorioLog';
    if (Test-Path $caminhoAbsolutoArquivoLogTemp) {
        $caminhoAbsolutoArquivoLogTemp += ((Get-Item -Path $MyInvocation.ScriptName | ForEach-Object {$_.Name}) -replace '.ps1','') + '_log_';
        $caminhoAbsolutoArquivoLogTemp += Get-Date | ForEach-Object {$_.ToString('yyyyMMdd')};
        $caminhoAbsolutoArquivoLogTemp += '.txt'
    }
    Set-Variable -Name 'caminhoAbsolutoArquivoLog' -Value $caminhoAbsolutoArquivoLogTemp -Option ReadOnly;
    Remove-Variable -Name 'caminhoAbsolutoArquivoLogTemp' -Force;

    Set-Variable -Name 'caminhoAbsolutoDiretorioCarga' -Value (BuscaValorParametro $jsonProperties 'caminhoAbsolutoDiretorioCarga') -Option ReadOnly;

    Set-Variable -Name 'caminhoAbsolutoDiretorioCnab' -Value (BuscaValorParametro $jsonProperties 'caminhoAbsolutoDiretorioCnab') -Option ReadOnly;
    Set-Variable -Name 'patternCnab' -Value (BuscaValorParametro $jsonProperties 'patternCnab') -Option ReadOnly;
    if ((BuscaValorParametro $jsonProperties 'arquivoCnabCompactado') -eq 'true') {
        Set-Variable -Name 'arquivoCnabCompactado' -Value $true -Option ReadOnly;
    } else {
        Set-Variable -Name 'arquivoCnabCompactado' -Value $false -Option ReadOnly;
    }
    Set-Variable -Name 'caminhoAbsolutoDiretorioCnabEnviados' -Value (BuscaValorParametro $jsonProperties 'caminhoAbsolutoDiretorioCnabEnviados') -Option ReadOnly;

    Set-Variable -Name 'caminhoAbsolutoDiretorioRetorno' -Value (BuscaValorParametro $jsonProperties 'caminhoAbsolutoDiretorioRetorno') -Option ReadOnly;
    Set-Variable -Name 'patternRetorno' -Value (BuscaValorParametro $jsonProperties 'patternRetorno') -Option ReadOnly;
    if ((BuscaValorParametro $jsonProperties 'arquivoRetornoCompactado') -eq 'true') {
        Set-Variable -Name 'arquivoRetornoCompactado' -Value $true -Option ReadOnly;
    } else {
        Set-Variable -Name 'arquivoRetornoCompactado' -Value $false -Option ReadOnly;
    }
    Set-Variable -Name 'caminhoAbsolutoDiretorioRetornoEnviados' -Value (BuscaValorParametro $jsonProperties 'caminhoAbsolutoDiretorioRetornoEnviados') -Option ReadOnly;

    Set-Variable -Name 'caminhoAbsolutoDiretorioEdi' -Value (BuscaValorParametro $jsonProperties 'caminhoAbsolutoDiretorioEdi') -Option ReadOnly;
    Set-Variable -Name 'patternEdi' -Value (BuscaValorParametro $jsonProperties 'patternEdi') -Option ReadOnly;
    if ((BuscaValorParametro $jsonProperties 'arquivoEdiCompactado') -eq 'true') {
        Set-Variable -Name 'arquivoEdiCompactado' -Value $true -Option ReadOnly;
    } else {
        Set-Variable -Name 'arquivoEdiCompactado' -Value $false -Option ReadOnly;
    }
    Set-Variable -Name 'caminhoAbsolutoDiretorioEdiEnviados' -Value (BuscaValorParametro $jsonProperties 'caminhoAbsolutoDiretorioEdiEnviados') -Option ReadOnly;

    Set-Variable -Name 'caminhoAbsolutoArquivo7zip' -Value (BuscaValorParametro $jsonProperties 'caminhoAbsolutoArquivo7zip') -Option ReadOnly;
 
    #Vai começar a festa! \o/
    $podeMandarVer = $true;

    if (!(ValidaDiretorio $caminhoAbsolutoDiretorioCarga)) {
        MostraLog $caminhoAbsolutoArquivoLog ('caminhoAbsolutoDiretorioCarga invalido (' + $caminhoAbsolutoDiretorioCarga + ').');
        $podeMandarVer = $false;
    }

    if (!(ValidaDiretorio $caminhoAbsolutoDiretorioCnab)) {
        MostraLog $caminhoAbsolutoArquivoLog ('caminhoAbsolutoDiretorioCnab invalido (' + $caminhoAbsolutoDiretorioCnab + ').');
        $podeMandarVer = $false;
    }

    if (!(ValidaDiretorio $caminhoAbsolutoDiretorioCnabEnviados)) {
        MostraLog $caminhoAbsolutoArquivoLog ('caminhoAbsolutoDiretorioCnabEnviados invalido (' + $caminhoAbsolutoDiretorioCnabEnviados + ').');
        $podeMandarVer = $false;
    }

    if (!(ValidaDiretorio $caminhoAbsolutoDiretorioRetorno)) {
        MostraLog $caminhoAbsolutoArquivoLog ('caminhoAbsolutoDiretorioRetorno invalido (' + $caminhoAbsolutoDiretorioRetorno + ').');
        $podeMandarVer = $false;
    }
    
    if (!(ValidaDiretorio $caminhoAbsolutoDiretorioRetornoEnviados)) {
        MostraLog $caminhoAbsolutoArquivoLog ('caminhoAbsolutoDiretorioRetornoEnviados invalido (' + $caminhoAbsolutoDiretorioRetornoEnviados + ').');
        $podeMandarVer = $false;
    }
    
    if (!(ValidaDiretorio $caminhoAbsolutoDiretorioEdi)) {
        MostraLog $caminhoAbsolutoArquivoLog ('caminhoAbsolutoDiretorioEdi invalido (' + $caminhoAbsolutoDiretorioEdi + ').');
        $podeMandarVer = $false;
    }
    
    if (!(ValidaDiretorio $caminhoAbsolutoDiretorioEdiEnviados)) {
        MostraLog $caminhoAbsolutoArquivoLog ('caminhoAbsolutoDiretorioEdiEnviados invalido (' + $caminhoAbsolutoDiretorioEdiEnviados + ').');
        $podeMandarVer = $false;
    }
    
    if (!(ValidaDiretorio $caminhoAbsolutoArquivo7zip)) {
        MostraLog $caminhoAbsolutoArquivoLog ('caminhoAbsolutoArquivo7zip invalido (' + $caminhoAbsolutoArquivo7zip + ').');
        $podeMandarVer = $false;
    }
    
    if (!$podeMandarVer) {
        return;
    }

    $quantidadeCnab = ProcuraArquivos $caminhoAbsolutoDiretorioCnab $caminhoAbsolutoDiretorioCnabEnviados $patternCnab $arquivoCnabCompactado;

    if ($quantidadeCnab -gt 0) {
        $caminhoAbsolutoDiretorioCargaEmperrada = $caminhoAbsolutoDiretorioCarga + 'waitingToProcess';
        $quantidadeEmperrado = ProcuraArquivos $caminhoAbsolutoDiretorioCargaEmperrada $caminhoAbsolutoDiretorioCarga '*.*' $false;
    }

    $quantidadeRetorno = ProcuraArquivos $caminhoAbsolutoDiretorioRetorno $caminhoAbsolutoDiretorioRetornoEnviados $patternRetorno $arquivoRetornoCompactado;

    $quantidadeEdi = ProcuraArquivos $caminhoAbsolutoDiretorioEdi $caminhoAbsolutoDiretorioEdiEnviados $patternEdi $arquivoEdiCompactado;

    if ($quantidadeCnab -gt 0) {
        MostraLog $caminhoAbsolutoArquivoLog ($quantidadeCnab + ' ARQUIVOS TIPO "CNAB" DISPONIBILIZADOS');
    }
    if ($quantidadeEmperrado -gt 0) {
        MostraLog $caminhoAbsolutoArquivoLog ($quantidadeEmperrado + ' ARQUIVOS "BLOQUEADOS" RE-DISPONIBILIZADOS');
    }
    if ($quantidadeRetorno -gt 0) {
        MostraLog $caminhoAbsolutoArquivoLog ($quantidadeRetorno + ' ARQUIVOS TIPO "RETORNO" DISPONIBILIZADOS');
    }
    if ($quantidadeEdi -gt 0) {
        MostraLog $caminhoAbsolutoArquivoLog ($quantidadeEdi + ' ARQUIVOS TIPO "EDI" DISPONIBILIZADOS');
    }

    Principal;
}

Principal;