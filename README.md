1\. Estruturas de Dados
-----------------------

Para gerir o estado do jogo de forma eficiente e cumprir os requisitos de memória, foram utilizadas as seguintes estruturas:

### Representação do Tabuleiro

    
*   **Dicionário de Defesa:** Uma lista de registos (records) ou mapas onde cada entrada representa um barco da frota. Cada barco contém:
    
    *   **Nome:** Identificador (ex: "fragata").
        
    *   **Células Vivas:** Uma lista de coordenadas (int \* int) que ainda não foram atingidas.
        
    *   **Estado:** Booleano indicando se o barco já foi afundado.
        

### Estado da IA

*   **Fila de Alvos (target\_queue):** Uma lista de coordenadas prioritárias para o **Modo Caça**.
    
*   **Memória de Disparos:** Um conjunto (Set) ou lista de coordenadas já atacadas para evitar tiros repetidos.
    

2\. Compilação e Execução
-------------------------

O agente foi desenvolvido para ser independente de mensagens de versão ou metadados da linguagem9.

### Pré-requisitos

*   OCaml compiler (ocamlc ou ocamlopt).
    

### Instruções

1.  Bashocamlc -o agente\_batalha\_naval agente.ml
    
2.  Executar: O agente comunica via stdin/stdout. Pode ser testado manualmente ou via script:
Bash./agente\_batalha\_naval

*Nota: O agente aguarda comandos como init N, random ou tiro L C. 
    

3\. Estratégia de IA
--------------------

A inteligência do agente divide-se em três estados principais para otimizar a destruição da frota adversária:

### Modo Busca (Default)

Enquanto não encontra barcos, o agente dispara em células desconhecidas seguindo um padrão de "paridade" (como um tabuleiro de xadrez). Isto reduz o número de tiros necessários para encontrar barcos lineares, que ocupam pelo menos 2 células.


### Modo "Caça" (Requisito Mínimo)

Ao receber a resposta tiro , o agente ativa este modo:

*   Filtra células fora do tabuleiro ou já atacadas.
    

### Modo "Destruição" (Requisito Essencial)

Se o agente obtiver dois acertos num barco (ex: duas vezes tiro fragata), a IA analisa a geometria:

1.  **Inferência de Orientação:** Se as linhas são iguais, o barco é **horizontal**; se as colunas são iguais, é **vertical**.
    
2.  **Foco Linear:** O agente descarta alvos adjacentes que saiam dessa linha/coluna e foca-se em disparar nas extremidades dos acertos conhecidos até receber a mensagem afundado.
    

### Otimização com afundado

Ao afundar um barco, o agente utiliza a regra de posicionamento estrito:

*   **Zona de Segurança:** Como os barcos não se podem tocar (nem nas diagonais), o agente marca automaticamente todas as células adjacentes ao barco afundado como Agua.
    
*   Isto evita o desperdício de turnos a atacar células que obrigatoriamente estão vazias.

**Ação do Usuário/AdversárioReação do Agente**Envia init 10

##Resumo do fluxo de trabalho

| Ação do Usuário / Adversário | Reação do Agente |
|-----------------------------|------------------|
| Envia `init 10`              | Redimensiona estruturas internas para 10 × 10. |
| Envia `random`               | Posiciona 8 barcos sem que se toquem. |
| Envia `vou eu`               | Escolhe uma coordenada e imprime `tiro L C`. |
| Envia `tiro 0 0`             | Verifica se algo foi atingido e responde (ex: `agua`). |
