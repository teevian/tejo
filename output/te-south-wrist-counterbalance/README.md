# Te — pequeno contrapeso dos punhos ao caminhar para sul

Revisão da versão aprovada em `../te-south-level-yaw/`: um pouco mais de avanço alternado dos punhos junto à frente da cintura, em oposição à perna que avança, acompanhado pelo ombro desse braço. Cabeça praticamente nivelada e rotação subtil do rosto preservadas. A pose de paragem é copiada integralmente da versão aprovada.

Sprite do jogo: `../../assets/characters/open_world/te-south-wrist-counterbalance.png`. Cinco pinturas completas: paragem e quatro fases de caminhada, distribuídas pelos oito tempos existentes. Não há peças articuladas nem cabeça desenhada separadamente. Só o Te virado para sul usa este atlas.

Edição com a ferramenta integrada `image_gen`, transparência preservada. Pedidos completos: [primeira edição](prompt.txt) e [correção da alternância dos braços](prompt-correction.txt). Referência inicial: `../te-south-level-yaw/edited.raw.png`. A segunda edição usa `first-pass.raw.png` como alvo e a referência inicial para preservar o braço que recua. Fonte final: `edited.raw.png`.

Preparação: `tools/pack_te_south_continuous.cjs output/te-south-wrist-counterbalance te-south-wrist-counterbalance.png --level --idle-from=assets/characters/open_world/te-south-level-yaw.png`. Uma escala comum para todas as pinturas, posição horizontal pela cintura e altura pela cabeça do conjunto completo. A opção `--idle-from` conserva a pose de paragem, píxel por píxel.

Verificações: `tools/check_te_south_continuity.cjs assets/characters/open_world/te-south-wrist-counterbalance.png --level`, `tests/te_south_level_test.gd` e `tests/character_rendering_test.gd`. As capturas desta revisão são guardadas aqui; `no-jogo.gif` mostra a paragem e a caminhada renderizadas pelo próprio jogo.

Resultados: altura da cabeça no motor entre 68 e 69 píxeis nas oito fases, diferença de apenas 1 píxel no teste ampliado. Antebraços com variação de largura inferior a 8%, tamanho do cabelo com variação inferior a 3%. Pose de paragem idêntica à aprovada na comparação dos píxeis. Verificação geral das duas personagens aprovada. `punhos-lento.gif` permite observar o movimento mais devagar.

Para testar: **Esc → Testar caminhada · só chão**.
