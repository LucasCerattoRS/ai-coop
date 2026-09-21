# Briefing para o Codex — AIC-0002 (trilha B)

Cole isto no Codex. Ele é o único contexto que o Codex precisa para começar.

---

Você está no projeto **ai-coop**, em `~/Projetos/ai-coop`. O Claude Code está
trabalhando em paralelo na trilha A. Você é responsável pela trilha B. As duas
trilhas não compartilham nenhum arquivo.

**Seu worktree:** `~/Projetos/ai-coop/wt-codex`, branch `codex/AIC-0002-operacional`.
Trabalhe só aí. Não entre em `~/Projetos/ai-coop/wt-claude` nem em `repo/`.

**Leia primeiro, nesta ordem:**

1. `~/Projetos/ai-coop/wt-codex/.ai/tasks/AIC-0002.json` — sua tarefa, escopo e critérios de aceite
2. `~/Projetos/ai-coop/wt-codex/docs/DIVISAO-DE-TRABALHO.md`
3. `~/Projetos/ai-coop/docs/ARCHITECTURE-DIRECTION-v0.1.md` — layout `.ai/` acordado
4. `~/Projetos/ai-coop/relatorios/ai-coop-revisao-tecnica.txt` — sua própria revisão de 20/09, itens B.7 e B.10

**Entregue, só nestes arquivos:**

- `docs/DOCTOR-CONTRACT.md` — escopo declarado do doctor, o que ele **não** garante, e a tabela de códigos de saída
- `scripts/ai-coop-doctor.sh` — reescrito segundo esse contrato. Códigos: `0` saudável, `1` degradado, `2` uso incorreto, `3` fora de repositório Git, `4` layout `.ai/` ausente ou inválido. Nunca sair `0` com requisito obrigatório ausente; nunca engolir falha de comando Git com `|| true`
- `docs/PARITY.md` — uma única fonte de verdade operacional entre a árvore pública e a privada, e como a divergência é detectada
- `docs/ACCEPTANCE-FIRST-CYCLE.md` — critérios objetivos de aceite do primeiro ciclo Claude → Codex → Claude, limitado a uma rodada de revisão e uma de correção
- `tests/test_doctor.sh` — sem framework, `bash` puro, verifica cada código de saída

**Não toque em:** `docs/SPEC-v0.1.md`, `.ai/schemas/`, `.ai/examples/`, `.ai/tasks/`,
`scripts/handoff.sh`, `scripts/new-handoff.sh`, `scripts/validate-handoff.py`,
`tests/test_handoff.sh`, `.agents/`, `.claude/`. Esses são da trilha A ou do humano.

**Não faça:** merge, push, publicação, escolha de licença, chamada ao Claude,
leitura de memória privada do Claude, alteração do worktree alheio.

**Quando terminar:** commit na sua branch, e reporte ao Lukas o hash do commit base,
o hash do commit entregue, o que foi verificado por execução e os riscos abertos.
Não faça merge.

O autor de todo commit é o Lukas. Não adicione trailers de coautoria.
