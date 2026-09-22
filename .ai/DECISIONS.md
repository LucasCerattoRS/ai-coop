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

**Reversal conditions:**

Rever uma decisão via nova tarefa, novo handoff e commit corretivo; nunca
editar handoff publicado.
