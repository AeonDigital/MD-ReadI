Pendencias e falhas dos testes Bats
================================================================

## SITUACAO GERAL

- Suite agregada: 289 testes; 274 passaram e 15 falharam.


- As 15 falhas estao concentradas em seis funcoes descritas abaixo.


- Este documento registra o comportamento observado nos testes. As expectativas dos
  testes foram mantidas para nao ocultar divergencias; cabe ao responsavel pelo projeto
  decidir se a implementacao deve mudar ou se algum comportamento esperado precisa
  ser revisto.


- Os testes ficam em `tests/unit/`.




## `SHELL_MD_READI_CANONIZE_HEADERS`

**Implementacao:**

[src/readi/canonize/03_headers.sh](src/readi/canonize/03_headers.sh)  
**Teste:**

[tests/unit/readi/canonize/03_headers.bats](tests/unit/readi/canonize/03_headers.bats)  
**Resultado:** ✅ **25/25 passaram — RESOLVIDO**



### Status: Corrigido ✅

A funcao foi corrigida para preservar separadores horizontais que antecedem diretamente
titulos ATX. Todos os 25 testes, incluindo o teste critico "ATX immediately after
a separator flushes that separator" (teste 19), agora passam sem problemas.

**Alteracao implementada:** Adicionada preservacao de `pending_separator_line` antes
do processamento de titulos ATX, garantindo que separadores normalizados nao sejam
descartados quando precedem imediatamente um titulo ATX.

**Data da resolucao:** 12/11/2026




## `_SHELL_MD_READI_CANONIZE_PROSE_SAFETY`

**Implementacao:**

[src/readi/canonize/05_content_lines.sh](src/readi/canonize/05_content_lines.sh)  
**Teste:**

[tests/unit/readi/canonize/05_content_lines_prose_safety.bats](tests/unit/readi/canonize/05_content_lines_prose_safety.bats)  
**Resultado:** ✅ **17/17 passaram — RESOLVIDO**



### Status: Corrigido ✅

A funcao foi corrigida para converter iterativamente todos os simbolos repetidos
para seus equivalentes Unicode, mesmo quando compartilham espacos entre eles.

**Alteracao implementada:** Conversao iterativa de todos os simbolos em cadeias,
garantindo que multiplas ocorrencias consecutivas de hifens (`- -`), sinais de mais
(`+ +`) e asteriscos (`* *`) sejam todos convertidos para seus equivalentes Unicode
(—, ＋, ★).

**Testes validados:** Todos os 17 testes passam, incluindo:

- Teste 8: Repeated hyphens sharing a boundary are all converted
- Teste 9: Repeated plus signs sharing a boundary are all converted
- Teste 10: Repeated asterisks sharing a boundary are all converted

**Data da resolucao:** 12/11/2026




## `SHELL_MD_READI_CANONIZE_CONTENT_LINES`

**Implementacao:**

[src/readi/canonize/05_content_lines.sh](src/readi/canonize/05_content_lines.sh)  
**Teste:**

[tests/unit/readi/canonize/05_content_lines.bats](tests/unit/readi/canonize/05_content_lines.bats)  
**Resultado:** 29/30 passaram; 1 falhou.



### Conteudo dentro de HTML bruto e juntado e transformado

O comentario da funcao diz que blocos HTML brutos devem ser protegidos contra a juncao
de linhas e a transformacao do texto. O teste verifica isso com:

```html
<div>
alpha + beta
second
</div>
```

Esperado: preservar o conteudo e as quebras de linha exatamente como recebido.

Resultado atual:

```html
<div>
alpha ＋ beta second
</div>
```

As linhas de texto foram juntadas e o `+` foi convertido para `＋`. Assim, o conteudo
que deveria permanecer literal dentro do bloco HTML e alterado.

**Decisao pendente:** o conteudo entre tags HTML deve ser preservado literalmente,
como descreve o comentario da funcao?




## `SHELL_MD_READI_CANONIZE_INDENTATION_BLOCK`

**Implementacao:**

[src/readi/canonize/07_indentation_block.sh](src/readi/canonize/07_indentation_block.sh)  
**Teste:**

[tests/unit/readi/canonize/07_indentation_block.bats](tests/unit/readi/canonize/07_indentation_block.bats)  
**Resultado:** 16/22 passaram; 6 falharam.



### 1. Bloco pre-formatado e escrito em stdout, nao no registrador global

Para um bloco como `    code`, os testes esperam que a funcao grave o texto em `SHELL_MD_READI_RESULT_CANONIZE_INDENTATI
ON_BLOCK` e nao produza saida direta. A funcao usa `printf` para escrever o bloco
em stdout e retorna sem preencher o registrador global.

Isso causa duas falhas: o conteudo esperado nao aparece no registrador e a funcao
produz saida inesperada em stdout.



### 2. Entrada vazia tambem segue o caminho de bloco pre-formatado

Para entrada vazia, os testes esperam uma quebra de linha no registrador global e
nenhuma saida em stdout. O caminho atual deixa o registrador vazio e imprime uma
quebra de linha em stdout. O argumento omitido apresenta o mesmo problema.

