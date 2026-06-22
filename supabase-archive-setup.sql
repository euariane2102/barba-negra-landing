-- ============================================
-- ARQUIVO AUTOMÁTICO DE DADOS
-- Execute em AMBOS os projetos Supabase:
-- 1. rcbmix (RCB)
-- 2. logflux (LogFlux)
-- ============================================

-- ✅ TABELA DE ARQUIVO: NOTAS
CREATE TABLE IF NOT EXISTS notas_archive (
  id uuid PRIMARY KEY,
  usuario_id uuid,
  titulo text,
  conteudo text,
  created_at timestamptz,
  updated_at timestamptz,
  arquivado_em timestamptz DEFAULT now()
);

-- ✅ TABELA DE ARQUIVO: LAUDOS
CREATE TABLE IF NOT EXISTS laudos_archive (
  id uuid PRIMARY KEY,
  usuario_id uuid,
  titulo text,
  conteudo text,
  arquivo_url text,
  created_at timestamptz,
  updated_at timestamptz,
  arquivado_em timestamptz DEFAULT now()
);

-- ✅ TABELA DE ARQUIVO: PLANILHAS
CREATE TABLE IF NOT EXISTS planilhas_archive (
  id uuid PRIMARY KEY,
  usuario_id uuid,
  titulo text,
  conteudo text,
  arquivo_url text,
  created_at timestamptz,
  updated_at timestamptz,
  arquivado_em timestamptz DEFAULT now()
);

-- ✅ TABELA DE LOG
CREATE TABLE IF NOT EXISTS arquivo_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tabela_nome text,
  registros_arquivados int,
  data_execucao timestamptz DEFAULT now()
);

-- ============================================
-- FUNÇÕES DE ARQUIVAMENTO (6 MESES)
-- ============================================

-- 📝 Arquivar notas antigas
CREATE OR REPLACE FUNCTION arquivar_notas_antigas()
RETURNS TABLE(arquivadas int, deleted int) AS $$
DECLARE
  v_count int;
BEGIN
  -- Mover notas com >6 meses para arquivo
  INSERT INTO notas_archive
  SELECT id, usuario_id, titulo, conteudo, created_at, updated_at, now()
  FROM notas
  WHERE updated_at < NOW() - INTERVAL '6 months'
  ON CONFLICT (id) DO NOTHING;

  GET DIAGNOSTICS v_count = ROW_COUNT;

  -- Deletar originals
  DELETE FROM notas
  WHERE updated_at < NOW() - INTERVAL '6 months';

  -- Log
  INSERT INTO arquivo_log (tabela_nome, registros_arquivados)
  VALUES ('notas', v_count);

  RETURN QUERY SELECT v_count, v_count;
END;
$$ LANGUAGE plpgsql;

-- 📋 Arquivar laudos antigos
CREATE OR REPLACE FUNCTION arquivar_laudos_antigos()
RETURNS TABLE(arquivadas int, deleted int) AS $$
DECLARE
  v_count int;
BEGIN
  INSERT INTO laudos_archive
  SELECT id, usuario_id, titulo, conteudo, arquivo_url, created_at, updated_at, now()
  FROM laudos
  WHERE updated_at < NOW() - INTERVAL '6 months'
  ON CONFLICT (id) DO NOTHING;

  GET DIAGNOSTICS v_count = ROW_COUNT;

  DELETE FROM laudos
  WHERE updated_at < NOW() - INTERVAL '6 months';

  INSERT INTO arquivo_log (tabela_nome, registros_arquivados)
  VALUES ('laudos', v_count);

  RETURN QUERY SELECT v_count, v_count;
END;
$$ LANGUAGE plpgsql;

-- 📊 Arquivar planilhas antigas
CREATE OR REPLACE FUNCTION arquivar_planilhas_antigas()
RETURNS TABLE(arquivadas int, deleted int) AS $$
DECLARE
  v_count int;
BEGIN
  INSERT INTO planilhas_archive
  SELECT id, usuario_id, titulo, conteudo, arquivo_url, created_at, updated_at, now()
  FROM planilhas
  WHERE updated_at < NOW() - INTERVAL '6 months'
  ON CONFLICT (id) DO NOTHING;

  GET DIAGNOSTICS v_count = ROW_COUNT;

  DELETE FROM planilhas
  WHERE updated_at < NOW() - INTERVAL '6 months';

  INSERT INTO arquivo_log (tabela_nome, registros_arquivados)
  VALUES ('planilhas', v_count);

  RETURN QUERY SELECT v_count, v_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNÇÃO RESTAURAÇÃO (em caso de necessidade)
-- ============================================

CREATE OR REPLACE FUNCTION restaurar_notas_arquivadas(p_id uuid)
RETURNS TABLE(sucesso boolean, mensagem text) AS $$
BEGIN
  INSERT INTO notas (id, usuario_id, titulo, conteudo, created_at, updated_at)
  SELECT id, usuario_id, titulo, conteudo, created_at, updated_at
  FROM notas_archive
  WHERE id = p_id
  ON CONFLICT (id) DO UPDATE SET updated_at = now();

  DELETE FROM notas_archive WHERE id = p_id;

  RETURN QUERY SELECT true, 'Nota restaurada com sucesso'::text;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- ÍNDICES para performance
-- ============================================
CREATE INDEX idx_notas_archive_updated ON notas_archive(updated_at);
CREATE INDEX idx_laudos_archive_updated ON laudos_archive(updated_at);
CREATE INDEX idx_planilhas_archive_updated ON planilhas_archive(updated_at);
CREATE INDEX idx_arquivo_log_data ON arquivo_log(data_execucao);
