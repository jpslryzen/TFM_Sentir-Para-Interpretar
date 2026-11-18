# Documentação do instrumento de avaliação

## 1. Identificação e propósito

Este protótipo é um instrumento de aprendizagem e avaliação para apoiar a interpretação humana da comunicação canina. Apresenta cenários audiovisuais de cães e solicita decisões interpretativas sobre vocalizações, comportamentos e momentos temporais relevantes.

O instrumento foi desenvolvido para comparar duas condições experimentais:

- AVH — audiovisual e háptica: imagem, som e estímulos vibrotáteis na luva bHaptics;
- AV — audiovisual de controlo: imagem e som, sem vibração.

O háptico foi concebido como um reforço temporal e atencional de eventos observáveis. Não comunica a categoria correta, não traduz semanticamente a resposta e não deve ser entendido como uma pista de solução.

As Atividades 3 e 4 são as partes destinadas à avaliação. As Atividades 1 e 2 permanecem no código como propostas exploratórias e ficam ocultas por defeito no menu.

## 2. Tecnologia e estrutura do protótipo

O protótipo é uma aplicação desktop desenvolvida em Processing, com renderização P2D em ecrã completo. A interface usa uma escala interna para manter a composição visual em diferentes resoluções e utiliza a fonte Inter incluída em data/common.

O sketch é composto pelos seguintes ficheiros Processing:

- UserInterface_bHaptics_processing.pde — fluxo principal, ecrãs, atividades, vídeo, áudio, menus e interface;
- ObservationHaptics.pde — calendário de estímulos hápticos durante as observações;
- ResearchTaskMetrics.pde — escrita do CSV e métricas de interação;
- ScenarioRatings.pde — escalas apresentadas no final de cada cenário.

A comunicação com a luva é realizada através de bhaptics_bridge.py, executado pelo Processing. A ponte usa Python e a biblioteca bhaptics-python para comunicar com o bHaptics Player. A configuração do Player depende de bhaptics-config.json, que contém credenciais e não deve ser partilhado.

Estrutura relevante da pasta data:

- activity3 — vídeos de observação e sons de comparação dos rosnados;
- activity4 — vídeos de comportamentos e materiais específicos;
- common — tipografia e recursos partilhados;
- research_logs — ficheiro de dados gerado durante a recolha.

O ecrã inicial de carregamento prepara os vídeos antes de libertar o menu principal. O objetivo é reduzir bloqueios e atrasos quando um cenário é aberto.

## 3. Fluxo geral de uso

1. O participante chega ao menu principal.
2. Quando a recolha está ativa, o investigador introduz um identificador pseudónimo e escolhe a condição AVH ou AV.
3. O participante abre uma atividade.
4. Cada cenário apresenta uma breve introdução contextual. O botão Continuar é desbloqueado após quatro segundos.
5. O participante observa o cenário.
6. Conclui a respetiva tarefa interpretativa.
7. Responde às três escalas finais do cenário.
8. Avança para o cenário seguinte.

O participante utiliza o rato para interagir. Existem atalhos técnicos destinados ao desenvolvimento e à inspeção do protótipo; não devem ser apresentados como parte do procedimento experimental nem analisados como respostas de participantes.

O botão Sair encerra a sessão de forma intencional. A tecla Escape é bloqueada durante a execução para evitar o encerramento instável do Processing.

## 4. Menu principal e opções

O menu apresenta o título Interpretação da comunicação canina e as atividades de avaliação:

- Rosnados caninos — referência interna: Atividade 3;
- Mudança de comportamento — referência interna: Atividade 4.

Em estado de hover, cada botão mostra uma breve explicação da respetiva atividade. O menu de opções inclui:

- baralhar ordem dos cenários;
- ativar ou desativar a recolha de dados;
- tornar visíveis as Atividades 1 e 2 para o designer;
- ocultar ou apresentar os ecrãs de feedback.

