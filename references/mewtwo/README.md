# Mewtwo — render Tibia

Modelo original: `assets/mewtwo/source/Mew-two.fbx`, extraído do ZIP fornecido.

Render 3D real no Godot, usando a projeção oblíqua do laboratório:
`tela_x = x - 0.5*y`, `tela_y = z - 0.5*y`.

- `mewtwo_*_128.png`: sprites em 128 × 128.
- `mewtwo_*_256.png`: sprites em 256 × 256.
- `mewtwo_*_768.png`: versão de 256 × 256 ampliada com vizinho mais próximo.
- `mewtwo_8_direcoes.png`: folha em 4 colunas e 2 linhas, de 0° a 315° em passos de 45°.

Todos os PNGs têm fundo transparente. A textura original recebe duas faixas de
iluminação (78% e 100%), sem reflexos. O contorno preto externo tem um pixel na
resolução nativa. A pose é a fornecida no FBX.

Para reproduzir a exportação em 256 × 256, execute com Godot 4.7:

```powershell
godot --path . res://mewtwo_render.tscn
```

Para exportar em 128 × 128, altere `RESOLUTION` em `mewtwo_render.gd` e o
sufixo do arquivo correspondente. A exportação fecha a cena ao terminar.
