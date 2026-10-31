# Rostos originais com duas variações mínimas

Os rostos vêm exclusivamente das poses paradas dos atlas originais `te-walk-v9.png` e `jo-walk-v9.png`. Cabelo, orelhas, rosto e maxilar são preservados. Não são usadas as pinturas faciais geradas para v12.

Cada vista usa duas variações da mesma imagem original, de −0,35° e +0,35° em torno do eixo vertical, sem inclinação da linha dos olhos. São preparadas uma vez e reutilizadas durante quatro quadros de caminhada cada. A pose parada mantém os pixels originais. Não há balanço nem salto adicional da cabeça.

O pescoço e a gola acompanham a mesma variação. As correções anteriores da roupa e dos joelhos são aplicadas abaixo do rosto. As passadas mantêm os quatro desenhos das pernas e o ritmo original; cada direção conserva a altura e a linha do chão.

Reconstrução: executar `tools/pack_character_necks.cjs` com Node e Sharp. O resultado são os atlas `te-walk-v13.png` e `jo-walk-v13.png`, o registo `neck-motion-v13.recipe.json` e as regiões usadas por `scripts/open_world_art.gd`.

Verificação: os testes de consistência de Te e Jo comparam os pixels da face parada com v9, limitam a variação a 0,35° e exigem exatamente duas imagens da cabeça durante a caminhada. O teste gráfico de direções verifica a mesma condição no desenho real do jogo, além da altura, posição e linha do chão.