O feedback fica oculto por defeito. Esta configuração permite utilizar o instrumento apenas para recolha de respostas, sem conteúdo explicativo entre cenários. Quando os ecrãs de feedback são ativados, apresentam explicações relativas ao cenário concluído.

O baralhamento apenas altera a ordem de apresentação. As tarefas, os estímulos, as respostas corretas e os feedbacks continuam associados ao mesmo cenário.

## 5. Condições experimentais

### AVH — audiovisual e háptica

Nesta condição, a observação inclui vídeo, som original e vibração na luva esquerda bHaptics Tactosy for Hands. Os estímulos estão calendarizados em relação ao tempo do vídeo e reforçam eventos visuais ou sonoros previamente definidos.

### AV — audiovisual de controlo

Nesta condição, o vídeo e o som permanecem ativos. A execução de qualquer vibração é bloqueada temporariamente durante o estudo. Assim, AV não significa condição silenciosa; significa ausência de háptico.

### Seleção e limitações

A condição é escolhida manualmente no ecrã de identificação do participante, antes de iniciar a recolha. Depois de iniciada a sessão, a condição fica bloqueada no código para evitar mudanças acidentais dentro da mesma recolha.

O protótipo não realiza randomização ou balanceamento automático entre AV e AVH. A atribuição da condição deve, por isso, ser controlada pelo investigador no protocolo de recolha. O estado atual também não inclui um campo participante-tipo para distinguir automaticamente piloto, teste ou recolha principal.

## 6. Atividade 3 — Rosnados caninos

### Objetivo

A Atividade 3 trabalha a interpretação de rosnados em contexto. O participante observa um vídeo e, em seguida, compara quatro rosnados gerados ou selecionados para a tarefa. O objetivo não é reconhecer literalmente o áudio do vídeo: o rosnado correspondente da comparação é um estímulo diferente, pertencente ao mesmo tipo ou contexto comunicativo.

### Estrutura de cada cenário

1. Introdução contextual;
2. Observação do vídeo;
3. Comparação de quatro cartões de rosnado, identificados por A, B, C e D;
4. Escolha de pistas sonoras e de um comportamento provável;
5. Feedback opcional;
6. Escalas finais do cenário.

Os quatro cartões permitem ouvir novamente cada rosnado. O ícone visual de onda reage à amplitude do ficheiro quando existe análise disponível, com uma alternativa visual quando não é possível analisar o áudio. O botão de reprodução muda para parar enquanto o som está ativo.

O rosnado correto não ocupa sempre a mesma posição. A posição de A, B, C ou D é distribuída entre cenários para reduzir a aprendizagem de um padrão de interface.

### Cenários e interpretação esperada

| Cenário | Contexto principal | Comportamento provável correto |
| --- | --- | --- |
| Ameaça — cenário 1 | O cão reage a uma aproximação, procurando aumentar a distância. | Pedido de distância / aviso |
| Ameaça — cenário 2 | A presença humana é acompanhada por sinais de afastamento e aviso. | Pedido de distância / aviso |
| Guarda de alimento — cenário 1 | A interação com a taça desencadeia proteção de um recurso. | Proteção de recurso alimentar |
| Guarda de alimento — cenário 2 | A aproximação ou manipulação de um osso desencadeia proteção do recurso. | Proteção de recurso alimentar |
| Lúdico — cenário 1 | O rosnado ocorre durante brincadeira de puxar. | Brincadeira |
| Lúdico — cenário 2 | O rosnado ocorre em contexto lúdico relacionado com uma bola. | Brincadeira |

As restantes opções são distratores plausíveis, incluindo pedido de atenção, procura de contacto, insegurança contextual, possível desconforto físico e frustração. Não representam uma resposta correta alternativa dentro de cada cenário.

### Pistas sonoras disponíveis

O participante pode selecionar, conforme o cenário, as seguintes descrições:

