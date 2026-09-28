# AIC-0010 — registro de atrito

Cada passo do protocolo que travou, confundiu ou foi contornado ao aplica-lo fora do laboratorio (repo `xilog-parsifal`).
Uma entrada por atrito, com evidencia. Ao final, vira lista de correcoes.

| # | Data | Atrito | Evidencia | Contorno | Correcao sugerida |
|---|---|---|---|---|---|
| 1 | 2026-09-23 | Nao ha guia de adocao em outro repo: nem lista de arquivos a levar, nem instalador. `PARITY.md` trata de arvore publica x privada, nao de adotar o protocolo | Foi preciso descobrir por leitura quais arquivos `handoff.sh`, os validadores e as skills exigem | `git archive` de uma lista escolhida a mao do commit `6c5a028`, versao gravada em `PROTOCOL-VERSION` | Documento ou script de adocao, com a lista minima e a checagem de versao |
| 2 | 2026-09-23 | O ID de tarefa e fixo em `^AIC-[0-9]{4}$` (allowlist do `handoff.sh`), entao o repo novo tem de usar `AIC-0001`, que colide de nome com a `AIC-0001` do ai-coop | `xilog-parsifal/.ai/tasks/AIC-0001.json` x `ai-coop/.ai/tasks/AIC-0001.json` | Aceitar a colisao e ligar as duas por texto nas notas | Prefixo configuravel por repo, mantendo a validacao anti path traversal |
| 3 | 2026-09-23 | `validate-task.py` aceita lista de arquivos sem avisar que so o modo sem argumento (ou `--scopes`) checa sobreposicao de escopo; a saida `0` parece prova de mais do que foi checado | Claude declarou "sem sobreposicao" apos rodar `validate-task.py .ai/tasks/*.json`, que so valida cada arquivo; corrigido depois rodando sem argumento | Rodar sem argumento e `--transition` | Imprimir o que foi checado, ou fazer o modo lista tambem checar escopo |
| 4 | 2026-09-23 | O hook `reference-transaction` barra ate commit de coordenacao em `main`; `MERGE-GUARD.md` fala em merge e push e nao explica que o coordenador precisa de `AI_COOP_HUMAN=1` para cada commit em `main` | `fatal: in 'prepared' phase, update aborted by the reference-transaction hook` ao registrar estado de tarefa | `AI_COOP_HUMAN=1` por comando, so apos ordem do coordenador | Documentar o caso na secao Cobertura |
| 5 | 2026-09-23 | O fluxo de transicao de estado exige um commit por passo (`ASSIGNED -> HANDED_OFF` e ilegal); nada no protocolo diz quem escreve cada commit intermediario nem avisa antes | `transicao ilegal: ASSIGNED -> HANDED_OFF` | Dois commits de coordenacao, por `IN_PROGRESS` | Regra explicita na SPEC ou um comando que faca a sequencia || 6 | 2026-09-27 | Agente fazendo papel de coordenador (commit em `main`, criar tarefa) por ordem do Lukas, contornando a trava com `AI_COOP_HUMAN=1`; a trava nao distingue ordem legitima de erro | devhub-web `3137c35`, `f08d8d4`, `6efb45d` | Variavel por comando | Regra de delegacao explicita (SPEC §1) e trava desativada por padrao |
| 7 | 2026-09-27 | Criar a tarefa de revisao depois de um handoff de entrega e trabalho manual e repetitivo (dono, commit exato, escopo so do canal) | devhub-web `AIC-0003`, escrita a mao | JSON a mao | `scripts/new-review-task.py` |
| 8 | 2026-09-27 | O proprio coordenador (agente delegado) pulou estado: `ASSIGNED -> UNDER_REVIEW` num commit so, sem nada avisar | devhub-web `6efb45d`, `.ai/tasks/AIC-0001.json` | Nenhum: ficou registrado como esta | `scripts/task-state.py` (#5) |

## Correcoes (AIC-0023, 27/09)

| # | Correcao |
|---|---|
| 1 | `scripts/adopt.sh DESTINO` instala/atualiza; `--check` compara versao arquivo a arquivo |
| 2 | prefixo por repo: `^[A-Z][A-Z0-9]{1,7}-[0-9]{4}$` em schemas, `handoff.sh` e validadores |
| 3 | `validate-task.py` no modo lista imprime que so checou formato |
| 4, 6 | trava desativada por padrao; delegacao escrita na SPEC §1 e no `AGENTS.md` |
| 5, 8 | `scripts/task-state.py` percorre o caminho legal, um commit por passo; regra escrita na SPEC §2 |
| 7 | `scripts/new-review-task.py HANDOFF NOVO_ID` |

## Ainda nao exercitado

- `/ai-handoff` no Claude em sessao nova (criterio de aceite da AIC-0010).
- Ciclo completo implementa -> handoff -> revisao no `xilog-parsifal`: bloqueado ate haver material em `fontes/`.
