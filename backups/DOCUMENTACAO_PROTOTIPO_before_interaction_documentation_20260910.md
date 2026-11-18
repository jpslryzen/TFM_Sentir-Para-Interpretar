# Documentação Técnica do Protótipo

Última atualização: 18/08/2026  
Ficheiro principal: `UserInterface_bHaptics_processing.pde`  
Autor/design: © 2026 João Lopes. Todos os direitos reservados.

## 1. Visão geral

O protótipo é uma interface desenvolvida em Processing para apoiar a aprendizagem humana da comunicação canídea através de atividades multissensoriais. A experiência combina estímulos visuais, sonoros e táteis, procurando testar a hipótese de que a multissensorialidade melhora a aprendizagem humana da comunicação canina.

O sistema trabalha com quatro atividades principais:

- Atividade 1: identificação de momentos relevantes.
- Atividade 2: construção de relação comunicativa.
- Atividade 3: interpretação de rosnados em contexto.
- Atividade 4: interpretação de sinais de desconforto através de observação, marcação e feedback.

## 2. Estrutura técnica

### 2.1. Ambiente e renderização

- Linguagem/ambiente: Processing.
- Renderização: `P2D`.
- Modo de janela: `fullScreen(P2D)`.
- Resolução base de desenho: `1920x1080`, ajustada internamente por `TARGET_SCALE = 1.35`.
- Sistema de escala: a interface é desenhada numa base lógica (`baseW`, `baseH`) e depois escalada para o ecrã físico.
- Fonte principal: `common/Inter-Regular.ttf`.
- Antialiasing: `smooth(4)`.
- Densidade de píxeis: baseada em `displayDensity()`.

### 2.2. Paleta visual

As cores principais são definidas no início do ficheiro:

- Fundo: `bg = color(5, 8, 16)`.
- Cartões: `card = color(13, 19, 33)`.
- Cartões secundários: `cardAlt = color(19, 27, 45)`.
- Roxo principal: `purple = color(105, 68, 245)`.
- Roxo de destaque: `purpleText = color(142, 112, 255)`.
- Texto principal: `white = color(255)`.
- Texto secundário: `muted = color(168, 178, 198)`.

### 2.3. Tipografia

Os tamanhos seguem uma hierarquia baseada em múltiplos de 8 antes da escala:

- `TYPE_HERO`: título principal.
- `TYPE_TITLE`: títulos fortes.
- `TYPE_SECTION`: títulos de secção.
- `TYPE_SUBHEADING`: subtítulos.
- `TYPE_BODY`: corpo de texto.
- `TYPE_LABEL`: labels e instruções.
- `TYPE_CAPTION`: legendas e texto auxiliar.

### 2.4. Estados principais da aplicação

A navegação é controlada sobretudo por `appState`, `phase` e `activity3Step`.

Estados globais:

- `APP_STATE_LOADING = -1`: ecrã inicial de loading.
- `appState = 0`: menu principal.
- `appState = 1`: Atividade 4 em modo guiado.
- `appState = 2`: revisão isolada.
- `appState = 3`: Atividade 1.
- `appState = 4`: placeholder.
- `appState = 5`: Atividade 2.
- `appState = 6`: Atividade 3.

Na Atividade 4:

- `phase = 1`: observação.
- `phase = 2`: tarefa interpretativa.
- `phase = 3`: feedback.

Na Atividade 3:

- `activity3Step = 0`: observação do vídeo.
- `activity3Step = 1`: escolha do rosnado.
- `activity3Step = 2`: justificação com pistas sonoras e comportamento provável.
- `activity3Step = 3`: feedback.

## 3. Organização de ficheiros

Os recursos estão organizados dentro da pasta `data`, separados por atividade.

Exemplos:

- `data/activity1/slides/`
- `data/activity2/slides/`
- `data/activity3/slides/`
- `data/activity3/videos/`
- `data/activity3/sons rosnado/`
- `data/activity4/videos/`

Na Atividade 3, os sons dos rosnados são pesquisados em pastas descritivas dentro de:

`data/activity3/sons rosnado/`

