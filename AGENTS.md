# Sprites direcionais finais aprovados

O utilizador aprovou os sprites direcionais atuais do Te e do Jo e pediu expressamente para apagar todas as versões antigas, prompts e ficheiros de trabalho dessas revisões. Não voltar a introduzir esses materiais.

- Preservar integralmente `assets/characters/open_world/te-walk-friendly-painted-face.png` e `assets/characters/open_world/jo-walk-south-painted-face.png`. Alterar rosto, cabelo, corpo, roupa, proporções ou caminhada apenas por pedido direto do utilizador para o personagem em causa.
- A pasta `assets/characters/open_world/` contém apenas os dois atlas finais e os respetivos `.import` do Godot. Não guardar nela prompts, cópias ou fontes antigas.
- SHA-256, dimensões e geometria aprovados estão em `assets/characters/approved-directions.json`. Verificar com `node tools/check_approved_characters.cjs` antes de concluir alterações aos personagens. Uma revisão pedida diretamente pode atualizar esta referência, limitada ao pedido.
- Preservar a escala, apoios, fases e espelhamento de `scripts/open_world_art.gd`. São sprites completos, com cinco vistas autorais e quatro passadas em oito tempos, espelhadas para as oito direções.
- As poses de desenhar na areia, sentar e apanhar objetos continuam necessárias e estão separadas em `assets/characters/interactions/interaction-poses.png`, usadas por `scripts/interaction_art.gd`.
- Para validar mudanças à integração dos atlas, executar `tests/character_rendering_test.gd` com gráficos e `tests/walking_test.gd` e `tests/interactions_test.gd` sem janela. Não recriar testes de versões de sprites retiradas.

- O gesto do Te de pôr a mão no ombro foi eliminado a pedido do utilizador. A espera do Te é agora sentar-se no chão a desenhar na areia; não repor o gesto anterior.
