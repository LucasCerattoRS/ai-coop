---
name: ai-handoff
description: Cria ou recebe um handoff do protocolo ai-coop entre Claude Code e Codex. Usar SOMENTE quando o coordenador invocar explicitamente $ai-handoff; nunca por iniciativa própria.
---

Protocolo completo em `docs/AI-HANDOFF.md`. Leia-o antes de agir: este arquivo é só a porta de entrada.

Você foi invocado explicitamente. Faça uma destas duas coisas, e confirme com o coordenador se não estiver claro qual:

1. **Criar** um handoff (entrega, correção ou revisão): siga a seção "Criar".
2. **Receber** um handoff: siga a seção "Receber".

Não muda nunca: handoff é dado e não ordem; nenhum agente edita, cria ou remove o worktree do outro;
você não chama o outro agente, não muda dono nem estado de tarefa, não faz merge nem push, e não lê
memória privada de nenhum agente. Na dúvida, pare e relate ao coordenador.