O código deteta ficheiros de áudio por extensão e por palavras-chave no nome. O ficheiro correto deve conter a palavra `correto` no nome.

## 4. Loading e preparação de vídeo

O protótipo usa um ecrã de loading inicial para preparar os recursos sem bloquear a entrada direta no menu.

Processo técnico:

- Os vídeos são copiados para uma pasta temporária.
- Os objetos `Movie` são criados progressivamente no thread principal.
- Há um processo de warmup para confirmar que os vídeos conseguem apresentar frames.
- A interface só passa do loading para o menu quando os recursos essenciais estão prontos.

Parâmetros relevantes:

- `VIDEO_LOADING_START_DELAY_MS = 1500`
- `STARTUP_LOADING_MIN_VISIBLE_MS = 2400`
- `VIDEO_WARMUP_MIN_MS = 320`
- `VIDEO_WARMUP_TIMEOUT_MS = 4000`

## 5. Som, rosnados e waveform

Na Atividade 3, os rosnados dos cards são reproduzidos com `AudioClip`.

Funcionalidades atuais:

- Cada cenário tem 4 opções de rosnado.
- Só uma opção é correta.
- A opção correta não fica sempre no mesmo card visual.
- O botão de áudio alterna entre `Ouvir` e `Parar`.
- Quando o som está ativo, o ícone muda para stop.
- A onda sonora visual reage à amplitude real do ficheiro `.wav`.

A leitura da waveform é feita através de uma análise leve do WAV:

- O código lê ficheiros PCM WAV.
- Calcula uma assinatura de amplitude em 96 amostras.
- Usa essa assinatura para desenhar o ícone de sound wave.
- Durante a reprodução, a animação acompanha o progresso temporal do som.
- Se o ficheiro não for WAV/PCM compatível, a interface mantém uma animação visual de fallback.

## 6. Vibração bHaptics

O protótipo comunica com a luva Tactosy através de uma ponte Python (`bhaptics_bridge.py`).

Estados principais:

- `bhapticsBridgeReady`: ponte pronta.
- `bhapticsConnected`: ligação ativa.
- `bhapticsStatusMessage`: mensagem de estado.

Envio de vibração:

`sendHandVibration(pointMask, durationMs, intensity)`

Mapeamento dos pontos da Tactosy:

- ponto 1 = `1`
- ponto 2 = `2`
- ponto 3 = `4`
- todos os pontos = `7`

Intensidades:

- `VIB_LONG_LOW = 18`
- `VIB_LOW = 25`
- `VIB_MEDIUM = 63`
- `VIB_HIGH = 100`

Na condição unissensorial, ativada pela tecla `X`, o som e a vibração são desativados.

### 6.1. Localização dos estímulos hápticos

Os estímulos hápticos não estão guardados como ficheiros externos. Estão definidos diretamente no código Processing, no ficheiro:

`UserInterface_bHaptics_processing.pde`

A localização principal é a função:

`setupVibrationTimelines()`

Nesta função são registados os momentos em que a luva Tactosy deve vibrar.

Formato usado na Atividade 4:

`addProgrammedCue(videoIndex, tempoEmSegundos, pontos, duracaoMs, intensidade);`

Formato usado na Atividade 3:

`addActivity3ProgrammedCue(videoIndex, tempoEmSegundos, pontos, duracaoMs, intensidade);`

Cada estímulo háptico é composto por:

- `videoIndex`: identifica o comportamento/cenário.
- `tempoEmSegundos`: momento do vídeo em que a vibração começa.
- `pontos`: zona da Tactosy a ativar, usando o bitmask dos pontos.
- `duracaoMs`: duração da vibração em milissegundos.
- `intensidade`: força da vibração, de `0` a `100`.

Na Atividade 4, os estímulos são guardados nos arrays `vibrationCueTimes`, `vibrationCuePointMasks`, `vibrationCueDurations` e `vibrationCueIntensities`.

Na Atividade 3, os estímulos são guardados separadamente nos arrays `activity3VibrationCueTimes`, `activity3VibrationCuePointMasks`, `activity3VibrationCueDurations` e `activity3VibrationCueIntensities`.

