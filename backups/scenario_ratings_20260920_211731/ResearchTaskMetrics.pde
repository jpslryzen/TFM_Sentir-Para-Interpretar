// Research-only instrumentation. No task navigation or presentation changes.
ResearchTaskTrace activeResearchTask;
java.util.HashMap<String, ResearchTaskTrace> completedResearchTasks = new java.util.HashMap<String, ResearchTaskTrace>();
java.util.HashMap<String, Integer> researchTaskAttempts = new java.util.HashMap<String, Integer>();
int researchTaskSerial = 0;

class ResearchChoiceTrace {
  String initial = "", current = "";
  boolean hasSelection = false;
  int changes = 0;
  JSONArray sequence = new JSONArray();

  boolean capture(String answer, int elapsed){
    if(answer.equals(current)) return false;
    if(hasSelection) changes++;
    else if(answer.length() > 0){ initial = answer; hasSelection = true; }
    current = answer;
    JSONObject entry = new JSONObject();
    entry.setInt("elapsed_ms", elapsed);
    entry.setString("answer", answer);
    sequence.append(entry);
    return true;
  }
}

class ResearchTaskTrace {
  String key, id, activity, stage, item, stimulus, startCondition;
  int scenario, mark, order, attempt, started, finished = -1;
  boolean conditionChanged = false;
  java.util.LinkedHashMap<String, ResearchChoiceTrace> choices = new java.util.LinkedHashMap<String, ResearchChoiceTrace>();
  JSONArray sequence = new JSONArray();

  void capture(String field, String value){
    ResearchChoiceTrace choice = choices.get(field);
    if(choice == null){ choice = new ResearchChoiceTrace(); choices.put(field, choice); }
    int elapsed = max(0, millis() - started);
    if(choice.capture(value, elapsed)){
      JSONObject entry = new JSONObject();
      entry.setInt("elapsed_ms", elapsed);
      entry.setString("field", field);
      entry.setString("answer", value);
      sequence.append(entry);
    }
  }

  int duration(){ return max(0, finished - started); }
  int changes(){
    int count = 0;
    for(ResearchChoiceTrace choice : choices.values()) count += choice.changes;
    return count;
  }
}

String researchCondition(){ return unisensoryMode ? "AV" : "AVH"; }

String researchCurrentTaskKey(){
  if(appState == 6 && (activity3Step == 1 || activity3Step == 2)){
    return "activity3/" + activity3CurrentScenarioIndex() + "/" + (activity3Step == 1 ? "growl_choice" : "justification");
  }
  if(appState == 1 && phase == 2){
    return "activity4/" + screen + "/" + currentInterpretationMarkIndex() + "/" +
      (interpretationTaskStage == INTERPRETATION_STAGE_TIME ? "timeline" : "meaning");
  }
  return "";
}

void resetResearchTaskTracking(){
  activeResearchTask = null;
  completedResearchTasks.clear();
  researchTaskAttempts.clear();
  researchTaskSerial = 0;
}

// Called immediately before drawing the task, after automatic transitions.
void syncResearchTaskAvailability(){
  if(!researchLoggingEnabled || researchLogWriter == null) return;
  String key = researchCurrentTaskKey();
  if(activeResearchTask != null && !activeResearchTask.key.equals(key)) abandonResearchTask();
  if(key.length() == 0 || activeResearchTask != null) return;
  ResearchTaskTrace task = new ResearchTaskTrace();
  task.key = key;
  task.id = researchSessionId + "_task_" + (++researchTaskSerial);
  task.attempt = researchTaskAttempts.containsKey(key) ? researchTaskAttempts.get(key) + 1 : 1;
  researchTaskAttempts.put(key, task.attempt);
  task.started = millis();
  task.startCondition = researchCondition();
  if(appState == 6){
    task.activity = "activity3";
    task.scenario = activity3CurrentScenarioIndex();
    task.stage = activity3Step == 1 ? "growl_choice" : "justification";
    task.item = activity3ResearchItemId(task.scenario);
    task.stimulus = activity3VideoFiles[task.scenario];
    task.mark = -1;
    task.order = activity3SequencePosition + 1;
  } else {
    task.activity = "activity4";
    task.scenario = screen;
    task.mark = currentInterpretationMarkIndex();
    task.stage = interpretationTaskStage == INTERPRETATION_STAGE_TIME ? "timeline" : "meaning";
    task.item = activity4ResearchItemId(screen, task.mark);
    task.stimulus = titles[screen];
    task.order = behaviorSequencePosition + 1;
    if(task.stage.equals("timeline")){
      // A repeated timeline starts a fresh pair, not a previous meaning result.
      completedResearchTasks.remove("activity4/" + screen + "/" + task.mark + "/meaning");
    }
  }
  activeResearchTask = task;
  completedResearchTasks.remove(key);
  recordResearchChoices();
  logResearchTaskEvent(task, "task_available");
}

