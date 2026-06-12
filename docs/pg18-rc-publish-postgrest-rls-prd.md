# PG18 RC1 Publish + Durable PostgREST/RLS Stack — PRD

Status: DELIVERED_PASS

## Objetivo

Executar os próximos passos autorizados por Karval após RC1 local:

1. Rodar `scripts/validate-pg18.sh` completo em runner com Nix, sem instalar Nix no host salvo necessidade explícita.
2. Publicar `registry.arthuragrelli.com/supabase-postgres:18-karval-rc1` no registry ArthurAgrelli e registrar digest imutável.
3. Converter o proof PostgREST/web em stack dev durável.
4. Implementar primeiro contrato database-centric real além de `hello`: JWT claims + RLS-safe RPC JSONB.
5. Rodar smoke HTTP/API e browser-proof + vision.
6. Fazer review por task e review final lado-a-lado solicitado vs entregue.
7. Commitar artefatos e entregar relatório final completo.

## Guardrails

- Não imprimir segredos, tokens Docker, JWT secrets ou senhas.
- Push autorizado apenas para `registry.arthuragrelli.com/supabase-postgres:18-karval-rc1` neste slice.
- Não mexer no Swarm live `postgres18_postgres`; proofs usam containers/compose descartáveis ou stack dev durável local.
- Se Nix runner completo bloquear por infraestrutura/rede, persistir blocker técnico honesto e manter registry/web proof separado.
- Browser-proof deve validar UI real, console/DOM e vision.

## Critérios de aceite

- PRD/tasks persistidos.
- Registry push real tentado; se passar, digest imutável registrado; se falhar, logs redigidos e blocker persistido.
- Stack dev durável versionada com PG18 RC1 + PostgREST + web/proxy.
- RPC RLS-safe usa claims do JWT/PostgREST ou equivalente controlado por role/claim local.
- Smoke prova acesso permitido e isolamento/negação.
- Browser prova página consumindo endpoint real.
- Reviews PASS após correções.
- Commit local e working tree limpo.