As verificacoes de entrada vazia e omitida respondem por tres falhas: valor esperado
no registrador, ausencia de saida no canal e equivalencia do argumento omitido com
entrada vazia.



### 3. O mapeamento de niveis depende do `IFS` do chamador

Um teste define `IFS=:` e espera que o mapeamento de indentacao continue igual. A
funcao monta os niveis separados por espacos e os le em um array usando o `IFS` vigente.
Com `IFS=:` os niveis nao sao separados como esperado, e as linhas indentadas deixam
de receber os tabs de nivel correspondentes.

**Decisoes pendentes:** blocos e entradas vazias devem sempre usar o registrador
global? O resultado deve ser independente do `IFS` recebido do chamador?




## `SHELL_MD_READI_CANONIZE_INDENTATION`

**Implementacao:**

[src/readi/canonize/08_indentation.sh](src/readi/canonize/08_indentation.sh)  
**Teste:**

[tests/unit/readi/canonize/08_indentation.bats](tests/unit/readi/canonize/08_indentation.bats)  
**Resultado:** 11/13 passaram; 2 falharam.



### 1. Uma linha em branco extra e acrescentada entre blocos

A suite testa dois blocos separados por uma linha vazia. O helper ja devolve o primeiro
bloco terminado por `\n`; ao descarrega-lo, a funcao acrescenta outra quebra e tambem
preserva a linha vazia da entrada. O resultado tem uma linha em branco a mais do
que o esperado.

Exemplo simplificado:

```text
Entrada:
root
  child

second
    child

Esperado:
root
	child

second
	child

Resultado atual: uma linha vazia adicional entre os dois blocos.
```



### 2. Bloco pre-formatado recebido do helper nao chega ao resultado final

O helper de bloco pre-formatado escreve o conteudo em stdout, em vez de coloca-lo
no registrador global que esta funcao consome. Por isso, o texto aparece no canal
de saida e nao e incorporado corretamente em `SHELL_MD_READI_RESULT_CANONIZE_INDENTATION`.

**Decisoes pendentes:** deve haver apenas uma linha vazia entre blocos? O helper
deve retornar seu conteudo pelo registrador global, sem escrever em stdout?




## `SHELL_MD_READI_FORMAT`

**Implementacao:** [src/readi/format.sh](src/readi/format.sh)  
**Teste:**

[tests/unit/readi/format/05_format.bats](tests/unit/readi/format/05_format.bats)  
**Resultado:** 11/12 passaram; 1 falhou.



### Documento vazio causa erro ao remover o ultimo caractere

Com documento vazio, `output_buffer` permanece vazio. Ao final, a funcao avalia `${output_buffer:0:
-1}` para remover a ultima quebra de linha. Como o buffer nao tem conteudo, o Bash
emite `substring expression < 0` (linha 378 da versao testada), e a formatacao nao
termina pelo caminho esperado.

**Decisao pendente:** documento vazio deve resultar em string vazia sem erro?




## `SHELL_MD_READI`

**Implementacao:** [src/readi/main.sh](src/readi/main.sh)  
**Teste:** [tests/unit/readi/main.bats](tests/unit/readi/main.bats)  
**Resultado:** 15/17 passaram; 2 falharam.



### Falhas do processador de arquivo sao reportadas como sucesso

Os testes substituem `shell_md_readi_process_file` por um mock que retorna status
`1` e verificam tanto a execucao de um arquivo quanto a de um diretorio com arquivo
Markdown.

Nos dois casos, `shell_md_readi` retorna `0` mesmo depois da falha do processador.
A funcao nao propaga o status de `shell_md_readi_process_file` e nao apresenta diagnostico
de erro, fazendo o chamador acreditar que o processamento foi bem-sucedido.

**Decisao pendente:** falhas do processador devem ser propagadas como falha de `shell_md_readi`?




## PROBLEMA OBSERVADO, MAS NAO CONTADO ENTRE AS 16 FALHAS

### `shell_md_readi_canonize_characters`: falha de `tr` nao resulta em status de erro

**Implementacao:**

[src/readi/canonize/01_characters.sh](src/readi/canonize/01_characters.sh)  
**Teste:**
[tests/unit/readi/canonize/01_characters.bats](tests/unit/readi/canonize/01_characters.bats)

O teste simula `tr` retornando status `42`, com diagnostico em stderr e saida parcial.
A funcao preserva o diagnostico e o resultado parcial, mas retorna sucesso (`0`).
O teste atual espera esse comportamento e, portanto, passa; ele nao esta incluido
nas 16 falhas agregadas.

**Decisao pendente:** a falha de `tr` deve ser propagada como erro ou o resultado
parcial com status de sucesso e intencional?




## COMPORTAMENTOS REGISTRADOS, MAS NAO CLASSIFICADOS COMO FALHAS PENDENTES

- O parser registra o comportamento atual de descartar estado de bloco de codigo
  nao fechado no fim da entrada. Esse comportamento foi aceito anteriormente para
  a suite.
- A canonizacao de blockquotes reduz marcadores repetidos (`>>`) a um unico `>`.
  A suite dessa funcao passa integralmente e registra o comportamento atual.