// Called only after committed clicks/drops; a timeline drag is one choice on release.
void recordResearchChoices(){
  ResearchTaskTrace task = activeResearchTask;
  if(task == null || !researchLoggingEnabled || !task.key.equals(researchCurrentTaskKey())) return;
  if(task.activity.equals("activity3")){
    if(task.stage.equals("growl_choice")){
      task.capture("growl", activity3SelectedGrowl < 0 ? "" : activity3GrowlLabels[activity3SelectedGrowl]);
    } else {
      task.capture("sound_cues", activity3SelectedSoundMask == 0 ? "" : activity3SelectedSoundSummary());
      task.capture("behavior", activity3SelectedBehavior < 0 ? "" : activity3CurrentBehaviorLabel(activity3SelectedBehavior));
    }
  } else if(task.stage.equals("timeline")){
    task.capture("time_ms", interpretationTimes[screen] < 0 ? "" : str(round(interpretationTimes[screen] * 1000)));
  } else {
    task.capture("behavior", interpretationChoices[screen] < 0 ? "" : interpretationChoiceLabel(interpretationChoices[screen]));
  }
}

void completeResearchTask(){
  if(activeResearchTask == null || !activeResearchTask.key.equals(researchCurrentTaskKey())) return;
  recordResearchChoices();
  ResearchTaskTrace task = activeResearchTask;
  task.finished = millis();
  completedResearchTasks.put(task.key, task);
  logResearchTaskEvent(task, "task_confirmed");
  activeResearchTask = null;
}

void abandonResearchTask(){
  if(activeResearchTask != null){
    logResearchTaskEvent(activeResearchTask, "task_abandoned");
    activeResearchTask = null;
  }
}

int researchColumn(String name){
  String[] headers = RESEARCH_DATA_HEADER.split(";", -1);
  for(int i = 0; i < headers.length; i++) if(headers[i].equals(name)) return i;
  throw new IllegalArgumentException("Unknown research column: " + name);
}

void researchPut(String[] row, String name, String value){ row[researchColumn(name)] = value; }
String researchGet(String[] row, String name){ return row[researchColumn(name)]; }

String[] emptyResearchRow(){
  String[] row = new String[RESEARCH_DATA_HEADER.split(";", -1).length];
  java.util.Arrays.fill(row, "");
  return row;
}

void applyResearchTaskMetrics(String[] row, ResearchTaskTrace task, String field){
  researchPut(row, "task_id", task.id);
  researchPut(row, "task_attempt", str(task.attempt));
  researchPut(row, "task_start_condition", task.startCondition);
  researchPut(row, "condition_changed_during_task", str(task.conditionChanged));
  if(task.finished >= 0) researchPut(row, "response_time_ms", str(task.duration()));
  ResearchChoiceTrace choice = task.choices.get(field);
  if(choice != null){
    researchPut(row, "initial_answer", choice.initial);
    researchPut(row, "final_answer", choice.current);
    researchPut(row, "answer_changes", str(choice.changes));
    researchPut(row, "answer_sequence", choice.sequence.toString());
  } else {
    researchPut(row, "answer_changes", str(task.changes()));
    researchPut(row, "answer_sequence", task.sequence.toString());
  }
}

