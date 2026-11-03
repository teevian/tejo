# Música do descanso

As faixas fornecidas pelo utilizador estão organizadas em `assets/audio/music/`, sem reconversão: `TEJO_vaporware.mp3` (196,76 s) e `TEJO_vaporware2.wav` (198,48 s).

O jogo começa a música quando os dois personagens fecham os olhos durante o dia (06:00–20:00), incluindo as poses de lado. Cada novo sono diurno alterna a faixa: primeira, segunda, primeira, segunda. Uma noite de descanso, pausa, mapa, mudança de postura ou seleção não avançam esta ordem. Cada faixa repete-se dentro do seu próprio sono. Sair temporariamente para outra cena e regressar ao mesmo sono conserva a faixa e a posição de reprodução.

Os efeitos entram suavemente em 1,2 segundos e começam a ganhar cor logo desde o início. A primeira faixa desenvolve rosa, ciano e lilás com ondas e auroras ao longo dos primeiros 32 segundos. A segunda tem animação própria: azul, violeta e pêssego, ondas concêntricas e cortinas diagonais de luz ao longo dos primeiros 42 segundos. Ambas têm brilho, refração e movimento suave, sincronizados com a energia, graves, agudos e impulsos da respetiva gravação. O HUD fica acima desta transformação. Os personagens dormem de olhos fechados nas três posturas e ao mudar de lado.

`TEJO_vaporware.analysis.json` e `TEJO_vaporware2.analysis.json` contêm energia em três bandas a 50 amostras/s e, respetivamente, 373 e 328 transientes de batida medidos nas próprias gravações. O SHA-256 identifica cada fonte; a análise pode ser refeita no Godot com `--headless --path . --script res://tools/analyze_rest_music.gd`, ou com os argumentos `-- --source=res://assets/audio/music/TEJO_vaporware2.wav --output=res://assets/audio/music/TEJO_vaporware2.analysis.json`. A sincronização usa a posição audível do leitor, compensando a latência de saída. Não há batidas inventadas por um temporizador.

Esc e mapa suspendem som, evolução e animação em conjunto. Selecionar o outro personagem ou mudar de postura conserva a música. Ao começar a levantar, o volume desvanece em menos de meio segundo e o mundo regressa ao normal em 0,8 segundos, ainda durante a animação de levantar. Descansar à noite não inicia esta faixa. Sair para outra cena interrompe e limpa os efeitos.

**Esc → Dormir** procura dois lugares livres próximos e leva os personagens até lá para se sentarem e deitarem através das animações aprovadas, sem esperar os temporizadores de inatividade. Não muda a hora nem teletransporta os personagens. Setas ou Espaço levantam-nos.

Verificações: `tests/rest_music_test.gd` cobre alternância 1/2/1, controlos, transições, dia/noite, áudio, pausas e saída. `tests/rest_dream_preview.gd`, com gráficos, verifica resposta às batidas, mistura de áudio real, HUD intacto e regresso à imagem original. A opção `-- --animate` exporta uma sequência curta; `-- --second-track --animate` verifica a segunda música e a sua animação.
