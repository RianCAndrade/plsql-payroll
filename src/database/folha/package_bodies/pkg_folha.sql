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

    function buscar_id_rubrica (
        p_codigo in rubrica.codigo%type
    ) return rubrica.id_rubrica%type is
        v_id rubrica.id_rubrica%type;
    begin
        select
            id_rubrica
        into v_id
        from
            rubrica
        where
            codigo = p_codigo;

        return v_id;
    exception
        when no_data_found then
            raise_application_error(-20005, 'Rubrica '
                                            || p_codigo
                                            || ' nao cadastrada.');
    end buscar_id_rubrica;

    procedure gravar_lancamento (
        p_id_competencia in lancamento.id_competencia%type,
        p_id_funcionario in lancamento.id_funcionario%type,
        p_id_rubrica     in lancamento.id_rubrica%type,
        p_valor          in lancamento.valor%type
    ) is
    begin
        merge into lancamento l
        using (
            select
                p_id_competencia as id_competencia,
                p_id_funcionario as id_funcionario,
                p_id_rubrica     as id_rubrica,
                p_valor          as valor
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

    end gravar_lancamento;

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
    function calcular_inss (
        p_base   in number,
        p_dt_ref in date
    ) return number is
        v_vigencia date;
        v_inss     number := 0;
    begin
        select
            max(dt_vigencia_ini)
        into v_vigencia
        from
            tabela_inss
        where
            dt_vigencia_ini <= p_dt_ref;

        if v_vigencia is null then
            raise_application_error(-20007,
                                    'Tabela do INSS sem vigencia para '
                                    || to_char(p_dt_ref, 'DD/MM/YYYY')
                                    || '.');

        end if;

        -- Cada faixa tributa so a parte da base que cai dentro dela.
        -- LEAST com o limite superior faz o teto aparecer sozinho.
        for f in (
            select
                limite_inferior,
                limite_superior,
                aliquota
            from
                tabela_inss
            where
                dt_vigencia_ini = v_vigencia
            order by
                limite_inferior
        ) loop
            exit when p_base <= f.limite_inferior;
            v_inss := v_inss + ( least(p_base, f.limite_superior) - f.limite_inferior ) * f.aliquota;

        end loop;

        return round(v_inss, 2);  -- arredonda so no final
    end calcular_inss;

    function calcular_irrf (
        p_bruto          in number,
        p_inss           in number,
        p_nr_dependentes in number,
        p_dt_ref         in date
    ) return number is

        v_par      parametro_fiscal%rowtype;
        v_vig_irrf date;
        v_deducao  number;
        v_base     number;
        v_aliquota tabela_irrf.aliquota%type;
        v_parcela  tabela_irrf.parcela_deduzir%type;
        v_imposto  number := 0;
        v_reducao  number := 0;
    begin
        begin
            select
                *
            into v_par
            from
                parametro_fiscal
            where
                dt_vigencia_ini = (
                    select
                        max(dt_vigencia_ini)
                    from
                        parametro_fiscal
                    where
                        dt_vigencia_ini <= p_dt_ref
                );

        exception
            when no_data_found then
                raise_application_error(-20007,
                                        'Parametros fiscais sem vigencia para '
                                        || to_char(p_dt_ref, 'DD/MM/YYYY')
                                        || '.');
        end;

        select
            max(dt_vigencia_ini)
        into v_vig_irrf
        from
            tabela_irrf
        where
            dt_vigencia_ini <= p_dt_ref;

        if v_vig_irrf is null then
            raise_application_error(-20007,
                                    'Tabela do IRRF sem vigencia para '
                                    || to_char(p_dt_ref, 'DD/MM/YYYY')
                                    || '.');
        end if;

        -- Usa a deducao mais vantajosa: legais (INSS + dependentes) ou simplificada
        v_deducao := greatest(p_inss + p_nr_dependentes * v_par.ded_dependente, v_par.desc_simplificado);
        v_base := p_bruto - v_deducao;
        if v_base > 0 then
            select
                aliquota,
                parcela_deduzir
            into
                v_aliquota,
                v_parcela
            from
                tabela_irrf
            where
                    dt_vigencia_ini = v_vig_irrf
                and v_base > limite_inferior
                and v_base <= limite_superior;

            v_imposto := greatest(v_base * v_aliquota - v_parcela, 0);
        end if;

        -- Reducao da Lei 15.270/2025: calculada sobre o BRUTO, nao sobre a base
        if p_bruto <= v_par.red_isencao_ate then
            v_reducao := v_par.red_valor_max;
        elsif p_bruto <= v_par.red_ate then
            v_reducao := v_par.red_constante - v_par.red_fator * p_bruto;
        end if;  -- acima de red_ate: sem reducao

        return round(
            greatest(v_imposto - v_reducao, 0),
            2
        );
    end calcular_irrf;

    procedure calcular_funcionario (
        p_id_funcionario in funcionario.id_funcionario%type,
        p_id_competencia in competencia.id_competencia%type
    ) is

        v_comp           competencia%rowtype;
        v_situacao       funcionario.situacao%type;
        v_nr_dependentes funcionario.nr_dependentes%type;
        v_salario_base   cargo.salario_base%type;
        v_dt_ref         date;
        v_base_inss      number;
        v_base_irrf      number;
        v_inss           number;
        v_irrf           number;
    begin
        v_comp := buscar_competencia(p_id_competencia);
        validar_competencia_aberta(v_comp);
        v_dt_ref := to_date ( to_char(v_comp.ano * 100 + v_comp.mes),
        'YYYYMM' );

        begin
            select
                f.situacao,
                f.nr_dependentes,
                c.salario_base
            into
                v_situacao,
                v_nr_dependentes,
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

        -- 1) Proventos
        gravar_lancamento(p_id_competencia,
                          p_id_funcionario,
                          buscar_id_rubrica(c_cod_salario_base),
                          v_salario_base);

        -- 2) Bases de calculo: soma dos proventos que incidem em cada imposto
        select
            nvl(
                sum(
                    case
                        when r.incide_inss = 'S' then
                            l.valor
                    end
                ),
                0
            ),
            nvl(
                sum(
                    case
                        when r.incide_irrf = 'S' then
                            l.valor
                    end
                ),
                0
            )
        into
            v_base_inss,
            v_base_irrf
        from
                 lancamento l
            join rubrica r on r.id_rubrica = l.id_rubrica
        where
                l.id_competencia = p_id_competencia
            and l.id_funcionario = p_id_funcionario
            and r.tipo = 'P';

        -- 3) Descontos
        v_inss := calcular_inss(v_base_inss, v_dt_ref);
        v_irrf := calcular_irrf(v_base_irrf, v_inss, v_nr_dependentes, v_dt_ref);
        gravar_lancamento(p_id_competencia,
                          p_id_funcionario,
                          buscar_id_rubrica(c_cod_inss),
                          v_inss);
        gravar_lancamento(p_id_competencia,
                          p_id_funcionario,
                          buscar_id_rubrica(c_cod_irrf),
                          v_irrf);
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


-- sqlcl_snapshot {"hash":"75d48678d11c989a6655352b9260a63572975b0a","type":"PACKAGE_BODY","name":"PKG_FOLHA","schemaName":"FOLHA","sxml":""}