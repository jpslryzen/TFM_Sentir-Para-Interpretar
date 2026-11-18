// Scenario-level self-report, after all interpretation choices and before feedback.
boolean scenarioRatingsActive = false;
boolean scenarioRatingsSaving = false;
int scenarioConfidence = 0, scenarioDifficulty = 0;
int ratedScenario = -1, ratedOrder = -1;
String ratedActivity = "", scenarioRatingsError = "";
float ratingsX, ratingsY, ratingsW = 720;
float ratingsScaleY, ratingsButtonW = 64, ratingsButtonH = 48, ratingsGap = 16;
float ratingsContinueX, ratingsContinueY;

void beginScenarioRatings(){
  if(scenarioRatingsActive) return;
  ratedActivity = appState == 6 ? "activity3" : "activity4";
  ratedScenario = appState == 6 ? activity3CurrentScenarioIndex() : screen;
  ratedOrder = appState == 6 ? activity3SequencePosition + 1 : behaviorSequencePosition + 1;
  scenarioConfidence = 0;
  scenarioDifficulty = 0;
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
    scenarioDifficulty >= 1 && scenarioDifficulty <= 5;
}

void drawScenarioRatings(){
  ratingsX = (baseW - ratingsW) / 2;
  ratingsY = 126;
  ratingsScaleY = ratingsY + 126;
  fill(white);
  textAlign(LEFT, TOP);
  textSize(TYPE_TITLE);
  text("Sobre a tua resposta", ratingsX, ratingsY);
  drawScenarioRatingScale("Confiança na resposta", scenarioConfidence, ratingsScaleY,
    "1 - Nada confiante", "5 - Muito confiante");
  drawScenarioRatingScale("Dificuldade percebida do cenário", scenarioDifficulty, ratingsScaleY + 184,
    "1 - Muito fácil", "5 - Muito difícil");
  ratingsContinueX = ratingsX + ratingsW - 180;
  ratingsContinueY = ratingsScaleY + 354;
  drawResearchPromptButton(ratingsContinueX, ratingsContinueY, 180, 48, "Continuar",
    true, scenarioRatingsComplete() && !scenarioRatingsSaving);
  if(scenarioRatingsError.length() > 0){
    fill(255, 138, 138);
    textSize(TYPE_LABEL);
    textAlign(LEFT, TOP);
    text(scenarioRatingsError, ratingsX, ratingsContinueY + 62, ratingsW, 58);
  }
}

void drawScenarioRatingScale(String title, int selected, float y, String low, String high){
  fill(white);
  textAlign(LEFT, TOP);
  textSize(TYPE_SUBHEADING);
  text(title, ratingsX, y - 46);
  for(int i = 1; i <= 5; i++){
    float x = ratingsX + (i - 1) * (ratingsButtonW + ratingsGap);
    drawResearchPromptButton(x, y, ratingsButtonW, ratingsButtonH, str(i), selected == i, true);
  }
  fill(muted);
  textSize(TYPE_LABEL);
  textAlign(LEFT, TOP);
  text(low, ratingsX, y + ratingsButtonH + 14);
  textAlign(RIGHT, TOP);
  text(high, ratingsX + 5 * ratingsButtonW + 4 * ratingsGap, y + ratingsButtonH + 14);
}

void handleScenarioRatingsMouse(float mx, float my){
  if(scenarioRatingsSaving) return;
  for(int i = 1; i <= 5; i++){
    float x = ratingsX + (i - 1) * (ratingsButtonW + ratingsGap);
    if(inside(mx, my, x, ratingsScaleY, ratingsButtonW, ratingsButtonH)) scenarioConfidence = i;
    if(inside(mx, my, x, ratingsScaleY + 184, ratingsButtonW, ratingsButtonH)) scenarioDifficulty = i;
  }
  if(inside(mx, my, ratingsContinueX, ratingsContinueY, 180, 48)) confirmScenarioRatings();
}

boolean saveScenarioRatings(){
  if(!researchLoggingEnabled) return true;
  if(researchLogWriter == null || researchLogWriter.checkError()) return false;
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
  writeResearchDataRow(row);
  return !researchLogWriter.checkError();
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
  if(ratedActivity.equals("activity3")){
    activity3Step = 3;
    skipHiddenFeedback();
  } else {
    phase = 3;
    t = 0;
    if(skipHiddenFeedback()) return;
    enterFeedbackScreen();
    sendAdvanceFeedbackVibration();
  }
}
