Using Module '..\.\Util.psm1'
Using Module '..\edi\pagseguro\model\.\EdiPagSeguroClass.psm1';

function EnviaArquivo {
    param (
        [EdiPagSeguro] $ediPagSeguro,
        $diretorioEnviados
    )

    $caminhoAbsolutoArquivoDestinoEmTransferencia = $diretorioDestino.FullName + 'TRANSF_' + $ediPagSeguro.getNomeNormalizado();
    $caminhoAbsolutoArquivoDestinoFinal = $diretorioDestino.FullName + $ediPagSeguro.getNomeNormalizado();
    $caminhoAbsolutoArquivoEnviados = $diretorioEnviados.FullName + $ediPagSeguro.getNomeNormalizado();

    if ($jsonDisponibilizacaoSftpRendimento.envioSftpRendimento -eq 'true') {
        if ($jsonDisponibilizacaoSftpRendimento.ids -contains $ediPagSeguro.getId()) {
            $caminhoAbsolutoDiretorioSftpRendimento = $jsonDisponibilizacaoSftpRendimento.caminhoAbsolutoDiretorioSftpRendimento + $ediPagSeguro.getId();

            if (!(ValidaDiretorio $caminhoAbsolutoDiretorioSftpRendimento)) {
                New-Item -Path $caminhoAbsolutoDiretorioSftpRendimento | Out-Null;
            }

            $caminhoAbsolutoArquivoRendimento = $jsonDisponibilizacaoSftpRendimento.caminhoAbsolutoDiretorioSftpRendimento + $ediPagSeguro.getId() + '\' + $ediPagSeguro.getNomeNormalizado();

            Copy-Item -Path $ediPagSeguro.getCaminhoAbsoluto() -Destination $caminhoAbsolutoArquivoRendimento -Force | Out-Null;
            if (!(ValidaDiretorio $caminhoAbsolutoArquivoRendimento)) {
                MostraLog $caminhoAbsolutoArquivoLog ('ERRO NA COPIA SFTP RENDIMENTO... ' + $caminhoAbsolutoArquivoRendimento);
            }
        }
    }

    Copy-Item -Path $ediPagSeguro.getCaminhoAbsoluto() -Destination $caminhoAbsolutoArquivoDestinoEmTransferencia -Force | Out-Null;
    if (ValidaDiretorio $caminhoAbsolutoArquivoDestinoEmTransferencia) {
        Rename-Item -Path $caminhoAbsolutoArquivoDestinoEmTransferencia -NewName $caminhoAbsolutoArquivoDestinoFinal | Out-Null;
        if (ValidaDiretorio $caminhoAbsolutoArquivoDestinoFinal) {
            Move-Item -Path $ediPagSeguro.getCaminhoAbsoluto() -Destination $caminhoAbsolutoArquivoEnviados -Force | Out-Null;
            if (ValidaDiretorio $caminhoAbsolutoArquivoEnviados) {
                return 'ENTREGUE (' + $caminhoAbsolutoArquivoDestinoFinal + ').';
            } else {
                return 'ENTREGUE ... ERRO AO MOVER PARA ENVIADOS.';
            }
        } else {
            return 'ERRO AO RETIRAR "TRANSF" DO ARQUIVO.';
        }
    } else {
        return 'ERRO AO COPIAR ARQUIVO PARA CAMINHO DESTINO.';
    }
}

