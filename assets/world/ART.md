# Serra de Sintra — arte da zona aberta

Todas as imagens desta revisão foram criadas com a **ferramenta de imagem integrada**, sem CLI/API externa. As pinturas de Sintra já existentes e os retratos/sprites aprovados de Te e Jo foram usados como referências de estilo e identidade. O mapa é uma interpretação artística, não uma reprodução cartográfica da serra.

## Assets finais em uso

| Asset | Ficheiro | Prompt |
| --- | --- | --- |
| Terreno noroeste | [sintra-nw.png](terrain/sintra-nw.png) | [prompt](terrain/sintra-nw.prompt.md) |
| Terreno nordeste / ponte de madeira / ruínas | [sintra-ne.png](terrain/sintra-ne.png) | [prompt](terrain/sintra-ne.prompt.md) |
| Terreno sudoeste / entrada | [sintra-sw-humid.png](terrain/sintra-sw-humid.png) | [prompt](terrain/sintra-sw-humid.prompt.md) |
| Terreno sudeste / ponte de pedra | [sintra-se.png](terrain/sintra-se.png) | [prompt](terrain/sintra-se.prompt.md) |
| Árvores, fetos, pedras, fonte e banco | [sintra-overhead-props-cutout.png](sintra-overhead-props-cutout.png) | [geração](sintra-overhead-props.prompt.md), [refinamento alfa](sintra-overhead-props-cutout.prompt.md) |
| Te, poses direcionais | [te-directions.png](../characters/open_world/te-directions.png) | [prompt](../characters/open_world/te-directions.prompt.md) |
| Jo, poses direcionais | [jo-directions.png](../characters/open_world/jo-directions.png) | [prompt](../characters/open_world/jo-directions.prompt.md) |

As quatro zonas têm 1448×1086 px cada e são desenhadas numa área de 4800×3600 unidades, com sobreposição suave nas juntas. A zona sudeste tem um ajuste de coordenadas na margem superior para ligar visualmente o curso da ribeira. As colisões e os pontos de interesse foram alinhados ao terreno final.

## Referências e etapas conservadas

- `sintra-overhead-ground.png` e respetivo `.prompt.md`: composição geral original.
- `sintra-overhead-ground-detail.png` e respetivo `.prompt.md`: refinamento intermédio, também usado como fundo por baixo das juntas. A resolução solicitada no prompt era 3072×2304; a ferramenta devolveu 1448×1086. Por isso foram geradas quatro zonas separadas para a textura final.
- `sintra-overhead-props.png`: primeira versão do atlas de objetos.
- `../backgrounds/sintra-trail.png`: referência de pintura.
- `../characters/te/te-portrait.png` e `../characters/jo/jo-portrait.png`: retratos aprovados, conservados na interface.

Os sprites são recortados no jogo a partir das silhuetas ligadas, com escala uniforme. As copas são objetos independentes e opacos; não fazem parte da textura do chão. Os personagens e os elementos de vegetação usam `shaders/opaque_cutout.gdshader` para manter a pintura opaca e os intervalos entre folhas vazios. O arco e partes das paredes são recortes da própria pintura desenhados como camadas sólidas, permitindo sobreposição por profundidade.

## Revisão húmida e extensão sul — 29 outubro

Criada com a ferramenta de imagem integrada a partir das novas fotografias fornecidas pelo utilizador. Originais conservados. Mapa ampliado para **4800×5400**, mais 50% de área; as quatro zonas originais conservam as suas coordenadas.

- [Terreno húmido da entrada](terrain/sintra-sw-humid.png), [prompt](terrain/sintra-sw-humid.prompt.md): substituição da pintura seca, mantendo a geometria.
- [Extensão sul](terrain/sintra-south.png), [prompt](terrain/sintra-south.prompt.md): bosque de hera, ravina com passadiço, escadaria de musgo e encosta da muralha. Textura 2048×768 numa faixa de 4800×1860, com transição de 60 unidades.
- [Árvores altas com hera e musgo](sintra-humid-trees.png), [prompt](sintra-humid-trees.prompt.md): atlas transparente; troncos colidem no chão e partilham ordenação com personagens.
- [Galhos elevados](sintra-high-branch.png), [prompt](sintra-high-branch.prompt.md): camada próxima com paralaxe de 8,5% e ligeira suavidade ótica. As superfícies continuam opacas, apenas os intervalos entre folhas são vazios.

A névoa fica sobre o chão e sob os personagens. A encosta é sugerida pela pintura, degraus, pequenos muros de contenção e planos de vegetação; a locomoção continua num plano 2D. A terceira ponte tem uma abertura inclinada nas colisões. Novos pontos de interesse incluem diálogos e descoberta no mapa.

## Galhos sem cortes retangulares

O primeiro plano usa agora [sintra-high-branch-complete.png](sintra-high-branch-complete.png), criado com a ferramenta integrada ([prompt](sintra-high-branch-complete.prompt.md)). A silhueta inteira, incluindo pontas de madeira e folhas, cabe dentro da imagem; as quatro bordas são transparentes. A versão antiga, desenhada até às margens, fica conservada mas não é usada. O movimento de paralaxe e o foco mantêm-se. `tests/branch_edges_preview.gd` verifica o alfa das quatro margens e captura três posições de câmara.


## Serra dispersa — 30 outubro

As pinturas atuais estão em [heritage/](heritage/ART.md), uma por local, e têm detalhe por unidade superior ao do terreno anterior. O mapa tem 12000×7560 unidades, o dobro da área de 8400×5400. O chão de expansão inclui bosque, hera, carvalhal, urzal e charcos em `expansion/`; árvores e fauna independentes preservam profundidade e comportamentos da floresta. [Prompts e parâmetros finais](heritage/ART.md).

A primeira pintura conjunta, `terrain/sintra-heritage.png`, fica conservada como referência e deixou de ser usada no jogo. As seis localizações atuais estão distribuídas pelo mundo em `scripts/sintra_heritage.gd`, com bases sólidas e recortes de profundidade alinhados à arte individual.

## Separação de chão, volumes e primeiro plano

Os recortes de `scripts/terrain_scenery.gd` e `scripts/sintra_heritage.gd` usam as coordenadas das pinturas originais, sem alterar nem reduzir as imagens. Cada objeto tem uma silhueta visual e, quando sólido, uma base poligonal independente. A mesma base cria a colisão física e impede a navegação; a altura visual só participa na ordenação pelos pés. Rochas grandes não podem ser atravessadas, copas podem tapar o corpo sem bloquear toda a sua largura, e as aberturas de arcos e pórticos ficam separadas dos apoios. As pedras da expansão acompanham os espelhamentos de cada chão e deixam de existir nas regiões cobertas por outra pintura.

As três árvores da Mata Relíquia têm máscaras SVG em `heritage/relic-oak-*-mask.svg`. São contornos editáveis, alinhados aos 1254×1254 pixels da pintura: vermelho preserva a madeira e verde delimita a folhagem. `painted_tree_cutout.gdshader` exclui a terra e as aberturas entre ramos, mantendo a cor original das superfícies. Estas máscaras foram desenhadas nas coordenadas da arte existente; não foram geradas novas pinturas. O teste gráfico `tree_cutout_rendering_test.gd` verifica transparência no chão, opacidade dos troncos e concordância com a visibilidade da fauna.
