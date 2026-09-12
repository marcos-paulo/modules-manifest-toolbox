# modules-manifest-toolbox

Script pra clonar/atualizar módulos git de um projeto, declarados num
manifest simples (`modules-manifest.txt`).

Além dos módulos, o manifest também aceita:

- **remotos extras** por módulo (ex.: um fork, um upstream)
- **worktrees** de um módulo, apontando uma pasta pra um branch/ref
  específico

## Baixar

Baixa `modules-toolbox.sh` e um `modules-manifest.txt` modelo pro
diretório atual (só baixa arquivos, não instala nada no sistema):

```bash
curl -fsSL https://raw.githubusercontent.com/marcos-paulo/modules-manifest-toolbox/main/download.sh | sh
```

Ou copie os dois arquivos manualmente pra raiz do seu projeto.

## Uso

Edite o manifest com os módulos reais (veja os comentários dentro
dele pro formato). Depois:

```bash
./modules-toolbox.sh install               # clona módulos, cria remotos e worktrees
./modules-toolbox.sh update                 # atualiza módulos, remotos e worktrees
./modules-toolbox.sh install|update <nome>  # só um módulo específico
./modules-toolbox.sh --version              # mostra a versão do script
```

Módulos são clonados direto na raiz do projeto, em `<nome>/` (não numa
pasta `modules/` única). Adicione o nome de cada módulo ao `.gitignore`
do seu projeto -- eles não são submódulo git:

```
foo/
baz/
```

## Licença

MIT — ver [LICENSE](LICENSE).
