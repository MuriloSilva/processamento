Using Module '..\..\.\Util.psm1'
Using Module '..\..\edi\pagseguro\model\.\EdiPagSeguroClass.psm1';

function ExecutaPrograma {
    param (
        $processFile,
        $processArgs
    )
    Push-Location -Path $caminhoAbsolutoDiretorioExecucao;

    $date = Get-Date;

    $caminhoAbsolutoArquivoLogStdOut = $caminhoAbsolutoArquivoLog + '.' + $date.ToString('yyyyMMddHHmmssfff') + '.stdout.txt';
    $caminhoAbsolutoArquivoLogStdErr = $caminhoAbsolutoArquivoLog + '.' + $date.ToString('yyyyMMddHHmmssfff') + '.stderr.txt';

    Start-Process -File $processFile -ArgumentList $processArgs -RedirectStandardOutput $caminhoAbsolutoArquivoLogStdOut -RedirectStandardError $caminhoAbsolutoArquivoLogStdErr -Wait -NoNewWindow;

    foreach ($linha in Get-Content $caminhoAbsolutoArquivoLogStdOut) {MostraLog $caminhoAbsolutoArquivoLog $linha $true};
    foreach ($linha in Get-Content $caminhoAbsolutoArquivoLogStdErr) {MostraLog $caminhoAbsolutoArquivoLog $linha $true};

    Remove-Item -Path $caminhoAbsolutoArquivoLogStdOut -Force;
    Remove-Item -Path $caminhoAbsolutoArquivoLogStdErr -Force;

    Pop-Location;
}

function EnviaArquivo {
    param (
        [EdiPagSeguro] $ediPagSeguro,
        $diretorioEnviados,
        $empresa_id
    )

    $caminhoAbsolutoArquivoDestinoEmTransferencia = $diretorioDestino.FullName + 'TRANSF_' + $ediPagSeguro.getNomeNormalizado();
    $caminhoAbsolutoArquivoDestinoFinal = $diretorioDestino.FullName + $ediPagSeguro.getNomeNormalizado();
    $caminhoAbsolutoArquivoEnviados = $diretorioEnviados.FullName + $ediPagSeguro.getNomeNormalizado();

    $textoLog = 'Arquivo: ' + $ediPagSeguro.getCaminhoAbsoluto() + ' -> ';

    Copy-Item -Path $ediPagSeguro.getCaminhoAbsoluto() -Destination $caminhoAbsolutoArquivoDestinoEmTransferencia -Force | Out-Null;
    if (ValidaDiretorio $caminhoAbsolutoArquivoDestinoEmTransferencia) {
        Rename-Item -Path $caminhoAbsolutoArquivoDestinoEmTransferencia -NewName $caminhoAbsolutoArquivoDestinoFinal | Out-Null;
        if (ValidaDiretorio $caminhoAbsolutoArquivoDestinoFinal) {

            MostraLog $caminhoAbsolutoArquivoLog ($textoLog + $caminhoAbsolutoArquivoDestinoFinal);

            $programaJreArgs = @();

            $programaJreArgs += $parametrosJre;
            $programaJreArgs += $programaJre;
            $programaJreArgs += $empresa_id;
            $programaJreArgs += $caminhoAbsolutoArquivoDestinoFinal;

            ExecutaPrograma $caminhoAbsolutoArquivoJre $programaJreArgs;

            Move-Item -Path $ediPagSeguro.getCaminhoAbsoluto() -Destination $caminhoAbsolutoArquivoEnviados -Force | Out-Null;
            if (!(ValidaDiretorio $caminhoAbsolutoArquivoEnviados)) {
                MostraLog $caminhoAbsolutoArquivoLog ($textoLog + 'ENTREGUE ... ERRO AO MOVER PARA ENVIADOS.');
            }
        } else {
            MostraLog $caminhoAbsolutoArquivoLog ($textoLog + 'ERRO AO RETIRAR "TRANSF" DO ARQUIVO.');
        }
    } else {
        MostraLog $caminhoAbsolutoArquivoLog ($textoLog + 'ERRO AO COPIAR ARQUIVO PARA CAMINHO DESTINO.');
    }
}

