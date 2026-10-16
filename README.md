# Tinkaton: referência de martelada

Abra `project.godot` no Godot 4.7 e pressione F5. A cena principal é
`tinkaton_lab.tscn`; o laboratório original com cubos continua em `main.tscn`.
`tinkaton_idle.tscn` mostra o mesmo personagem parado, com os braços relaxados
e sem o martelo. Os botões "Ver parado sem martelo" e "Ver martelada" alternam
entre as duas cenas. Fundo, altura, câmera, iluminação e shader são os mesmos.
Na cena parada, "Salvar pose parada em PNG" gera
`references/tinkaton_sem_martelo.png`, sem a interface.

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
- `toon_reference.gdshader`: texturas sem reflexos, com iluminação real em faixas
  sem sombra projetada no chão. A luz principal fica a 45° na lateral e na elevação, com tom quente
  e preenchimento ambiente frio, inspirada em iluminação Rembrandt.
- `pixel_reference.gdshader`: pixels de tela e quantização de cores.
- `anime_outline.gdshader`: contorno de silhueta em roxo escuro.

As duas cenas usam acabamento anime pixelado: saturação reforçada, cel shading
em três faixas, preenchimento colorido nas sombras e contorno de silhueta.
O tamanho dos pixels e a quantidade de níveis de cor continuam ajustáveis.

A projeção aprovada usa câmera ortográfica superior e cisalhamento dos objetos:
`tela_x = x - 0.5*y`, `tela_y = z - 0.5*y`. O chão permanece quadrado, e a
altura é projetada para cima e à esquerda. Esse laboratório de renderização
não implementa física ou colisões para o personagem.

A cabeça do martelo está girada -90° em torno do cabo para apresentar a face
frontal durante o golpe, mantendo a mesma trajetória da animação.

O fundo de referência é liso, amarelo `#FFFF00`, sem o piso quadriculado.
O personagem está elevado 1,46 unidades em Y (altura no Godot, equivalente ao
Z do Blender). O ponto mais baixo do martelo nas 61 poses fica acima do plano
do chão, com margem de aproximadamente 0,056 unidade.
