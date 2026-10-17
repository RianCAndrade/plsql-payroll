-- =============================================================
-- Dados 100% ficticios para desenvolvimento e testes
-- =============================================================

ALTER SESSION SET CURRENT_SCHEMA = folha;

INSERT INTO cargo (nome, salario_base) VALUES ('Analista Junior', 4500.00);
INSERT INTO cargo (nome, salario_base) VALUES ('Analista Pleno',  7200.00);
INSERT INTO cargo (nome, salario_base) VALUES ('Coordenador',    11500.00);

INSERT INTO rubrica (codigo, descricao, tipo, natureza, incide_inss, incide_irrf)
VALUES ('001', 'Salario base', 'P', 'FIXA', 'S', 'S');
INSERT INTO rubrica (codigo, descricao, tipo, natureza, incide_inss, incide_irrf)
VALUES ('101', 'INSS', 'D', 'CALCULADA', 'N', 'N');
INSERT INTO rubrica (codigo, descricao, tipo, natureza, incide_inss, incide_irrf)
VALUES ('102', 'IRRF', 'D', 'CALCULADA', 'N', 'N');
INSERT INTO rubrica (codigo, descricao, tipo, natureza, incide_inss, incide_irrf)
VALUES ('201', 'Hora extra 50%', 'P', 'VARIAVEL', 'S', 'S');
INSERT INTO rubrica (codigo, descricao, tipo, natureza, incide_inss, incide_irrf)
VALUES ('301', 'Falta injustificada', 'D', 'VARIAVEL', 'N', 'N');

INSERT INTO funcionario (matricula, nome, cpf, id_cargo, dt_admissao, nr_dependentes)
SELECT '0001', 'Maria Teste', '00000000001', id_cargo, DATE '2022-03-01', 2
  FROM cargo WHERE nome = 'Analista Pleno';
INSERT INTO funcionario (matricula, nome, cpf, id_cargo, dt_admissao, nr_dependentes)
SELECT '0002', 'Joao Exemplo', '00000000002', id_cargo, DATE '2024-08-15', 0
  FROM cargo WHERE nome = 'Analista Junior';
INSERT INTO funcionario (matricula, nome, cpf, id_cargo, dt_admissao, nr_dependentes)
SELECT '0003', 'Ana Ficticia', '00000000003', id_cargo, DATE '2019-01-10', 1
  FROM cargo WHERE nome = 'Coordenador';

INSERT INTO competencia (ano, mes) VALUES (2026, 10);

COMMIT;
