# Te — contrabalanço dos dois antebraços

Corrige a assimetria: o braço esquerdo do Te (lado direito da imagem) estava quase parado. Nesta revisão, ambos os antebraços alternam o avanço/recuo com amplitude semelhante, mantendo os ombros aproximadamente nivelados e os cotovelos estáveis junto ao tronco. As fases 1 e 3 mostram os avanços opostos; 2 e 4 são posições intermédias.

Atlas do jogo: `../../assets/characters/open_world/te-south-forearm-balance.png`. Cinco sprites completos de 400×560, paragem e quatro poses de caminhada, com a cadência existente de oito tempos. O jogo continua a desenhar cada personagem como uma imagem completa. A paragem é preservada da versão aprovada; só o Te a sul usa a revisão.

Ferramenta integrada `image_gen`, edição com transparência. Pedidos usados: [primeira edição com guia de movimento](prompt.txt) e [retoque localizado dos antebraços](prompt-panels.txt). Referências iniciais: `edit-target.png`, composto de poses completas da versão `te-south-level-yaw.png`, e `motion-guide.png`. A primeira pintura está em `first-pass.raw.png`, preparada em `first-pass-atlas.png`. O retoque usa `forearm-panels-target.png` e `forearm-panels-guide.png`; a pintura resultante está em `forearm-panels-edited.raw.png`.

Preparação inicial: `tools/pack_te_south_continuous.cjs`, escala comum, cabeça nivelada e paragem copiada da versão aprovada. Preparação final: `tools/bake_te_forearm_balance.cjs`, que integra a pintura dos antebraços nas fases 2 e 3. O registo do retoque conserva o cotovelo e alinha as mãos com os níveis pretendidos; a mão mantém a sua forma, variando a projeção do antebraço. O atlas final contém cinco sprites completos, sem articulação de peças no jogo. As fases 0, 1 e 4 ficam integralmente iguais à fonte; nas outras duas, os píxeis acima da linha 304 e abaixo da linha 400 mantêm-se intactos. A roupa é preservada onde não é coberta pelo braço.

Verificações: `tools/check_te_forearm_balance.cjs assets/characters/open_world/te-south-forearm-balance.png` mede ambas as mãos, alternância, posições intermédias, amplitude semelhante, estabilidade lateral dos cotovelos e nível dos ombros. A medição segue a faixa do braço para não confundir a pele da coxa com a mão. O controlo deteta a mão praticamente imóvel na versão anterior. `tools/check_te_south_continuity.cjs assets/characters/open_world/te-south-forearm-balance.png --level --tucked-elbows` verifica contorno dos cotovelos, cabeça, espessura dos antebraços e profundidade da passada.

Capturas no motor com `tests/te_south_level_test.gd`, terceira coluna Te/norte e saída nesta pasta. A apresentação geral usa `tests/character_rendering_test.gd`. `sul-norte-no-jogo.gif` compara as direções e `sul-lento.gif` permite observar o movimento mais devagar.

Resultados: excursão vertical das mãos de 11 e 10 píxeis na fonte, alternada, com posições intermédias. Os ombros ficam separados por no máximo 2 píxeis na vertical e o contorno dos cotovelos permanece recolhido. A cabeça varia apenas de 68 a 69 píxeis no teste ampliado do motor. As verificações de movimento, continuidade e renderização passam. Registos: `forearm-balance-check.txt`, `continuity-check.txt`, `head-level-check.txt` e `rendering-check.txt`. `no-jogo.gif` mostra o Te completo à cadência real capturada no motor.

Para experimentar: **Esc → Testar caminhada · só chão**.
