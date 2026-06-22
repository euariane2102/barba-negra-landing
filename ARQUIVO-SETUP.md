# 📦 Sistema Automático de Arquivamento de Dados

## Objetivo
Arquivar automaticamente **notas, laudos e planilhas** com mais de **6 meses** em ambos os Supabase (RCB + LogFlux), liberando espaço no banco de dados sem deletar dados.

---

## 🚀 Setup (Passo a Passo)

### 1️⃣ Executar SQL em AMBOS os Supabase

**Em `rcbmix` (RCB):**
1. Acesse: https://app.supabase.com → Projeto **euariane2102's Project**
2. SQL Editor → New Query
3. Cole o conteúdo de `supabase-archive-setup.sql`
4. Clique **Run**

**Em `logflux` (LogFlux):**
1. Acesse: https://app.supabase.com → Projeto **logflux-saas**
2. SQL Editor → New Query
3. Cole o conteúdo de `supabase-archive-setup.sql`
4. Clique **Run**

✅ **Resultado esperado:** Sem erros, tabelas e funções criadas.

---

### 2️⃣ Configurar Environment Variables no Vercel

No painel do Vercel, adicione:

```
SUPABASE_RCB_URL=https://fnthgmfoozgdaxfninly.supabase.co
SUPABASE_RCB_KEY=sb_publishable_q7I3BIckM6A5LMzXpw6Xyg_V1LxglES

SUPABASE_LOGFLUX_URL=<URL do LogFlux>
SUPABASE_LOGFLUX_KEY=<Chave anon do LogFlux>
```

**Como obter as chaves:**
1. Supabase → Projeto → Settings → API
2. Copie: **Project URL** e **anon public**

---

### 3️⃣ Verificar a API (Teste Manual)

Acesse: https://seu-dominio.vercel.app/api/archive-data

Resposta esperada:
```json
{
  "sucesso": true,
  "mensagem": "Arquivo de dados executado com sucesso",
  "resultados": [
    {
      "projeto": "RCB",
      "tipo": "notas",
      "registros": 5
    },
    ...
  ]
}
```

---

### 4️⃣ Agendar para Rodar Automaticamente (Todo Mês)

**Opção A: Vercel Cron (Recomendado)**

Crie `vercel.json`:
```json
{
  "crons": [
    {
      "path": "/api/archive-data",
      "schedule": "0 2 1 * *"
    }
  ]
}
```

**Horário:** 1º dia do mês, às 2am UTC

**Opção B: Node-cron (Local/Self-hosted)**

```bash
npm install node-cron
```

---

## 📊 Monitoramento

### Ver Histórico de Arquivamento

No Supabase, execute:
```sql
SELECT * FROM arquivo_log ORDER BY data_execucao DESC LIMIT 10;
```

### Ver Dados Arquivados

```sql
-- Notas arquivadas
SELECT COUNT(*) FROM notas_archive;

-- Laudos arquivados
SELECT COUNT(*) FROM laudos_archive;

-- Planilhas arquivadas
SELECT COUNT(*) FROM planilhas_archive;
```

---

## 🔄 Restaurar Dados (Se Necessário)

Se precisar reativar uma nota arquivada:

```sql
SELECT * FROM restaurar_notas_arquivadas('ID-DA-NOTA');
```

---

## 📋 Checklist Final

- [ ] SQL executado em **RCB**
- [ ] SQL executado em **LogFlux**
- [ ] Environment variables configuradas no Vercel
- [ ] Teste manual da API funcionando
- [ ] Cron agendado (1º do mês)
- [ ] Logs sendo registrados

---

## ⚠️ Notas Importantes

- ⏱️ **Período:** 6 meses (ajustável no SQL)
- 🔄 **Frequência:** Mensalmente (ajustável no cron)
- 📦 **Dados:** Nunca deletados, apenas movidos
- 🔍 **Recuperação:** Tabela `*_archive` sempre acessível
- 💾 **Espaço:** Libera ~80% do espaço em grandes bases

---

## 🆘 Troubleshooting

**"Function arquivar_notas_antigas not found"**
- SQL não foi executado em ambos os Supabase
- Verifique se a query rodou sem erros

**"Credenciais não configuradas"**
- Environment variables faltando no Vercel
- Verifique `SUPABASE_RCB_URL` e `SUPABASE_RCB_KEY`

**Cron não rodou?**
- Vercel cron é best-effort, não garantido
- Use alternativa: Google Cloud Scheduler ou externa

---

## 📈 Próximas Melhorias

- [ ] Backup em CSV antes de arquivar
- [ ] Notificação por email quando atingir 80% quota
- [ ] Dashboard de uso de storage
- [ ] Política customizável por tabela

