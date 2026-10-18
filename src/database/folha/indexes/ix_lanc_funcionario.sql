create index folha.ix_lanc_funcionario on
    folha.lancamento (
        id_funcionario
    );


-- sqlcl_snapshot {"hash":"0f4d9795196a16a289ff5d8bb0ba403d6a8ad3a8","type":"INDEX","name":"IX_LANC_FUNCIONARIO","schemaName":"FOLHA","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>FOLHA</SCHEMA>\n   <NAME>IX_LANC_FUNCIONARIO</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>FOLHA</SCHEMA>\n         <NAME>LANCAMENTO</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>ID_FUNCIONARIO</NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      \n   </TABLE_INDEX>\n</INDEX>"}