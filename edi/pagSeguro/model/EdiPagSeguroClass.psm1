class EdiPagSeguro
{
    [string] $caminhoAbsoluto
    [string] $id
    [string] $tipo
    [datetime] $dataReferencia
    [datetime] $dataGeracao
    [string] $versao
    [string] $especificacao
    [string] $nomeNormalizado

    EdiPagSeguro ([string] $caminhoAbsoluto) {
        $this.caminhoAbsoluto = $caminhoAbsoluto;
        
        foreach ($linha in Get-Content $this.caminhoAbsoluto) {
            if ($linha -match '^[0]{1}.*$') {
                $idArquivo = $linha.Substring(1,10) -replace '^0+','';
                if ($idArquivo.Trim() -eq '') {$this.setId($null)} else {$this.setId($idArquivo)};
    
                $tipoArquivo = $null;
                switch ($linha.Substring(47,2)) {
                    '01' {
                        $tipoArquivo = 'TRANS';
                        if($this.caminhoAbsoluto.ToLower() -match '^.*summary.*$') {
                            $tipoArquivo += 'SUMMARY';
                        }
                        break;
                    }
                    '02' {
                        $tipoArquivo = 'FIN';
                        break;
                    }
                    '03' {
                        $tipoArquivo = 'ANT';
                        break;
                    }
                    default {
                        $tipoArquivo = $null;
                        break;
                    }
                }
                if ($tipoArquivo.Trim() -eq '') {$this.setTipo($null)} else {$this.setTipo($tipoArquivo)};

                $dataString = $linha.Substring(27,8) -replace '^0+','';
                if ($dataString.Trim() -eq '') {$data = $null} else {$data = Get-Date -Year $dataString.Substring(0,4) -Month $dataString.Substring(4,2) -Day $dataString.Substring(6,2) -Hour 0 -Minute 0 -Second 0 -Millisecond 0};
                $this.setDataReferencia($data);

                $dataString = $linha.Substring(11,8) -replace '^0+','';
                if ($dataString.Trim() -eq '') {$data = $null} else {$data = Get-Date -Year $dataString.Substring(0,4) -Month $dataString.Substring(4,2) -Day $dataString.Substring(6,2) -Hour 0 -Minute 0 -Second 0 -Millisecond 0};
                $this.setDataGeracao($data);

                $versaoArquivo = $linha.Substring(70,6);
                if ($versaoArquivo.Trim() -eq '') {$this.setVersao($null)} else {$this.setVersao($versaoArquivo.Trim())};

                $especificacaoArquivo = $linha.Substring(76,2);
                if ($especificacaoArquivo.Trim() -eq '') {$this.setEspecificacao($null)} else {$this.setEspecificacao($especificacaoArquivo.Trim())};
                
            }
            break;
        }
    
        if (!($this.id -eq '') -and !($this.tipo -eq '') -and !($null -eq $this.dataReferencia) -and !($null -eq $this.dataGeracao) -and !($this.versao -eq '')) {
            $nomeArquivo = 'PAGSEG' + '_';
            $nomeArquivo += $this.id + '_';
            $nomeArquivo += $this.tipo + '_';
            $nomeArquivo += $this.dataReferencia.ToString('yyyyMMdd') + '_';
            $nomeArquivo += $this.dataGeracao.ToString('yyyyMMdd') + '_';
            $nomeArquivo += (($this.versao -replace ('\,','')) -replace ('\.', '')) + '_';

            if (!($this.especificacao -eq '')) {$nomeArquivo += (($this.especificacao -replace '\,','') -replace ('\.','')) + '_'};
        
            $arquivoOrigem = Get-Item -Path $caminhoAbsoluto;

            $nomeArquivoOrigemSplit = $arquivoOrigem.Name.Split('{_}');
            $posicao = $nomeArquivoOrigemSplit.Count;
            if ($posicao -ge 5) {
                $posicao -= 1;
                $nomeArquivo += $nomeArquivoOrigemSplit[$posicao];
            } else {
                $nomeArquivo += '01';
            }

            if (!($nomeArquivo -match '^.*\.txt$')) {
                $nomeArquivo += '.txt';
            }

            $this.setNomeNormalizado($nomeArquivo);
        } else {
            $this.setNomeNormalizado($null);
        }
    }

    [void] setId ([string] $id) {
        $this.id = $id;
    }
    [void] setTipo ([string] $tipo) {
        $this.tipo = $tipo;
    }
    [void] setDataReferencia ([datetime] $data) {
        $this.dataReferencia = $data;
    }
    [void] setDataGeracao ([datetime] $data) {
        $this.dataGeracao = $data;
    }
    [void] setVersao ([string] $versao) {
        $this.versao = $versao;
    }
    [void] setEspecificacao ([string] $especificacao) {
        $this.especificacao = $especificacao;
    }
    [void] setNomeNormalizado ($nomeNormalizado) {
        $this.nomeNormalizado = $nomeNormalizado;
    }

    [string] getCaminhoAbsoluto () {
        return $this.caminhoAbsoluto;
    }
    [string] getId () {
        return $this.id;
    }
    [string] getTipo () {
        return $this.tipo;
    }
    [datetime] getDataReferencia () {
        return $this.dataReferencia;
    }
    [datetime] getDataGeracao () {
        return $this.dataGeracao;
    }
    [string] getVersao () {
        return $this.versao;
    }
    [string] getEspecificacao () {
        return $this.especificacao;
    }
    [string] getNomeNormalizado () {
        return $this.nomeNormalizado;
    }
}