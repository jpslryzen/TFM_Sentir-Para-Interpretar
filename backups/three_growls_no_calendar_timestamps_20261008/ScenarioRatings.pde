// Scenario-level self-report, after all interpretation choices and before feedback.
boolean scenarioRatingsActive = false;
boolean scenarioRatingsSaving = false;
int scenarioConfidence = 0, scenarioDifficulty = 0, scenarioMentalEffort = 0;
int ratedScenario = -1, ratedOrder = -1;
String ratedActivity = "", scenarioRatingsError = "";
float ratingsX, ratingsY, ratingsW = 1200;
float ratingsScaleY, ratingsButtonH = 48, ratingsGap = 12;
final float RATINGS_ROW_GAP = 180;
String[][] scenarioRatingLabels = {
  {"Nada confiante", "Pouco confiante", "Moderadamente confiante", "Confiante", "Muito confiante"},
  {"Muito, muito\nreduzido", "Muito reduzido", "Reduzido", "Relativamente\nreduzido",
   "Nem reduzido\nnem elevado", "Relativamente\nelevado", "Elevado", "Muito elevado", "Muito, muito\nelevado"},
  {"Muito fácil", "Fácil", "Nem fácil nem difícil", "Difícil", "Muito difícil"}
};
float ratingsContinueX, ratingsContinueY;

void beginScenarioRatings(){
  if(scenarioRatingsActive) return;
  ratedActivity = appState == 6 ? "activity3" : "activity4";
  ratedScenario = appState == 6 ? activity3CurrentScenarioIndex() : screen;
  ratedOrder = appState == 6 ? activity3SequencePosition + 1 : behaviorSequencePosition + 1;
  scenarioConfidence = 0;
  scenarioDifficulty = 0;
  scenarioMentalEffort = 0;
  scenarioRatingsError = "";
  scenarioRatingsSaving = false;
  clearInterpretationSeek();
  stopAllVideos();
  stopActivity3GrowlSounds();
  stopBHapticsVibration();
  scenarioRatingsActive = true;
}

boolean scenarioRatingsComplete(){
  return scenarioConfidence >= 1 && scenarioConfidence <= 5 &&
    scenarioMentalEffort >= 1 && scenarioMentalEffort <= 9 &&
    scenarioDifficulty >= 1 && scenarioDifficulty <= 5;
}

void drawScenarioRatings(){
  ratingsW = min(1200, baseW - 152);
  ratingsX = (baseW - ratingsW) / 2;
  ratingsY = 58;
  ratingsScaleY = ratingsY + 136;
  fill(white);
  textAlign(LEFT, TOP);
  textSize(TYPE_TITLE);
  text("Sobre a tua resposta", ratingsX, ratingsY);
  drawScenarioRatingScale("Quão confiante estás de que a tua interpretação deste cenário está correta?",
    scenarioConfidence, ratingsScaleY, scenarioRatingLabels[0]);
  drawScenarioRatingScale("Quanto esforço mental investiste para interpretar este cenário?",
    scenarioMentalEffort, ratingsScaleY + RATINGS_ROW_GAP, scenarioRatingLabels[1]);
  drawScenarioRatingScale("Quão difícil foi interpretar este cenário?",
    scenarioDifficulty, ratingsScaleY + RATINGS_ROW_GAP * 2, scenarioRatingLabels[2]);
  ratingsContinueX = ratingsX + ratingsW - 180;
  ratingsContinueY = baseH - 100;
  drawResearchPromptButton(ratingsContinueX, ratingsContinueY, 180, 48, "Continuar",
    true, scenarioRatingsComplete() && !scenarioRatingsSaving);
  if(scenarioRatingsError.length() > 0){
    fill(255, 138, 138);
    textSize(TYPE_LABEL);
    textAlign(LEFT, TOP);
    text(scenarioRatingsError, ratingsX, ratingsContinueY + 58, ratingsW, 40);
  }
}

float scenarioRatingButtonWidth(int count){
  return (ratingsW - (count - 1) * ratingsGap) / count;
}

void drawScenarioRatingScale(String title, int selected, float y, String[] labels){
  fill(white);
  textAlign(LEFT, TOP);
  textSize(TYPE_SUBHEADING);
  text(title, ratingsX, y - 46);
  float buttonW = scenarioRatingButtonWidth(labels.length);
  for(int i = 1; i <= labels.length; i++){
    float x = ratingsX + (i - 1) * (buttonW + ratingsGap);
    drawResearchPromptButton(x, y, buttonW, ratingsButtonH, str(i), selected == i, true);
    fill(muted);
    textSize(TYPE_LABEL);
    textLeading(LEADING_COMPACT);
    textAlign(CENTER, TOP);
    text(labels[i - 1], x, y + ratingsButtonH + 12, buttonW, 72);
  }
}

