# Documentação UX/UI/Interaction do Protótipo

Última atualização: 14/09/2026  
Protótipo: `UserInterface_bHaptics_processing.pde`  
Autor/design: João Lopes

> Nota de âmbito: esta documentação descreve a experiência de utilizador, interface visual e interação do instrumento/protótipo. A componente háptica/tátil não é documentada aqui por se encontrar ainda em desenvolvimento.

## 1. Enquadramento do Instrumento

O protótipo materializa um instrumento de aprendizagem orientado para a interpretação da comunicação canina. A sua estrutura resulta da passagem de princípios teóricos para uma experiência prática, onde o participante observa comportamentos, interpreta pistas e recebe feedback explicativo.

O instrumento foi desenhado para apoiar a hipótese de investigação de que a multissensorialidade pode melhorar a aprendizagem humana da comunicação canina. Nesta versão documental, o foco recai sobre a organização da experiência, a interface gráfica, os padrões de interação e a forma como o participante é conduzido entre observação, interpretação e feedback.

As atividades avaliativas atualmente privilegiadas são:

- Atividade 3: interpretação de rosnados em contexto.
- Atividade 4: identificação e interpretação de sinais comportamentais em vídeo.

As Atividades 1 e 2 permanecem no protótipo como propostas exploratórias de aprendizagem, mas ficam ocultas por defeito no menu principal. Podem ser reativadas pelo designer através do menu de opções.

## 2. Princípios de UX Aplicados

### 2.1. Aprendizagem por Sequência Guiada

A experiência foi organizada como uma sequência pedagógica progressiva:

1. Contextualização breve.
2. Observação do estímulo.
3. Tarefa interpretativa.
4. Feedback explicativo.

Esta estrutura evita que o participante seja lançado diretamente para a interpretação sem enquadramento mínimo. O ecrã de contexto antes da observação ajuda a estabelecer a relação entre cão, pessoa, objeto ou ambiente, sem revelar a resposta correta.

O objetivo é reduzir ambiguidades desnecessárias e permitir que a interpretação se concentre nas pistas relevantes do comportamento observado.

### 2.2. Interpretação Antes do Feedback

O protótipo obriga o participante a concluir a tarefa interpretativa antes de aceder ao feedback. Esta decisão protege a validade da tarefa, porque impede que a explicação final antecipe a resposta.

Na Atividade 3, o participante primeiro escolhe o rosnado mais semelhante ao ouvido no vídeo e depois justifica essa escolha com pistas sonoras e comportamento provável.

Na Atividade 4, o participante primeiro marca o momento relevante na timeline e só depois escolhe o comportamento ou significado associado. Quando existem duas mudanças comportamentais no mesmo vídeo, o fluxo repete a sequência marcação temporal -> escolha interpretativa.

### 2.3. Atenção Orientada

O instrumento usa pequenos mecanismos de orientação para dirigir a atenção do participante:

- Ecrã de contexto antes da observação.
- Títulos de fase: `Contexto`, `Observação`, `Tarefa interpretativa` e `Feedback`.
- Indicadores de progresso por pontos.
- Botões desativados quando a ação ainda não está disponível.
- Texto auxiliar discreto junto ao botão `Continuar`, com contagem de espera.
- Feedback visual quando uma opção é selecionada.

Estes elementos procuram apoiar a navegação sem transformar a interface num tutorial excessivamente verbal.

### 2.4. Redução de Memorização por Ordem

O protótipo inclui uma opção de baralhamento da ordem de apresentação dos comportamentos/cenários. Esta funcionalidade reduz a possibilidade de o participante decorar a ordem das respostas ou criar associações por posição.

O baralhamento altera a ordem de apresentação, mas mantém sempre associados:

- vídeo;
- tarefa;
- respostas corretas;
- feedback;
- dados registados.

Assim, a experiência pode variar entre participantes sem comprometer a correspondência interna de cada item.

### 2.5. Separação Entre Participante e Designer

