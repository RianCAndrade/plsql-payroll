alter table folha.lancamento
    add constraint fk_lanc_funcionario
        foreign key ( id_funcionario )
            references folha.funcionario ( id_funcionario )
        enable;


-- sqlcl_snapshot {"hash":"12ab4a01f727a54cc2eadf32649f0506015adb39","type":"REF_CONSTRAINT","name":"FK_LANC_FUNCIONARIO","schemaName":"FOLHA","sxml":""}