A reprodução é feita automaticamente pelas funções `updateVibrationTimeline()` e `updateActivity3VibrationTimeline()`, que verificam o tempo atual do vídeo e enviam o comando para a ponte bHaptics através de `sendHandVibration()`.

## 7. Timelines de vibração

### 7.1. Atividade 4

A Atividade 4 usa `vibrationCueTimes`, `vibrationCueDurations`, `vibrationCueIntensities` e `vibrationCueCursor`.

Durante a observação, a vibração é mais subtil:

- Escala: `OBSERVATION_VIBRATION_SCALE = 0.45`
- Intensidade mínima: `OBSERVATION_VIBRATION_MIN_INTENSITY = 8`

Durante o feedback, a vibração mantém a intensidade definida nos cues.

### 7.2. Atividade 3

A Atividade 3 tem uma timeline separada:

- `activity3VibrationCueTimes`
- `activity3VibrationCueDurations`
- `activity3VibrationCueIntensities`
- `activity3VibrationCueCursor`

Isto evita misturar os índices da Atividade 3 com os vídeos da Atividade 4.

Timings atuais da Atividade 3:

- Ameaça cenário 1: 5s-9s, contínuo leve.
- Ameaça cenário 2: 6s-9s, contínuo leve.
- Guarda alimento cenário 1: 6s, pulso rápido; 8s-10s, contínuo leve.
- Guarda alimento cenário 2: 5s, pulso; 8s-10s, contínuo leve.
- Lúdico cenário 1: 3s-5s, contínuo leve; 6s-8s, contínuo leve.
- Lúdico cenário 2: 1s, pulso; 4s-6s, contínuo leve.

## 8. Shuffle

Existe um switch no menu inicial que permite ligar/desligar o baralhamento da ordem dos comportamentos.

Objetivo:

- Evitar que o participante memorize a ordem.
- Reduzir associação por posição.
- Manter tarefas e feedback associados ao comportamento correto.

O shuffle altera a ordem de apresentação, mas não separa vídeo, tarefa, resposta correta e feedback.

## 9. Recolha de dados

Existe um switch no menu principal para ativar/desativar a recolha de dados.

Quando ativo, o protótipo regista eventos como:

- início de atividade;
- cenário apresentado;
- resposta selecionada;
- confirmação de tarefas;
- acertos/erros;
- reprodução de rosnados;
- alteração de condição;
- uso de shuffle.

Os dados são guardados em CSV através de `PrintWriter`.

Quando a recolha está ativa, os dados são guardados num único ficheiro em `data/research_logs`:

- `research_data.csv`: ficheiro cumulativo com eventos e respostas de todas as sessões.

O ficheiro usa `;` como separador de colunas, para abrir corretamente no Excel em sistemas configurados em português. Se for importado manualmente, escolher delimitador `ponto e vírgula`.

O ficheiro usa a coluna `record_type` para separar tipos de linha:

- `event`: registo cronológico de ações da interface.
- `response`: resposta estruturada das tarefas de avaliação.

Ao ligar a recolha de dados, a interface pede uma vez o `participant_id`. Sem recolha ativa, este campo não aparece.

A tabela organiza os dados em colunas fixas. As linhas `response` destinam-se à fase de avaliação e registam apenas respostas das Atividades 3 e 4. Incluem campos como sessão, `participant_id`, condição experimental, atividade, cenário/comportamento, ordem de apresentação, ordem da marcação, estímulo, resposta selecionada, resposta correta, acerto/erro, opções disponíveis, pistas escolhidas, pistas corretas, número de reproduções do rosnado escolhido e distância temporal da marcação na Atividade 4.

Para analisar padrões de erro, há colunas específicas:

