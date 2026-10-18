alter table folha.lancamento
    add constraint fk_lanc_rubrica
        foreign key ( id_rubrica )
            references folha.rubrica ( id_rubrica )
        enable;


-- sqlcl_snapshot {"hash":"ee0e87c29ca8b4ef4ce3f0fd6050acf9a176f72c","type":"REF_CONSTRAINT","name":"FK_LANC_RUBRICA","schemaName":"FOLHA","sxml":""}