void logResearchTaskEvent(ResearchTaskTrace task, String event){
  if(!researchLoggingEnabled || researchLogWriter == null) return;
  String[] row = emptyResearchRow();
  researchPut(row, "record_type", "event");
  researchPut(row, "timestamp", researchTimestamp());
  researchPut(row, "participant_id", researchParticipantId);
  researchPut(row, "session_id", researchSessionId);
  researchPut(row, "elapsed_ms", str(max(0, millis() - researchSessionStartedMillis)));
  researchPut(row, "app_state", task.activity.equals("activity3") ? "6" : "1");
  researchPut(row, "condition", researchCondition());
  researchPut(row, "shuffle", str(shuffleBehaviorsEnabled));
  researchPut(row, "event", event);
  researchPut(row, "activity", task.activity);
  researchPut(row, "activity_id", task.activity);
  researchPut(row, "activity_name", task.activity.equals("activity3") ? "Atividade 3" : "Atividade 4");
  researchPut(row, "step", task.stage);
  researchPut(row, "response_stage", task.stage);
  researchPut(row, "scenario_index", str(task.scenario));
  researchPut(row, "item_id", task.item);
  researchPut(row, "item_order", str(task.order));
  researchPut(row, "mark_order", task.mark < 0 ? "" : str(task.mark + 1));
  researchPut(row, "stimulus_id", task.stimulus);
  applyResearchTaskMetrics(row, task, "all_fields");
  writeResearchDataRow(row);
}

String[] enrichResearchDataRow(String[] source){
  if(source.length == RESEARCH_DATA_HEADER.split(";", -1).length) return source;
  String[] row = emptyResearchRow();
  System.arraycopy(source, 0, row, 0, source.length);
  if(!researchGet(row, "record_type").equals("response")) return row;
  String activity = researchGet(row, "activity_id");
  String stage = researchGet(row, "response_stage");
  if(activity.equals("activity3")){
    String taskStage = stage.equals("growl_choice") ? "growl_choice" : "justification";
    ResearchTaskTrace task = completedResearchTasks.get("activity3/" + activity3CurrentScenarioIndex() + "/" + taskStage);
    if(task != null){
      String field = stage.equals("growl_choice") ? "growl" : stage.equals("justification_sound_cues") ? "sound_cues" : "behavior";
      applyResearchTaskMetrics(row, task, field);
      researchPut(row, "scenario_index", str(task.scenario));
    }
  } else if(activity.equals("activity4")){
    int mark = Integer.parseInt(researchGet(row, "mark_order")) - 1;
    String prefix = "activity4/" + screen + "/" + mark + "/";
    ResearchTaskTrace meaning = completedResearchTasks.get(prefix + "meaning");
    ResearchTaskTrace timeline = completedResearchTasks.get(prefix + "timeline");
    if(meaning != null){
      applyResearchTaskMetrics(row, meaning, "behavior");
      researchPut(row, "meaning_response_time_ms", str(meaning.duration()));
      researchPut(row, "scenario_index", str(meaning.scenario));
    }
    if(timeline != null){
      researchPut(row, "timeline_response_time_ms", str(timeline.duration()));
      ResearchChoiceTrace choice = timeline.choices.get("time_ms");
      if(choice != null){
        researchPut(row, "timeline_answer_changes", str(choice.changes));
        researchPut(row, "timeline_answer_sequence", choice.sequence.toString());
      }
      if(meaning != null){
        researchPut(row, "response_time_ms", str(timeline.duration() + meaning.duration()));
        researchPut(row, "task_id", timeline.id + "+" + meaning.id);
        researchPut(row, "task_start_condition", timeline.startCondition);
        researchPut(row, "condition_changed_during_task", str(timeline.conditionChanged || meaning.conditionChanged || !timeline.startCondition.equals(meaning.startCondition)));
      }
    }
  }
  return row;
}

