create index folha.ix_func_cargo on
    folha.funcionario (
        id_cargo
    );


-- sqlcl_snapshot {"hash":"71081541be9577ef9b4dbdc03eb79247f86acdb3","type":"INDEX","name":"IX_FUNC_CARGO","schemaName":"FOLHA","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>FOLHA</SCHEMA>\n   <NAME>IX_FUNC_CARGO</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>FOLHA</SCHEMA>\n         <NAME>FUNCIONARIO</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>ID_CARGO</NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      \n   </TABLE_INDEX>\n</INDEX>"}