function PegaArquivos {
    param (
        [string]$caminhoAbsolutoDiretorioBusca,
        [string]$caminhoAbsolutoDiretorioEnviados,
        [string]$empresa_id,
        [string]$padraoNomeArquivo
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
                EnviaArquivo $ediPagSeguro (Get-Item $caminhoAbsolutoDiretorioEnviados) $empresa_id;
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
    Remove-Variable -Name 'caminhoAbsolutoDiretorioExecucao' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'caminhoAbsolutoArquivoJre' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'parametrosJre' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'programaJre' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'caminhoAbsolutoDiretorioDestino' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'diretorioDestino' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'diretoriosBusca' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'diretoriosEnviados' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'scriptIdEmpresas' -Force -ErrorAction 'SilentlyContinue';
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

    Set-Variable -Name 'caminhoAbsolutoDiretorioExecucao' -Value (BuscaValorParametro $jsonProperties 'caminhoAbsolutoDiretorioExecucao') -Option ReadOnly;
    Set-Variable -Name 'caminhoAbsolutoArquivoJre' -Value (BuscaValorParametro $jsonProperties 'caminhoAbsolutoArquivoJre') -Option ReadOnly;
    Set-Variable -Name 'parametrosJre' -Value (BuscaValorParametro $jsonProperties 'parametrosJre') -Option ReadOnly;
    Set-Variable -Name 'programaJre' -Value (BuscaValorParametro $jsonProperties 'programaJre') -Option ReadOnly;
    Set-Variable -Name 'caminhoAbsolutoDiretorioDestino' -Value (BuscaValorParametro $jsonProperties 'caminhoAbsolutoDiretorioDestino') -Option ReadOnly;
    Set-Variable -Name 'diretoriosBusca' -Value (BuscaValorParametro $jsonProperties 'diretoriosBusca') -Option ReadOnly;
    Set-Variable -Name 'diretoriosEnviados' -Value (BuscaValorParametro $jsonProperties 'diretoriosEnviados') -Option ReadOnly;
    Set-Variable -Name 'scriptIdEmpresas' -Value (BuscaValorParametro $jsonProperties 'scriptIdEmpresas') -Option ReadOnly;
    Set-Variable -Name 'sqlServer' -Value (BuscaValorParametro $jsonProperties 'sqlServer') -Option ReadOnly;
    Set-Variable -Name 'sqlDatabase' -Value (BuscaValorParametro $jsonProperties 'sqlDatabase') -Option ReadOnly;
    Set-Variable -Name 'sqlUsername' -Value (BuscaValorParametro $jsonProperties 'sqlUsername') -Option ReadOnly;
    Set-Variable -Name 'sqlPassword' -Value (BuscaValorParametro $jsonProperties 'sqlPassword') -Option ReadOnly;

    #Vai começar a festa! \o/
    $podeMandarVer = $true;

    if (ValidaDiretorio $caminhoAbsolutoDiretorioDestino) {
        Set-Variable -Name 'diretorioDestino' -Value (Get-Item -Path $caminhoAbsolutoDiretorioDestino) -Option ReadOnly;
    } else {
        MostraLog $caminhoAbsolutoArquivoLog ('caminhoAbsolutoDiretorioDestino invalido (' + $caminhoAbsolutoDiretorioDestino + ').');
        $podeMandarVer = $false;
    }
    
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

    $dataRowResults = ExecutaComandoSql $sqlServer $sqlDatabase $sqlUsername $sqlPassword $scriptIdEmpresas;

    if ($null -eq $dataRowResults) {
        MostraLog $caminhoAbsolutoArquivoLog ('$null -eq $dataRowResults');
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

            PegaArquivos $diretorioBusca $diretorioEnviados $jsonResult.empresa_id ('PAGS*_' + $jsonResult.cliente_id + '_*.txt');

            $posicao += 1;
        }

    }

    Principal;
}

Principal;