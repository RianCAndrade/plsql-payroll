# PL/SQL Payroll — Motor de Folha de Pagamento

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Motor de cálculo de folha de pagamento escrito em **PL/SQL** para **Oracle Database Free**, com o cálculo de INSS, IRRF e redutor do IRPF implementado inteiramente no banco.

A ideia do projeto é simples: as regras fiscais e trabalhistas ficam **centralizadas no banco de dados**, em um pacote único (`PKG_FOLHA`), em vez de espalhadas pela aplicação. Assim, qualquer cliente — SQL*Plus, SQLcl, uma API, um app — obtém exatamente o mesmo resultado, com a mesma validação e a mesma atomicidade.

O repositório é organizado como um **SQLcl Project**: os objetos do schema `FOLHA` ficam em arquivos `.sql` versionados, e o SQLcl consegue exportá-los do banco, gerar changelogs Liquibase e publicá-los em outro ambiente.

---

## Sumário

- [Sobre o projeto](#sobre-o-projeto)
- [Stack](#stack)
- [Estrutura do repositório](#estrutura-do-repositório)
- [Modelo de dados](#modelo-de-dados)
- [Regras de negócio](#regras-de-negócio)
- [API do pacote `PKG_FOLHA`](#api-do-pacote-pkg_folha)
- [Códigos de erro](#códigos-de-erro)
- [Como executar](#como-executar)
- [Carga inicial de dados](#carga-inicial-de-dados)
- [Exemplo de uso](#exemplo-de-uso)
- [Fluxo de desenvolvimento com SQLcl Projects](#fluxo-de-desenvolvimento-com-sqlcl-projects)
- [Limitações e próximos passos](#limitações-e-próximos-passos)
- [Manutenção](#manutenção)
- [Licença](#licença)

---

## Sobre o projeto

O projeto implementa o ciclo básico de uma folha mensal:

1. **Cadastro** de cargos, funcionários e rubricas.
2. **Abertura** de uma competência (mês/ano).
3. **Cálculo** dos lançamentos de cada funcionário ativo (proventos e descontos).
4. **Fechamento** da competência, impedindo recálculos.
5. **Consulta** do holerite consolidado pela view `VW_HOLERITE`.

O cálculo cobre:

- Salário base vindo do cargo do funcionário.
- **INSS** progressivo por faixas, com teto.
- **IRRF** com escolha automática entre dedução legal e desconto simplificado.
- **Redutor do IRPF** introduzido pela Lei nº 15.270/2025.
- Tabelas de INSS, IRRF e parâmetros fiscais **versionados por vigência**.

---

## Stack

| Item | Versão / detalhe |
|---|---|
| Linguagem | Oracle PL/SQL |
| Banco | Oracle Database Free (`gvenzl/oracle-free:slim`) |
| Container | Docker + Docker Compose |
| Ferramenta de projeto | Oracle SQLcl 26.2 com extensão SQLcl Projects |
| Schema | `FOLHA` |
| Porta no host | `1522` (mapeada para `1521` no container) |

---

## Estrutura do repositório

```text
plsql-payroll/
├── .dbtools/                     # Metadados do SQLcl Project (config, filtros, formatação)
├── sql/
│   └── sql_dev.sql               # Consultas de apoio ao desenvolvimento (não é migração)
├── src/database/folha/
│   ├── indexes/                  # IX_FUNC_CARGO, IX_LANC_FUNCIONARIO, IX_LANC_RUBRICA
│   ├── package_bodies/pkg_folha.sql
│   ├── package_specs/pkg_folha.sql
│   ├── ref_constraints/          # FKs de funcionario e lancamento
│   ├── tables/                   # 8 tabelas do schema
│   └── views/vw_holerite.sql
├── docker-compose.yml
├── folha_FREE.sql                # SELECTs rápidos em todas as tabelas
├── .env.example                  # Modelo das variáveis de ambiente
├── .gitignore
├── LICENSE                       # MIT
└── README.md
```

Os diretórios `dist/` e `artifact/` são **gerados** pelo SQLcl (`project stage` / `project gen-artifact`) e não são versionados.

> Os arquivos em `src/` são exportados pelo SQLcl e carregam um rodapé `-- sqlcl_snapshot {...}`. Ele é usado pela ferramenta para detectar mudanças — **não remova**.

---

## Modelo de dados

```text
CARGO 1 ────────── N FUNCIONARIO 1 ────── N LANCAMENTO N ────── 1 RUBRICA
                                             │
                                             └── N ── 1 COMPETENCIA

TABELA_INSS ─┐
TABELA_IRRF ─┼── parametrizadas por DT_VIGENCIA_INI (histórico fiscal)
PARAMETRO_FISCAL ─┘
```

### Tabelas

| Tabela | Papel |
|---|---|
| `CARGO` | Nome do cargo e salário base. |
| `FUNCIONARIO` | Matrícula, CPF, cargo, admissão/demissão, dependentes e situação (`ATIVO`, `AFASTADO`, `DESLIGADO`). |
| `COMPETENCIA` | Mês/ano da folha e situação (`ABERTA`, `CALCULADA`, `FECHADA`). `(ano, mes)` é único. |
| `RUBRICA` | Verba da folha: código, descrição, tipo (`P` provento / `D` desconto), natureza (`FIXA`, `CALCULADA`, `VARIAVEL`) e incidências de INSS/IRRF (`S`/`N`). |
| `LANCAMENTO` | Valor de uma rubrica para um funcionário em uma competência. Único por `(competência, funcionário, rubrica)`. `origem` indica se veio do cálculo (`AUTO`) ou de lançamento manual (`MANUAL`). |
| `TABELA_INSS` | Faixas de INSS por vigência (limite inferior/superior + alíquota). |
| `TABELA_IRRF` | Faixas de IRRF por vigência (limite inferior/superior, alíquota e parcela a deduzir). |
| `PARAMETRO_FISCAL` | Dedução por dependente, desconto simplificado e parâmetros do redutor, por vigência. |

### View

| View | Papel |
|---|---|
| `VW_HOLERITE` | Consolida os lançamentos por competência/funcionário, somando `total_proventos`, `total_descontos` e `liquido`. |

### Rubricas reservadas

O pacote depende de três códigos fixos:

| Código | Descrição | Tipo |
|---|---|---|
| `001` | Salário base | `P` |
| `101` | INSS | `D` |
| `102` | IRRF | `D` |

---

## Regras de negócio

### Vigência das tabelas fiscais

Para uma data de referência (o primeiro dia da competência), o cálculo sempre busca o registro com **maior `DT_VIGENCIA_INI` menor ou igual** à data. Isso mantém o histórico fiscal intacto: para calcular 2024 e 2026 corretamente, basta cadastrar as respectivas vigências — nada é sobrescrito.

Se não houver vigência aplicável, o cálculo aborta com o erro `-20007`.

### INSS

Cálculo **progressivo por faixas**: cada faixa tributa apenas a parcela da base que cai dentro dela.

```
para cada faixa (ordenada por limite_inferior):
    se base <= limite_inferior: encerra
    inss += (menor(base, limite_superior) - limite_inferior) * aliquota
```

O `LEAST` com o limite superior faz o **teto** surgir naturalmente, sem constante hardcoded. O arredondamento acontece **uma única vez**, no retorno (`round(v_inss, 2)`), para não acumular erro de centavos.

### IRRF

1. Considera apenas rubricas do tipo `P` com `INCIDE_IRRF = 'S'`.
2. Calcula as duas deduções possíveis:
   - **Legal:** `INSS + nr_dependentes * ded_dependente`
   - **Simplificada:** `desc_simplificado`
3. Usa a **maior** delas (`GREATEST`), aplica a alíquota da faixa e subtrai a parcela a deduzir, com piso em zero.
4. Aplica o **redutor da Lei nº 15.270/2025**, calculado sobre o **bruto** (não sobre a base):
   - `bruto <= red_isencao_ate` → redução de `red_valor_max`
   - `bruto <= red_ate` → redução de `red_constante - red_fator * bruto`
   - acima disso → sem redução
5. Retorna `GREATEST(imposto - redução, 0)`, arredondado a 2 casas.

### Bases de cálculo

As bases de INSS e IRRF são recalculadas a partir dos lançamentos do próprio funcionário na competência, somando apenas os proventos que incidem em cada tributo. Ou seja: se um provento manual for adicionado antes do cálculo, ele entra na base automaticamente.

### Ciclo de vida da competência

```text
ABERTA ──(calcular_competencia)──> CALCULADA ──(fechar_competencia)──> FECHADA
```

- Só é possível calcular competência `ABERTA` (ou recalculável) — `FECHADA` levanta `-20002`.
- Só é possível fechar competência `CALCULADA` — caso contrário, `-20006`.
- Depois de `FECHADA`, nenhum recálculo é aceito.

### Atomicidade do cálculo da competência

`calcular_competencia` é **tudo ou nada**:

- Um `SAVEPOINT` é criado **antes** de qualquer operação que possa falhar (se ficasse depois, o `ROLLBACK TO` do handler mascararia o erro original).
- Se qualquer funcionário falhar, o handler faz `ROLLBACK TO` o savepoint e **relança a exceção original** (`RAISE`).
- No sucesso, atualiza a competência para `CALCULADA` e faz `COMMIT`.

### Idempotência e preservação de lançamentos manuais

`gravar_lancamento` usa `MERGE` por `(competência, funcionário, rubrica)`:

- Se o lançamento **não existe**, insere com `origem = 'AUTO'`.
- Se **existe e é `AUTO`**, atualiza o valor.
- Se **existe e é `MANUAL`**, **não sobrescreve** — o ajuste feito à mão é preservado.

Recalcular uma competência aberta, portanto, pode ser feito sem medo de perder lançamentos manuais.

---

## API do pacote `PKG_FOLHA`

| Rotina | Tipo | O que faz | Faz `COMMIT`? |
|---|---|---|---|
| `calcular_inss(p_base, p_dt_ref)` | function | INSS progressivo para a base, na vigência de `p_dt_ref`. | Não |
| `calcular_irrf(p_bruto, p_inss, p_nr_dependentes, p_dt_ref)` | function | IRRF com dedução mais vantajosa + redutor legal. | Não |
| `calcular_funcionario(p_id_funcionario, p_id_competencia)` | procedure | Gera/atualiza salário base, INSS e IRRF de **um** funcionário. | Não |
| `calcular_competencia(p_ano, p_mes)` | procedure | Calcula todos os ativos com admissão até o último dia do mês. | Sim (rollback no erro) |
| `fechar_competencia(p_ano, p_mes)` | procedure | Move `CALCULADA` → `FECHADA`. | Sim |
| `obter_liquido(p_id_funcionario, p_id_competencia)` | function | Líquido do funcionário na competência (0 se não houver lançamentos). | Não |

Quem chama `calcular_funcionario` decide quando commitar — útil para calcular um lote sob controle da aplicação.

A spec também expõe as exceções nomeadas (`e_competencia_inexistente`, `e_competencia_fechada`, etc.), permitindo tratá-las por nome:

```sql
begin
    pkg_folha.calcular_competencia(2026, 10);
exception
    when pkg_folha.e_competencia_fechada then
        dbms_output.put_line('Competência já fechada.');
end;
/
```

---

## Códigos de erro

| Código | Exceção | Situação |
|---|---|---|
| `-20001` | `e_competencia_inexistente` | Competência não encontrada. |
| `-20002` | `e_competencia_fechada` | Tentativa de calcular/alterar competência fechada. |
| `-20003` | `e_funcionario_inexistente` | Funcionário não encontrado. |
| `-20004` | `e_funcionario_desligado` | Cálculo para funcionário desligado. |
| `-20005` | `e_rubrica_inexistente` | Rubrica obrigatória não cadastrada. |
| `-20006` | `e_competencia_nao_calculada` | Fechamento sem cálculo prévio. |
| `-20007` | `e_tabela_inexistente` | Tabela/parâmetro fiscal sem vigência para a data. |

---

## Como executar

### Pré-requisitos

- Docker e Docker Compose
- Oracle SQLcl (recomendado 26.2 ou superior) — ou qualquer cliente Oracle

### 1. Configurar as variáveis de ambiente

```bash
cp .env.example .env
```

Preencha o `.env`:

```dotenv
ORACLE_PASSWORD=senha_do_sys
APP_USER=folha
APP_USER_PASSWORD=senha_do_schema_folha
```

> O `.env` está no `.gitignore` e **não deve ser commitado**. Só o `.env.example` vai para o repositório.
>
> No `docker-compose.yml` o usuário da aplicação está fixo em `folha`; `APP_USER` no `.env` serve como documentação do padrão.

### 2. Subir o banco

```bash
docker compose up -d
docker compose logs -f oracle
```

O container se chama `oracle-folha`, escuta em `localhost:1522` e cria o schema `FOLHA` (via `APP_USER`) no PDB `FREEPDB1`.

A primeira inicialização demora alguns minutos (criação do banco). Aguarde a mensagem de `DATABASE IS READY TO USE!`.

### 3. Conectar

```bash
sql folha@sua_senha@//localhost:1522/FREEPDB1
```

### 4. Resetar o banco do zero

```bash
docker compose down -v
docker compose up -d
```

> ⚠️ `-v` apaga o volume `oracle-folha` — todos os dados são perdidos.

### Sobre o diretório `sql/`

O `docker-compose.yml` monta `./sql` em `/container-entrypoint-initdb.d`, que o Oracle executa **apenas na primeira inicialização**, quando o volume está vazio.

Na prática, `sql/sql_dev.sql` é um arquivo de **apoio ao desenvolvimento** (consultas e chamadas de teste) e não um script de migração. Se você adicionar scripts nesse diretório, eles precisam ser idempotentes e coerentes com o banco do container.

---

## Carga inicial de dados

O repositório versiona o **schema** e o **código PL/SQL**, mas não os dados de carga. Para calcular qualquer coisa, o banco precisa de:

1. As três rubricas reservadas.
2. Faixas de INSS e IRRF e parâmetros fiscais com vigência para o período.
3. Ao menos um cargo e um funcionário `ATIVO`.
4. A competência aberta.

Carga mínima das rubricas:

```sql
insert into folha.rubrica (codigo, descricao, tipo, natureza, incide_inss, incide_irrf)
values ('001', 'Salario base', 'P', 'FIXA', 'S', 'S');

insert into folha.rubrica (codigo, descricao, tipo, natureza, incide_inss, incide_irrf)
values ('101', 'INSS', 'D', 'CALCULADA', 'N', 'N');

insert into folha.rubrica (codigo, descricao, tipo, natureza, incide_inss, incide_irrf)
values ('102', 'IRRF', 'D', 'CALCULADA', 'N', 'N');

commit;
```

Abertura de competência:

```sql
insert into folha.competencia (ano, mes) values (2026, 10);
commit;
```

As tabelas `TABELA_INSS`, `TABELA_IRRF` e `PARAMETRO_FISCAL` devem ser populadas com os valores oficiais de cada vigência (`DT_VIGENCIA_INI` = primeiro dia de validade da tabela).

---

## Exemplo de uso

```sql
set serveroutput on

-- 1) Garantir que a competência está aberta
update folha.competencia
   set situacao = 'ABERTA'
 where ano = 2026 and mes = 10;
commit;

-- 2) Calcular a folha inteira
begin
    pkg_folha.calcular_competencia(2026, 10);
end;
/

-- 3) Consultar o holerite
select f.nome,
       h.total_proventos,
       h.total_descontos,
       h.liquido
  from folha.vw_holerite h
  join folha.funcionario f on f.id_funcionario = h.id_funcionario
 order by f.nome;
```

Conferência das funções fiscais isoladamente (valores de referência usados no desenvolvimento, em `sql/sql_dev.sql`):

```sql
select pkg_folha.calcular_inss(7200, date '2026-10-01') from dual;                  -- 809.51
select pkg_folha.calcular_irrf(7200, 809.51, 2, date '2026-10-01') from dual;       -- 724.40
select pkg_folha.calcular_inss(20000, date '2026-10-01') from dual;                 -- 988.09 (teto)
```

E, por último, o fechamento:

```sql
begin
    pkg_folha.fechar_competencia(2026, 10);
end;
/
```

---

## Fluxo de desenvolvimento com SQLcl Projects

Os objetos em `src/database/folha/` são gerados pelo SQLcl a partir do banco. O ciclo normal é:

```sql
-- Conectado ao banco de desenvolvimento
project export        -- banco -> src/ (gera os arquivos .sql versionados)
project verify        -- valida a estrutura do projeto
project stage         -- gera changelogs Liquibase em dist/, por branch
project gen-artifact  -- gera o pacote de deploy em artifact/
project deploy -file artifact/<arquivo>.zip   -- aplica o artefato em outro banco
project release       -- promove o conjunto de trabalho atual para uma release
```

Regras práticas:

- **Nunca edite os arquivos de `src/` manualmente** esperando que o SQLcl preserve a alteração: o próximo `project export` sobrescreve. Alterações estruturais devem ser feitas no banco e exportadas.
- Verifique o diff antes de commitar — o rodapé `sqlcl_snapshot` muda quando o objeto muda.
- `main` é branch protegida (`git.protectedBranches` em `.dbtools/project.config.json`): trabalhe em branches e abra Pull Request.

---

## Limitações e próximos passos

O que o projeto **já faz**: cálculo de salário base, INSS, IRRF com redutor e holerite, com controle de competência e proteção dos lançamentos manuais.

O que **ainda não** está implementado:

- **Seed versionado** das tabelas fiscais e das rubricas (hoje é carga manual).
- **Proventos além do salário base** (horas extras, adicional noturno, comissões, faltas, férias, 13º). O motor já está preparado — basta cadastrar a rubrica com `INCIDE_INSS`/`INCIDE_IRRF` corretos e lançar o valor antes do cálculo.
- **FGTS, férias, 13º salário e rescisão**.
- **Proporcionalidade** por admissão/demissão no meio do mês (hoje o funcionário entra no cálculo se foi admitido até o último dia da competência).
- **Testes automatizados** (utPLSQL ou similar).
- **Camada de API/aplicação** — hoje o consumo é via SQL direto.

---

## Manutenção

- Repositório: <https://github.com/RianCAndrade/plsql-payroll>
- Responsável: Rian Andrade ([@RianCAndrade](https://github.com/RianCAndrade))
- Branch padrão: `main` (protegida)
