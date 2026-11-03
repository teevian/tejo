# Olhos fechados durante o sono

Edição de pálpebras feita com a ferramenta integrada ImageGen sobre recortes registados dos desenhos aprovados. A composição final repõe apenas a região dos olhos sobre os píxeis originais; todos os píxeis exteriores às máscaras, incluindo cabelo, nariz, boca, corpo, roupa, mãos e o telefone, foram preservados.

- `te-sleep-poses.png` e `jo-sleep-poses.png`: 1920 × 560; três poses (costas, ombro esquerdo, ombro direito), células de 640 × 560 e apoio (320, 520).
- `te-sleep-roll.png` e `jo-sleep-roll.png`: 2560 × 1120; quatro fases para cada sentido da mudança de lado, com olhos fechados em todas as fases.
- `sleep-eyes.json`: recortes e máscaras dos olhos, com o registo de cada edição. `tests/sleep_art_test.gd` compara os ficheiros e confirma igualdade exata de todos os píxeis exteriores às máscaras e dos apoios entre poses e transições.

Os desenhos de sono são usados de dia e de noite. Sentados, semi-recostados e deitados de olhos abertos continuam a observar a natureza. Depois de ambos se deitarem começam esperas individuais de 5–10 s; cada um fecha os olhos no seu prazo e deixa de fazer os olhares de vigília. Ver [REST_SEQUENCE.md](REST_SEQUENCE.md). Mudar de ombro conserva os olhos fechados; começar a levantar repõe os desenhos acordados. Os atlas direcionais e os desenhos originais de descanso continuam preservados.

## Prompt final — ferramenta integrada

```text
Use case: precise-object-edit. Edit this exact 1024x1024 transparent 4x4 contact sheet of sixteen game character closeups. Change ONLY the eyes: in EVERY one of the sixteen panels, close BOTH eyes fully with natural relaxed closed eyelids, as if the character is peacefully ASLEEP. There must be no visible iris, pupil or white of an eye in any panel. Follow the existing eye angles, head rotations and facial anatomy; eyelids are a small soft dark curved line with a warm subtle lid shadow in the SAME painted cartoon RPG style. These are NOT squinting, winking, looking down or half-open eyes. Keep their expressions relaxed and faces recognizable, preserving exactly their nose, eyebrows, face shape, mouth, faint stubble on Te, hair, skin colours, pose, arms, shirt, outlines and existing shading. Absolutely no head or body movement, no new facial proportions, no repainting the surrounding image. Preserve exact panel positions, registration, canvas size 1024x1024, 4 columns by 4 rows, transparency and every other pixel as closely as possible. Top 8 panels are Te, bottom 8 are Jo; all 16 need CLOSED EYES. Do not add text, panel borders, background, effects, props or extra faces. This is a surgical eyelid-only edit for registered game sprites, not a character redesign.
```