function PegaArquivos {
    param (
        [string] $caminhoAbsolutoDiretorioBusca,
        [string] $caminhoAbsolutoDiretorioEnviados,
        $padraoNomeArquivo
    )

    if (!(ValidaDiretorio $caminhoAbsolutoDiretorioBusca)) {
        MostraLog $caminhoAbsolutoArquivoLog ('$.caminhoAbsolutoDiretorioBusca invalido (' + $caminhoAbsolutoDiretorioBusca + ').');
        return;
    } else {
        $diretorioBusca = Get-Item $caminhoAbsolutoDiretorioBusca;
    }

    if (!(ValidaDiretorio $caminhoAbsolutoDiretorioEnviados)) {
        MostraLog $caminhoAbsolutoArquivoLog ('$.caminhoAbsolutoDiretorioEnviados invalido (' + $caminhoAbsolutoDiretorioEnviados + ').');
        return;
    }

    ForEach-Object -InputObject $diretorioBusca.GetFiles($padraoNomeArquivo) {
        foreach ($arquivo in $_) {
            $ediPagSeguro = [EdiPagSeguro]::New($arquivo.FullName);

            if (!($ediPagSeguro.getNomeNormalizado() -eq '')) {
                $retornoEnviaArquivo = (EnviaArquivo $ediPagSeguro (Get-Item $caminhoAbsolutoDiretorioEnviados));
                MostraLog $caminhoAbsolutoArquivoLog ('Arquivo: ' + $ediPagSeguro.getCaminhoAbsoluto() + ' -> ' + $retornoEnviaArquivo);
            }
        }
    }
}