- som grave;
- som contínuo;
- pausas curtas;
- som mais agudo;
- som intermitente;
- pausas longas;
- rosnado curto;
- ritmo rápido;
- intensidade baixa;
- rosnado prolongado;
- ritmo lento;
- intensidade alta.

Nos cenários de ameaça e guarda de alimento, a configuração de referência privilegia som grave, contínuo e prolongado. Nos cenários lúdicos, privilegia rosnado curto, intermitente, com pausas curtas e ritmo rápido. Estas escolhas devem ser interpretadas no contexto completo do vídeo, e não como regras universais isoladas.

### Limites intencionais

Depois da observação, não é possível voltar a reproduzir literalmente o áudio do vídeo. Apenas os quatro sons comparativos podem ser ouvidos de novo. Esta decisão evita uma resposta baseada em reconhecimento acústico direto.

## 7. Atividade 4 — Mudança de comportamento

### Objetivo

A Atividade 4 trabalha a identificação de comportamentos caninos e o seu posicionamento temporal na observação. A tarefa pede que o participante assinale, numa timeline, quando identificou a mudança comportamental e, depois, escolha o significado ou comportamento correspondente.

### Estrutura de cada cenário

1. Introdução contextual;
2. Observação do vídeo;
3. Timeline interativa apresentada isoladamente, com indicação para marcar o momento observado;
4. Escolha do significado ou comportamento depois da confirmação da marca temporal;
5. Repetição timeline-escolha quando existem duas mudanças;
6. Feedback opcional;
7. Escalas finais do cenário.

Esta separação foi introduzida após testes de usabilidade: quando a timeline e as opções apareciam ao mesmo tempo, participantes não percebiam que era necessário interagir com a timeline. A timeline recebe um destaque visual subtil para orientar a atenção.

### Comportamentos observados

| Cenário | Marcas exigidas | Comportamento de referência |
| --- | --- | --- |
| Abaixamento corporal | Uma | Abaixamento corporal perante aproximação |
| Afastamento | Uma | Afastamento do cão |
| Desvio de olhar e cabeça | Duas | Primeiro desvio de olhar; depois desvio de cabeça |
| Levantamento de pata dianteira | Uma | Levantamento de pata dianteira |
| Recuo corporal | Uma | Recuo corporal |

No cenário de desvio, a ordem é importante: a primeira escolha temporal e semântica refere-se ao desvio de olhar; a segunda refere-se ao desvio de cabeça. Os registos usam identificadores distintos, incluindo o número da marca, para não confundir ambas as respostas na análise.

## 8. Estímulos hápticos

### Princípio de desenho

Os estímulos vibrotáteis só ocorrem durante a observação e apenas na condição AVH. Foram definidos para chamar discretamente a atenção para intervalos de ação, movimento ou vocalização observáveis, sem determinar a interpretação correta.

O hardware esperado é uma luva bHaptics Tactosy for Hands esquerda. O mapa implementado contempla três pontos ou motores. As intensidades são deliberadamente baixas a moderadas e variam entre eventos; os pulsos têm uma duração técnica de 100 ms, salvo definição diferente no calendário.

### Cobertura implementada

Existem eventos programados para os seis cenários da Atividade 3 e os cinco cenários da Atividade 4. Ameaça, guarda de alimento, brincadeira, aproximação, afastamento, desvios, levantamento de pata e recuo possuem agendas próprias.

Os intervalos concretos, intensidades, pontos de atuação e justificação de cada evento estão documentados em REGISTO_HAPTICO_OBSERVACAO.md e codificados em ObservationHaptics.pde. Esse registo deve ser a referência para ajustes de calibração e para descrever a implementação háptica numa secção metodológica.

### Limitações técnicas a declarar

