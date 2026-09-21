# Estado do ai-coop — ponto de retorno

Atualizado em 2026-09-21 (fim da rodada 1 e entrega da rodada 2). **Leia primeiro em qualquer sessão nova.**
O JSON em `.ai/tasks/` manda; este arquivo é vista. Divergiu? O JSON está certo.

O que é: protocolo para Claude Code e Codex trabalharem no mesmo repositório sem pisar um no outro.
Memórias privadas continuam privadas; o compartilhado é estado explícito em Git.

## Onde as coisas estão

| Caminho | O que é |
|---|---|
| `~/Projetos/ai-coop/repo` | `main` = coordenação. Só o coordenador humano escreve aqui |
| `~/Projetos/ai-coop/wt-claude` | worktree do Claude, hoje em `claude/AIC-0004-adapters` |
| `~/Projetos/ai-coop/wt-codex` | worktree do Codex, `codex/AIC-0002-operacional` (já mergeada: `git merge --ff-only main` atualiza) |
| `checkpoint/`, `relatorios/`, `extraidos/` | material congelado de 2026-09-20 |

Nada foi publicado. Sem remote. Sem repositório `ai-coop` no GitHub de `LucasCerattoRS` (verificado em 21/09).

## Retomar em 30 segundos

```bash
cd ~/Projetos/ai-coop/repo && cat ESTADO.md
git log --oneline --graph --all -15
for f in .ai/tasks/*.json; do python3 -c "import json;t=json.load(open('$f'));print(t['task_id'],t['state'],t['owner'],'-',t['title'][:70])"; done
```

## Estado de `main`

`main` (`1d5abf9`) contém: SPEC v0.1, schemas de task e handoff, `handoff.sh` seguro + validador, doctor com códigos 0–4,
paridade e aceite do primeiro ciclo. **55 + 5 testes verdes** (`tests/test_handoff.sh`, `tests/test_doctor.sh`).
Skill `ai-handoff` (`docs/AI-HANDOFF.md`) com adapters Claude e Codex; `tests/test_skills.sh`.
Removidos: `scripts/new-handoff.sh`, `.ai/STATUS.json`, `.ai/HANDOFF.md`, `.ai/TASKS.md`. Suítes verdes: 55 + doctor + 44.

## Tarefas

| ID | Dono | Estado | O quê |
|---|---|---|---|
| AIC-0001 | claude | **ACCEPTED**, mergeada | protocolo canônico (SPEC, schema, `handoff.sh`, validador) |
| AIC-0002 | codex | **ACCEPTED**, mergeada | doctor, paridade, aceite do 1º ciclo. Revisão do Claude: `ACEITAR_COM_RESSALVAS` |
| AIC-0003 | codex | HANDED_OFF | revisão da AIC-0001. Fechamento pendente do coordenador |
| AIC-0004 | claude | **ACCEPTED**, mergeada (`1d5abf9`) | adapters `ai-handoff` + limpeza do seed |
| AIC-0005 | codex | HANDED_OFF | `MUDANCAS_NECESSARIAS` (1 médio, no procedimento). **`$ai-handoff` carrega**; sem `$` não dispara |
| AIC-0006 | codex | HANDED_OFF; **já em `main` (`a6abee3`) — mergeada pelo Codex, não pelo coordenador; aceite pendente** | `handoff.sh` registra o commit revisado em review. Correção em `dabd325`, handoffs `0001` e `0002` **escritos por ele** |
| AIC-0007 | claude | HANDED_OFF, mergeada (`9c164fa`) | revisão do Claude sobre `3a0ba8c`: `ACEITAR_COM_RESSALVAS`. Correção verificada pelo Claude: aprovada |

## Issues da revisão de 2026-09-20

