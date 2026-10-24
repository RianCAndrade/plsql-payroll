create or replace package folha.pkg_folha as

    ----------------------------------------------------------------
    -- Erros da aplicacao (faixa permitida: -20000 a -20999)
    -- O PRAGMA permite capturar o erro pelo nome em quem chama:
    --   EXCEPTION WHEN pkg_folha.e_competencia_fechada THEN ...
    ----------------------------------------------------------------
    e_competencia_inexistente exception;
    pragma exception_init ( e_competencia_inexistente, -20001 );
    e_competencia_fechada exception;
    pragma exception_init ( e_competencia_fechada, -20002 );
    e_funcionario_inexistente exception;
    pragma exception_init ( e_funcionario_inexistente, -20003 );
    e_funcionario_desligado exception;
    pragma exception_init ( e_funcionario_desligado, -20004 );
    e_rubrica_inexistente exception;
    pragma exception_init ( e_rubrica_inexistente, -20005 );
    e_competencia_nao_calculada exception;
    pragma exception_init ( e_competencia_nao_calculada, -20006 );

    -- Codigo da rubrica de salario base (ver 02_seed.sql)
    c_cod_salario_base constant rubrica.codigo%type := '001';

    -- Gera (ou atualiza) o lancamento de salario base de um funcionario.
    -- Nao faz COMMIT: quem chama decide.
    procedure calcular_funcionario (
        p_id_funcionario in funcionario.id_funcionario%type,
        p_id_competencia in competencia.id_competencia%type
    );

    -- Calcula todos os funcionarios ativos da competencia (tudo ou nada).
    -- Faz COMMIT no sucesso e ROLLBACK ate o savepoint no erro.
    procedure calcular_competencia (
        p_ano in competencia.ano%type,
        p_mes in competencia.mes%type
    );

    -- Fecha a competencia (so se ja estiver CALCULADA). Faz COMMIT.
    procedure fechar_competencia (
        p_ano in competencia.ano%type,
        p_mes in competencia.mes%type
    );

    -- Valor liquido do funcionario na competencia (0 se nao houver lancamentos).
    function obter_liquido (
        p_id_funcionario in funcionario.id_funcionario%type,
        p_id_competencia in competencia.id_competencia%type
    ) return number;

    e_tabela_inexistente exception;
    pragma exception_init ( e_tabela_inexistente, -20007 );
    c_cod_inss constant rubrica.codigo%type := '101';
    c_cod_irrf constant rubrica.codigo%type := '102';
    function calcular_inss (
        p_base   in number,
        p_dt_ref in date
    ) return number;

    function calcular_irrf (
        p_bruto          in number,
        p_inss           in number,
        p_nr_dependentes in number,
        p_dt_ref         in date
    ) return number;

end pkg_folha;
/


-- sqlcl_snapshot {"hash":"e57d1d6779420b2147efec4f23eb2fbf01e364ab","type":"PACKAGE_SPEC","name":"PKG_FOLHA","schemaName":"FOLHA","sxml":""}