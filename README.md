# url_redirect

Página estática (GitHub Pages) usada como **redirect URI do OAuth do Mercado Livre** e como
surpresa para a Nanda. Arquivo único: `index.html`, sem recursos externos.

## Quando o site precisa estar no ar?
- **Para mostrar a página para a Nanda:** sim, ligue o site.
- **Para autorizar o app do Mercado Livre:** em geral **não**. O ML só redireciona o navegador para
  a URL; mesmo que a página dê 404, o endereço (com `?code=...&state=...`) aparece na barra, e é
  ele que se cola no `smartdeal ml-authorize`. Se a página estiver no ar, aparece um botão
  "Copiar endereço completo".

## Ligar e desligar (GitHub Pages)
```powershell
.\site.ps1 status        # está no ar?
.\site.ps1 on            # publica
.\site.ps1 on -Horas 2   # publica e desliga sozinho em 2 horas (precisa do PC ligado/ao voltar)
.\site.ps1 off           # despublica
```
Requer o `gh` autenticado na conta `jef-loppes-reis`.

## Segurança
- A página não faz nenhuma requisição: sem fontes, scripts ou imagens de terceiros, e com
  `referrer: no-referrer`, então o `code` do OAuth não sai do navegador.
- O `code` vale poucos minutos e só uma vez, mas não compartilhe o endereço com ele.
- `noindex` evita que buscadores listem a página.
