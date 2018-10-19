Using Module '..\..\.\Util.psm1'
Using Module 'model\.\EdiPagSeguroClass.psm1';

param (
    [string] $caminhoAbsolutoDiretorio
)

Function Principal {
    try {
        $diretorioOrigem = Get-Item -Path $caminhoAbsolutoDiretorio;
    } catch [Exception] {
        MostraLog '' ('ERRO: ' + $_.Exception.Message);
        MostraLog '' ('$.caminhoAbsolutoDiretorio invalido (' + $caminhoAbsolutoDiretorio + ').');
        return;
    }

    $caminhoAbsolutoArquivoLog = $caminhoAbsolutoDiretorio + '\Log\'
    if (Test-Path $caminhoAbsolutoArquivoLog) {
        $caminhoAbsolutoArquivoLog += ((Get-Item -Path $MyInvocation.ScriptName | ForEach-Object {$_.Name}) -replace '.ps1','') + '_log_';
        $caminhoAbsolutoArquivoLog += Get-Date | ForEach-Object {$_.ToString('yyyyMMdd')};
        $caminhoAbsolutoArquivoLog += '.txt'
    }

    ForEach-Object -InputObject $diretorioOrigem.GetFiles('PAGS*.*') {
        foreach ($arquivoEdi in $_) {
            $ediPagSeguro = [EdiPagSeguro]::New($arquivoEdi.FullName);
            
            if ($ediPagSeguro.getNomeNormalizado() -eq '') {
                MostraLog $caminhoAbsolutoArquivoLog ($arquivoEdi.FullName + ' = NAO E EDI PAGSEGURO.');
            } else {
                $caminhoAbsolutoArquivoRenomeado = $arquivoEdi.DirectoryName + '\' + $ediPagSeguro.getNomeNormalizado();
                $renomeou = $true;
                try {
                    Rename-Item -Path $arquivoEdi.FullName -NewName $caminhoAbsolutoArquivoRenomeado;
                } catch [System.Exception] {
                    $renomeou = $false;
                    MostraLog $caminhoAbsolutoArquivoLog ($arquivoEdi.FullName + ' = ERRO: ' + $_.Exception.Message);
                }
            }

            if ($renomeou) {
                MostraLog $caminhoAbsolutoArquivoLog ($arquivoEdi.FullName + ' = ' + $caminhoAbsolutoArquivoRenomeado);
            }
        }
    }
}

Principal;