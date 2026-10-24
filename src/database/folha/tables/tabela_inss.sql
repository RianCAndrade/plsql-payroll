create table folha.tabela_inss (
    id_faixa        number generated always as identity minvalue 1 maxvalue 9999999999999999999999999999 increment by 1 cache 20 noorder
    nocycle nokeep noscale not null enable,
    dt_vigencia_ini date not null enable,
    limite_inferior number(12, 2) not null enable,
    limite_superior number(12, 2) not null enable,
    aliquota        number(5, 4) not null enable
);

alter table folha.tabela_inss add constraint ck_inss_limites check ( limite_superior > limite_inferior ) enable;

alter table folha.tabela_inss
    add constraint pk_tabela_inss primary key ( id_faixa )
        using index enable;

alter table folha.tabela_inss
    add constraint uk_tabela_inss unique ( dt_vigencia_ini,
                                           limite_inferior )
        using index enable;


-- sqlcl_snapshot {"hash":"1712c5ee8479b7bdf5de354b6dce4125533b5323","type":"TABLE","name":"TABELA_INSS","schemaName":"FOLHA","sxml":"\n  <TABLE xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>FOLHA</SCHEMA>\n   <NAME>TABELA_INSS</NAME>\n   <RELATIONAL_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>ID_FAIXA</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n            <IDENTITY_COLUMN>\n               <SCHEMA>FOLHA</SCHEMA>\n               <GENERATION>ALWAYS</GENERATION>\n               \n               <INCREMENT>1</INCREMENT>\n               <MINVALUE>1</MINVALUE>\n               <MAXVALUE>9999999999999999999999999999</MAXVALUE>\n               <CACHE>20</CACHE>\n               <SCALE>NOSCALE</SCALE>\n            </IDENTITY_COLUMN>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>DT_VIGENCIA_INI</NAME>\n            <DATATYPE>DATE</DATATYPE>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>LIMITE_INFERIOR</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n            <PRECISION>12</PRECISION>\n            <SCALE>2</SCALE>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>LIMITE_SUPERIOR</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n            <PRECISION>12</PRECISION>\n            <SCALE>2</SCALE>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>ALIQUOTA</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n            <PRECISION>5</PRECISION>\n            <SCALE>4</SCALE>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n      </COL_LIST>\n      <CHECK_CONSTRAINT_LIST>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>CK_INSS_LIMITES</NAME>\n            <CONDITION>limite_superior > limite_inferior</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n      </CHECK_CONSTRAINT_LIST>\n      <PRIMARY_KEY_CONSTRAINT_LIST>\n         <PRIMARY_KEY_CONSTRAINT_LIST_ITEM>\n            <NAME>PK_TABELA_INSS</NAME>\n            <COL_LIST>\n               <COL_LIST_ITEM>\n                  <NAME>ID_FAIXA</NAME>\n               </COL_LIST_ITEM>\n            </COL_LIST>\n            <USING_INDEX></USING_INDEX>\n         </PRIMARY_KEY_CONSTRAINT_LIST_ITEM>\n      </PRIMARY_KEY_CONSTRAINT_LIST>\n      <UNIQUE_KEY_CONSTRAINT_LIST>\n         <UNIQUE_KEY_CONSTRAINT_LIST_ITEM>\n            <NAME>UK_TABELA_INSS</NAME>\n            <COL_LIST>\n               <COL_LIST_ITEM>\n                  <NAME>DT_VIGENCIA_INI</NAME>\n               </COL_LIST_ITEM>\n               <COL_LIST_ITEM>\n                  <NAME>LIMITE_INFERIOR</NAME>\n               </COL_LIST_ITEM>\n            </COL_LIST>\n            <USING_INDEX></USING_INDEX>\n         </UNIQUE_KEY_CONSTRAINT_LIST_ITEM>\n      </UNIQUE_KEY_CONSTRAINT_LIST>\n      <DEFAULT_COLLATION>USING_NLS_COMP</DEFAULT_COLLATION>\n      <PHYSICAL_PROPERTIES>\n         <HEAP_TABLE></HEAP_TABLE>\n      </PHYSICAL_PROPERTIES>\n      \n   </RELATIONAL_TABLE>\n</TABLE>"}