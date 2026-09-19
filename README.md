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

`download.sh` baixa só `modules-toolbox.sh` (módulos). Pra worktrees do
próprio repositório, use o `download-self-worktrees.sh` (veja
[Worktrees do próprio repositório](#worktrees-do-próprio-repositório)
abaixo).

## Uso

Edite o manifest com os módulos reais (veja os comentários dentro
dele pro formato). Depois:

```bash
./modules-toolbox.sh clone                 # clona módulos, cria remotos e worktrees
./modules-toolbox.sh update                 # atualiza módulos, remotos e worktrees
./modules-toolbox.sh clone|update <nome>    # só um módulo específico
./modules-toolbox.sh --version              # mostra a versão do script
```

Módulos são clonados direto na raiz do projeto, em `<nome>/` (não numa
pasta `modules/` única). Adicione o nome de cada módulo ao `.gitignore`
do seu projeto -- eles não são submódulo git:

```
foo/
baz/
```

## Worktrees do próprio repositório

`modules-toolbox-self-worktrees.sh` é uma ferramenta separada: em vez de
clonar módulos, ela cria worktrees do **próprio repositório onde ela
mora** (a pasta do script precisa já ser a raiz de um repositório git).
Cada worktree nasce como pasta filha dessa raiz, irmã das outras -- nunca
um dentro do outro.

Manifest próprio, `self-worktrees-manifest.txt` (formato: linha
`worktree <pasta> <ref>`, ver comentários no arquivo).

Baixa os dois pro diretório atual (rode a partir da raiz de um
repositório git):

```bash
curl -fsSL https://raw.githubusercontent.com/marcos-paulo/modules-manifest-toolbox/main/download-self-worktrees.sh | sh
```

Uso:

```bash
./modules-toolbox-self-worktrees.sh clone                 # cria os worktrees que faltam
./modules-toolbox-self-worktrees.sh update                 # atualiza os worktrees existentes
./modules-toolbox-self-worktrees.sh clone|update <pasta>   # só um worktree específico
./modules-toolbox-self-worktrees.sh --version              # mostra a versão do script
```

Exemplo de resultado, com um worktree `dev`:

```
meurepo/
├── .git
├── modules-toolbox-self-worktrees.sh
├── self-worktrees-manifest.txt
└── dev/            <- worktree, filho da raiz, irmão do restante do repo
    └── .git
```

## Limitações

- Nenhum campo dos manifests (nome, url, ref, pasta, nome-do-remoto)
  pode ter espaço -- o parsing divide a linha por espaço/tab.
- Se um `ref` de worktree já estiver em uso em outro worktree do mesmo
  repositório, a criação/atualização daquele worktree falha e é pulada
  (o script continua com os demais módulos/worktrees).

## Licença

MIT — ver [LICENSE](LICENSE).