A ponte comunica com o bHaptics Player e envia comandos durante a reprodução. A sincronia deve ser validada empiricamente na luva em cada computador, porque a latência do vídeo, do sistema operativo, do Player e do dispositivo pode introduzir pequenas diferenças. A ponte também interrompe comandos anteriores antes de iniciar um novo evento, pelo que eventos contíguos exigem validação prática.

## 9. Escalas após cada cenário

No fim de todos os seis cenários da Atividade 3 e dos cinco da Atividade 4, o participante responde obrigatoriamente a três medidas. Não existem respostas pré-selecionadas.

### Confiança na resposta

Pergunta: Quão confiante estás de que a tua interpretação deste cenário está correta?

Escala de cinco pontos:

1. Nada confiante
2. Pouco confiante
3. Moderadamente confiante
4. Confiante
5. Muito confiante

### Esforço mental

Pergunta: Quanto esforço mental investiste para interpretar este cenário?

Escala de nove pontos:

1. Muito, muito reduzido
2. Muito reduzido
3. Reduzido
4. Relativamente reduzido
5. Nem reduzido nem elevado
6. Relativamente elevado
7. Elevado
8. Muito elevado
9. Muito, muito elevado

### Dificuldade percebida

Pergunta: Quão difícil foi interpretar este cenário?

Escala de cinco pontos:

1. Muito fácil
2. Fácil
3. Nem fácil nem difícil
4. Difícil
5. Muito difícil

As escalas são apresentadas durante a recolha ativa ou inativa. Só são gravadas no CSV quando a recolha de dados está ativa.

## 10. Recolha de dados

### Ativação

A recolha é ativada no menu de opções. O sistema pede participant_id e condição antes de permitir iniciar. Recomenda-se utilizar um código pseudónimo, por exemplo P001, e não um nome identificável.

Os dados são guardados localmente em:

data/research_logs/research_data.csv

O ficheiro usa codificação UTF-8 com BOM e separador ponto e vírgula, para abertura mais direta em Excel configurado em português. Todas as sessões são acrescentadas ao mesmo CSV.

### Informação associada a cada registo

Os registos incluem, quando aplicável:

- timestamp, session_id e elapsed_ms;
- participant_id;
- condição experimental AV ou AVH;
- estado do baralhamento;
- atividade, cenário, passo, identificadores de item e ordem;
- estímulo apresentado e categoria;
- resposta selecionada, categoria e papel da opção;
- resposta correta, acerto, tipo de erro, distância e distractor mais próximo;
- opções e pistas disponíveis;
- pistas selecionadas e pistas de referência;
- reproduções de estímulos sonoros;
- resposta inicial, resposta final, número de alterações e sequência de escolhas;
- tempo de resposta desde a disponibilidade da tarefa;
- tempos e alterações da resposta na timeline;
- estado da condição no início da tarefa e indício de mudança durante a tarefa;
- confiança, dificuldade percebida e esforço mental.

### Tipos de eventos guardados

O CSV combina linhas de evento e linhas de resposta. Entre outros, pode conter:

- início e fim da recolha;
- início, disponibilidade, conclusão ou abandono de uma tarefa;
- reprodução de um rosnado de comparação;
- seleção ou alteração de uma opção;
- resposta confirmada;
- confirmação das escalas do cenário;
- eventos técnicos ou de designer que devem ser excluídos da análise participante.

As respostas temporais da Atividade 4 registam a marca exigida. Isto permite distinguir, no cenário de desvio, a primeira marca de desvio de olhar da segunda marca de desvio de cabeça.

### Métricas principais sugeridas

- precisão na comparação e interpretação de rosnados da Atividade 3;
- identificação comportamental na Atividade 4;
- precisão temporal da timeline na Atividade 4.

### Dados secundários e exploratórios

- confiança na resposta;
- esforço mental;
- dificuldade percebida;
- tempo de resposta;
- número e sequência de alterações de escolha;
- número e sequência de audições dos rosnados comparativos;
- ordem dos cenários quando o baralhamento está ativo;
- padrões de erro, incluindo opção errada escolhida e distractor correto mais próximo.

