# PG18 Release Candidate + PostgREST/Web Proof — PRD

Status: LOCAL_RC_READY_WITH_WARNINGS

## Objetivo

Executar os próximos passos 1..7 do relatório PG18 anterior:

1. Tentar full `scripts/validate-pg18.sh` em runner com Nix.
2. Definir release candidate tag/digest local.
3. Preparar/persistir estratégia de registry; push somente se houver registry/escopo explícito.
4. Criar checklist de release.
5. Iniciar slice database-centric PostgREST.
6. Implementar tiny `api` schema/RPC + PostgREST + web client simples.
7. Avaliar `wrappers all_fdws` como risco/peso de release.

## Decisões

- Não instalar Nix no host sem autorização explícita.
- Não fazer push para registry externo sem registry/credenciais/escopo explícito.
- Usar containers descartáveis locais para PostgREST/web proof.
- Django fora do escopo.
- Web simples local; reui.io fica como referência visual, sem dependência externa obrigatória.

## Critérios de aceite

- PRD/tasks persistidos.
- Ambiente auditado.
- Runner Nix: executar se possível via container; se bloqueado, registrar blocker técnico com comando e evidência.
- Release tag local criada e smokeada.
- Registry checklist persistido; push externo classificado honestamente.
- PostgREST responde RPC `api.hello` via HTTP.
- Web client local consome RPC via browser.
- Browser-proof + vision persistidos.
- Review por task e review final side-by-side.
- Commit local e working tree limpo.
