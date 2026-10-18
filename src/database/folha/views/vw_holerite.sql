create or replace force editionable view folha.vw_holerite (
    id_competencia,
    id_funcionario,
    total_proventos,
    total_descontos,
    liquido
) as
    select
        l.id_competencia,
        l.id_funcionario,
        sum(
            case
                when r.tipo = 'P' then
                    l.valor
                else
                    0
            end
        ) as total_proventos,
        sum(
            case
                when r.tipo = 'D' then
                    l.valor
                else
                    0
            end
        ) as total_descontos,
        sum(
            case
                when r.tipo = 'P' then
                    l.valor
                else
                    - l.valor
            end
        ) as liquido
    from
             lancamento l
        join rubrica r on r.id_rubrica = l.id_rubrica
    group by
        l.id_competencia,
        l.id_funcionario;


-- sqlcl_snapshot {"hash":"22fc2a442061b6a25b5f260b3b1a2ff64d328852","type":"VIEW","name":"VW_HOLERITE","schemaName":"FOLHA","sxml":""}