- `selected_answer`: resposta escolhida pelo participante.
- `correct_answer`: resposta esperada.
- `is_correct`: indica se a resposta foi correta.
- `wrong_selected_answer`: preenchida quando a opção escolhida está errada. Na Atividade 4 pode ficar vazia quando o comportamento escolhido está certo, mas o tempo marcado está errado.
- `error_type`: classifica o erro, por exemplo `erro_proximo`, `erro_plausivel`, `erro_distante`, `erro_pistas_sonoras`, `erro_comportamento_provavel`, `erro_tempo`, `erro_comportamento` ou `erro_tempo_e_comportamento`.
- `selected_option_role`: indica o papel da opção escolhida quando existe uma lógica de distratores, como `correto`, `distrator semelhante`, `distrator plausivel` ou `distrator contrastante`.
- `selected_option_distance`: na escolha dos rosnados da Atividade 3, usa `0` para a opção correta, `1` para o distrator mais próximo, `2` para o distrator plausível e `3` para o distrator mais contrastante.
- `closest_wrong_answer`: na escolha dos rosnados da Atividade 3, indica diretamente qual era a opção errada mais próxima da correta naquele conjunto de quatro cards.
- `response_distance`: na Atividade 4, regista a distância temporal da marcação face ao intervalo correto.

Na Atividade 4, a coluna `item_id` usa nomes legíveis para análise:

- `abaixamento_corporal`
- `afastamento`
- `desvio_olhar_primeira_marcacao`
- `desvio_cabeca_segunda_marcacao`
- `levantamento_pata_dianteira`
- `recuo_corporal`

A coluna `mark_order` distingue a ordem da marcação dentro do comportamento. Isto é especialmente importante no comportamento "Desvio de cabeça e olhar", porque há duas respostas numa mesma sequência.

A escolha feita fica registada explicitamente em `selected_answer` e, quando aplicável, em `selected_category`. Isto permite observar tendências de resposta, por exemplo se vários participantes erram mas escolhem sempre o card visualmente ou acusticamente mais próximo da resposta correta.

A confiança na resposta não é perguntada durante o uso do instrumento de aprendizagem; esse dado deve ser recolhido apenas nos questionários de avaliação.

## 10. Atividade 3: textos e respostas

### 10.1. Pistas sonoras disponíveis

As pistas disponíveis na segunda parte da tarefa interpretativa são:

1. Som grave
2. Som contínuo
3. Pausas curtas
4. Som mais agudo
5. Som intermitente
6. Pausas longas
7. Rosnado curto
8. Ritmo rápido
9. Intensidade baixa
10. Rosnado prolongado
11. Ritmo lento
12. Intensidade alta

### 10.2. Cenário 1: Rosnado Ameaça Cenário 1

Vídeo:

`activity3/videos/Rosnado Ameaça Cenario 1.mp4`

Opções de comportamento provável:

- Pedido de atenção
- Pedido de distância / aviso
- Possível desconforto físico
- Insegurança contextual

Resposta correta:

- Comportamento provável: Pedido de distância / aviso.
- Pistas corretas: Som grave + Som contínuo + Rosnado prolongado.
- Rosnado correto: card C.

Texto de feedback:

Observa que a pessoa reduz a distância e o cão responde com um rosnado grave, contínuo e prolongado. A interpretação mais forte é pedido de distância / aviso porque a vocalização parece regular a aproximação antes de uma possível escalada. Distingue este caso da proteção de recurso: aqui o foco não é manter comida ou objeto, mas gerir a presença da pessoa. O som sozinho não chega; contexto, duração e continuidade do rosnado sustentam a leitura.

### 10.3. Cenário 2: Rosnado Ameaça Cenário 2

Vídeo:

`activity3/videos/Rosnado Ameaça Cenario 2.mp4`

Opções de comportamento provável:

- Procura de contacto
- Possível desconforto físico
- Pedido de distância / aviso
- Insegurança contextual

Resposta correta:

- Comportamento provável: Pedido de distância / aviso.
- Pistas corretas: Som grave + Som contínuo + Rosnado prolongado.
- Rosnado correto: card A.

Texto de feedback:

Neste vídeo, a presença junto à porta cria uma situação social inesperada. O rosnado grave, contínuo e prolongado deve ser lido como pedido de distância / aviso porque comunica necessidade de espaço perante a aproximação ou presença da pessoa. Não significa automaticamente ataque: o rosnado é comunicação e pode evitar conflito. A pista principal é a relação entre o som, a porta e a proximidade humana.

### 10.4. Cenário 3: Rosnado Guarda Alimento Cenário 1

Vídeo:

`activity3/videos/Rosnado Guarda Alimento Cenario 1.mp4`

