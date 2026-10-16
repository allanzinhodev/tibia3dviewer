# Tinkaton: referência de martelada

Abra `project.godot` no Godot 4.7 e pressione F5. A cena principal é
`tinkaton_lab.tscn`; o laboratório original com cubos continua em `main.tscn`.

O modelo fornecido não continha animações. `Hammer_Slam` foi criada para este
estudo: preparação, levantamento, golpe à frente e recuperação em 2,5 segundos,
com 24 quadros por segundo. É uma animação de referência, sujeita a ajustes de
pose; não é uma animação oficial do jogo.

## Controles

- Espaço: pausar ou continuar.
- Setas esquerda/direita ou botões: avançar um quadro com a animação pausada.
- Barra de tempo: escolher uma pose.
- Velocidade: reproduzir mais devagar.
- Tamanho do pixel e níveis de cor: ajustar a referência visual.
- Direção do personagem: girar o modelo mantendo a projeção oblíqua.
- Roda do mouse: zoom; WASD: mover o enquadramento; R: restaurar.
- Salvar 12 poses em PNG: exportar a direção e o efeito atuais para `references/`.

Os PNGs individuais têm 800 × 800 na janela padrão. A folha de 12 poses tem
1024 × 768 e é lida da esquerda para a direita, de cima para baixo. A exportação
sobrescreve os arquivos de referência gerados anteriormente.

## Arquivos

- `assets/tinkaton/tinkaton.glb`: modelo texturizado, esqueleto e animação.
- `assets/tinkaton/source/Tera.blend`: arquivo original extraído do ZIP.
- `assets/tinkaton/source/tinkaton_animated.blend`: fonte editável animada.
- `prepare_tinkaton.py`: conversão de texturas, poses e exportação GLB pelo Blender.
- `toon_reference.gdshader`: texturas sem reflexos, com iluminação em faixas.
- `pixel_reference.gdshader`: pixels de tela e quantização de cores.

A projeção aprovada usa câmera ortográfica superior e cisalhamento dos objetos:
`tela_x = x - 0.5*y`, `tela_y = z - 0.5*y`. O chão permanece quadrado, e a
altura é projetada para cima e à esquerda. Esse laboratório de renderização
não implementa física ou colisões para o personagem.
