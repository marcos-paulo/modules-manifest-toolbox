# modules-manifest-toolbox

Script pra clonar/atualizar módulos git de um projeto, declarados num
manifest simples (`modules-manifest.txt`).

Além dos módulos, o manifest também aceita:

- **remotos extras** por módulo (ex.: um fork, um upstream)
- **worktrees** de um módulo, apontando uma pasta pra um branch/ref
  específico

## Uso

Copie `modules-toolbox.sh` e `modules-manifest.txt` pra raiz do seu
projeto. Edite o manifest com os módulos reais (veja os comentários
dentro dele pro formato). Depois:

```bash
./modules-toolbox.sh install               # clona módulos, cria remotos e worktrees
./modules-toolbox.sh update                 # atualiza módulos, remotos e worktrees
./modules-toolbox.sh install|update <nome>  # só um módulo específico
./modules-toolbox.sh --version              # mostra a versão do script
```

Módulos são clonados em `modules/<nome>/` — adicione essa pasta ao
`.gitignore` do seu projeto:

```
modules/*
!modules/.gitkeep
```

## Licença

MIT — ver [LICENSE](LICENSE).
