Using Module '..\.\Util.psm1';

function PegaArquivoMaisRecente {
    param (
        [string] $caminhoAbsolutoDiretorio,
        [string] $pattern
    )
    try {Test-Path -Path ($caminhoAbsolutoDiretorio)} catch {
        return $null;
    }

    return Get-ChildItem -Path $caminhoAbsolutoDiretorio -Filter $pattern | Sort-Object -Property LastWriteTime | Select-Object -Last 1;
}

function CriaRelatorio {
    param (
        $arquivoCnabMaisRecente,
        $arquivoRetornoMaisRecente,
        $arquivoEdiMaisRecente
    )
    $sucesso = $true;
    $hoje = Get-Date;

    MostraLog $caminhoAbsolutoArquivoLog ('$arquivoCnabMaisRecente = ' + $arquivoCnabMaisRecente.FullName);
    MostraLog $caminhoAbsolutoArquivoLog ('$arquivoRetornoMaisRecente = ' + $arquivoRetornoMaisRecente.FullName);
    MostraLog $caminhoAbsolutoArquivoLog ('$arquivoEdiMaisRecente = ' + $arquivoEdiMaisRecente.FullName);

    $arquivosPendentes = @();

    if (!($null -eq $arquivoCnabMaisRecente)) {
        if ((Get-Date $arquivoCnabMaisRecente.LastWriteTime.ToString('yyyy-MM-dd')) -lt (Get-Date $hoje.ToString('yyyy-MM-dd'))) {
            $sucesso = $false;
            $arquivosPendentes += '- CNAB';
        }
    }
    if (!($null -eq $arquivoRetornoMaisRecente)) {
        if ((Get-Date $arquivoRetornoMaisRecente.LastWriteTime.ToString('yyyy-MM-dd')) -lt (Get-Date $hoje.ToString('yyyy-MM-dd'))) {
            $sucesso = $false;
            $arquivosPendentes += '- RETORNO';
        }
    }
    if (!($null -eq $arquivoEdiMaisRecente)) {
        if ((Get-Date $arquivoEdiMaisRecente.LastWriteTime.ToString('yyyy-MM-dd')) -lt (Get-Date $hoje.ToString('yyyy-MM-dd'))) {
            $sucesso = $false;
            $arquivosPendentes += '- EDI';
        }
    }

    $relatorio = @();
    $relatorio += '------------------------------------------------------------------------------';
    $texto = 'STATUS PROCESSAMENTO FIDC: ';
    $texto += if ($sucesso) {'SUCESSO'} ELSE {'FALHA'};

    $emailSubject = $texto
    $emailSubject += ' - '
    $emailSubject +=  Get-Date | ForEach-Object $_ {$_.ToString('yyyy-MM-dd HH:mm')};

    $relatorio += $texto;
    $relatorio += '------------------------------------------------------------------------------';
    $relatorio += '';
    if (!$sucesso) {
        $relatorio += 'ARQUIVOS PENDENTES DE RECEBIMENTO:';
        foreach ($texto in $arquivosPendentes) {
            $relatorio += $texto;
        }
        $relatorio += '';
        $relatorio += '------------------------------------------------------------------------------';
        $relatorio += '';
    }
    $relatorio += 'ULTIMOS ARQUIVOS RECEBIDOS:';
    $relatorio += '';
    $relatorio += 'TIPO: CNAB';
    if (!($null -eq $arquivoCnabMaisRecente)) {
        $relatorio += ('NOME: ' + $arquivoCnabMaisRecente.Name);
        $relatorio += ('DATA: ' + $arquivoCnabMaisRecente.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss.fff'));
    } else {
        $relatorio += 'NOME: (nenhum)';
        $relatorio += 'DATA: (nenhum)';
    }
    $relatorio += '';
    if (!($null -eq $arquivoRetornoMaisRecente)) {
        $relatorio += 'TIPO: RETORNO';
        $relatorio += ('NOME: ' + $arquivoRetornoMaisRecente.Name);
        $relatorio += ('DATA: ' + $arquivoRetornoMaisRecente.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss.fff'));
    } else {
        $relatorio += 'NOME: (nenhum)';
        $relatorio += 'DATA: (nenhum)';
    }
    $relatorio += '';
    if (!($null -eq $arquivoEdiMaisRecente)) {
        $relatorio += 'TIPO: EDI';
        $relatorio += ('NOME: ' + $arquivoEdiMaisRecente.Name);
        $relatorio += ('DATA: ' + $arquivoEdiMaisRecente.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss.fff'));
    } else {
        $relatorio += 'NOME: (nenhum)';
        $relatorio += 'DATA: (nenhum)';
    }
    $relatorio += '';
    $relatorio += '------------------------------------------------------------------------------';

    $smtpMessage = New-Object System.Net.Mail.MailMessage;
    $smtpMessage.Sender = New-Object System.Net.Mail.MailAddress($emailFromAddress, $emailFromName);
    $smtpMessage.From = New-Object System.Net.Mail.MailAddress($emailFromAddress, $emailFromName);
    $smtpMessage.To.Add($emailTo);
    $smtpMessage.Subject = $emailSubject;

    $smtpMessage.IsBodyHtml = $true;
    foreach ($texto in $relatorio) {
        $smtpMessage.Body += $texto + '<br />';
    }
    if (!($emailCc -eq '')){$smtpMessage.CC.Add($emailCc)};
    if (!($emailBcc -eq '')){$smtpMessage.Bcc.Add($emailBcc)};

    $smtpClient = New-Object Net.Mail.SmtpClient;
    $smtpClient.Host = $smtpServer;
    $smtpClient.Port = $smtpPort;
    if ($smtpSecure -eq 'true') {
        $smtpClient.EnableSsl = $true;
    }
    if (!($smtpUser -eq '') -and !($smtpPassword -eq '')) {
        $smtpClient.Credentials = New-Object System.Net.NetworkCredential($smtpUser, $smtpPassword);
    }

    try {
        $smtpClient.Send($smtpMessage);
    } catch [Exception] {
        MostraLog $caminhoAbsolutoArquivoLog ($_.Exception.GetType().FullName + ' - ' + $_.Exception.Message);
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
    Remove-Variable -Name 'caminhoAbsolutoDiretorioCnabEnviados' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'patternCnab' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'caminhoAbsolutoDiretorioRetornoEnviados' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'patternRetorno' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'caminhoAbsolutoDiretorioEdiEnviados' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'patternEdi' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'smtpServer' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'smtpPort' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'smtpSecure' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'smtpUser' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'smtpPassword' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'emailFromAddress' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'emailFromName' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'emailTo' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'emailCc' -Force -ErrorAction 'SilentlyContinue';
    Remove-Variable -Name 'emailBcc' -Force -ErrorAction 'SilentlyContinue';

    #Preenche variáveis de configuração (Prenchidas lendo arquivo .properties)
    $caminhoAbsolutoArquivoLogTemp = BuscaValorParametro $jsonProperties 'caminhoAbsolutoDiretorioLog';
    if (Test-Path $caminhoAbsolutoArquivoLogTemp) {
        $caminhoAbsolutoArquivoLogTemp += ((Get-Item -Path $MyInvocation.ScriptName | ForEach-Object {$_.Name}) -replace '.ps1','') + '_log_';
        $caminhoAbsolutoArquivoLogTemp += Get-Date | ForEach-Object {$_.ToString('yyyyMMddHHmmssfff')};
        $caminhoAbsolutoArquivoLogTemp += '.txt'
    }
    Set-Variable -Name 'caminhoAbsolutoArquivoLog' -Value $caminhoAbsolutoArquivoLogTemp -Option ReadOnly;
    Remove-Variable -Name 'caminhoAbsolutoArquivoLogTemp' -Force;

    Set-Variable -Name 'caminhoAbsolutoDiretorioCnabEnviados' -Value (BuscaValorParametro $jsonProperties 'caminhoAbsolutoDiretorioCnabEnviados') -Option ReadOnly;
    Set-Variable -Name 'patternCnab' -Value (BuscaValorParametro $jsonProperties 'patternCnab') -Option ReadOnly;
    Set-Variable -Name 'caminhoAbsolutoDiretorioRetornoEnviados' -Value (BuscaValorParametro $jsonProperties 'caminhoAbsolutoDiretorioRetornoEnviados') -Option ReadOnly;
    Set-Variable -Name 'patternRetorno' -Value (BuscaValorParametro $jsonProperties 'patternRetorno') -Option ReadOnly;
    Set-Variable -Name 'caminhoAbsolutoDiretorioEdiEnviados' -Value (BuscaValorParametro $jsonProperties 'caminhoAbsolutoDiretorioEdiEnviados') -Option ReadOnly;
    Set-Variable -Name 'patternEdi' -Value (BuscaValorParametro $jsonProperties 'patternEdi') -Option ReadOnly;

    Set-Variable -Name 'smtpServer' -Value (BuscaValorParametro $jsonProperties 'smtpServer') -Option ReadOnly;
    Set-Variable -Name 'smtpPort' -Value (BuscaValorParametro $jsonProperties 'smtpPort') -Option ReadOnly;
    Set-Variable -Name 'smtpSecure' -Value (BuscaValorParametro $jsonProperties 'smtpSecure') -Option ReadOnly;
    Set-Variable -Name 'smtpUser' -Value (BuscaValorParametro $jsonProperties 'smtpUser') -Option ReadOnly;
    Set-Variable -Name 'smtpPassword' -Value (BuscaValorParametro $jsonProperties 'smtpPassword') -Option ReadOnly;
    Set-Variable -Name 'emailFromAddress' -Value (BuscaValorParametro $jsonProperties 'emailFromAddress') -Option ReadOnly;
    Set-Variable -Name 'emailFromName' -Value (BuscaValorParametro $jsonProperties 'emailFromName') -Option ReadOnly;
    Set-Variable -Name 'emailTo' -Value (BuscaValorParametro $jsonProperties 'emailTo') -Option ReadOnly;
    Set-Variable -Name 'emailCc' -Value (BuscaValorParametro $jsonProperties 'emailCc') -Option ReadOnly;
    Set-Variable -Name 'emailBcc' -Value (BuscaValorParametro $jsonProperties 'emailBcc') -Option ReadOnly;

    #Vai começar a festa! \o/
    $podeMandarVer = $true;

    try {Test-Path -Path ($caminhoAbsolutoDiretorioCnabEnviados)} catch {
        MostraLog $caminhoAbsolutoArquivoLog ('caminhoAbsolutoDiretorioCnabEnviados invalido (' + $caminhoAbsolutoDiretorioCnabEnviados + ').');
        $podeMandarVer = $false;
    }

    try {Test-Path -Path ($caminhoAbsolutoDiretorioRetornoEnviados)} catch {
        MostraLog $caminhoAbsolutoArquivoLog ('caminhoAbsolutoDiretorioRetornoEnviados invalido (' + $caminhoAbsolutoDiretorioRetornoEnviados + ').');
        $podeMandarVer = $false;
    }

    try {Test-Path -Path ($caminhoAbsolutoDiretorioEdiEnviados)} catch {
        MostraLog $caminhoAbsolutoArquivoLog ('caminhoAbsolutoDiretorioEdiEnviados invalido (' + $caminhoAbsolutoDiretorioEdiEnviados + ').');
        $podeMandarVer = $false;
    }

    if (!$podeMandarVer) {
        return;
    }

    CriaRelatorio (PegaArquivoMaisRecente $caminhoAbsolutoDiretorioCnabEnviados $patternCnab) (PegaArquivoMaisRecente $caminhoAbsolutoDiretorioRetornoEnviados $patternRetorno) (PegaArquivoMaisRecente $caminhoAbsolutoDiretorioEdiEnviados $patternEdi);

}

Principal;