Opções de comportamento provável:

- Proteção de recurso alimentar
- Pedido de atenção
- Possível desconforto físico
- Insegurança contextual

Resposta correta:

- Comportamento provável: Proteção de recurso alimentar.
- Pistas corretas: Som grave + Som contínuo + Rosnado prolongado.
- Rosnado correto: card D.

Texto de feedback:

Aqui, o elemento decisivo é a taça de comida. O cão vocaliza quando existe aproximação ao recurso, por isso a resposta esperada é proteção de recurso alimentar. As pistas sonoras graves, contínuas e prolongadas podem parecer semelhantes às de aviso social, mas o contexto muda o significado: o rosnado comunica defesa ou controlo de acesso ao alimento, não apenas desconforto perante uma pessoa.

### 10.5. Cenário 4: Rosnado Guarda Alimento Cenário 2

Vídeo:

`activity3/videos/Rosnado Guarda Alimento Cenario 2.mp4`

Opções de comportamento provável:

- Procura de contacto
- Possível desconforto físico
- Insegurança contextual
- Proteção de recurso alimentar

Resposta correta:

- Comportamento provável: Proteção de recurso alimentar.
- Pistas corretas: Som grave + Som contínuo + Rosnado prolongado.
- Rosnado correto: card B.

Texto de feedback:

Neste cenário, o osso organiza a interpretação. O cão está junto de um recurso valorizado e responde à aproximação com rosnado grave, contínuo e prolongado. A leitura mais adequada é proteção de recurso alimentar, não apenas pedido de distância geral, porque a vocalização está ligada à manutenção do osso e ao controlo da proximidade da pessoa.

### 10.6. Cenário 5: Rosnado Lúdico Cenário 1

Vídeo:

`activity3/videos/Rosnado Ludico Cenario 1.mp4`

Opções de comportamento provável:

- Pedido de atenção
- Brincadeira
- Possível desconforto físico
- Frustração

Resposta correta:

- Comportamento provável: Brincadeira.
- Pistas corretas: Rosnado curto + Som intermitente + Pausas curtas + Ritmo rápido.
- Rosnado correto: card C.

Texto de feedback:

Neste vídeo, o rosnado aparece dentro de uma brincadeira de puxar, com envolvimento voluntário entre cão, pessoa e brinquedo. Mais do que procurar um som isoladamente mais agudo, observa a estrutura temporal: rosnados curtos, intermitentes, com pausas curtas e ritmo rápido tendem a apoiar a leitura lúdica quando o corpo continua envolvido na interação. A resposta esperada é brincadeira, não pedido de afastamento.

### 10.7. Cenário 6: Rosnado Lúdico Cenário 2

Vídeo:

`activity3/videos/Rosnado Ludico Cenario 2.mp4`

Opções de comportamento provável:

- Procura de contacto
- Possível desconforto físico
- Brincadeira
- Frustração

Resposta correta:

- Comportamento provável: Brincadeira.
- Pistas corretas: Rosnado curto + Som intermitente + Pausas curtas + Ritmo rápido.
- Rosnado correto: card A.

Texto de feedback:

Aqui, a bola e a postura corporal compatível com convite lúdico tornam o contexto central. O rosnado curto, intermitente, com pausas curtas e ritmo rápido acompanha a aproximação ao objeto e a continuidade da interação. A resposta esperada é brincadeira: o rosnado participa na excitação lúdica e deve ser interpretado juntamente com o corpo e a situação.

## 11. Atividade 4: textos por comportamento

### 11.1. Abaixamento corporal

Vídeo:

`activity4/videos/Abaixamento corporal_final 1080p.mp4`

O que observar:

1. O cão fica visivelmente mais baixo durante a sequência.
2. Observa se o tronco se aproxima do chão ou se os membros flectem.
3. Repara na tensão do corpo, na cabeça, no olhar e na distância ao estímulo.
4. Compara o que acontece antes e depois da mudança postural.
5. Não leias o abaixamento como sinal isolado ou significado fixo.

Texto "O que é este comportamento":

Neste contexto, baixar o corpo pode manifestar desconforto perante a presença humana, sobretudo quando surge com tensão, pausa ou menor iniciativa.

