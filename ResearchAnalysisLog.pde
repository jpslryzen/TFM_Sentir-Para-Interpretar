// Secondary, human-readable log. The technical event CSV remains the source of record.
final String RESEARCH_ANALYSIS_FILE = "research_analysis_live.csv";
final String RESEARCH_ANALYSIS_HEADER =
  "tipo_registo;participant_id;condicao;atividade;cenario;etapa;marcacao;" +
  "resposta;resposta_correta;tipo_erro;alteracoes_resposta;historico_alteracoes;" +
  "confianca;esforco_mental;dificuldade_percecionada";

PrintWriter researchAnalysisWriter;
boolean researchAnalysisLogAvailable = false;

// The CSV is the immediate, durable source. This background refresh mirrors it
// into the existing analysis workbook without blocking a participant task.
Process researchAnalysisWorkbookUpdateProcess;
int researchAnalysisWorkbookUpdateRequestedAt = -1;
final int RESEARCH_ANALYSIS_WORKBOOK_UPDATE_DELAY_MS = 1800;

void requestResearchAnalysisWorkbookUpdate(){
  researchAnalysisWorkbookUpdateRequestedAt = millis();
}

void updateResearchAnalysisWorkbookIfNeeded(boolean force){
  // Excel refreshes are intentionally deferred until the participant session
  // ends. Rebuilding a workbook while they interact would add unnecessary I/O.
  if(!force && researchLoggingEnabled) return;
  if(researchAnalysisWorkbookUpdateProcess != null){
    try {
      if(researchAnalysisWorkbookUpdateProcess.isAlive()) return;
    } catch(Exception ignored) {}
    researchAnalysisWorkbookUpdateProcess = null;
  }
  if(researchAnalysisWorkbookUpdateRequestedAt < 0) return;
  if(!force && millis() - researchAnalysisWorkbookUpdateRequestedAt < RESEARCH_ANALYSIS_WORKBOOK_UPDATE_DELAY_MS) return;

  File script = new File(sketchPath("atualizar_analise_excel.ps1"));
  File logDir = new File(dataPath("research_logs"));
  File rawCsv = new File(logDir, RESEARCH_DATA_FILE);
  File workbook = new File(logDir, "analise_dados_instrumento.xlsx");
  if(!script.exists() || !rawCsv.exists() || !workbook.exists()){
    println("AVISO: atualizacao do Excel indisponivel; os CSV continuam guardados.");
    researchAnalysisWorkbookUpdateRequestedAt = -1;
    return;
  }

  try {
    ProcessBuilder builder = new ProcessBuilder(
      "powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
      script.getAbsolutePath(), "-RawCsvPath", rawCsv.getAbsolutePath(),
      "-WorkbookPath", workbook.getAbsolutePath()
    );
    builder.redirectErrorStream(true);
    researchAnalysisWorkbookUpdateProcess = builder.start();
    researchAnalysisWorkbookUpdateRequestedAt = -1;
    println("Analise Excel: atualizacao automatica iniciada.");
  } catch(Exception e){
    println("AVISO: nao foi possivel iniciar a atualizacao do Excel; os CSV continuam guardados. " + e.getMessage());
  }
}

boolean startResearchAnalysisLog(File logDir){
  researchAnalysisLogAvailable = false;
  closeResearchAnalysisWriterQuietly();
  try {
    File analysisFile = new File(logDir, RESEARCH_ANALYSIS_FILE);
    boolean writeHeader = !analysisFile.exists() || analysisFile.length() == 0;
    researchAnalysisWriter = new PrintWriter(new BufferedWriter(
      new OutputStreamWriter(new FileOutputStream(analysisFile, true), "UTF-8")
    ));
    if(writeHeader){
      researchAnalysisWriter.print("\ufeff");
      researchAnalysisWriter.println(RESEARCH_ANALYSIS_HEADER);
      researchAnalysisWriter.flush();
    }
    if(researchAnalysisWriter.checkError()) throw new IOException("O ficheiro de analise nao aceita escrita.");
    researchAnalysisLogAvailable = true;
    println("Recolha legivel: " + analysisFile.getAbsolutePath());
    return true;
  } catch(Exception e){
    closeResearchAnalysisWriterQuietly();
    println("AVISO: CSV legivel indisponivel; o CSV tecnico continuara a ser recolhido. " + e.getMessage());
    return false;
  }
}

void closeResearchAnalysisWriterQuietly(){
  if(researchAnalysisWriter == null) return;
  try {
    researchAnalysisWriter.flush();
    researchAnalysisWriter.close();
  } catch(Exception ignored) {}
  researchAnalysisWriter = null;
  researchAnalysisLogAvailable = false;
}

String analysisActivityLabel(String activity){
  if(activity.equals("activity3")) return "Rosnados caninos";
  if(activity.equals("activity4")) return "Mudanca de comportamento";
  return activity.length() == 0 ? "" : activity;
}

