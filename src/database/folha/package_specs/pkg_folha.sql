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

end pkg_folha;
/


-- sqlcl_snapshot {"hash":"7e9e41d31544adc4c17c8e70540cf24c4b15f7da","type":"PACKAGE_SPEC","name":"PKG_FOLHA","schemaName":"FOLHA","sxml":""}