function Principal {
    Set-Variable -Name jsonProperties -Value (PegaProperties $MyInvocation.ScriptName) -Option ReadOnly;
    if ($null -eq $jsonProperties) {
        MostraLog '' 'Arquivo ".properties" nao localizado.';
        return;
    }

    #Limpa conteúdo das variáveis de configuração (Prenchidas lendo arquivo .properties)
    Remove-Variable -Name 'caminhoAbsolutoArquivoLog' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'caminhoAbsolutoDiretorioDestino' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'diretorioDestino' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'diretoriosBusca' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'diretoriosEnviados' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'disponibilizacaoSftpRendimento' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'scriptIdVersaoVan' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'sqlServer' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'sqlDatabase' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'sqlUsername' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'sqlPassword' -Force -ErrorAction 'SilentlyContinue';

    #Preenche variáveis de configuração (Prenchidas lendo arquivo .properties)
    $caminhoAbsolutoArquivoLogTemp = BuscaValorParametro $jsonProperties 'caminhoAbsolutoDiretorioLog';
    if (Test-Path $caminhoAbsolutoArquivoLogTemp) {
        $caminhoAbsolutoArquivoLogTemp += ((Get-Item -Path $MyInvocation.ScriptName | ForEach-Object {$_.Name}) -replace '.ps1','') + '_log_';
        $caminhoAbsolutoArquivoLogTemp += Get-Date | ForEach-Object {$_.ToString('yyyyMMdd')};
        $caminhoAbsolutoArquivoLogTemp += '.txt'
    }
    Set-Variable -Name 'caminhoAbsolutoArquivoLog' -Value $caminhoAbsolutoArquivoLogTemp -Option ReadOnly;
    Remove-Variable -Name 'caminhoAbsolutoArquivoLogTemp' -Force;

    Set-Variable -Name 'caminhoAbsolutoDiretorioDestino' -Value (BuscaValorParametro $jsonProperties 'caminhoAbsolutoDiretorioDestino') -Option ReadOnly;
    Set-Variable -Name 'diretoriosBusca' -Value (BuscaValorParametro $jsonProperties 'diretoriosBusca') -Option ReadOnly;
    Set-Variable -Name 'diretoriosEnviados' -Value (BuscaValorParametro $jsonProperties 'diretoriosEnviados') -Option ReadOnly;
    Set-Variable -Name 'disponibilizacaoSftpRendimento' -Value (BuscaValorParametro $jsonProperties 'disponibilizacaoSftpRendimento') -Option ReadOnly;
    Set-Variable -Name 'scriptIdVersaoVan' -Value (BuscaValorParametro $jsonProperties 'scriptIdVersaoVan') -Option ReadOnly;
    Set-Variable -Name 'sqlServer' -Value (BuscaValorParametro $jsonProperties 'sqlServer') -Option ReadOnly;
    Set-Variable -Name 'sqlDatabase' -Value (BuscaValorParametro $jsonProperties 'sqlDatabase') -Option ReadOnly;
    Set-Variable -Name 'sqlUsername' -Value (BuscaValorParametro $jsonProperties 'sqlUsername') -Option ReadOnly;
    Set-Variable -Name 'sqlPassword' -Value (BuscaValorParametro $jsonProperties 'sqlPassword') -Option ReadOnly;

    #Vai começar a festa! \o/
    $podeMandarVer = $true;

    try {
        $jsonDiretoriosBusca = ConvertFrom-Json -InputObject $diretoriosBusca;
    } catch [Exception] {
        MostraLog $caminhoAbsolutoArquivoLog ('diretoriosBusca: ' + $_.Exception.GetType().FullName + ' - ' + $_.Exception.Message);
        $podeMandarVer = $false;
    }
    try {
        $jsonDiretoriosEnviados = ConvertFrom-Json -InputObject $diretoriosEnviados
    } catch [Exception] {
        MostraLog $caminhoAbsolutoArquivoLog ('diretoriosEnviados: ' + $_.Exception.GetType().FullName + ' - ' + $_.Exception.Message);
        $podeMandarVer = $false;
    }

    if ($podeMandarVer -and !($jsonDiretoriosBusca.Count -eq $jsonDiretoriosEnviados.Count)) {
        MostraLog $caminhoAbsolutoArquivoLog ('quantidade de diretorios divergentes: diretoriosBusca ' + $jsonDiretoriosBusca.Count + ' diretoriosEnviados ' + $jsonDiretoriosEnviados.Count);
        $podeMandarVer = $false;
    }

    if (ValidaDiretorio $caminhoAbsolutoDiretorioDestino) {
        Set-Variable -Name 'diretorioDestino' -Value (Get-Item -Path $caminhoAbsolutoDiretorioDestino) -Option ReadOnly;
    } else {
        MostraLog $caminhoAbsolutoArquivoLog ('caminhoAbsolutoDiretorioDestino invalido (' + $caminhoAbsolutoDiretorioDestino + ').');
        $podeMandarVer = $false;
    }

    foreach ($diretorioBusca in $jsonDiretoriosBusca.diretorio) {
        if (!(ValidaDiretorio $diretorioBusca)) {
            MostraLog $caminhoAbsolutoArquivoLog ('diretorioBusca invalido (' + $diretorioBusca + ').');
            $podeMandarVer = $false;
        }
    }

    foreach ($diretorioEnviados in $jsonDiretoriosEnviados.diretorio) {
        if (!(ValidaDiretorio $diretorioEnviados)) {
            MostraLog $caminhoAbsolutoArquivoLog ('diretorioEnviados invalido (' + $diretorioEnviados + ').');
            $podeMandarVer = $false;
        }
    }

    try {
        $jsonDisponibilizacaoSftpRendimento = ConvertFrom-Json -InputObject $disponibilizacaoSftpRendimento
    } catch [Exception] {
        MostraLog $caminhoAbsolutoArquivoLog ('disponibilizacaoSftpRendimento: ' + $_.Exception.GetType().FullName + ' - ' + $_.Exception.Message);
        $podeMandarVer = $false;
    }

    $dataRowResults = ExecutaComandoSql $sqlServer $sqlDatabase $sqlUsername $sqlPassword $scriptIdVersaoVan;

    if ($null -eq $dataRowResults) {
        MostraLog $caminhoAbsolutoArquivoLog ('');
        $podeMandarVer = $false;
    } else {
        $jsonResults = $dataRowResults | Select-Object * -ExcludeProperty ItemArray, Table, RowError, RowState, HasErrors | ConvertTo-Json | ConvertFrom-Json;
    }

    if (!$podeMandarVer) {
        return
    }

    foreach ($jsonResult in $jsonResults) {
        $posicao = 0;
        foreach ($diretorioBusca in $jsonDiretoriosBusca.diretorio) {
            $diretorioEnviados = $jsonDiretoriosEnviados.diretorio[$posicao];
    
            PegaArquivos $diretorioBusca $diretorioEnviados ('PAGS*_' + $jsonResult.cliente_id + '_*.txt');

            $posicao += 1;
        }

    }



    Principal;
}

Principal;