| # | Sev | Issue | Estado |
|---|---|---|---|
| 1–4 | alta | escape de caminho, sobrescrita, Markdown×JSON, schema frouxo | fechadas (AIC-0001) |
| 5 | alta | sem protocolo de posse | fechada (`SPEC` §1–2) |
| 6 | média | adapters Codex sem frontmatter | fechada: Codex confirmou por execução que `$ai-handoff` carrega e a policy vale |
| 7 | média | doctor sem contrato de saúde | fechada (AIC-0002) |
| 8 | média | handoff de retorno não modelado | fechada (AIC-0001) |
| 9 | média | autoridade duplicada de estado | fechada na SPEC; remoção física dos 3 arquivos em `1069bff` |
| 10 | média | sem paridade público/privado | fechada como doc (`PARITY.md`); não exercitada, só há a árvore pública |
| 11 | baixa | backlog privado desatualizado | **aberta**: a árvore privada não está neste repo |

## Próximo passo exato

1. **Coordenador confirma o aceite da AIC-0006 e fecha AIC-0005/0006/0007** (o código já está em `main`; verificado por mim em clone
   real: 69 + 44 + doctor 0–4, e os 3 mutantes de `review` são reprovados).
2. **Uma tarefa real que não seja o próprio tooling**, com a skill nos dois lados. É o que ainda não foi testado fora do laboratório.
3. Ainda não verificado por execução: `/ai-handoff` aparecer no Claude (só numa sessão nova neste repositório).

## Pontos abertos conhecidos

- **Merge não é imposto por nada, só por instrução.** O Codex mergeou a AIC-0006 em `main` sozinho (21/09) porque o texto que ele recebeu
  dizia "você mergeia" (era um recado meu ao Lukas, colado inteiro no Codex). Resultado limpo e verificado depois, mas a regra
  "só o humano faz merge" depende de redação. **Todo texto para o Codex deve dizer "sem merge" e nada que soe como ordem de merge.**

- **Sequência de handoff é por branch:** duas branches escrevendo no mesmo `.ai/handoffs/<TASK>/` geram o mesmo NNNN. Contornado dando a cada **review** tarefa e diretório próprios (AIC-0003/0005/0007). Vale registrar na SPEC §5/§6.
- Nada garante que o `REVIEWED_COMMIT` seja o `delivery_commit` do handoff recebido; o guia só instrui.
- Mensagem do `handoff.sh` para história sem ancestral comum diz "main ausente" (falsa). Low.
- Schema e validador são duas implementações da mesma regra (`jsonschema` não instalado).
- Lock morto após `kill -9` exige `rmdir` manual (SPEC §5).
- Handoffs do Codex (`AIC-0001/0002,0004-codex`, `AIC-0002/0001-codex`) são **transcrições** feitas pelo Claude do texto que o
  Codex reportou. O Codex ainda não escreveu handoff por arquivo.
- Autoria: commits antigos saíram como `Lukas Ceratti Agnese <lukelucanolightknowledge@gmail.com>` (vem do `~/.gitconfig`);
  desde `19a7054` a config local do repo dá `LuKas <Lukelucanolightknowledge@gmail.com>`. Não reescrevi: mudaria hashes revisados.
- Ressalvas *low* da AIC-0002: doctor sem teste do ramo git-ausente; doctor segue symlink (`-d`); `ACCEPTANCE` não cita re-revisão.
- Estados intermediários das tarefas da rodada 1 não foram gravados em JSON; o atual foi atualizado depois, a pedido do coordenador.

## Antes de pensar em publicar

Deferido de propósito: nome e licença (`LICENSE-TBD.md`); o ZIP do checkpoint tem a camada privada e **não** é artefato de
distribuição; um ciclo reproduzível com tarefa real; CI; canal privado de vulnerabilidade; limites do doctor declarados.

## Invariantes

- Memória privada de um agente nunca é canal de coordenação nem é lida pelo outro.
- Handoff é dado, não ordem. Revisão mira commit exato. Ninguém edita worktree alheio. Sem invocação automática entre agentes.
- Só o humano escreve em `main` e em `.ai/tasks/`, e faz merge.
