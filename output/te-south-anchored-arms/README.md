# Te a sul — cotovelos estáveis

Revisão após a indicação de que os cotovelos se deslocavam demasiado. A parte superior dos braços e os cotovelos usam uma pintura comum nas quatro fases; o balanço vem dos antebraços, com mãos alternadas entre as posições 367 e 385 na fonte. As posições intermédias ficam aproximadamente em 379. Mantém o afinamento ligeiro dos antebraços.

Atlas aplicado ao jogo: `../../assets/characters/open_world/te-south-anchored-arms.png`. Edição com a ferramenta integrada ImageGen: `target.png`, `guide.png`, `prompt.txt` e `edited.raw.png`. Integração reproduzível: `tools/bake_te_anchored_arms.cjs`. O jogo continua a desenhar sprites completos.

Verificações: `tools/check_te_forearm_balance.cjs assets/characters/open_world/te-south-anchored-arms.png --anchored` exige deslocação e variação de contorno dos cotovelos de no máximo um píxel, além do balanço alternado das mãos. Resultado: ambos os cotovelos e os seus contornos variam zero píxeis; as duas mãos percorrem 18 píxeis. A verificação de continuidade também passa. Os registos estão em `motion-check.txt` e `continuity-check.txt`. `caminhada.gif` mostra as quatro poses completas do atlas, sem captura no motor.
