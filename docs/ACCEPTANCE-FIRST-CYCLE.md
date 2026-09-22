# Aceite do primeiro ciclo Claude → Codex → Claude

O ciclo é coordenado pelo humano. Ele atribui a implementação ao Claude, a revisão
ao Codex e decide o aceite. Cada agente trabalha no próprio worktree; revisão
aponta para o SHA completo do commit entregue, sem checkout da branch alheia.

O ciclo passa somente quando há evidência verificável de todos os itens:

1. A tarefa autorizada em `.ai/tasks/<TASK-ID>.json` identifica escopo, dono e
   critérios. Nenhum commit da entrega toca caminho proibido.
2. Claude entrega um commit e um handoff com SHA completo, arquivos alterados,
   testes executados com resultado e riscos. O handoff não altera a autoridade da
   tarefa.
3. Codex faz **uma** revisão do commit exato, sem editar o trabalho do Claude.
   O parecer registra veredito, achados com severidade e caminho/linha quando
   aplicável, comandos realmente executados e próximo passo.
4. Se houver mudanças necessárias, o humano devolve os achados e Claude faz no
   máximo **uma** rodada de correção, com novo commit, novo SHA e evidência dos
   testes relevantes. O coordenador pode abrir uma re-revisão contra o SHA da
   correção; se não a pedir, ele verifica o handoff de correção, o SHA e os
   testes registrados antes de decidir o aceite. Se a primeira revisão aceitar
   a entrega, essa rodada é dispensada. Não há segunda rodada de revisão
   automática.
5. Handoffs preservam a sequência e o vínculo com o anterior. Durante o bootstrap,
   quando o gerador ainda não está integrado à branch de coordenação, o parecer
   textual nos campos do protocolo é a evidência provisória; o humano registra a
   decisão e o histórico canônico antes de fechar a tarefa.
6. O humano confere os critérios da tarefa contra os commits e resultados citados,
   registra aceite ou rejeição e só então fecha o ciclo. Falha persistente após a
   correção encerra este ciclo como rejeitado; trabalho adicional exige nova tarefa.

Sem SHA verificável, teste alegado sem execução, histórico perdido, violação de
escopo ou decisão humana registrada, o ciclo não é aceito.
