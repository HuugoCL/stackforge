# SUPORTE STACKFORGE

Distribuição gratuita para Windows de uma adaptação em português brasileiro do [WinUtil](https://github.com/ChrisTitusTech/winutil), projeto original de Chris Titus Tech. A ferramenta original, seus créditos e a licença MIT devem acompanhar qualquer distribuição. Consulte [LICENSE](LICENSE) e os avisos presentes no pacote.

## Instalação

Abra o Windows PowerShell como administrador e execute:

```powershell
irm https://stackforge.pages.dev/sup | iex
```

O endereço `/sup` entrega o script PowerShell como `text/plain`. O script consulta a última Release em `HuugoCL/stackforge`, exige o ativo `SUPORTE-STACKFORGE-PTBR.zip` e valida tamanho, SHA-256 e estrutura antes de extrair ou executar arquivos. A Release precisa publicar o digest SHA-256 no campo `digest` do GitHub ou no corpo como `SHA256: <64 caracteres hexadecimais>`. Sem digest publicado, a instalação é cancelada. Para revisar o instalador antes de executá-lo, baixe-o pelo navegador em `https://stackforge.pages.dev/sup`.

## Publicação no Cloudflare Pages

O projeto usa o modo Advanced Pages Functions: `public` é o diretório de arquivos estáticos e `public/_worker.js` roteia `/sup` e `/`. Crie/associe o projeto **stackforge**, conecte o repositório GitHub **HuugoCL/stackforge**, selecione a branch **main**, defina `public` como diretório de saída e habilite o modo Advanced com o `_worker.js` incluído. O domínio pretendido é `stackforge.pages.dev`.

Após cada push em `main`, aguarde o deploy do Pages e verifique:

```powershell
(Invoke-WebRequest https://stackforge.pages.dev/).StatusCode
(Invoke-WebRequest https://stackforge.pages.dev/sup).Headers['Content-Type']
(Invoke-WebRequest https://stackforge.pages.dev/sup).Content | Select-String 'SUPORTE STACKFORGE - Instalador remoto'
```

As configurações de conta e vinculação do Cloudflare Pages não são versionadas neste repositório. Confirme em Cloudflare Dashboard → Workers & Pages → `stackforge` que a produção está conectada a `main` e usa `public`.

## Publicar uma versão

1. Preserve o código original do WinUtil, os créditos e os arquivos de licença/avisos no pacote.
2. Gere o arquivo `SUPORTE-STACKFORGE-PTBR.zip` e calcule SHA-256: `(Get-FileHash .\SUPORTE-STACKFORGE-PTBR.zip -Algorithm SHA256).Hash`.
3. Publique o ZIP em uma nova Release de `HuugoCL/stackforge` com esse nome exato e registre o hash no corpo como `SHA256: <hash>`. O GitHub também pode fornecer o digest SHA-256 da asset.
4. Revise e envie as alterações do instalador e site para `main`; o Pages publica o site conectado à branch.
5. Verifique o asset da Release e as duas rotas de produção conforme a seção anterior.

## Atualização

Execute novamente o mesmo comando de instalação. Ele sempre consulta a última Release do GitHub. O instalador baixa para uma área temporária, verifica a origem HTTPS oficial, o tamanho e o digest, valida `Compile.ps1` e `LICENSE` e só então substitui os arquivos extraídos. Ele não desativa proteções do Windows e não usa `ExecutionPolicy Bypass`.

## Rollback

Para reverter o site, no Cloudflare Pages selecione um deployment anterior como produção ou reverta o commit em `main` e aguarde nova publicação. Para reverter o pacote distribuído, publique uma nova Release com o pacote conhecido como bom e seu SHA-256; não apague nem renomeie releases existentes. Depois confirme `/` e `/sup` e o ativo correspondente.

## Teste local

O worker é um Cloudflare Pages Advanced Mode Worker. Para executar o ambiente local, instale Wrangler (`npm install --save-dev wrangler`) e rode `npx wrangler pages dev public`; valide `/` e `/sup` em `http://localhost:8788`. A lógica de roteamento pode ser verificada em Node.js; o runtime local Wrangler/workerd também deve iniciar corretamente na máquina usada. O Windows PowerShell do instalador requer uma máquina Windows 64 bits, PowerShell 5.1+ e execução como administrador; uma instalação real deve ser feita apenas após revisar e confiar no pacote de Release.
