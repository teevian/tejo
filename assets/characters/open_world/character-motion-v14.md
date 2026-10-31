# Movimento v14

Os rostos vêm das poses paradas dos atlas aprovados v9. A cabeça, o maxilar e o pescoço são preservados juntos, com estreitamento localizado abaixo do maxilar e transição para a t-shirt. Não são usadas as pinturas faciais geradas em v12.

Cada direção usa dois ângulos horizontais pequenos (−2° e +2°), alternados a cada meia passada. A projeção mantém a altura dos olhos e atenua o movimento até à gola. A altura total e o ponto de apoio são comuns entre direções.

A gola usa como referência as poses neutras de `sources/te-natural-body-v9.png` e `sources/jo-body-v8.png`. A largura dos braços é normalizada localmente em relação à pose neutra, preservando a posição de cada braço e as silhuetas originais dos calções e das pernas. Jo usa a correção anterior dos joelhos para sul.

Reconstrução: `tools/pack_character_necks.cjs` com Node e Sharp. O resultado é registado em `neck-motion-v14.recipe.json`. Pré-visualizações: `tools/preview_character_motion.cjs`; capturas no jogo: `tools/preview_shared_characters.gd -- --motion-v14 --all-directions`.

Para sul, a cabeça não sofre translação: cabelo, orelhas, contorno do maxilar e pescoço mantêm a mesma posição. A projeção interna do nariz varia mais do que a dos olhos e bochechas, para sugerir uma rotação vertical subtil. `tools/check_south_head_yaw.cjs` verifica o contorno fixo e a diferença de projeção entre nariz e olhos nas duas fases.
