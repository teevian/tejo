# Te a sul — acabamentos da passada aprovada

Retoques locais sobre `te-south-subtle-shoulder.png`, cuja animação foi aprovada. O pescoço fica ligeiramente mais fino. A T-shirt usa o tom dos ténis existentes, os calções passam a cinzento-claro neutro e as solas recebem o mesmo tom da T-shirt. As cinco poses, incluindo a paragem, partilham a paleta.

No ombro que recua, recupera-se subtilmente a largura da pose parada. O lado que avança conserva a rotação já aprovada. A correção limita-se ao tecido e à silhueta do ombro, terminando antes da região dos braços; não desloca cotovelos, antebraços, punhos ou mãos. Os contornos dos membros, pernas e pés conservam exatamente os píxeis de transparência a partir da linha 278.

Edição de referência com a ferramenta integrada ImageGen: `edit-reference.png`, pedido `prompt.txt`, resultado `edited-reference.raw.png`, normalizado apenas como referência de acabamento em `colour-reference.png`. A aplicação às poses aprovadas é feita por `tools/finish_te_south_details.cjs`, com máscaras de materiais e alterações locais de forma. As posições dos membros não são substituídas pelas da referência gerada.

Paleta da T-shirt e das solas: RGB 53, 52, 53, amostrado do ténis original. Base dos calções: RGB 193, 192, 194, derivada da referência cinzenta, preservando pregas e sombras. A largura do pescoço reduz-se até 5%; o ombro recuado recupera 80% da pequena diferença para a largura da paragem. Os registos completos estão em `recipe.json`.

Atlas aplicado no jogo: `assets/characters/open_world/te-south-final-details.png`. `verification.json` confirma a preservação das silhuetas dos membros, dos cotovelos, das posições das mãos, da espessura dos antebraços e do rosto/cabelo superior. Confirma também o afinamento do pescoço em cada pose, a manutenção do contorno do ombro que avança e a remoção de branco do material da sola.

`sequencia.png`, `caminhada.gif` e `parado-e-caminhar.gif` são pré-visualizações dos sprites com a transformação de transparência do shader aplicada. Não são capturas do motor. Apenas o atlas para sul é atualizado nesta revisão.