void handleScenarioRatingsMouse(float mx, float my){
  if(scenarioRatingsSaving) return;
  for(int row = 0; row < scenarioRatingLabels.length; row++){
    int count = scenarioRatingLabels[row].length;
    float buttonW = scenarioRatingButtonWidth(count);
    for(int i = 1; i <= count; i++){
      float x = ratingsX + (i - 1) * (buttonW + ratingsGap);
      if(inside(mx, my, x, ratingsScaleY + row * RATINGS_ROW_GAP, buttonW, ratingsButtonH)){
        if(row == 0) scenarioConfidence = i;
        else if(row == 1) scenarioMentalEffort = i;
        else scenarioDifficulty = i;
      }
    }
  }
  if(inside(mx, my, ratingsContinueX, ratingsContinueY, 180, 48)) confirmScenarioRatings();
}

boolean saveScenarioRatings(){
  if(!researchLoggingEnabled) return true;
  if(researchStorageFailure || researchLogWriter == null || researchLogWriter.checkError()){
    signalResearchStorageFailure("O ficheiro de dados nao esta disponivel para guardar as medidas.");
    return false;
  }
  String[] row = emptyResearchRow();
  researchPut(row, "record_type", "response");
  researchPut(row, "timestamp", researchTimestamp());
  researchPut(row, "participant_id", researchParticipantId);
  researchPut(row, "session_id", researchSessionId);
  researchPut(row, "elapsed_ms", str(max(0, millis() - researchSessionStartedMillis)));
  researchPut(row, "app_state", str(appState));
  researchPut(row, "condition", researchCondition());
  researchPut(row, "shuffle", str(shuffleBehaviorsEnabled));
  researchPut(row, "event", "scenario_ratings_confirm");
  researchPut(row, "activity", ratedActivity);
  researchPut(row, "activity_id", ratedActivity);
  researchPut(row, "activity_name", ratedActivity.equals("activity3") ? "Atividade 3" : "Atividade 4");
  researchPut(row, "scenario_index", str(ratedScenario));
  researchPut(row, "item_id", ratedActivity.equals("activity3") ?
    activity3ResearchItemId(ratedScenario) : "behavior_" + (ratedScenario + 1));
  researchPut(row, "item_order", str(ratedOrder));
  researchPut(row, "step", "scenario_ratings");
  researchPut(row, "response_stage", "scenario_ratings");
  researchPut(row, "interpretation_confidence", str(scenarioConfidence));
  researchPut(row, "perceived_difficulty", str(scenarioDifficulty));
  researchPut(row, "mental_effort", str(scenarioMentalEffort));
  return writeResearchDataRow(row);
}

void confirmScenarioRatings(){
  if(!scenarioRatingsActive || scenarioRatingsSaving || !scenarioRatingsComplete()) return;
  scenarioRatingsSaving = true;
  if(!saveScenarioRatings()){
    scenarioRatingsError = "Não foi possível guardar. As respostas permanecem neste ecrã.";
    scenarioRatingsSaving = false;
    return;
  }
  scenarioRatingsActive = false;
  scenarioRatingsSaving = false;
  advanceAfterScenarioRatings();
}

// Designer shortcut: leave the three measures blank while preserving an explicit audit event.
void skipScenarioRatings(){
  if(!scenarioRatingsActive || scenarioRatingsSaving) return;
  logResearchEvent(
    "scenario_ratings_skipped",
    ratedActivity,
    "scenario_ratings",
    ratedScenario,
    "reason=shortcut_S;confidence=;mental_effort=;perceived_difficulty="
  );
  scenarioRatingsActive = false;
  scenarioRatingsSaving = false;
  advanceAfterScenarioRatings();
}

void advanceAfterScenarioRatings(){
  if(ratedActivity.equals("activity3")){
    stopActivity3GrowlSounds();
    stopBHapticsVibration();
    advanceActivity3AfterFeedback();
  } else {
    restoreInterpretationVideoAudio();
    stopBHapticsVibration();
    if(onLastBehaviorStep()) returnToHomeMenu();
    else goNextScreen();
  }
}
