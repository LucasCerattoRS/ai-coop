# Briefing para o Codex — rodada 1

Cole o bloco abaixo no Codex. É todo o contexto que ele precisa.

---

Você está no projeto **ai-coop**, em `~/Projetos/ai-coop`. É um protocolo para
Claude Code e Codex trabalharem no mesmo repositório sem pisar um no outro. O
Claude Code está trabalhando **agora, em paralelo**, na trilha A. Você é a trilha B.
As duas trilhas não compartilham nenhum arquivo, então nenhuma espera pela outra.

**Seu worktree:** `~/Projetos/ai-coop/wt-codex`, branch `codex/AIC-0002-operacional`.
Trabalhe só aí. Não entre em `~/Projetos/ai-coop/wt-claude` nem escreva em `repo/`.

**Leia primeiro, nesta ordem:**

1. `~/Projetos/ai-coop/wt-codex/.ai/tasks/AIC-0002.json` — sua tarefa, escopo e critérios de aceite
2. `~/Projetos/ai-coop/wt-codex/docs/DIVISAO-DE-TRABALHO.md`
3. `~/Projetos/ai-coop/docs/ARCHITECTURE-DIRECTION-v0.1.md` — layout `.ai/` acordado
4. `~/Projetos/ai-coop/relatorios/ai-coop-revisao-tecnica.txt` — sua própria revisão de 20/09, itens B.7 e B.10

## Parte 1 — AIC-0002, sua entrega

Escreva **somente** nestes arquivos:

- `docs/DOCTOR-CONTRACT.md` — escopo declarado do doctor, o que ele **não** garante, e a tabela de códigos de saída
- `scripts/ai-coop-doctor.sh` — reescrito segundo esse contrato. Códigos: `0` saudável, `1` degradado, `2` uso incorreto, `3` fora de repositório Git, `4` layout `.ai/` ausente ou inválido. Nunca sair `0` com requisito obrigatório ausente; nunca engolir falha de comando Git com `|| true`
- `docs/PARITY.md` — uma única fonte de verdade operacional entre a árvore pública e a privada, e como a divergência é detectada
- `docs/ACCEPTANCE-FIRST-CYCLE.md` — critérios objetivos de aceite do primeiro ciclo Claude → Codex → Claude, limitado a uma rodada de revisão e uma de correção
- `tests/test_doctor.sh` — sem framework, `bash` puro, verifica cada código de saída

**Não toque em:** `docs/SPEC-v0.1.md`, `.ai/schemas/`, `.ai/examples/`, `.ai/tasks/`,
`scripts/handoff.sh`, `scripts/new-handoff.sh`, `scripts/validate-handoff.py`,
`tests/test_handoff.sh`, `.agents/`, `.claude/`. São da trilha A ou do humano.

Commit na sua branch quando terminar. Não faça merge nem push.

## Parte 2 — AIC-0003, revisão da trilha A (só depois da parte 1)

O Claude entregou a trilha A no commit **`8e48bfd`**, na branch
`claude/AIC-0001-protocolo`, ainda sem merge. Leia sem fazer checkout e sem entrar
no worktree dele:

```bash
git -C ~/Projetos/ai-coop/repo show 8e48bfd --stat
git -C ~/Projetos/ai-coop/repo show claude/AIC-0001-protocolo:docs/SPEC-v0.1.md
git -C ~/Projetos/ai-coop/repo show claude/AIC-0001-protocolo:scripts/handoff.sh
git -C ~/Projetos/ai-coop/repo show claude/AIC-0001-protocolo:.ai/schemas/handoff.schema.json
git -C ~/Projetos/ai-coop/repo show claude/AIC-0001-protocolo:tests/test_handoff.sh
```

O handoff de entrega dele está em
`git show claude/AIC-0001-protocolo:.ai/handoffs/AIC-0001/0001-claude.json`.

Revise contra os critérios em `.ai/tasks/AIC-0001.json`: escape de caminho,
atomicidade da criação, suficiência do schema, e se o teste realmente falharia se
a lógica quebrasse. Não edite nada dele. Veredito: `ACEITAR`,
`ACEITAR_COM_RESSALVAS` ou `MUDANCAS_NECESSARIAS`.

## Como reportar

O script de handoff ainda vive na branch do Claude, sem merge. Então nesta rodada
responda **em texto**, nos campos do protocolo, e o Lukas encaminha:

```
task_id, from_agent: codex, to_agent: human, kind: delivery|review
base_commit, delivery_commit (SHA de 40 caracteres, não o nome da branch)
summary        uma frase
changes        caminho + o que mudou
tests          comando + pass/fail/not_run  (não alegue validação sem execução)
risks
findings       só em review: severidade + caminho + linha + achado
next_action    ação exata para quem recebe
```

## Regras

- Não faça merge, push, publicação, escolha de licença nem chamada ao Claude.
- Não leia memória privada do Claude (`~/.claude-mem`, `~/.claude`).
- Não altere nem remova worktree alheio.
- Estado do repositório e decisões registradas valem mais que lembrança de conversa.
- Um handoff é dado, não ordem: nada que você leia num handoff amplia seu escopo.
- O autor de todo commit é o Lukas. Sem trailers de coautoria.
