Using Module '.\EdiPagSeguroClass.psm1';

class IdentificadorEdiPagSeguro
{
    [string] $tipo
    [datetime] $dataReferencia
    [datetime] $dataGeracao
    [string] $versao
    [string] $especificacao

    IdentificadorEdiPagSeguro ([EdiPagSeguro] $ediPagSeguro) {
                $this.setTipo($ediPagSeguro.getTipo());
                $this.setDataReferencia($ediPagSeguro.getDataReferencia());
                $this.setDataGeracao($ediPagSeguro.getDataGeracao());
                $this.setVersao($ediPagSeguro.getVersao());
                $this.setEspecificacao($ediPagSeguro.getEspecificacao());
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
}