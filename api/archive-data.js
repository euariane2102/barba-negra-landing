// ============================================
// ARQUIVO AUTOMÁTICO DE DADOS
// Executa arquivo de notas, laudos e planilhas
// com >6 meses em ambos os Supabase
// ============================================

import { createClient } from '@supabase/supabase-js';

const SUPABASE_PROJECTS = [
  {
    name: 'RCB',
    url: process.env.SUPABASE_RCB_URL,
    key: process.env.SUPABASE_RCB_KEY,
  },
  {
    name: 'LogFlux',
    url: process.env.SUPABASE_LOGFLUX_URL,
    key: process.env.SUPABASE_LOGFLUX_KEY,
  },
];

export default async function handler(req, res) {
  try {
    console.log('🕐 Iniciando arquivo de dados...');

    const resultados = [];

    for (const project of SUPABASE_PROJECTS) {
      if (!project.url || !project.key) {
        console.warn(`⚠️ Credenciais não configuradas para ${project.name}`);
        continue;
      }

      const supabase = createClient(project.url, project.key);

      console.log(`\n📦 Processando ${project.name}...`);

      // ✅ Arquivar notas
      const notasResult = await supabase.rpc('arquivar_notas_antigas');
      if (notasResult.error) {
        console.error(`❌ Erro ao arquivar notas em ${project.name}:`, notasResult.error);
      } else {
        console.log(`✅ Notas arquivadas em ${project.name}:`, notasResult.data);
        resultados.push({
          projeto: project.name,
          tipo: 'notas',
          registros: notasResult.data?.[0]?.arquivadas || 0,
        });
      }

      // ✅ Arquivar laudos
      const laudosResult = await supabase.rpc('arquivar_laudos_antigos');
      if (laudosResult.error) {
        console.error(`❌ Erro ao arquivar laudos em ${project.name}:`, laudosResult.error);
      } else {
        console.log(`✅ Laudos arquivados em ${project.name}:`, laudosResult.data);
        resultados.push({
          projeto: project.name,
          tipo: 'laudos',
          registros: laudosResult.data?.[0]?.arquivadas || 0,
        });
      }

      // ✅ Arquivar planilhas
      const planilhasResult = await supabase.rpc('arquivar_planilhas_antigas');
      if (planilhasResult.error) {
        console.error(`❌ Erro ao arquivar planilhas em ${project.name}:`, planilhasResult.error);
      } else {
        console.log(`✅ Planilhas arquivadas em ${project.name}:`, planilhasResult.data);
        resultados.push({
          projeto: project.name,
          tipo: 'planilhas',
          registros: planilhasResult.data?.[0]?.arquivadas || 0,
        });
      }
    }

    console.log('\n✅ Arquivo concluído!');

    return res.status(200).json({
      sucesso: true,
      mensagem: 'Arquivo de dados executado com sucesso',
      resultados,
      timestamp: new Date().toISOString(),
    });

  } catch (erro) {
    console.error('❌ Erro ao executar arquivo:', erro);

    return res.status(500).json({
      sucesso: false,
      erro: erro.message,
      timestamp: new Date().toISOString(),
    });
  }
}