String analysisScenarioLabel(String activity, String scenario){
  if(scenario == null || scenario.length() == 0 || scenario.equals("-1")) return "";
  try {
    int index = Integer.parseInt(scenario);
    if(activity.equals("activity3")) return "Cenario " + (index + 1);
    if(activity.equals("activity4") && index >= 0 && index < titles.length) return titles[index];
  } catch(Exception ignored) {}
  return scenario;
}

String analysisStageLabel(String stage){
  if(stage.equals("growl_choice")) return "Escolha do rosnado";
  if(stage.equals("justification_sound_cues")) return "Pistas sonoras";
  if(stage.equals("justification_behavior")) return "Comportamento provavel";
  if(stage.equals("interpretation")) return "Interpretacao";
  if(stage.equals("scenario_ratings")) return "Medidas apos o cenario";
  if(stage.equals("observation")) return "Observacao";
  return stage;
}

boolean isReadableInteractionEvent(String event){
  return event.equals("activity3_growl_sound_play") ||
    event.equals("observation_repeat");
}

String analysisRecordType(String[] row){
  String record = researchGet(row, "record_type");
  String stage = researchGet(row, "response_stage");
  String event = researchGet(row, "event");
  if(record.equals("response") && stage.equals("scenario_ratings")) return "Medidas";
  if(record.equals("response")) return "Resposta";
  if(event.equals("activity3_growl_sound_play")) return "Audicao de rosnado";
  if(event.equals("observation_repeat")) return "Repeticao de observacao";
  return "";
}

String analysisSelectedResponse(String[] row){
  String answer = researchGet(row, "selected_answer");
  if(answer.length() > 0) return answer;
  if(researchGet(row, "event").equals("activity3_growl_sound_play")){
    return analysisDetailsValue(researchGet(row, "details"), "growl");
  }
  return "";
}

String analysisDetailsValue(String details, String key){
  String[] fields = split(details == null ? "" : details, ';');
  String prefix = key + "=";
  for(int i = 0; i < fields.length; i++){
    if(fields[i].startsWith(prefix)) return fields[i].substring(prefix.length());
  }
  return "";
}

String analysisChoiceSequence(String raw, boolean timeValues){
  if(raw == null || raw.length() == 0) return "";
  try {
    JSONArray entries = parseJSONArray(raw);
    String[] values = new String[entries.size()];
    for(int i = 0; i < entries.size(); i++){
      JSONObject entry = entries.getJSONObject(i);
      String answer = entry.getString("answer");
      if(timeValues){
        try { answer = nf(Float.parseFloat(answer) / 1000.0, 0, 1) + " s"; }
        catch(Exception ignored) {}
      }
      values[i] = answer;
    }
    return join(values, " > ");
  } catch(Exception ignored) { return ""; }
}

String analysisSequence(String[] row){
  String answerSequence = analysisChoiceSequence(researchGet(row, "answer_sequence"), false);
  String timelineSequence = analysisChoiceSequence(researchGet(row, "timeline_answer_sequence"), true);
  if(timelineSequence.length() == 0) return answerSequence;
  if(answerSequence.length() == 0) return "Linha temporal: " + timelineSequence;
  return "Linha temporal: " + timelineSequence + " | Comportamento: " + answerSequence;
}

void writeResearchAnalysisRow(String[] row){
  if(!researchAnalysisLogAvailable || researchAnalysisWriter == null) return;
  String record = researchGet(row, "record_type");
  String event = researchGet(row, "event");
  if(!record.equals("response") && !isReadableInteractionEvent(event)) return;
  try {
    String activity = researchGet(row, "activity_id");
    if(activity.length() == 0) activity = researchGet(row, "activity");
    String stage = researchGet(row, "response_stage");
    if(stage.length() == 0) stage = researchGet(row, "step");
    String[] readable = {
      analysisRecordType(row),
      researchGet(row, "participant_id"),
      researchGet(row, "condition"),
      analysisActivityLabel(activity),
      analysisScenarioLabel(activity, researchGet(row, "scenario_index")),
      analysisStageLabel(stage),
      researchGet(row, "mark_order"),
      analysisSelectedResponse(row),
      researchGet(row, "is_correct"),
      researchGet(row, "error_type"),
      researchGet(row, "answer_changes"),
      analysisSequence(row),
      researchGet(row, "interpretation_confidence"),
      researchGet(row, "mental_effort"),
      researchGet(row, "perceived_difficulty")
    };
    for(int i = 0; i < readable.length; i++){
      if(i > 0) researchAnalysisWriter.print(RESEARCH_CSV_SEPARATOR);
      researchAnalysisWriter.print(csvField(readable[i]));
    }
    researchAnalysisWriter.println();
    researchAnalysisWriter.flush();
    if(researchAnalysisWriter.checkError()){
      println("AVISO: o CSV legivel deixou de aceitar registos; o CSV tecnico continua ativo.");
      closeResearchAnalysisWriterQuietly();
    }
    requestResearchAnalysisWorkbookUpdate();
  } catch(Exception e){
    println("AVISO: nao foi possivel atualizar o CSV legivel; o CSV tecnico continua ativo. " + e.getMessage());
    closeResearchAnalysisWriterQuietly();
  }
}