A interface distingue a experiência do participante das ferramentas de configuração do designer. O menu principal apresenta apenas as atividades relevantes, enquanto o menu `Opções` concentra controlos técnicos:

- ativar/desativar baralhamento;
- ativar/desativar recolha de dados;
- mostrar/ocultar Atividades 1 e 2.

Esta separação reduz ruído na experiência principal e evita que o participante interaja com funcionalidades destinadas à preparação ou avaliação do protótipo.

## 3. Estrutura de Navegação

### 3.1. Menu Principal

O menu principal funciona como ponto de entrada da experiência. A área esquerda apresenta o nome do projeto e os botões das atividades disponíveis. A área direita apresenta um cartão informativo sobre a atividade selecionada.

Por defeito, o menu destaca as atividades avaliativas:

- Atividade 3.
- Atividade 4.

As Atividades 1 e 2 podem ser novamente exibidas pelo designer no menu `Opções`.

### 3.2. Menu Opções

O botão de opções fica no canto superior direito do menu principal. Ao clicar, abre um overlay com switches. A opção por um overlay evita sobrecarregar o menu principal com controlos permanentes.

As opções são apresentadas como interruptores binários, porque representam estados globais ligados/desligados.

### 3.3. Ecrã de Contexto

Antes de cada observação nas atividades avaliativas, é apresentado um ecrã de contexto. Este ecrã inclui:

- título da fase;
- texto breve contextual;
- botão `Continuar`;
- indicação discreta de espera junto ao botão.

O botão `Continuar` só fica disponível após 4 segundos. Este bloqueio temporário incentiva uma leitura mínima do contexto antes da observação, sem tornar o processo pesado.

O contador foi colocado junto ao botão para manter a relação direta entre a espera e a ação bloqueada. A opção evita uma barra de progresso visualmente dominante, que poderia competir com o conteúdo textual.

### 3.4. Observação

Na fase de observação, o participante vê o vídeo ou imagem principal antes de tomar decisões. Esta separação reforça o princípio de observar antes de interpretar.

Existe um botão `Repetir` nos ecrãs de observação, permitindo rever o estímulo antes de avançar. A repetição apoia participantes que precisam de mais tempo para perceber a sequência.

### 3.5. Tarefa Interpretativa

A tarefa interpretativa muda consoante a atividade:

- Atividade 3: escolha de rosnado, seleção de pistas sonoras e seleção do comportamento provável.
- Atividade 4: marcação temporal do momento relevante e seleção do comportamento/significado.

O desenho da tarefa privilegia respostas ativas. O participante não lê apenas a explicação: tem de construir uma interpretação antes do feedback.

### 3.6. Feedback

O feedback apresenta a comparação entre resposta do participante e resposta esperada. O objetivo é transformar erro e acerto em oportunidade de aprendizagem.

O feedback combina:

- resposta escolhida;
- resposta correta;
- explicação textual;
- reforço visual por cor;
- possibilidade de rever ou avançar, conforme o fluxo.

Na Atividade 4, o feedback só pode ser ultrapassado após a reprodução obrigatória pelo menos uma vez. Isto garante que o participante é exposto à correção antes de prosseguir.

## 4. UI: Linguagem Visual

### 4.1. Paleta Cromática

A interface usa uma paleta escura com destaques roxos. O fundo escuro reduz distrações e dá destaque aos elementos interativos, vídeos, cartões e estados selecionados.

Cores principais:

- fundo escuro: base da interface;
- cartões azul-escuros: organização de conteúdo;
- roxo: destaque, seleção e progresso;
- branco: texto principal;
- cinzento claro: texto secundário;
- verde: indicação de resposta correta ou estado positivo;
- vermelho/erro: usado pontualmente em feedback ou estado negativo.

O roxo atua como cor de ação e orientação. É usado em estados ativos, contornos selecionados, progresso e botões principais.

### 4.2. Tipografia

A interface usa a fonte Inter, adequada para leitura em ecrã. A hierarquia tipográfica está organizada em níveis:

