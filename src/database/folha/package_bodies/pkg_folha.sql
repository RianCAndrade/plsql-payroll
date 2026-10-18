create or replace package body folha.pkg_folha as

    ----------------------------------------------------------------
    -- PRIVADOS (nao aparecem na spec, so existem dentro do body)
    ----------------------------------------------------------------

    -- Sobrecarga (overload): mesmo nome, parametros diferentes.
    function buscar_competencia (
        p_id_competencia in competencia.id_competencia%type
    ) return competencia%rowtype is
        v_comp competencia%rowtype;
    begin
        select
            *
        into v_comp
        from
            competencia
        where
            id_competencia = p_id_competencia;

        return v_comp;
    exception
        when no_data_found then
            raise_application_error(-20001, 'Competencia id '
                                            || p_id_competencia
                                            || ' nao encontrada.');
    end buscar_competencia;

    function buscar_competencia (
        p_ano in competencia.ano%type,
        p_mes in competencia.mes%type
    ) return competencia%rowtype is
        v_comp competencia%rowtype;
    begin
        select
            *
        into v_comp
        from
            competencia
        where
                ano = p_ano
            and mes = p_mes;

        return v_comp;
    exception
        when no_data_found then
            raise_application_error(-20001,
                                    'Competencia '
                                    || p_ano
                                    || '/'
                                    || lpad(p_mes, 2, '0')
                                    || ' nao encontrada.');
    end buscar_competencia;

    procedure validar_competencia_aberta (
        p_comp in competencia%rowtype
    ) is
    begin
        if p_comp.situacao = 'FECHADA' then
            raise_application_error(-20002,
                                    'Competencia '
                                    || p_comp.ano
                                    || '/'
                                    || lpad(p_comp.mes, 2, '0')
                                    || ' esta fechada.');

        end if;
    end validar_competencia_aberta;

    ----------------------------------------------------------------
    -- PUBLICOS
    ----------------------------------------------------------------

    procedure calcular_funcionario (
        p_id_funcionario in funcionario.id_funcionario%type,
        p_id_competencia in competencia.id_competencia%type
    ) is

        v_comp         competencia%rowtype;
        v_situacao     funcionario.situacao%type;
        v_salario_base cargo.salario_base%type;
        v_id_rubrica   rubrica.id_rubrica%type;
    begin
        v_comp := buscar_competencia(p_id_competencia);
        validar_competencia_aberta(v_comp);
        begin
            select
                f.situacao,
                c.salario_base
            into
                v_situacao,
                v_salario_base
            from
                     funcionario f
                join cargo c on c.id_cargo = f.id_cargo
            where
                f.id_funcionario = p_id_funcionario;

        exception
            when no_data_found then
                raise_application_error(-20003, 'Funcionario id '
                                                || p_id_funcionario
                                                || ' nao encontrado.');
        end;

        if v_situacao = 'DESLIGADO' then
            raise_application_error(-20004, 'Funcionario id '
                                            || p_id_funcionario
                                            || ' esta desligado.');
        end if;

        begin
            select
                id_rubrica
            into v_id_rubrica
            from
                rubrica
            where
                codigo = c_cod_salario_base;

        exception
            when no_data_found then
                raise_application_error(-20005, 'Rubrica '
                                                || c_cod_salario_base
                                                || ' (salario base) nao cadastrada.');
        end;

        -- MERGE = "insere se nao existe, atualiza se existe".
        -- Recalcular nao duplica o lancamento, e lancamento MANUAL nunca e sobrescrito.
        merge into lancamento l
        using (
            select
                p_id_competencia as id_competencia,
                p_id_funcionario as id_funcionario,
                v_id_rubrica     as id_rubrica,
                v_salario_base   as valor
            from
                dual
        ) s on ( l.id_competencia = s.id_competencia
                 and l.id_funcionario = s.id_funcionario
                 and l.id_rubrica = s.id_rubrica )
        when matched then update
        set l.valor = s.valor
        where
            l.origem = 'AUTO'
        when not matched then
        insert (
            id_competencia,
            id_funcionario,
            id_rubrica,
            valor,
            origem )
        values
            ( s.id_competencia,
              s.id_funcionario,
              s.id_rubrica,
              s.valor,
              'AUTO' );

    end calcular_funcionario;

    ----------------------------------------------------------------

    procedure calcular_competencia (
        p_ano in competencia.ano%type,
        p_mes in competencia.mes%type
    ) is
        v_comp   competencia%rowtype;
        v_dt_ref date;
        v_qtd    pls_integer := 0;
    begin
        -- O savepoint precisa vir ANTES de qualquer coisa que possa falhar,
        -- senao o ROLLBACK TO do handler daria erro e esconderia o erro original.
        savepoint sp_calculo;
        v_comp := buscar_competencia(p_ano, p_mes);
        validar_competencia_aberta(v_comp);
        v_dt_ref := to_date ( to_char(p_ano * 100 + p_mes),
        'YYYYMM' );
        for r in (
            select
                id_funcionario
            from
                funcionario
            where
                    situacao = 'ATIVO'
                and dt_admissao <= last_day(v_dt_ref)
            order by
                id_funcionario
        ) loop
            calcular_funcionario(r.id_funcionario, v_comp.id_competencia);
            v_qtd := v_qtd + 1;
        end loop;

        update competencia
        set
            situacao = 'CALCULADA'
        where
            id_competencia = v_comp.id_competencia;

        commit;
        dbms_output.put_line('Competencia '
                             || p_ano
                             || '/'
                             || lpad(p_mes, 2, '0')
                             || ': '
                             || v_qtd || ' funcionario(s) calculado(s).');

    exception
        when others then
            rollback to sp_calculo;
            raise;  -- relanca o erro original
    end calcular_competencia;

    ----------------------------------------------------------------

    procedure fechar_competencia (
        p_ano in competencia.ano%type,
        p_mes in competencia.mes%type
    ) is
        v_comp competencia%rowtype;
    begin
        v_comp := buscar_competencia(p_ano, p_mes);
        validar_competencia_aberta(v_comp);  -- erro se ja estiver FECHADA

        if v_comp.situacao <> 'CALCULADA' then
            raise_application_error(-20006,
                                    'Competencia '
                                    || p_ano
                                    || '/'
                                    || lpad(p_mes, 2, '0')
                                    || ' ainda nao foi calculada.');
        end if;

        update competencia
        set
            situacao = 'FECHADA'
        where
            id_competencia = v_comp.id_competencia;

        commit;
    end fechar_competencia;

    ----------------------------------------------------------------

    function obter_liquido (
        p_id_funcionario in funcionario.id_funcionario%type,
        p_id_competencia in competencia.id_competencia%type
    ) return number is
        v_liquido number;
    begin
        -- SUM sem GROUP BY sempre devolve 1 linha, entao nao dispara NO_DATA_FOUND.
        select
            nvl(
                sum(liquido),
                0
            )
        into v_liquido
        from
            vw_holerite
        where
                id_competencia = p_id_competencia
            and id_funcionario = p_id_funcionario;

        return v_liquido;
    end obter_liquido;

end pkg_folha;
/


-- sqlcl_snapshot {"hash":"37d32d536fdc9783b9bf676ba4e8f5924235f4a1","type":"PACKAGE_BODY","name":"PKG_FOLHA","schemaName":"FOLHA","sxml":""}