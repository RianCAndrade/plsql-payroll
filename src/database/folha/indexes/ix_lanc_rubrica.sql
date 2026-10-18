create index folha.ix_lanc_rubrica on
    folha.lancamento (
        id_rubrica
    );


-- sqlcl_snapshot {"hash":"cce19ad9eca3e0b77fb51897870ff30af2d26eee","type":"INDEX","name":"IX_LANC_RUBRICA","schemaName":"FOLHA","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>FOLHA</SCHEMA>\n   <NAME>IX_LANC_RUBRICA</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>FOLHA</SCHEMA>\n         <NAME>LANCAMENTO</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>ID_RUBRICA</NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      \n   </TABLE_INDEX>\n</INDEX>"}