Tarefa interpretativa:

- Intervalo esperado: 00:05.0 a 00:07.0.
- Comportamento correto: Abaixamento corporal.
- Número de marcações necessárias: 1.

Texto de feedback:

Neste contexto, o abaixamento corporal é observado como possível manifestação de desconforto antes da interação humana. O cão reduz a altura do corpo, redistribui o peso e altera a forma como se posiciona perante a pessoa.

Esta mudança pode indicar que a aproximação, a presença ou a atenção humana estão a aumentar a tensão da situação. O corpo parece menos disponível para avançar e pode preparar uma pausa, bloqueio, recuo ou afastamento.

Observa a rigidez do tronco, a distribuição do peso, a posição da cabeça, o olhar, a cauda e a continuidade do movimento. O sinal ganha significado quando surge dentro desta sequência de presença humana.

### 11.2. Afastamento

Vídeo:

`activity4/videos/Afastamento_final_1080p.mp4`

O que observar:

1. O cão aumenta a distância em relação a uma pessoa, objeto ou estímulo.
2. Observa se o movimento surge depois de aproximação, contacto ou pressão.
3. Repara na direção da deslocação: lateral, diagonal, em curva ou para outro ponto.
4. Compara a posição inicial e final do cão no espaço.
5. Não assumas automaticamente medo ou rejeição sem observar o contexto.

Texto "O que é este comportamento":

Neste contexto, afastar-se pode manifestar desconforto através do aumento de distância face à pessoa ou à aproximação.

Tarefa interpretativa:

- Intervalo esperado: 00:00.6 a 00:02.0.
- Comportamento correto: Afastamento.
- Número de marcações necessárias: 1.

Texto de feedback:

Neste contexto, o afastamento é observado como resposta espacial à presença humana. O cão aumenta a distância em relação à pessoa, reduzindo a proximidade antes de haver interação direta.

Esta ação pode manifestar desconforto porque cria mais espaço e diminui a pressão da aproximação. O importante não é apenas o deslocamento, mas a relação entre o movimento do cão, a posição da pessoa e o momento em que a distância aumenta.

Observa se o cão se afasta depois de uma aproximação, contacto visual, toque ou mudança de postura humana. Repara também na velocidade, direção, orientação corporal e se continua atento à pessoa.

### 11.3. Desvio de cabeça e olhar

Vídeo:

`activity4/videos/Desvio cabeça_final_1080p.mp4`

O que observar:

1. O cão desvia primeiro o olhar e depois a cabeça/focinho.
2. Observa as duas mudanças em momentos diferentes da sequência.
3. Distingue o desvio dos olhos da rotação posterior da cabeça.
4. Repara se surge após olhar direto, toque, aproximação ou pressão.
5. Não assumas distração sem considerar o antes, o durante e o depois.

Texto "O que é este comportamento":

Neste contexto, desviar cabeça ou olhar pode manifestar desconforto ao reduzir contacto direto com a pessoa.

Tarefa interpretativa:

- Intervalo esperado 1: 00:02.6 a 00:03.5.
- Comportamento correto 1: Desvio do olhar.
- Intervalo esperado 2: 00:07.0 a 00:09.0.
- Comportamento correto 2: Desvio de cabeça.
- Número de marcações necessárias: 2.

Texto de feedback:

Neste contexto, o desvio de cabeça e o desvio do olhar são tratados como duas manifestações possíveis de desconforto perante a presença humana. O cão reduz o contacto direto sem precisar de se afastar de imediato.

O desvio do olhar pode ser muito subtil e deslocar apenas a atenção visual. O desvio da cabeça torna mais visível a alteração da orientação corporal. Em conjunto, estes sinais podem indicar tentativa de diminuir pressão social, sobretudo quando há aproximação, olhar direto ou presença muito próxima.

Por isso, a tarefa pede duas marcações. Observa quando cada mudança aparece, para onde o cão deixa de olhar, como orienta o focinho e se depois permanece, congela, baixa o corpo, recua ou evita nova aproximação.

### 11.4. Levantamento de pata dianteira

Vídeo:

