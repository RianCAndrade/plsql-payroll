alter table folha.funcionario
    add constraint fk_func_cargo
        foreign key ( id_cargo )
            references folha.cargo ( id_cargo )
        enable;


-- sqlcl_snapshot {"hash":"579c9356147d580ef0e49beb2ef41864c7c95a67","type":"REF_CONSTRAINT","name":"FK_FUNC_CARGO","schemaName":"FOLHA","sxml":""}