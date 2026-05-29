# Controlador de Cache RISC-V — Relatório Final

**Disciplina:** Arquitetura de Computadores III 

**Equipe:** Bruno Menezes Rodrigues Oliveira Vaz · João Costa Calazans · João Pedro Torres · Lucas Carneiro Nassau Malta · Pedro Henrique Debs Rabelo 

**Data:** Maio de 2026

---

## Sumário

1. [Introdução](#1-introdução)
2. [Desenvolvimento](#2-desenvolvimento)
   - 2.1 [Definições Arquiteturais e Estruturas de Interface](#21-definições-arquiteturais-e-estruturas-de-interface-cache_defsv)
   - 2.2 [Módulo de Tags — dm_cache_tag](#22-módulo-de-tags--dm_cache_tag)
   - 2.3 [Módulo de Dados — dm_cache_data](#23-módulo-de-dados--dm_cache_data)
   - 2.4 [Máquina de Estados Finitos (FSM)](#24-máquina-de-estados-finitos-fsm)
   - 2.5 [Integração Top-Level e Modelo de Memória](#25-integração-top-level-e-modelo-de-memória)
   - 2.6 [Testbenches e Validação Automatizada](#26-testbenches-e-validação-automatizada)
3. [Resultados](#3-resultados)
4. [Conclusão](#4-conclusão)
5. [Uso de IA](#5-uso-de-ia)

---

## 1. Introdução

A disparidade crescente entre a velocidade de processamento das CPUs modernas e a latência de acesso à memória principal constitui um dos gargalos fundamentais na arquitetura de computadores. Enquanto processadores RISC-V de alto desempenho executam instruções em poucos nanosegundos, acessos à DRAM podem exigir dezenas a centenas de ciclos de clock, criando uma diferença de desempenho que se agrava a cada nova geração de processadores — fenômeno descrito na literatura como o *Memory Wall*.

A solução consagrada para esse problema é a utilização de **memórias cache**: pequenas memórias SRAM de alta velocidade posicionadas entre o processador e a memória principal, explorando os princípios de **localidade temporal** (dados acessados recentemente tendem a ser acessados novamente) e **localidade espacial** (dados próximos na memória tendem a ser acessados em sequência). Esses princípios, formalizados por Hennessy e Patterson, permitem que a cache atenda a grande maioria dos acessos à memória sem recorrer à DRAM, reduzindo drasticamente a latência média de acesso.

O presente trabalho implementa em **SystemVerilog** um **controlador de cache direct-mapped com política Write-Back**, seguindo a especificação apresentada na Seção 5.12 do livro *Computer Organization and Design: The Hardware/Software Interface — RISC-V Edition* (Patterson & Hennessy). A implementação compreende:

- **Definições arquiteturais** centralizadas em um package (`cache_def.sv`), incluindo parâmetros geométricos e estruturas tipadas para as interfaces CPU↔Cache e Cache↔Memória;
- **Módulos de armazenamento** para tags (`dm_cache_tag`) e dados (`dm_cache_data`), com política de temporização rigorosamente especificada;
- **Máquina de estados finitos** (FSM) com quatro estados (Idle, Compare Tag, Allocate, Write-Back) para controlar hits, misses, evicções e preenchimentos;
- **Testbenches automatizados** com verificação autônoma (self-checking) para validação funcional abrangente.

A cache possui **1024 blocos** com linhas de **128 bits** (4 palavras de 32 bits cada), mapeamento direto e tags de **18 bits**, totalizando **16 KB** de capacidade de dados. A decomposição do endereço de 32 bits segue a estrutura:

```
 31              14 | 13          4 | 3    2 | 1  0
 ──────────────────┼──────────────┼────────┼──────
     TAG (18)      |  INDEX (10)  | OFFSET | BYTE
                   |              |  (2)   | (2)
```

O relatório está organizado de forma a refletir a divisão de trabalho adotada pela equipe, com cada seção do Desenvolvimento documentando as decisões de projeto de um membro específico.

---

## 2. Desenvolvimento

### 2.1. Definições Arquiteturais e Estruturas de Interface (`cache_def.sv`)

A primeira decisão de projeto foi centralizar todos os parâmetros arquiteturais e tipos de dados em um único package SystemVerilog (`cache_def`), importado por todos os módulos do sistema. Essa abordagem garante consistência em larguras de campos e elimina a necessidade de redefinir constantes em cada módulo.

#### 2.1.1. Parâmetros Geométricos

Os parâmetros fundamentais da cache são derivados da geometria escolhida:

| Parâmetro           | Valor  | Justificativa                                    |
|:---------------------|:------:|:-------------------------------------------------|
| `NUM_BLOCKS`         | 1024   | Compromisso entre capacidade e complexidade      |
| `CACHE_LINE_WIDTH`   | 128    | 4 palavras × 32 bits — explora localidade espacial |
| `TAG_WIDTH`          | 18     | 32 − 10 (index) − 4 (offset + byte) = 18 bits   |
| `INDEX_WIDTH`        | 10     | log₂(1024) = 10 bits                             |
| `OFFSET_WIDTH`       | 2      | log₂(4 palavras) = 2 bits                        |

A escolha de 1024 blocos com linhas de 4 palavras resulta em uma cache de 16 KB — dimensão compatível com caches L1 de processadores embarcados RISC-V e suficiente para demonstrar todos os cenários de hit, miss e evicção.

#### 2.1.2. Estruturas de Interface

As interfaces entre os componentes do sistema foram modeladas como `struct packed` do SystemVerilog, agrupando logicamente os sinais de cada barramento:

**CPU → Cache (`cpu_req_type`):**
Encapsula o endereço de acesso (32 bits), dado de escrita (32 bits), sinal de leitura/escrita (`rw`) e sinalização de requisição válida (`valid`). O agrupamento em struct permite que a FSM manipule todos os sinais de requisição como uma unidade atômica.

**Cache → CPU (`cpu_result_type`):**
Retorna o dado lido (32 bits) e o sinal `ready` que indica a conclusão da operação — implementando o handshake necessário para que a CPU saiba quando pode consumir o resultado.

**Cache → Memória (`mem_req_type`):**
Similar à interface da CPU, mas opera no nível de **linha completa** (128 bits) para transferências de write-back (evicção) e allocate (preenchimento). A transferência de linhas inteiras, em vez de palavras individuais, maximiza a utilização da largura de banda do barramento de memória.

**Memória → Cache (`mem_data_type`):**
Retorna a linha completa (128 bits) recebida da memória principal durante uma operação de allocate, junto com o sinal `ready` de confirmação.

---

### 2.2. Módulo de Tags — `dm_cache_tag`

O módulo `dm_cache_tag` constitui o componente de controle central do subsistema de cache, sendo responsável por armazenar as **tags de 18 bits** e os **bits de status** (valid, dirty) para cada uma das 1024 linhas.

#### 2.2.1. Estrutura de Armazenamento

Internamente, o módulo utiliza um array de structs `cache_tag_type`:

```systemverilog
cache_tag_type tag_mem [0:NUM_BLOCKS-1];  // 1024 entradas × 20 bits
```

Cada entrada ocupa 20 bits (1 valid + 1 dirty + 18 tag) e é do tipo `struct packed`, permitindo atribuições atômicas como:

```systemverilog
tag_mem[index] <= '{valid: 1'b1, dirty: 1'b0, tag: addr[31:14]};
```

#### 2.2.2. Política de Temporização — Leitura Combinacional

A decisão mais significativa neste módulo é a utilização de **leitura combinacional** (assíncrona):

```systemverilog
assign tag_out = tag_mem[index];
```

Essa escolha é motivada pelo funcionamento da FSM: quando o controlador entra no estado `COMPARE_TAG`, ele precisa avaliar imediatamente se há hit ou miss (comparando `tag_out` com o campo tag do endereço e verificando `valid_out`). Uma leitura síncrona (registrada) introduziria um ciclo adicional de latência, exigindo um estado intermediário na FSM apenas para aguardar a disponibilidade dos dados do tag array, o que degradaria o desempenho de leitura em caso de hit.

A implicação direta é que, em uma implementação FPGA, o array de tags será inferido como **Distributed RAM** (LUT-RAM) em vez de Block RAM (BRAM), uma vez que BRAMs possuem leitura síncrona obrigatória na maioria das famílias FPGA (Xilinx, Intel/Altera). Para o escopo deste projeto (simulação funcional com Icarus Verilog), essa distinção não impacta a validação.

#### 2.2.3. Política de Temporização — Escrita Síncrona com Reset Assíncrono

A escrita é rigorosamente síncrona, ocorrendo **somente na borda positiva do clock** e **condicionada ao sinal `we`**:

```systemverilog
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        for (int i = 0; i < NUM_BLOCKS; i++)
            tag_mem[i] <= '{valid: 1'b0, dirty: 1'b0, tag: '0};
    end else if (we) begin
        tag_mem[index] <= tag_in;
    end
end
```

O **reset assíncrono** garante que a cache inicie em estado "frio" (*cold start*) — todos os bits de validade zerados — independentemente da fase do clock no momento da ativação do reset. Os bits de dirty e tag também são limpos para evitar valores indeterminados (`x`) em simulação, embora em hardware real apenas o bit `valid` necessite de inicialização.

A gating por `we` é essencial para evitar escritas espúrias: sem ela, qualquer borda de clock corromperia a entrada endereçada por `index`, mesmo quando o módulo não está sendo utilizado pelo controlador.

---

### 2.3. Módulo de Dados — `dm_cache_data`

O módulo `dm_cache_data` armazena as **linhas de cache de 128 bits** e opera como uma memória endereçável por índice, sem conhecimento da semântica de hit/miss.

#### 2.3.1. Estrutura de Armazenamento

```systemverilog
cache_data_type data_mem [0:NUM_BLOCKS-1];  // 1024 linhas × 128 bits = 16 KB
```

O tipo `cache_data_type` é definido no package como `logic [127:0]`, representando 4 palavras de 32 bits concatenadas.

#### 2.3.2. Decisão de Projeto: Operação em Nível de Linha

Uma decisão fundamental neste módulo é operar exclusivamente no **nível de linha completa** (128 bits), em vez de expor acesso direto a palavras individuais. A seleção de uma palavra específica dentro da linha é delegada ao controlador FSM, que utiliza o campo `offset[3:2]` do endereço como seletor de um multiplexador:

```
Offset = 2'b00 → data_out[31:0]    (Palavra 0)
Offset = 2'b01 → data_out[63:32]   (Palavra 1)
Offset = 2'b10 → data_out[95:64]   (Palavra 2)
Offset = 2'b11 → data_out[127:96]  (Palavra 3)
```

Essa separação de responsabilidades traz duas vantagens:
1. **Simplicidade do módulo**: O data array torna-se uma memória genérica sem lógica de controle, facilitando a verificação e reutilização.
2. **Flexibilidade para o controlador**: A FSM pode decidir entre gravar uma linha completa (durante allocate) ou apenas uma palavra (durante write hit, via read-modify-write na linha) sem exigir múltiplas portas de escrita no data array.

#### 2.3.3. Política de Temporização

A leitura é **combinacional**, pelos mesmos motivos apresentados para o tag array (resolução de hit no mesmo ciclo):

```systemverilog
assign data_out = data_mem[index];
```

A escrita é **síncrona** e condicionada a `we`:

```systemverilog
always_ff @(posedge clk) begin
    if (we)
        data_mem[index] <= data_in;
end
```

#### 2.3.4. Decisão de Projeto: Ausência de Reset

Diferentemente do tag array, o módulo de dados **não possui sinal de reset**. Essa decisão é justificada pelo fato de que a validade dos dados é controlada exclusivamente pelo bit `valid` no tag array. Dados em posições cujo `valid = 0` nunca são utilizados pela FSM, tornando sua inicialização desnecessária. Essa abordagem:

- Reduz a complexidade do circuito de reset (não há necessidade de zerar 16 KB de dados);
- Diminui o tempo de simulação do reset (inicializar 1024 × 128 bits levaria ciclos significativos);
- É prática padrão em implementações de cache reais.

---

<!-- TODO (Responsável pela FSM — Subtask T3):
Documentar nesta seção as decisões de projeto da máquina de estados finitos.
Incluir:
  - Justificativa para o número de estados (Idle, Compare Tag, Allocate, Write-Back)
  - Diagrama de transição de estados com as condições de transição
  - Mapa de sinais de controle por estado (quais sinais são assertados em cada estado)
  - Protocolo de transferência word-by-word para Write-Back e Allocate
  - Detalhamento da lógica de read-modify-write para write hits
  - Decisões sobre a implementação: always_ff para transições, always_comb para saídas
  - Quaisquer dificuldades encontradas durante a implementação
-->

### 2.4. Máquina de Estados Finitos (FSM)

*Seção a ser preenchida pelo responsável da Subtask T3.*

---

<!-- TODO (Responsável pela Integração — Subtask T4):
Documentar nesta seção as decisões de projeto da integração top-level.
Incluir:
  - Estrutura do módulo cache_top.sv e como conecta os submódulos
  - Modificações realizadas no modelo de memória principal (mem_main_model.sv)
  - Atualizações no Makefile e targets de compilação
  - Dificuldades de integração encontradas (ex: sinais desconectados, incompatibilidades
    de largura de barramento, problemas de timing entre módulos)
  - Decisões sobre pré-inicialização da memória ($readmemh) para testes determinísticos
-->

### 2.5. Integração Top-Level e Modelo de Memória

*Seção a ser preenchida pelo responsável da Subtask T4.*

---

<!-- TODO (Responsável pelos Testbenches — Subtask T5):
Documentar nesta seção a estratégia de validação e os testbenches implementados.
Incluir:
  - Metodologia de self-checking (tasks cpu_read, cpu_write_op, check)
  - Listagem das 4 categorias de teste: Read Path, Write Path, Replacement/Write-Back, Edge Cases
  - Para cada cenário de teste: descrição, estímulos aplicados, resultado esperado
  - Estratégia de cobertura funcional (quais cenários garantem cobertura completa)
  - Dificuldades encontradas nos testes (ex: timing de handshake, race conditions)
-->

### 2.6. Testbenches e Validação Automatizada

*Seção a ser preenchida pelo responsável da Subtask T5.*

---

## 3. Resultados

<!-- TODO (Todos os membros):
Esta seção deve conter os resultados da validação funcional do sistema completo.
Estrutura sugerida:

3.1. Resultados dos Testes Unitários
  - Tabela resumo com PASS/FAIL para cada teste do cache_tag_tb e cache_data_tb
  - Capturas de tela (waveforms) dos testes TT-02 e TD-02 demonstrando a
    temporização de escrita síncrona e leitura combinacional

3.2. Resultados dos Testes de FSM
  - Tabela resumo com PASS/FAIL para TF-01 a TF-06
  - Waveform mostrando uma transição completa: IDLE → COMPARE_TAG → ALLOCATE → COMPARE_TAG → IDLE
  - Waveform mostrando evicção: IDLE → COMPARE_TAG → WRITE_BACK → ALLOCATE → COMPARE_TAG → IDLE

3.3. Resultados dos Testes de Sistema
  - Tabela consolidada com todos os 17 testes (TS-A01 a TS-D05)
  - Saída do console mostrando a contagem final de PASS/FAIL
  - Waveforms representativos para cenários críticos:
    * TS-C02 (dirty replacement com write-back)
    * TS-D02 (reset mid-operation)
    * TS-D05 (write → evict → re-read)

3.4. Análise de Desempenho
  - Contagem de ciclos de clock para cada tipo de operação (read hit, read miss, write hit, etc.)
  - Comparação com os valores esperados da teoria (Seção 5.12)

Para inserir waveforms como imagem, use:
  ![Descrição do waveform](nome_do_arquivo.png)
-->

*Seção a ser preenchida após a conclusão de todas as subtasks.*

---

## 4. Conclusão

<!-- TODO (Todos os membros — redigir colaborativamente):
Incluir:
  - Resumo do que foi implementado e validado
  - Comparação entre o projeto final e a especificação da Seção 5.12
  - Principais desafios técnicos enfrentados e como foram superados
  - Lições aprendidas sobre design de hardware digital e hierarquia de memória
  - Possíveis extensões: cache set-associativa, write-through, suporte a burst,
    integração com um core RISC-V real, etc.
-->

*Seção a ser preenchida ao final do projeto.*

---

## 5. Uso de IA

<!-- TODO (Todos os membros):
Documentar de forma transparente como ferramentas de IA foram utilizadas no projeto.
Para cada uso, incluir:
  - Ferramenta utilizada (ex: ChatGPT, GitHub Copilot, Gemini, Claude, etc.)
  - Contexto de uso (ex: geração de scaffold inicial, debugging, revisão de código,
    geração de testbenches, redação de documentação)
  - O que foi gerado pela IA vs. o que foi desenvolvido/modificado manualmente
  - Avaliação crítica: a IA acertou/errou? O que precisou ser corrigido?

Exemplo de formato:
  | Ferramenta | Contexto                          | Contribuição da IA                | Modificações Manuais           |
  |:-----------|:----------------------------------|:----------------------------------|:-------------------------------|
  | Gemini     | Scaffold do work_breakdown.md     | Estrutura inicial do WBS          | Ajuste de parâmetros e revisão |
-->

*Seção a ser preenchida por cada membro individualmente.*

---

*Relatório gerado como parte do Trabalho Prático 1 — Controlador de Cache RISC-V.*
