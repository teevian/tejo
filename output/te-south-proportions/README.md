# Te a sul — proporções dos ombros e antebraços

Revisão após a indicação de antebraços demasiado finos e ombros demasiado largos. A pintura repõe volume no antebraço, com transição gradual entre cotovelo e punho, e contém a silhueta dos ombros. Usa a personagem original em `proportion-reference.png` como referência de construção. Conserva a intenção de balanço do braço inteiro e a rotação dos punhos da revisão anterior.

Atlas aplicado em `scripts/open_world_art.gd`: `assets/characters/open_world/te-south-proportions.png`, cinco células de 400×560. A edição foi feita com a ferramenta integrada ImageGen: alvo `target.png`, pedido `prompt.txt`, resultado `edited.raw.png`.

`tools/pack_te_south_proportions.cjs` prepara as quatro figuras completas por escala uniforme e registo da altura e do centro da cabeça. Os ombros e braços provêm da mesma pintura, sem escalas independentes nem junções de mangas. A identidade estabelecida do rosto e do cabelo é reposta na região da cabeça, conciliada com o pescoço; a pose parada é preservada. A escala uniforme mantém as proporções internas do corpo pintado.

Conferência visual à escala real em `sequencia.png` e `caminhada.gif`. `antes-depois.gif` mostra a versão anterior à esquerda e a revisão à direita. As pré-visualizações aplicam a transformação de transparência usada pelo shader; não são capturas do motor.

`verification.json` regista a comparação das quatro fases: os ombros passam de 170 para 158–161 píxeis na faixa medida e os antebraços recuperam espessura em todas as fases. O rosto/cabelo superior e a paragem são preservados; a altura e o apoio dos pés mantêm-se dentro de um píxel. As medidas de pele são secções 2D para comparação entre versões, não uma medição anatómica 3D.
