# Documentos para o INPI

- `memorial_descritivo.pdf` — memorial descritivo atualizado do jogo (versão atual).
- `memorial_descritivo.html` — fonte editável do PDF. Depois de editar, gere o
  PDF de novo com `ferramentas/gerar_memorial_pdf.sh` (atualiza também o hash).
- `2023_original.pdf` — documento enviado em 2023 (não aprovado), guardado para histórico.
- `telas/` — prints das telas usados no documento (`ferramentas/capturar.sh`).

Na hora de fazer o pedido de registro de programa de computador:

1. `ferramentas/hash_inpi.sh` gera o pacote do código-fonte (`build/inpi/*.zip`)
   e o hash SHA-512 que vai no formulário.
2. Guarde o `.zip` exatamente como foi gerado (é a prova de autoria).
3. Veja as pendências na seção 11.3 do memorial e no `PENDENCIAS.md`.
