# Te — braços de sul com o ciclo de norte como referência

O balanço anterior abria os cotovelos e aproximava o gesto de uma flexão lateral. Esta revisão mantém os braços junto às costelas e os cotovelos sob os ombros; as mãos alternam para a frente e para trás junto à própria anca, acompanhadas pelo ombro. O ciclo original de norte serve de referência para o gesto e mantém-se no jogo. A cabeça de sul fica praticamente à mesma altura e a pose de paragem é preservada integralmente.

Ativo: `../../assets/characters/open_world/te-south-north-matched.png`. Cinco sprites completos, paragem e quatro fases de caminhada com a cadência existente de oito tempos. Sem articulação de peças no jogo ou cabeças desenhadas separadamente. Só foi substituído o atlas do Te para sul.

Edição com a ferramenta integrada `image_gen`, com transparência. Pedidos completos: [pedido inicial](prompt.txt), [ajuste da amplitude](prompt-correction.txt) e [segunda metade do ciclo](prompt-bottom.txt). Referências iniciais: `../te-south-level-yaw/edited.raw.png` e `north-four-reference.png`, recortada do atlas v14 realmente usado a norte. A pintura inicial está em `first-pass.raw.png`; a segunda em `second-pass.raw.png`; as duas fases opostas revistas em `bottom-edited.raw.png`.

Preparação: as três primeiras poses completas de `top-source-atlas.png` e o par de poses completas de `bottom-edited.raw.png` são compostos por `tools/assemble_te_south_north_matched.cjs`. O resultado, `edited.raw.png`, é preparado com `tools/pack_te_south_continuous.cjs output/te-south-north-matched te-south-north-matched.png --level --idle-from=assets/characters/open_world/te-south-level-yaw.png`. Escala uniforme e registo do conjunto completo pela cintura e altura da cabeça; sem máscaras de membros, pescoço ou rosto. A paragem é copiada diretamente da versão aprovada.

Verificação do atlas: `tools/check_te_south_continuity.cjs assets/characters/open_world/te-south-north-matched.png --level --tucked-elbows`. O controlo adicional mede o contorno dos cotovelos face à posição relaxada de paragem; deteta a abertura lateral da versão rejeitada e aceita esta revisão. Cabeça, dimensões visíveis dos antebraços e profundidade dos pés também são verificadas. A opção para os cotovelos não altera os critérios de cabeça/antebraços já existentes.

Comparação no motor: `tests/te_south_level_test.gd`, com a terceira coluna a mostrar o Te a norte em vez do Jo e as capturas nesta pasta. `sul-norte-no-jogo.gif` mostra sul parado, sul a caminhar e norte a caminhar ao mesmo ritmo. `sul-lento.gif` mostra o sul mais devagar. `tests/character_rendering_test.gd` confere as duas personagens nas restantes poses.

Resultados: os controlos do atlas passam, incluindo o limite de abertura lateral dos cotovelos. A altura da cabeça no motor varia apenas de 68 a 69 píxeis no teste ampliado; a pose parada conserva os píxeis da versão aprovada. A verificação geral de renderização também passa. Registos: `continuity-check.txt`, `head-level-check.txt` e `rendering-check.txt`.

Para testar: **Esc → Testar caminhada · só chão**, WASD/setas e Tab para trocar de personagem.
