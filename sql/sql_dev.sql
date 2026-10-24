-- Modifique


SELECT pkg_folha.calcular_inss(7200, DATE '2026-10-01') FROM dual;              -- 809,51
SELECT pkg_folha.calcular_irrf(7200, 809.51, 2, DATE '2026-10-01') FROM dual;   -- 724,40
SELECT pkg_folha.calcular_inss(20000, DATE '2026-10-01') FROM dual;             -- 988,09 (teto)


UPDATE competencia SET situacao = 'ABERTA' WHERE ano = 2026 AND mes = 10;
COMMIT;

SET SERVEROUTPUT ON
BEGIN
    pkg_folha.calcular_competencia(2026, 10);
END;
/

SELECT f.nome, h.total_proventos, h.total_descontos, h.liquido
  FROM vw_holerite h
  JOIN funcionario f ON f.id_funcionario = h.id_funcionario
 ORDER BY f.nome;