O tempo de resposta e as interações exploratórias já são registados tecnicamente. A decisão de os tratar como resultados principais ou exploratórios deve ser definida antes da análise.

### Cuidados de análise

As linhas não devem ser interpretadas todas como ensaios equivalentes: há linhas de evento, resposta, métricas e escalas. A análise deve filtrar record_type, event, activity, response_stage e item_id.

Quando o modo de recolha está desligado, a interface pode manter o mesmo fluxo visual, mas não cria registos experimentais no CSV. Ações de desenvolvimento, como atalhos de avanço, devem ser identificadas e excluídas.

## 11. Atividades exploratórias ocultas

### Atividade 1

Propõe classificação de momentos como relevantes ou neutros, através de arrastar cartões para zonas associadas a segmentos de vídeo.

### Atividade 2

Propõe uma associação entre intervenientes, alvo, pistas comportamentais e significado.

Estas atividades não fazem parte da fase de avaliação atual. Podem ser reativadas no menu de opções para desenvolvimento ou demonstração, mas os seus resultados não devem ser combinados com os dados experimentais das Atividades 3 e 4.

## 12. Preparação de uma sessão

1. Abrir o bHaptics Player.
2. Confirmar que a luva esquerda está ligada e visível no Player.
3. Confirmar que bhaptics-config.json está presente e contém as credenciais corretas.
4. Abrir o sketch principal no Processing e executar.
5. Aguardar pelo ecrã de carregamento e pelo menu principal.
6. No menu de opções, ativar recolha de dados.
7. Introduzir participant_id e selecionar AVH ou AV.
8. Confirmar que feedback, baralhamento e visibilidade das atividades correspondem ao protocolo.
9. Para AVH, confirmar visualmente a ligação da ponte antes de iniciar. Para AV, confirmar que a condição escolhida mostra AV no registo.
10. No fim, confirmar que research_data.csv recebeu a sessão antes de encerrar a aplicação.

## 13. Limitações e verificações recomendadas

- A atribuição AV ou AVH é manual; deve existir uma lista externa de balanceamento.
- O participant_id é pseudónimo, mas deve ser protegido juntamente com a chave de correspondência, se esta existir.
- Os ficheiros CSV devem ser copiados com controlo de versões e verificados depois de cada sessão.
- O ficheiro bhaptics-config.json, credenciais e chaves não devem ser enviados a participantes ou colaboradores externos.
- A sincronização háptica tem de ser testada no computador e na luva utilizados na sessão.
- Os vídeos e sons devem ser verificados antes de cada recolha, em particular após mover a pasta do protótipo.
- Não devem ser utilizados atalhos técnicos durante a recolha principal.
- Para uma comparação experimental rigorosa, AV e AVH devem idealmente ser executadas com o mesmo computador, ecrã, áudio e procedimento presencial; fazer AV remotamente e AVH presencialmente introduz diferenças adicionais.

## 14. Documentos complementares

- RECOLHA_DADOS_METRICAS.md — estrutura e interpretação detalhada das colunas do CSV;
- RECOLHA_ESCALAS_CENARIO.md — implementação das escalas finais;
- REGISTO_HAPTICO_OBSERVACAO.md — tabela de estímulos vibrotáteis por cenário;
- DOCUMENTACAO_UX_UI_INTERACAO.md — decisões de UX, UI e interação;
- DOCUMENTACAO_PROTOTIPO.md — documentação histórica e de apoio. Deve ser lida com cuidado, pois algumas decisões antigas foram substituídas pela condição AV atual e pelo fluxo mais recente.

## 15. Estado de implementação

Esta documentação descreve o estado funcional observado no código em setembro de 2026. Antes de uma recolha formal, recomenda-se um ensaio completo por condição, com verificação de vídeo, áudio, luva, CSV e transição entre todos os cenários.
