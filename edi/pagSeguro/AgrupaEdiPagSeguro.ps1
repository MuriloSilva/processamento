Using Module '..\..\.\Util.psm1'
Using Module 'model\.\EdiPagSeguroClass.psm1';
Using Module 'model\.\IdentificadorEdiPagSeguroClass.psm1';


function GeraArquivoUnico {
    param (
        [string]$idQueVaiNoHeader,
        $csvEmpresa,
        [IdentificadorEdiPagSeguro]$indentificadorEdiPagSeguro,
        $ediPagSeguroCollection
    )

    MostraLog '' ('iniciando geracao: ' + $indentificadorEdiPagSeguro.getTipo() + ' ' + $indentificadorEdiPagSeguro.getDataReferencia().ToString('yyyy-MM-dd') + ' ' + $indentificadorEdiPagSeguro.getDataGeracao().ToString('yyyy-MM-dd') + ' ' + $indentificadorEdiPagSeguro.getVersao() + ' ' + $indentificadorEdiPagSeguro.getEspecificacao());

    if ($ediPagSeguroCollection.Count -eq  $csvEmpresa.Count) {
        $caminhoAbsolutoEdiPagSeguroUnico = $caminhoAbsolutoDiretorioSaida;

        $quantidadeLinhas = 0;

        foreach ($ediPagSeguro in $ediPagSeguroCollection.Where({$_.id -eq $idQueVaiNoHeader})) {
            if ($caminhoAbsolutoEdiPagSeguroUnico -eq $caminhoAbsolutoDiretorioSaida) {
                $caminhoAbsolutoEdiPagSeguroUnico += $ediPagSeguro.getNomeNormalizado();
            }

            foreach ($linha in Get-Content $ediPagSeguro.getCaminhoAbsoluto()) {
                if (!($linha -match '^9.*$')) {
                    $quantidadeLinhas += 1
                    Add-content $caminhoAbsolutoEdiPagSeguroUnico -value $linha;
                }
            }

            Move-Item -Path $ediPagSeguro.getCaminhoAbsoluto() -Destination $caminhoAbsolutoDiretorioProcessado -Force;
        }

        foreach ($ediPagSeguro in $ediPagSeguroCollection.Where({!($_.id -eq $idQueVaiNoHeader)})) {
            foreach ($linha in Get-Content $ediPagSeguro.getCaminhoAbsoluto()) {
                if (!($linha -match '^[0,9]{1}.*$')) {
                    $quantidadeLinhas += 1;
                    Add-content $caminhoAbsolutoEdiPagSeguroUnico -value $linha;
                }
            }
            Move-Item -Path $ediPagSeguro.getCaminhoAbsoluto() -Destination $caminhoAbsolutoDiretorioProcessado -Force;
        }

        if ($quantidadeLinhas -gt 0) {
            $linha = '9' + $quantidadeLinhas.ToString().PadLeft(11,'0');
            if ($indentificadorEdiPagSeguro.versao = '00105') {
                $linha = $linha.PadRight(44,' ');
            } else {
                $linha = $linha.PadRight(530,' ');
            }
            Add-content $caminhoAbsolutoEdiPagSeguroUnico -value $linha;
            MostraLog $caminhoAbsolutoArquivoLog ('arquivo gerado: ' + $caminhoAbsolutoEdiPagSeguroUnico);
        }

    } else {
        MostraLog $caminhoAbsolutoArquivoLog ('quantidades divergentes! CSV:' + $csvEmpresa.Count + ' EDI:' + $ediPagSeguroCollection.Count);
    }
}
function PegaArquivo {
    param (
        $csvEmpresa
    )

    $idQueVaiNoHeader = [long]::MaxValue;
    foreach ($csvEmpresaItem in $csvEmpresa) {
        if ($idQueVaiNoHeader -ge [long]$csvEmpresaItem.idPagSeguro) {
            $idQueVaiNoHeader = [long]$csvEmpresaItem.idPagSeguro;
        }
    }

    MostraLog $caminhoAbsolutoArquivoLog ('identificando arquivos...');

    $diretorioEnvio = Get-Item -Path ($caminhoAbsolutoDiretorioOrigem);

    $ediPagSeguroCollection = @();
    $indentificadorEdiPagSeguroCollection = @();

    ForEach-Object -InputObject $diretorioEnvio.GetFiles('PAGS*.*') {
        foreach ($arquivo in $_) {
            $ediPagSeguro = [EdiPagSeguro]::New($arquivo.FullName);

            if (!$ediPagSeguro.getNomeNormalizado() -eq '' -And ($csvEmpresa.idPagSeguro -contains $ediPagSeguro.getId())) {
                $ediPagSeguroCollection += $ediPagSeguro;
                $indentificadorEdiPagSeguro = [IdentificadorEdiPagSeguro]::New($ediPagSeguro);
                if (!($indentificadorEdiPagSeguroCollection.Where({$_.tipo -eq $indentificadorEdiPagSeguro.getTipo() -and $_.dataReferencia -eq $indentificadorEdiPagSeguro.getDataReferencia() -and $_.dataGeracao -eq $indentificadorEdiPagSeguro.getDataGeracao() -and $_.versao -eq $indentificadorEdiPagSeguro.getVersao() -and $_.especificacao -eq $indentificadorEdiPagSeguro.getEspecificacao()}))) {
                    $indentificadorEdiPagSeguroCollection += $indentificadorEdiPagSeguro;
                }
            }
        }
    }

    MostraLog $caminhoAbsolutoArquivoLog ($indentificadorEdiPagSeguroCollection.Count.ToString() + ' arquivos identificados...');
    
    foreach ($indentificadorEdiPagSeguro in $indentificadorEdiPagSeguroCollection) {
        GeraArquivoUnico $idQueVaiNoHeader $csvEmpresa $indentificadorEdiPagSeguro $ediPagSeguroCollection.Where({$_.tipo -eq $indentificadorEdiPagSeguro.getTipo() -and $_.dataReferencia -eq $indentificadorEdiPagSeguro.getDataReferencia() -and $_.dataGeracao -eq $indentificadorEdiPagSeguro.getDataGeracao() -and $_.versao -eq $indentificadorEdiPagSeguro.getVersao() -and $_.especificacao -eq $indentificadorEdiPagSeguro.getEspecificacao()});
    }
}
function Principal {
    Set-Variable -Name jsonProperties -Value (PegaProperties $MyInvocation.ScriptName) -Option Constant;
    if ($null -eq $jsonProperties) {
        MostraLog '' 'Arquivo ".properties" nao localizado.';
        return;
    }

    #Limpa conteúdo das variáveis de configuração (Prenchidas lendo arquivo .properties)
    Remove-Variable -Name 'caminhoAbsolutoArquivoLog' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'caminhoAbsolutoDiretorioOrigem' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'caminhoAbsolutoDiretorioSaida' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'caminhoAbsolutoDiretorioProcessado' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'caminhoAbsolutoArquivoCsvEmpresa' -Force -ErrorAction 'SilentlyContinue';

    #Preenche variáveis de configuração (Prenchidas lendo arquivo .properties)
    $caminhoAbsolutoArquivoLogTemp = BuscaValorParametro $jsonProperties 'caminhoAbsolutoDiretorioLog';
    if (Test-Path $caminhoAbsolutoArquivoLogTemp) {
        $caminhoAbsolutoArquivoLogTemp += ((Get-Item -Path $MyInvocation.ScriptName | ForEach-Object {$_.Name}) -replace '.ps1','') + '_log_';
        $caminhoAbsolutoArquivoLogTemp += Get-Date | ForEach-Object {$_.ToString('yyyyMMddmmssfff')};
        $caminhoAbsolutoArquivoLogTemp += '.txt'
    }
    Set-Variable -Name 'caminhoAbsolutoArquivoLog' -Value $caminhoAbsolutoArquivoLogTemp -Option ReadOnly;
    Remove-Variable -Name 'caminhoAbsolutoArquivoLogTemp' -Force;

    Set-Variable -Name 'caminhoAbsolutoDiretorioOrigem' -Value (BuscaValorParametro $jsonProperties 'caminhoAbsolutoDiretorioOrigem') -Option ReadOnly;
    Set-Variable -Name 'caminhoAbsolutoDiretorioSaida' -Value (BuscaValorParametro $jsonProperties 'caminhoAbsolutoDiretorioSaida') -Option ReadOnly;
    Set-Variable -Name 'caminhoAbsolutoDiretorioProcessado' -Value (BuscaValorParametro $jsonProperties 'caminhoAbsolutoDiretorioProcessado') -Option ReadOnly;
    Set-Variable -Name 'caminhoAbsolutoArquivoCsvEmpresa' -Value (BuscaValorParametro $jsonProperties 'caminhoAbsolutoArquivoCsvEmpresa') -Option ReadOnly;

    #Vai começar a festa! \o/
    $podeMandarVer = $true;

    if (!(Test-Path -Path ($caminhoAbsolutoDiretorioOrigem))) {
        MostraLog $caminhoAbsolutoArquivoLog ('$caminhoAbsolutoDiretorioEnvio invalido (' + $caminhoAbsolutoDiretorioOrigem + ').');
        $podeMandarVer = $false;
    }

    if (!(Test-Path -Path ($caminhoAbsolutoDiretorioSaida))) {
        MostraLog $caminhoAbsolutoArquivoLog ('$caminhoAbsolutoDiretorioEnvio invalido (' + $caminhoAbsolutoDiretorioSaida + ').');
        $podeMandarVer = $false;
    }

    if (!(Test-Path -Path ($caminhoAbsolutoDiretorioProcessado))) {
        MostraLog $caminhoAbsolutoArquivoLog ('$caminhoAbsolutoDiretorioEnviados invalido (' + $caminhoAbsolutoDiretorioProcessado + ').');
        $podeMandarVer = $false;
    }

    if (!(Test-Path -Path ($caminhoAbsolutoArquivoCsvEmpresa))) {
        MostraLog $caminhoAbsolutoArquivoLog ('$caminhoAbsolutoDiretorioDestino invalido (' + $caminhoAbsolutoArquivoCsvEmpresa + ').');
        $podeMandarVer = $false;
    }

    if (!$podeMandarVer) {
        return
    }
    
    try {
        $csvEmpresa = Import-Csv -Path $caminhoAbsolutoArquivoCsvEmpresa -Header codigoEmpresa,idPagSeguro,statusProcessamento,mensagemProcessamento,nomeEmpresa,sequenciaProcessamento | Sort-Object -Property codigoEmpresa;
    } catch [Exception] {
        MostraLog $caminhoAbsolutoArquivoLog ('ERRO: ' + $_.Exception.Message);
        return
    }

    $codigoEmpresa = '';
    $csvEmpresaTrabalhar = @();
    foreach ($csvEmpresaItem in $csvEmpresa) {
        if (!($codigoEmpresa -eq $csvEmpresaItem.codigoEmpresa)) {
            if (!($codigoEmpresa -eq '')) {
                PegaArquivo $csvEmpresaTrabalhar;
                $csvEmpresaTrabalhar.Clear();
            }
            $codigoEmpresa = $csvEmpresaItem.codigoEmpresa;
        }
        $csvEmpresaTrabalhar += $csvEmpresaItem
    }

    if ($csvEmpresaTrabalhar.Count -gt 0) {
        PegaArquivo $csvEmpresaTrabalhar;
    }
}

Principal;