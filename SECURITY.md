# Política de Segurança

## Versões suportadas

| Versão | Suporte de segurança |
|--------|----------------------|
| 2.x    | Sim                  |
| 1.x    | Não                  |

## Reportando uma vulnerabilidade

Se você encontrou uma vulnerabilidade de segurança em `dump_ia`, **não abra
uma issue pública**. Issues públicas expõem o problema a terceiros antes que
ele possa ser corrigido.

### Como reportar

Envie um e-mail para **petrinhu@yahoo.com.br** com:

- **Assunto:** `[SECURITY] dump_ia — descrição breve`
- Descrição clara da vulnerabilidade
- Passos para reproduzir o problema
- Impacto potencial (o que um atacante poderia fazer)
- Versão afetada do script
- Sistema operacional e versão do bash utilizados

### O que esperar

- **Confirmação de recebimento** em até 72 horas
- **Avaliação inicial** em até 7 dias
- **Correção e divulgação coordenada** assim que a versão corrigida estiver
  disponível

Se a vulnerabilidade for confirmada, você será creditado no CHANGELOG e nas
notas de lançamento, salvo preferência por anonimato.

## Escopo

Este projeto é um script bash para uso local. Considere os seguintes pontos
ao avaliar o escopo de uma vulnerabilidade:

- **Em escopo:** execução arbitrária de comandos via argumentos maliciosos,
  leitura não intencional de arquivos sensíveis, bypass do sistema de
  exclusão de arquivos `.env`
- **Fora de escopo:** problemas no sistema operacional ou no bash em si,
  riscos decorrentes do uso intencional do script em ambientes não confiáveis

## Boas práticas ao usar o dump_ia

- Nunca versione arquivos de dump gerados — adicione `dump_ia_*.log` e
  `dump_ia_*.sha*` ao seu `.gitignore`
- O dump pode conter informações sensíveis do projeto; trate-o como dado
  confidencial
- Verifique sempre a integridade do dump antes de enviar a uma IA:
  ```bash
  ./dump_ia.sh --verificar dump_ia_DDMMYYYY_HHMMSS.log
  ```
