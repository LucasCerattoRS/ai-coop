# Decisions

Record durable architectural decisions here.

Recommended format:

## YYYY-MM-DD — Decision title

**Decision:**

**Context:**

**Alternatives considered:**

**Consequences:**

**Reversal conditions:**

## 2026-09-22 — Integração da rodada 3 e modelo operacional

**Decision:**

O coordenador autorizou integrar e publicar AIC-0008, AIC-0009, AIC-0011,
AIC-0012, AIC-0013 e AIC-0014, com seus seis pareceres independentes. Os
achados de AIC-0018 e AIC-0019 foram aceitos como não bloqueantes. GPT-5.6
Terra é aceito para o trabalho rotineiro deste projeto, com verificação
executável antes de integração/publicação.

**Context:**

As seis entregas e as revisões já estavam em branches locais; a cota do Claude
acabou. AIC-0013 instala a barreira local para impedir merge/push acidental.

**Alternatives considered:**

Esperar a volta do Claude ou abrir outra rodada para os dois polimentos
documentais. Ambos foram dispensados pelo coordenador.

**Consequences:**

Os commits de entrega e review entram em `main`; o coordenador ainda escolhe a
tarefa real AIC-0010. Terra não substitui testes, validação de handoff ou a
revisão proporcional ao risco.

**Execution:**

O canal privado de vulnerabilidades foi habilitado e confirmado no GitHub. Após
conceder o escopo OAuth `workflow`, `main` foi publicado e o CI concluiu com
sucesso no run 35786334427 para o commit 3647f93.

**Reversal conditions:**

Rever uma decisão via nova tarefa, novo handoff e commit corretivo; nunca
editar handoff publicado.

## 2026-09-27 — Trava de merge/push desativada; delegacao ao agente; AIC-0023 mergeada antes da revisao

**Decision:** A guarda local (AIC-0013) fica desativada por padrao (`core.hooksPath` removido
dos clones). O coordenador delega acoes de coordenacao ao agente por ordem explicita na conversa
(SPEC §1, "Delegacao"). A AIC-0023 (atritos) entrou em `main` antes da revisao do Codex (AIC-0024)
porque o devhub-web e o xilog-parsifal precisam do `adopt.sh` e do prefixo por repo agora.

**Context:** Pedido do Lukas em 27/09: "resolva todos os atritos antes ... tire a trava de
merge/push, desative-a". Atritos em `.ai/knowledge/AIC-0010-atrito.md`.

**Reversal conditions:** Achado bloqueante da AIC-0024 vira correcao por nova tarefa. Religar a
guarda: `bash scripts/install-hooks.sh`.
