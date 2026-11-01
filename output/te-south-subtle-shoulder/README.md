# Te a sul — pequeno avanço do ombro

Retoque localizado da passada aprovada `te-south-proportions.png`. O cotovelo do braço que avança desloca-se três píxeis para dentro nas poses de avanço maior e cerca de um píxel nas fases intermédias. A deslocação diminui gradualmente em direção ao ombro e ao punho; não há deslocação vertical nem escala do braço.

A ferramenta integrada ImageGen fornece um ligeiro retoque das pregas da manga em `edited.raw.png`, a partir dos recortes ampliados `target.png` e do pedido `prompt.txt`. A integração limita essa resposta de cor a 14% no máximo, em píxeis opacos da manga com cores semelhantes. A geometria usa os próprios píxeis da passada aprovada para conservar a espessura e a textura.

Preparação: `tools/bake_te_subtle_shoulder.cjs`. Atlas aplicado ao jogo: `assets/characters/open_world/te-south-subtle-shoulder.png`. `verification.json` verifica que todas as mudanças ficam no ombro/cotovelo que avança e que a posição das mãos e a espessura medida dos antebraços continuam iguais. `caminhada.gif` e `sequencia.png` são pré-visualizações dos sprites com a transformação de transparência do shader aplicada.