- títulos principais;
- títulos de secção;
- subtítulos;
- corpo de texto;
- labels;
- legendas/captions.

Os tamanhos foram aumentados face a versões anteriores para melhorar a leitura, especialmente tendo em conta feedback de utilizadores mais velhos. O corpo de texto, descrições de tarefa e texto de feedback foram tratados como elementos centrais da aprendizagem, não apenas como apoio secundário.

### 4.3. Sistema de Cartões

Os cartões são usados para organizar unidades de decisão:

- opções de rosnado;
- pistas disponíveis;
- respostas selecionadas;
- comportamentos prováveis;
- feedback comparativo.

O cartão cria uma unidade visual clara e reduz a carga cognitiva, porque cada resposta ou bloco de informação fica delimitado.

Os cartões têm cantos discretamente arredondados e contornos subtis. O estado selecionado é indicado por alteração de contorno/cor, mantendo coerência visual entre atividades.

### 4.4. Botões

Os botões seguem uma lógica consistente:

- botão preenchido para ação principal;
- botão com contorno para ação secundária;
- ícone + texto para aumentar reconhecimento;
- estado desativado quando a ação não pode ser executada;
- cor reduzida em estados indisponíveis.

Botões principais:

- `Continuar`;
- `Confirmar`;
- `Seguinte`;
- `Concluir`.

Botões secundários:

- `Sair`;
- `Refazer`;
- `Repetir`;
- `Rever`;
- `Anterior`.

O botão `Sair` substitui os antigos botões de voltar durante as atividades, tornando a intenção mais clara: abandonar a atividade e regressar ao menu.

### 4.5. Indicadores de Progresso

As atividades usam pontos de progresso para indicar a posição do participante na sequência. Esta representação é discreta e evita ocupar espaço excessivo.

Na Atividade 3, o progresso aparece como `1/6`, `2/6`, etc.  
Na Atividade 4, aparece como progressão entre os cinco comportamentos.

O indicador ajuda o participante a perceber duração e avanço sem transformar a experiência numa checklist pesada.

## 5. Interaction Design

### 5.1. Modelo de Interação Principal

O protótipo privilegia interação por rato:

- clicar em botões;
- selecionar cartões;
- arrastar etiquetas;
- marcar pontos numa timeline;
- reproduzir/parar sons;
- abrir opções.

As teclas são usadas sobretudo como apoio técnico ou de design. A experiência do participante foi pensada para funcionar apenas com rato.

### 5.2. Estados Interativos

Os elementos interativos têm estados visuais:

- normal;
- hover;
- selecionado;
- desativado;
- correto;
- incorreto.

Esta diferenciação apoia a perceção de causa-efeito: o participante percebe quando uma ação foi aceite, quando falta completar algo e quando uma opção está ativa.

### 5.3. Drag and Drop

O drag and drop é usado para tarefas que exigem construção de resposta. Em vez de apenas clicar numa opção, o participante desloca pistas para zonas de destino.

Esta escolha reforça a ideia de associação ativa:

- selecionar uma pista;
- deslocá-la para a interpretação;
- construir a resposta progressivamente.

Na Atividade 3, o drag and drop é usado para pistas sonoras e comportamento provável.

### 5.4. Timeline Interativa

Na Atividade 4, a timeline é usada para marcar o momento relevante da mudança comportamental.

Após testes de usabilidade, a timeline foi reforçada no fluxo:

- primeiro aparece a timeline como foco principal;
- só depois de confirmada aparecem as opções de escolha;
- no comportamento com duas mudanças, a sequência repete-se.

Esta alteração resolve a dificuldade observada nos testes, onde os participantes não percebiam inicialmente que a timeline era interativa.

### 5.5. Reprodução Sonora na Atividade 3

Na primeira parte da tarefa interpretativa da Atividade 3, cada card de rosnado tem um botão de reprodução. O participante pode ouvir cada opção antes de escolher.

O botão alterna entre:

- play/ouvir;
- stop/parar.

A opção por `stop` em vez de `pause` torna mais clara a função real: interromper o som e reiniciar a escuta quando necessário.