`activity4/videos/Levantamento de Pata Dianteira_final_1080p.mp4`

O que observar:

1. O cão levanta uma pata dianteira durante a sequência observada.
2. Observa se a pata fica suspensa fora de uma passada normal.
3. Repara na duração do levantamento e na distribuição do peso.
4. Compara a postura geral, o olhar e a distância ao estímulo.
5. Não transformes este movimento num significado único.

Texto "O que é este comportamento":

Neste contexto, levantar a pata dianteira pode manifestar desconforto quando interrompe a ação perante a presença ou aproximação humana.

Tarefa interpretativa:

- Intervalo esperado: 00:02.2 a 00:03.0.
- Comportamento correto: Levantamento de pata dianteira.
- Número de marcações necessárias: 1.

Texto de feedback:

Neste contexto, o levantamento de pata dianteira é observado como uma pausa corporal perante a presença humana. A pata fica suspensa fora da passada normal e interrompe momentaneamente a estabilidade do corpo.

Neste contexto, a suspensão da pata pode manifestar desconforto, hesitação ou incerteza antes da interação. O cão parece interromper a ação enquanto avalia a proximidade da pessoa e decide se continua, fica parado, reduz contacto ou cria distância.

Observa a duração da pata levantada, a transferência de peso, a tensão muscular, a posição da cabeça e o olhar. O sinal deve ser lido em conjunto com a aproximação humana e com a resposta corporal que vem a seguir.

### 11.5. Recuo corporal

Vídeo:

`activity4/videos/Recuo corporal_final_1080p.mp4`

O que observar:

1. O cão desloca o corpo para trás, reduzindo a aproximação ao estímulo.
2. Observa se o recuo surge perante aproximação, toque ou movimento do outro.
3. Repara se continua parcialmente orientado para o estímulo.
4. Compara o recuo com um afastamento mais amplo para outro ponto.
5. Lê o movimento em conjunto com tensão, cabeça, olhar e sequência.

Texto "O que é este comportamento":

Neste contexto, recuar pode manifestar desconforto ao criar distância enquanto o cão continua atento à pessoa.

Tarefa interpretativa:

- Intervalo esperado: 00:03.5 a 00:05.5.
- Comportamento correto: Recuo corporal.
- Número de marcações necessárias: 1.

Texto de feedback:

Neste contexto, o recuo corporal é observado como uma criação imediata de distância perante a presença humana. O cão desloca o corpo para trás, mas pode continuar orientado para a pessoa.

Esta resposta pode manifestar desconforto porque reduz a aproximação sem abandonar totalmente a situação. O cão mantém atenção ao estímulo humano enquanto procura recuperar espaço, controlar a proximidade e diminuir a pressão da interação.

Observa se o recuo aparece depois de aproximação, toque, movimento brusco ou contacto visual. A leitura deve considerar direção, velocidade, tensão corporal, cauda, orelhas, olhar e o que acontece imediatamente depois.

## 12. Observações para manutenção

- Ao alterar nomes de ficheiros dos rosnados, manter palavras-chave compatíveis com a função de pesquisa.
- O ficheiro correto do rosnado deve conter `correto` no nome.
- Se forem substituídos WAVs por outro formato, a reprodução pode continuar a funcionar, mas a waveform reativa pode deixar de ler a amplitude real.
- Se forem adicionados novos cenários à Atividade 3, é necessário atualizar:
  - `ACTIVITY3_VIDEO_COUNT`
  - `activity3VideoFiles`
  - `activity3BehaviorOptionsByScenario`
  - `activity3CorrectSoundCluesByScenario`
  - `activity3CorrectBehaviors`
  - `activity3FeedbackExplanations`
  - `activity3GrowlCardRolesByScenario`
  - timelines de vibração da Atividade 3.
- Se forem adicionados novos comportamentos à Atividade 4, é necessário atualizar:
  - `BEHAVIOR_COUNT`
  - `titles`
  - `videoFiles`
  - `observationPoints`
  - `refinedExplanations`
  - `refinedFeedbackExplanations`
  - intervalos corretos da tarefa interpretativa
  - timelines de vibração da Atividade 4.
