# A noite no Lord Byron

O recanto Lord Byron, na zona poente da vila, recebe uma esplanada de bar com balcão de azulejos, mesas altas, coluna de música e horário visível. Abre às **20:30** e fecha à **01:30**. A luz quente ilumina localmente o encontro; o resto da vila conserva a sua iluminação noturna.

São as mesmas pessoas que têm atividades durante o dia, sem duplicar personagens: Gil, Tiago, Alexandre, Martim, Afonso, Yuki, Camila, Beatriz e Samira. O Nuno guarda a cerâmica e ajuda ao balcão durante o turno da noite. As deslocações para o bar começam em momentos distintos entre as 20:40 e as 21:30, depois do jantar; o Nuno janta no bar e sai antes para preparar o balcão. Camila e Samira saem mais cedo, os restantes regressam em momentos distintos depois da meia-noite. O Nuno descansa no quarto do bar depois de fechar e começa a manhã mais tarde.

## O que acontece

- Pequenas conversas com perguntas e respostas entre pessoas próximas, incluindo depois das 22:45 e da meia-noite.
- Gil, Afonso, Camila e Beatriz alternam entre conversa, dança e descanso. Caminham até ao espaço da dança e regressam aos seus lugares; cada um tem fases e pausas diferentes.
- Poses completas novas de ouvir, falar e dançar, com expressões naturais e duas posições distintas dos braços, pernas e corpo. Os protagonistas conservam os seus sprites aprovados.
- Música instrumental original, com duas versões e volume por proximidade. O jogador pode pedir outra música; o som e o ritmo da dança mudam.
- É possível abordar as pessoas; quem dança interrompe a dança para responder. O balcão, as mesas e a placa dão acesso à conversa e ao horário.
- Os percursos usam a navegação e as colisões da vila. O balcão e as mesas são obstáculos físicos registados antes da construção da navegação.
- À 01:30 apagam-se as luzes do bar e pára a música; os regressos a casa continuam a pé. Ao sair da região o som fica suspenso. Ao voltar, o relógio repõe as atividades adequadas.

## Arte e integração

Foram usados os recursos do **ImageGen integrado**, com os sprites existentes como referências de identidade e estilo. PNGs finais preservados sem edição de píxeis:

- `assets/characters/villagers/nightlife-friends.png` — cinco amigos, quatro poses por pessoa.
- `assets/characters/villagers/nightlife-guests.png` — quatro convidadas, quatro poses por pessoa.
- `assets/world/village/nightlife-bar.png` — balcão, mesa, coluna, placa e duas poses do Nuno.

Os pedidos exatos e as referências estão em `data/village/nightlife-image-prompts.json`. `tools/measure_village_nightlife.py` apenas mede as silhuetas e apoios para `data/village/nightlife-art.json`; o recorte de transparência usa o material já existente. A escala mantém a relação de altura entre as poses. As novas poses aplicam-se apenas aos adultos que estão no bar; as suas caminhadas e atividades diurnas continuam a usar a arte anterior.

A luz local é aplicada no mesmo tratamento de dia/noite da cena, conservando a ordem de profundidade e as oclusões dos edifícios, mesas e pessoas. Não cria uma segunda cópia dos personagens por cima da cena.

## Verificação

`tests/village_nightlife_test.gd` percorre uma noite contínua: chegadas reais sem teletransporte, conversa recíproca, dois passos de dança para cada dançarino, passagem da meia-noite, saídas e descanso em interiores, fecho, música, participação do jogador e reposição do horário. `tests/village_nightlife_preview.gd` captura o bar aberto, depois da meia-noite e durante o dia. As regressões da comunidade, movimento, interação e personagens aprovados complementam estas verificações.

Validação concluída em 5 de novembro de 2026: a noite contínua registou dez participantes, oito ainda presentes depois da meia-noite, 62 intervenções em conversa e 225 mudanças entre poses de dança. Passaram também o dia completo das histórias da rua, os encontros sociais, a caminhada, as interações e a renderização dos personagens; o verificador dos atlas aprovados do Te e do Jo passou. As capturas finais estão em `output/village-nightlife-open.png`, `output/village-nightlife-midnight.png` e `output/village-nightlife-day.png`.