### 5.6. Waveform Visual

Os cards de rosnado apresentam uma representação visual em forma de onda. Quando existe ficheiro WAV compatível, a onda visual reage à amplitude do próprio som, tornando a representação mais congruente com aquilo que é ouvido.

Esta solução não substitui a escuta, mas reforça a relação entre estímulo auditivo e representação visual. O objetivo é tornar a experiência mais coerente e comunicativa.

### 5.7. Feedback Comparativo

O feedback usa comparação entre resposta do participante e resposta esperada. Esta comparação torna visível:

- o que foi escolhido;
- o que era esperado;
- que pistas sustentam a resposta;
- por que razão a interpretação é mais adequada.

Na Atividade 3, a comparação inclui rosnado escolhido, pistas sonoras e comportamento provável.  
Na Atividade 4, inclui momento temporal marcado e comportamento selecionado.

## 6. Atividade 3: UX/UI/Interaction

### 6.1. Objetivo da Atividade

A Atividade 3 procura desenvolver a interpretação de rosnados em contexto. O objetivo não é apenas identificar qual vídeo está a ser mostrado, mas relacionar vocalização, situação e comportamento provável.

Cada cenário apresenta um vídeo com um rosnado contextualizado. Depois, o participante escuta quatro opções de rosnado e seleciona a que mais se assemelha ao som observado.

### 6.2. Estrutura da Atividade

Cada cenário segue a sequência:

1. Contexto.
2. Observação do vídeo.
3. Escolha do rosnado.
4. Justificação com pistas sonoras.
5. Seleção de comportamento provável.
6. Feedback.

Esta organização separa perceção auditiva, análise de pistas e interpretação comportamental.

### 6.3. Cards de Rosnado

Os quatro cards de rosnado são apresentados lado a lado. Cada card inclui:

- nome neutro (`Rosnado A`, `Rosnado B`, etc.);
- waveform visual;
- botão de ouvir/parar;
- estado selecionável.

Os nomes são neutros para evitar que a resposta seja sugerida pelo texto.

### 6.4. Pistas Sonoras

Na segunda parte da tarefa, o participante seleciona pistas como:

- som grave;
- som contínuo;
- pausas curtas;
- som intermitente;
- rosnado curto;
- ritmo rápido;
- rosnado prolongado.

Estas pistas deslocam a tarefa de uma escolha puramente intuitiva para uma justificação observável.

### 6.5. Comportamento Provável

O participante também escolhe um comportamento provável. As opções incluem a resposta correta e distratores plausíveis. Isto permite avaliar padrões de erro, por exemplo quando o participante escolhe uma opção próxima mas não correta.

As opções foram escritas em linguagem acessível, para não dependerem apenas de nomes técnicos.

### 6.6. Feedback da Atividade 3

O feedback explica a correspondência entre:

- som ouvido;
- contexto observado;
- pistas selecionadas;
- comportamento provável.

A explicação evita tratar o rosnado como sinal isolado. O foco está na relação entre vocalização e contexto.

## 7. Atividade 4: UX/UI/Interaction

### 7.1. Objetivo da Atividade

A Atividade 4 procura desenvolver a capacidade de identificar sinais comportamentais em sequência temporal. O participante observa vídeos curtos e deve marcar o momento em que ocorre a mudança relevante.

O foco está na articulação entre:

- momento da ocorrência;
- sinal comportamental;
- interpretação contextual.

### 7.2. Estrutura da Atividade

Cada comportamento segue a sequência:

1. Contexto.
2. Observação do vídeo.
3. Marcação temporal na timeline.
4. Escolha do comportamento/significado.
5. Feedback.

Quando existem duas mudanças no mesmo vídeo, como no caso do desvio do olhar e posterior desvio de cabeça, a sequência de marcação e escolha repete-se.

### 7.3. Timeline Como Foco da Tarefa

A timeline foi reposicionada no fluxo para ser percebida como elemento central da tarefa. Em vez de apresentar todas as opções ao mesmo tempo, o protótipo solicita primeiro a marcação temporal.

