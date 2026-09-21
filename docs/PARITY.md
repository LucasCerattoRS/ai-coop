# Paridade entre árvore pública e privada

A árvore pública versionada em Git é a única fonte de verdade **operacional** para
protocolo, schemas, scripts, testes e exemplos distribuíveis. Na instância de
coordenação, `.ai/tasks/*.json` é o estado autorizado; handoffs imutáveis registram
o histórico e hashes de commit identificam entregas. A árvore privada consome uma
revisão identificada desse código. Configuração local e memórias privadas ficam
fora desses caminhos e nunca são promovidas por sincronização automática.

Não mantenha uma segunda implementação editável na árvore privada. Para executar
o protocolo ali, use um checkout/worktree do commit escolhido. Registre o SHA
completo usado pela instância privada. Uma atualização é explícita: escolha novo
commit, revise o diff e atualize a referência; não copie arquivos em mão dupla.

## Como detectar divergência

1. Compare o SHA registrado pela instância privada com o commit público escolhido
   para a mesma versão. SHA diferente significa versões diferentes; não declare
   paridade até revisar ou alinhar a versão.
2. No checkout privado, `git status --porcelain` deve estar vazio para os caminhos
   operacionais versionados (`scripts/`, `tests/`, `.ai/schemas/` e documentos do
   protocolo em `docs/`). Qualquer alteração ou arquivo que substitua um desses
   caminhos é divergência. Confirme o conteúdo com `git diff --exit-code HEAD --`
   seguido dos caminhos afetados; arquivos não rastreados exigem inspeção separada.
3. Rode os testes do commit escolhido na instância que o consome. Teste aprovado
   indica comportamento exercitado, não substitui a comparação de SHA e diff.

Se a árvore privada não é um checkout Git, compare os hashes dos arquivos
operacionais com um checkout limpo do commit registrado antes de usá-la. Conteúdo
privado não entra nessa comparação nem em relatórios de paridade. Diante de
divergência, suspenda a alegação de paridade e reconcilie no repositório público
por revisão humana; não escolha automaticamente a cópia mais recente.
