alter table folha.lancamento
    add constraint fk_lanc_competencia
        foreign key ( id_competencia )
            references folha.competencia ( id_competencia )
        enable;


-- sqlcl_snapshot {"hash":"68c9c9d9dc8d1beefccb9c0000bd7af92e3d5251","type":"REF_CONSTRAINT","name":"FK_LANC_COMPETENCIA","schemaName":"FOLHA","sxml":""}