Esta decisão reduz a dispersão visual e ajuda o participante a compreender que a primeira tarefa é localizar a mudança no tempo.

### 7.4. Escolha Interpretativa

Depois da marcação temporal, surgem as opções de interpretação. Isto evita que o participante escolha primeiro um significado e depois procure um momento que confirme a escolha.

A ordem força uma leitura mais próxima da observação:

1. O que aconteceu?
2. Quando aconteceu?
3. Que significado é plausível neste contexto?

### 7.5. Feedback da Atividade 4

O feedback mostra se o momento marcado e a escolha interpretativa correspondem ao esperado. Quando há erro, a comparação ajuda a perceber se a dificuldade esteve na deteção temporal, na interpretação ou em ambas.

O texto de feedback reforça que sinais como abaixamento corporal, afastamento, desvio do olhar/cabeça, levantamento da pata ou recuo corporal devem ser lidos no conjunto da sequência, não como significados fixos isolados.

## 8. Recolha de Dados Como Parte da UX de Investigação

A recolha de dados foi integrada como modo opcional, ativado no menu `Opções`.

Quando ativa, a interface pede um `participant_id` antes de iniciar o registo. Este pedido aparece numa overlay separada, evitando interferir com a experiência quando o protótipo está a ser usado apenas para teste ou demonstração.

O sistema regista:

- atividade;
- cenário/comportamento;
- ordem de apresentação;
- resposta escolhida;
- resposta correta;
- acerto/erro;
- tipo de erro;
- opções disponíveis;
- pistas selecionadas;
- número de reproduções de áudio na Atividade 3;
- distância temporal da resposta na Atividade 4.

Esta camada permite analisar não só se o participante acertou, mas também que tipo de resposta escolheu quando errou.

## 9. Acessibilidade e Legibilidade

Foram aplicadas várias decisões para melhorar a legibilidade:

- aumento do tamanho de texto nas descrições e feedback;
- uso de alto contraste entre texto e fundo;
- limitação de texto por cartão;
- organização por blocos;
- uso de botões com ícone e texto;
- estados desativados visualmente distintos;
- feedback por cor e texto, não apenas por cor.

O feedback de utilizadores mais velhos levou ao aumento da escala tipográfica em textos explicativos. Esta decisão reforça a adequação do instrumento a participantes com diferentes níveis de conforto visual.

## 10. Consistência Visual

A interface mantém padrões consistentes entre atividades:

- fundo escuro com grelha subtil;
- cartões como unidades de conteúdo;
- roxo como cor de ação;
- cabeçalho no topo;
- botão `Sair` no canto superior esquerdo;
- progresso no canto superior direito;
- botões de confirmação no canto inferior direito;
- feedback com comparação entre resposta dada e resposta esperada.

Esta consistência reduz o esforço de reaprendizagem entre atividades.

## 11. Justificação Sintética Para a Dissertação

O protótipo foi materializado como um instrumento interativo de aprendizagem baseado numa sequência de observação, interpretação e feedback. A interface procura orientar a atenção do participante para sinais comportamentais relevantes, evitando apresentar respostas antes da tarefa interpretativa.

O desenho UX privilegia a construção ativa de resposta: o participante observa, escolhe, arrasta pistas, marca momentos e compara a sua interpretação com feedback. A UI utiliza uma linguagem visual escura, cartões, estados de seleção, indicadores de progresso e botões consistentes para reduzir ruído e favorecer foco.

As decisões de interação procuram equilibrar orientação e autonomia. O ecrã de contexto prepara a observação sem revelar a resposta; a timeline exige localização temporal antes da interpretação; os cards de rosnado permitem escuta comparativa; e o feedback transforma a resposta numa oportunidade de aprendizagem.

Assim, o protótipo não funciona apenas como interface de apresentação de conteúdos, mas como instrumento de mediação entre observação comportamental, tomada de decisão e aprendizagem interpretativa.

