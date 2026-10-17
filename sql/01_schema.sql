-- =============================================================
-- Folha de Pagamento (projeto de treino PL/SQL)
-- Etapa 1: modelo de dados base
-- Requer Oracle 12c+ (IDENTITY). Testado para Oracle Free/XE.
-- =============================================================

ALTER SESSION SET CURRENT_SCHEMA = folha;

CREATE TABLE cargo (
    id_cargo       NUMBER GENERATED ALWAYS AS IDENTITY,
    nome           VARCHAR2(100)  NOT NULL,
    salario_base   NUMBER(12,2)   NOT NULL,
    CONSTRAINT pk_cargo PRIMARY KEY (id_cargo),
    CONSTRAINT uk_cargo_nome UNIQUE (nome),
    CONSTRAINT ck_cargo_salario CHECK (salario_base >= 0)
);

CREATE TABLE funcionario (
    id_funcionario   NUMBER GENERATED ALWAYS AS IDENTITY,
    matricula        VARCHAR2(10)   NOT NULL,
    nome             VARCHAR2(150)  NOT NULL,
    cpf              VARCHAR2(11)   NOT NULL,
    id_cargo         NUMBER         NOT NULL,
    dt_admissao      DATE           NOT NULL,
    dt_demissao      DATE,
    nr_dependentes   NUMBER(2)      DEFAULT 0 NOT NULL,
    situacao         VARCHAR2(10)   DEFAULT 'ATIVO' NOT NULL,
    CONSTRAINT pk_funcionario PRIMARY KEY (id_funcionario),
    CONSTRAINT uk_func_matricula UNIQUE (matricula),
    CONSTRAINT uk_func_cpf UNIQUE (cpf),
    CONSTRAINT fk_func_cargo FOREIGN KEY (id_cargo) REFERENCES cargo (id_cargo),
    CONSTRAINT ck_func_situacao CHECK (situacao IN ('ATIVO', 'AFASTADO', 'DESLIGADO')),
    CONSTRAINT ck_func_dependentes CHECK (nr_dependentes >= 0),
    CONSTRAINT ck_func_datas CHECK (dt_demissao IS NULL OR dt_demissao >= dt_admissao)
);

CREATE INDEX ix_func_cargo ON funcionario (id_cargo);

CREATE TABLE rubrica (
    id_rubrica    NUMBER GENERATED ALWAYS AS IDENTITY,
    codigo        VARCHAR2(5)    NOT NULL,
    descricao     VARCHAR2(100)  NOT NULL,
    tipo          CHAR(1)        NOT NULL,                  -- P = provento, D = desconto
    natureza      VARCHAR2(10)   DEFAULT 'FIXA' NOT NULL,   -- FIXA, CALCULADA, VARIAVEL
    incide_inss   CHAR(1)        DEFAULT 'N' NOT NULL,
    incide_irrf   CHAR(1)        DEFAULT 'N' NOT NULL,
    CONSTRAINT pk_rubrica PRIMARY KEY (id_rubrica),
    CONSTRAINT uk_rubrica_codigo UNIQUE (codigo),
    CONSTRAINT ck_rubrica_tipo CHECK (tipo IN ('P', 'D')),
    CONSTRAINT ck_rubrica_natureza CHECK (natureza IN ('FIXA', 'CALCULADA', 'VARIAVEL')),
    CONSTRAINT ck_rubrica_inss CHECK (incide_inss IN ('S', 'N')),
    CONSTRAINT ck_rubrica_irrf CHECK (incide_irrf IN ('S', 'N'))
);

CREATE TABLE competencia (
    id_competencia   NUMBER GENERATED ALWAYS AS IDENTITY,
    ano              NUMBER(4)     NOT NULL,
    mes              NUMBER(2)     NOT NULL,
    situacao         VARCHAR2(10)  DEFAULT 'ABERTA' NOT NULL,
    CONSTRAINT pk_competencia PRIMARY KEY (id_competencia),
    CONSTRAINT uk_competencia UNIQUE (ano, mes),
    CONSTRAINT ck_comp_mes CHECK (mes BETWEEN 1 AND 12),
    CONSTRAINT ck_comp_situacao CHECK (situacao IN ('ABERTA', 'CALCULADA', 'FECHADA'))
);

CREATE TABLE lancamento (
    id_lancamento    NUMBER GENERATED ALWAYS AS IDENTITY,
    id_competencia   NUMBER         NOT NULL,
    id_funcionario   NUMBER         NOT NULL,
    id_rubrica       NUMBER         NOT NULL,
    referencia       NUMBER(10,2),                           -- quantidade, dias, horas ou percentual
    valor            NUMBER(12,2)   NOT NULL,
    origem           VARCHAR2(6)    DEFAULT 'AUTO' NOT NULL, -- AUTO (calculado) ou MANUAL
    dt_criacao       TIMESTAMP      DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT pk_lancamento PRIMARY KEY (id_lancamento),
    CONSTRAINT uk_lancamento UNIQUE (id_competencia, id_funcionario, id_rubrica),
    CONSTRAINT fk_lanc_competencia FOREIGN KEY (id_competencia) REFERENCES competencia (id_competencia),
    CONSTRAINT fk_lanc_funcionario FOREIGN KEY (id_funcionario) REFERENCES funcionario (id_funcionario),
    CONSTRAINT fk_lanc_rubrica FOREIGN KEY (id_rubrica) REFERENCES rubrica (id_rubrica),
    CONSTRAINT ck_lanc_valor CHECK (valor >= 0),
    CONSTRAINT ck_lanc_origem CHECK (origem IN ('AUTO', 'MANUAL'))
);

CREATE INDEX ix_lanc_funcionario ON lancamento (id_funcionario);
CREATE INDEX ix_lanc_rubrica ON lancamento (id_rubrica);

-- Resumo do holerite por funcionario/competencia
CREATE OR REPLACE VIEW vw_holerite AS
SELECT l.id_competencia,
       l.id_funcionario,
       SUM(CASE WHEN r.tipo = 'P' THEN l.valor ELSE 0 END)  AS total_proventos,
       SUM(CASE WHEN r.tipo = 'D' THEN l.valor ELSE 0 END)  AS total_descontos,
       SUM(CASE WHEN r.tipo = 'P' THEN l.valor ELSE -l.valor END) AS liquido
  FROM lancamento l
  JOIN rubrica r ON r.id_rubrica = l.id_rubrica
 GROUP BY l.id_competencia, l.id_funcionario;