// Read quoted semicolon CSV, including multiline JSON fields, without splitting lines.
java.util.ArrayList<String[]> readResearchCsv(File file) throws IOException {
  java.util.ArrayList<String[]> rows = new java.util.ArrayList<String[]>();
  java.util.ArrayList<String> fields = new java.util.ArrayList<String>();
  StringBuilder value = new StringBuilder();
  boolean quoted = false, closed = false, touched = false;
  try(java.io.PushbackReader reader = new java.io.PushbackReader(new java.io.InputStreamReader(new java.io.FileInputStream(file), "UTF-8"), 1)){
    int ch;
    boolean first = true;
    while((ch = reader.read()) != -1){
      if(first && ch == 0xfeff){ first = false; continue; }
      first = false;
      if(quoted){
        if(ch == '"'){
          int next = reader.read();
          if(next == '"') value.append('"');
          else { quoted = false; closed = true; if(next != -1) reader.unread(next); }
        } else value.append((char)ch);
      } else if(ch == ';' || ch == '\n' || ch == '\r'){
        if(ch == ';'){
          fields.add(value.toString()); value.setLength(0); touched = true; closed = false;
        } else {
          if(ch == '\r'){ int next = reader.read(); if(next != '\n' && next != -1) reader.unread(next); }
          if(touched || value.length() > 0 || !fields.isEmpty()){
            fields.add(value.toString()); rows.add(fields.toArray(new String[0]));
          }
          fields.clear(); value.setLength(0); touched = false; closed = false;
        }
      } else if(ch == '"' && value.length() == 0 && !closed){
        quoted = true; touched = true;
      } else {
        if(closed) throw new IOException("Unexpected data after CSV quote");
        value.append((char)ch); touched = true;
      }
    }
    if(quoted) throw new IOException("Unclosed CSV quote");
    if(touched || value.length() > 0 || !fields.isEmpty()){
      fields.add(value.toString()); rows.add(fields.toArray(new String[0]));
    }
  }
  return rows;
}

String researchMigrationCsvField(String value){
  return "\"" + value.replace("\"", "\"\"") + "\"";
}

void ensureResearchCsvSchema(File file) throws IOException {
  if(!file.exists() || file.length() == 0) return;
  java.util.ArrayList<String[]> rows = readResearchCsv(file);
  String[] oldHeader = RESEARCH_DATA_BASE_HEADER.split(";", -1);
  String[] newHeader = RESEARCH_DATA_HEADER.split(";", -1);
  boolean hasHeader = !rows.isEmpty() && rows.get(0)[0].equals("record_type");
  String[] sourceHeader = hasHeader ? rows.get(0) : oldHeader;
  if(!java.util.Arrays.equals(sourceHeader, oldHeader) && !java.util.Arrays.equals(sourceHeader, newHeader)){
    throw new IOException("CSV schema not recognized; original file preserved");
  }
  int start = hasHeader ? 1 : 0;
  for(int i = start; i < rows.size(); i++){
    String[] row = rows.get(i);
    if(row.length != sourceHeader.length || !(row[0].equals("event") || row[0].equals("response"))){
      throw new IOException("CSV row incompatible with header; original file preserved");
    }
  }
  if(hasHeader && java.util.Arrays.equals(sourceHeader, newHeader)) return;
  File backupDir = new File(sketchPath("backups"));
  if(!backupDir.exists() && !backupDir.mkdirs()) throw new IOException("Cannot create CSV backup");
  File backup = new File(backupDir, "research_data_before_task_metrics_" + System.currentTimeMillis() + ".csv");
  Files.copy(file.toPath(), backup.toPath());
  java.nio.file.Path temporary = Files.createTempFile(file.getParentFile().toPath(), "research_schema_", ".tmp");
  try {
    try(BufferedWriter writer = Files.newBufferedWriter(temporary, java.nio.charset.StandardCharsets.UTF_8)){
      writer.write("\ufeff" + RESEARCH_DATA_HEADER); writer.newLine();
      for(int i = start; i < rows.size(); i++){
        String[] row = rows.get(i);
        for(int col = 0; col < newHeader.length; col++){
          if(col > 0) writer.write(';');
          writer.write(researchMigrationCsvField(col < row.length ? row[col] : ""));
        }
        writer.newLine();
      }
    }
    Files.move(temporary, file.toPath(), StandardCopyOption.ATOMIC_MOVE, StandardCopyOption.REPLACE_EXISTING);
  } finally { Files.deleteIfExists(temporary); }
}
