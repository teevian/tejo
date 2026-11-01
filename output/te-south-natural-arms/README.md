# Te a sul — movimento conjunto do braço

Revisão da altura e da rigidez dos cotovelos. Os braços foram redesenhados desde as mangas, com inclinação do braço superior e movimento do cotovelo acompanhando a rotação do antebraço. As referências são a caminhada para norte e os quatro recortes da caminhada lateral realmente usada em `te-walk-v14.png`.

Ativo: `assets/characters/open_world/te-south-natural-arms.png`, cinco células de 400×560, paragem e quatro fases de caminhada. A cadência do jogo mantém-se. A edição foi feita com a ferramenta integrada ImageGen, com os pedidos em `prompt.txt` e `prompt-passing.txt`. `extremes.raw.png` contém a pintura dos extremos; `passing.raw.png` contém as fases intermédias. `edited.png` reúne as fases na ordem correta para as pernas existentes.

`tools/pack_te_natural_arms.cjs` regista a pintura pelo centro da camisola e pela ligação da manga ao braço. Os cotovelos não têm posição imposta nem são copiados de uma pose comum. O braço superior, antebraço e punho mantêm o movimento da pintura. O contorno da manga é conciliado com o tronco e os braços antigos são retirados antes de integrar os novos.

Inspeção visual em `sequencia.png`, `caminhada.gif` e `bracos.gif`, com a resposta de transparência do shader aplicada à pré-visualização. Não são capturas do motor. `motion-measurements.json` regista os braços conectados e a variação entre fases; o teste antigo de cotovelos fixos não se aplica a esta revisão. A preservação da paragem, cabeça e parte inferior das pernas é verificada em `preservation-check.txt`.
