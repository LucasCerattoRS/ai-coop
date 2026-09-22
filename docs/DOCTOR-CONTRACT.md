# Contrato do `ai-coop-doctor.sh`

Execute `scripts/ai-coop-doctor.sh` sem argumentos, em qualquer diretório de um
worktree Git. O script examina a raiz desse worktree; não modifica arquivos.

`0` significa somente que o Git está disponível, `git rev-parse --show-toplevel`
identificou o worktree, `git worktree list --porcelain` funcionou e os requisitos
de layout abaixo existem na raiz:

- diretórios `.ai/`, `.ai/tasks/` e `.ai/schemas/`;
- arquivo não vazio `.ai/schemas/task.schema.json`.

Os três diretórios precisam ser diretórios reais, nunca symlinks. Um symlink em
`.ai`, `.ai/tasks` ou `.ai/schemas` produz `4`: o doctor não segue uma árvore
externa ao verificar o estado local autoritativo. Essa recusa evita que um
layout aparentemente saudável dependa de arquivos fora do worktree.

Essa é a parte do layout já fixada para esta rodada. `handoffs/`, `decisions/`,
`knowledge/` e `handoff.schema.json` não são requisitos do doctor nesta versão:
parte deles ainda depende da trilha A ou só passa a existir quando houver dados.

| Código | Significado |
|---|---|
| `0` | Checagens declaradas passaram. |
| `1` | Degradado: Git indisponível ou `git worktree list` falhou. |
| `2` | Uso incorreto: algum argumento foi passado. |
| `3` | Fora de worktree Git: `git rev-parse --show-toplevel` falhou. |
| `4` | Layout `.ai/` obrigatório ausente ou inválido. |

Em caso de múltiplos problemas, a precedência é: uso, Git disponível, worktree,
layout e listagem de worktrees. Falhas dos comandos Git são comunicadas; nenhuma
é convertida em sucesso.

O doctor **não garante** conteúdo ou validade do JSON/schema, estado correto da
tarefa, segurança de handoffs, paridade entre árvores, ausência de segredos,
isolamento de processos, integridade de memória privada, instalação dos agentes,
nem aptidão para publicação. Use os validadores, testes e revisão humana próprios
para essas afirmações.
