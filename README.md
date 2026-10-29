# luz-bairro-config

Repositório de **configuração** do Portal Luz do Bairro (Lab 09 — 200DEV): o estado desejado de cada ambiente, em Kustomize.
O Argo CD lê este repositório; o pipeline de CI **escreve** nele; ninguém aplica nada no cluster "na mão".

```
base/                    Deployment, Service e Route (sem namespace, sem imagem real)
overlays/dev/            ambiente de desenvolvimento — o PIPELINE atualiza digest e versão
overlays/hml/            homologação (usada só no Incidente D do lab)
overlays/prod/           produção — só muda por pull request de promoção
components/canary/       componente opcional (Extensão: canary com Route)
scripts/promover.sh      prepara o PR de promoção (dev → prod, ou dev → hml)
```

Regras do jogo:

1. A imagem é **sempre por digest** (`images.digest` do overlay). A tag existe só para rastreabilidade.
2. Em `overlays/dev`, três linhas são reescritas pelo CI por padrão de texto: `newName`, `digest` e `APP_VERSION`. Não mude o formato delas.
3. Produção recebe a **mesma** imagem de dev, por pull request revisado (`bash scripts/promover.sh`).
4. Rollback = `git revert` do commit de promoção.
5. **Nenhum segredo** neste repositório.

```bash
oc kustomize overlays/dev        # ou: kubectl kustomize overlays/dev
```
