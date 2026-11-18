import processing.video.*;
import java.io.File;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileOutputStream;
import java.io.InputStreamReader;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.applet.Applet;
import java.applet.AudioClip;
import java.net.URL;

// -------------------------
// BHAPTICS - TACTOSY FOR HANDS (ESQUERDA)
// -------------------------
Process bhapticsProcess;
BufferedWriter bhapticsInput;
BufferedReader bhapticsOutput;
final Object bhapticsWriteLock = new Object();
volatile boolean bhapticsConnected = false;
volatile boolean bhapticsBridgeReady = false;
volatile boolean bhapticsStarting = false;
volatile boolean bhapticsClosing = false;
String bhapticsStatusMessage = "Tactosy esquerda desligada";
boolean bhapticsStatusIsFailure = false;
int bhapticsProcessStartedMillis = -1;
int bhapticsLastStatusMillis = -1;

final float MIN_SECONDS_BEFORE_ADVANCE = 3.0;
final float VIDEO_END_MARGIN_SECONDS = 0.15;
final int MAX_VIBRATION_CUES = 80;
final int DEFAULT_MARK_DURATION_MS = 300;
final int VIB_LOW = 25;
final int VIB_LONG_LOW = 18;
final float OBSERVATION_VIBRATION_SCALE = 0.45;
final int OBSERVATION_VIBRATION_MIN_INTENSITY = 8;
final int VIB_MEDIUM = 63;
final int VIB_HIGH = 100;
final int HAPTIC_TUNE_MIN_AMPLITUDE = 5;
final int HAPTIC_TUNE_MAX_AMPLITUDE = 100;
final float HAPTIC_TUNE_MIN_FREQUENCY = 0.5;
final float HAPTIC_TUNE_MAX_FREQUENCY = 8.0;
final int HAPTIC_TUNE_PREVIEW_HOLD_MS = 1800;
final int ADVANCE_FEEDBACK_DURATION_MS = 180;
final int GUIDED_AUTO_ADVANCE_DELAY_MS = 3000;
final int ISOLATED_AUTO_ADVANCE_DELAY_MS = 3000;
final int ACTIVITY1_OBSERVATION_AUTO_ADVANCE_DELAY_MS = 3000;
final int ACTIVITY1_TEMP_VIDEO_INDEX = 0;
final int ACTIVITY2_OBSERVATION_AUTO_ADVANCE_DELAY_MS = 3000;
final int ACTIVITY2_TEMP_VIDEO_INDEX = 0;
final int ACTIVITY3_OBSERVATION_AUTO_ADVANCE_DELAY_MS = 3000;
final int ACTIVITY3_VIDEO_COUNT = 6;
final int ACTIVITY3_VIDEO_STALL_GRACE_MS = 1400;
final float ACTIVITY3_VIDEO_STALL_EPSILON = 0.04;
final int MOVIE_PREPARATION_DELAY_FRAMES = 8;
final int VIDEO_LOADING_START_DELAY_MS = 1500;
final int STARTUP_LOADING_MIN_VISIBLE_MS = 2400;
final int VIDEO_WARMUP_MIN_MS = 320;
final int VIDEO_WARMUP_TIMEOUT_MS = 4000;
final int VIBRATION_OVERLAY_MIN_VISIBLE_MS = 900;
final int ACTIVITY_OBSERVATION_SLIDE_COUNT = 3;
final int ACTIVITY_OBSERVATION_SLIDE_DURATION_MS = 2200;
final int BEHAVIOR_COUNT = 5;
final int MAX_INTERPRETATION_MARKS = 2;
final int INTERPRETATION_CHOICE_COUNT = 8;
final int CHOICE_DESVIO_CABECA = 8;
final int CHOICE_DESVIO_OLHAR = 9;
final float VIDEO_AUDIO_VOLUME = 1.0;
final float VIDEO_MUTED_VOLUME = 0.0;
final int VIDEO_END_FREEZE_SETTLE_MS = 120;
final int FEEDBACK_LOOP_PAUSE_MS = 3000;
final boolean ENABLE_TEST_VIBRATION_CUES = false;
boolean unisensoryMode = false;
boolean exitRequested = false;
boolean shuffleBehaviorsEnabled = false;
boolean researchLoggingEnabled = false;
boolean designerActivitiesVisible = false;
boolean homeOptionsOverlayOpen = false;
PrintWriter researchLogWriter;
String researchSessionId = "";
String researchParticipantId = "";
String researchParticipantDraft = "";
String researchParticipantPromptError = "";
boolean researchParticipantPromptActive = false;
int researchSessionStartedMillis = -1;
final String RESEARCH_DATA_FILE = "research_data.csv";
final String RESEARCH_CSV_SEPARATOR = ";";
final String RESEARCH_DATA_HEADER =
  "record_type;timestamp;participant_id;session_id;elapsed_ms;app_state;condition;shuffle;" +
  "event;activity;step;scenario_index;" +
  "activity_id;activity_name;item_id;item_order;mark_order;stimulus_id;stimulus_category;response_stage;" +
  "selected_answer;selected_category;selected_option_role;wrong_selected_answer;correct_answer;correct_category;is_correct;error_type;selected_option_distance;closest_wrong_answer;" +
  "available_options;selected_cues;available_cues;correct_cues;" +
  "initial_answer;final_answer;answer_changes;stimulus_replay_count;" +
  "answer_before_feedback;answer_after_feedback;changed_after_feedback;correct_before_feedback;correct_after_feedback;" +
  "response_distance;response_similarity;confusion_type;details";

// -------------------------
// ESTADO DA APP
// -------------------------
final int APP_STATE_LOADING = -1;
int appState = APP_STATE_LOADING;

Movie[] videos  = new Movie[BEHAVIOR_COUNT];
boolean[] hasVideo = new boolean[BEHAVIOR_COUNT];
boolean[] videoWarmed = new boolean[BEHAVIOR_COUNT];
boolean[] videoFrameDecoded = new boolean[BEHAVIOR_COUNT];
String[] preparedVideoPaths = new String[BEHAVIOR_COUNT];
Movie[] activity3Videos = new Movie[ACTIVITY3_VIDEO_COUNT];
boolean[] activity3HasVideo = new boolean[ACTIVITY3_VIDEO_COUNT];
boolean[] activity3VideoWarmed = new boolean[ACTIVITY3_VIDEO_COUNT];
boolean[] activity3VideoFrameDecoded = new boolean[ACTIVITY3_VIDEO_COUNT];
String[] activity3PreparedVideoPaths = new String[ACTIVITY3_VIDEO_COUNT];
Movie[][] activity3GrowlSounds = new Movie[ACTIVITY3_VIDEO_COUNT][4];
String[][] activity3GrowlSoundLoadedPaths = new String[ACTIVITY3_VIDEO_COUNT][4];
String[][] activity3GrowlResolvedSoundPaths = new String[ACTIVITY3_VIDEO_COUNT][4];
AudioClip[][] activity3GrowlAudioClips = new AudioClip[ACTIVITY3_VIDEO_COUNT][4];
String[][] activity3GrowlAudioLoadedPaths = new String[ACTIVITY3_VIDEO_COUNT][4];
float[][][] activity3GrowlAmplitudeEnvelopes = new float[ACTIVITY3_VIDEO_COUNT][4][];
String[][] activity3GrowlEnvelopeLoadedPaths = new String[ACTIVITY3_VIDEO_COUNT][4];
int[][] activity3GrowlEnvelopeDurationsMs = new int[ACTIVITY3_VIDEO_COUNT][4];
int[][] activity3GrowlPlayCounts = new int[ACTIVITY3_VIDEO_COUNT][4];
int activity3PlayingGrowlScenario = -1;
int activity3PlayingGrowlIndex = -1;
int activity3PlayingGrowlStartedMillis = -1;
boolean activity3MoviesPrepared = false;
int activity3MoviesPreparedCount = 0;
volatile boolean activity3FilesPrepared = false;
PImage[][] activityObservationSlides = new PImage[3][ACTIVITY_OBSERVATION_SLIDE_COUNT];
String[][] activityObservationSlideFiles = {
  {
    "activity1/slides/1_Lamber o focinho.png",
    "activity1/slides/2_Lamber o focinho.png",
    "activity1/slides/3_Lamber o focinho.png"
  },
  {
    "activity2/slides/1_Olhar para o alvo.png",
    "activity2/slides/2_Olhar para o alvo.png",
    "activity2/slides/3_Olhar para o alvo.png"
  },
  {
    "activity3/slides/1_Rosnado L\u00fadico.png",
    "activity3/slides/2_Rosnado L\u00fadico.png",
    "activity3/slides/3_Rosnado L\u00fadico.png"
  }
};
int[] activityObservationSlideStartedMillis = {-1, -1, -1};
int videoStartMillis = 0;
int videoRestartAttempts = 0;
int guidedVideoFinishedMillis = -1;
int isolatedVideoFinishedMillis = -1;
int activity1ObservationFinishedMillis = -1;
int activity2ObservationFinishedMillis = -1;
int activity3ObservationFinishedMillis = -1;
int activity3VideoIndex = 0;
int activity3SequencePosition = 0;
boolean activity3VideoStarted = false;
int activity3VideoStartMillis = 0;
int[] activity3VideoRestartAttempts = new int[ACTIVITY3_VIDEO_COUNT];
float activity3VideoWatchdogLastTime = -1;
int activity3VideoWatchdogLastProgressMillis = -1;
int activity3VideoWatchdogIndex = -1;
boolean replayVibrationActive = false;
boolean vibrationOverlayEnabled = false;
int vibrationOverlayStartedMillis = -1;
int vibrationOverlayUntilMillis = -1;
int vibrationOverlayPointMask = 0;
int vibrationOverlayIntensity = 0;
int vibrationOverlayDurationMs = 0;
float vibrationOverlayX = -1;
float vibrationOverlayY = -1;
float vibrationOverlaySize = 68;
boolean vibrationOverlayDragging = false;
float vibrationOverlayDragOffsetX = 0;
float vibrationOverlayDragOffsetY = 0;
int hapticTuneAmplitude = 25;
float hapticTuneFrequencyHz = 2.0;
boolean hapticTunePreviewActive = false;
int hapticTunePreviewUntilMillis = -1;
int hapticTuneLastPulseMillis = -1;
boolean homeHapticAmpDragging = false;
boolean homeHapticFreqDragging = false;
boolean currentVideoEndFrozen = false;
int videoEndFreezePauseMillis = -1;
int lastVideoDrawErrorMillis = 0;
volatile boolean videosLoading = false;
volatile boolean videosLoaded = false;
volatile int videosLoadedCount = 0;
volatile int activity3VideosLoadedCount = 0;
boolean videosLoadingScheduled = false;
boolean videosLoadingStarted = false;
int videosLoadingScheduledMillis = -1;
int startupLoadingStartedMillis = -1;
boolean moviesPrepared = false;
int moviesPreparedCount = 0;
int activity3VideoWarmupIndex = 0;
int videoWarmupIndex = 0;
int videoWarmupStartedMillis = -1;

float[][] vibrationCueTimes = new float[BEHAVIOR_COUNT][MAX_VIBRATION_CUES];
int[][] vibrationCuePointMasks = new int[BEHAVIOR_COUNT][MAX_VIBRATION_CUES];
int[][] vibrationCueDurations = new int[BEHAVIOR_COUNT][MAX_VIBRATION_CUES];
int[][] vibrationCueIntensities = new int[BEHAVIOR_COUNT][MAX_VIBRATION_CUES];
int[] vibrationCueCounts = new int[BEHAVIOR_COUNT];
int[] vibrationCueCursor = new int[BEHAVIOR_COUNT];
float[][] activity3VibrationCueTimes = new float[ACTIVITY3_VIDEO_COUNT][MAX_VIBRATION_CUES];
int[][] activity3VibrationCuePointMasks = new int[ACTIVITY3_VIDEO_COUNT][MAX_VIBRATION_CUES];
int[][] activity3VibrationCueDurations = new int[ACTIVITY3_VIDEO_COUNT][MAX_VIBRATION_CUES];
int[][] activity3VibrationCueIntensities = new int[ACTIVITY3_VIDEO_COUNT][MAX_VIBRATION_CUES];
int[] activity3VibrationCueCounts = new int[ACTIVITY3_VIDEO_COUNT];
int[] activity3VibrationCueCursor = new int[ACTIVITY3_VIDEO_COUNT];
boolean vibrationMarkingMode = false;

int screen = 0;
int behaviorSequencePosition = 0;
// 1: observacao, 2: tarefa interpretativa, 3: feedback
int phase  = 1;

float t = 0;
boolean animating = false;

float nextX, nextY, nextW, nextH;
float backX, backY, backW, backH;
float replayX, replayY, replayW, replayH;
float phase2NextX, phase2NextY, phase2NextW, phase2NextH;

float[] interpretationTimes = {-1, -1, -1, -1, -1};
int[] interpretationChoices = {-1, -1, -1, -1, -1};
float[][] interpretationMarkedTimes = {
  {-1, -1}, {-1, -1}, {-1, -1}, {-1, -1}, {-1, -1}
};
int[][] interpretationMarkedChoices = {
  {-1, -1}, {-1, -1}, {-1, -1}, {-1, -1}, {-1, -1}
};
int[] interpretationMarkCounts = {0, 0, 0, 0, 0};
int[] requiredInterpretationMarks = {1, 1, 2, 1, 1};
final int INTERPRETATION_STAGE_TIME = 0;
final int INTERPRETATION_STAGE_CHOICE = 1;
int interpretationTaskStage = INTERPRETATION_STAGE_TIME;
float[] correctInterpretationStarts = {5.00, 0.60, 2.60, 2.20, 3.50};
float[] correctInterpretationEnds   = {7.00, 2.00, 3.50, 3.00, 5.50};
float[] correctInterpretationSecondStarts = {-1, -1, 7.00, -1, -1};
float[] correctInterpretationSecondEnds   = {-1, -1, 9.00, -1, -1};
boolean interpretationDragging = false;
boolean interpretationSeekPending = false;
float interpretationRequestedTime = -1;
int interpretationPauseAtMillis = -1;
int interpretationLastSeekMillis = 0;
float interpretationTimelineX, interpretationTimelineY;
float interpretationTimelineW, interpretationTimelineH;
float[] interpretationChoiceX = new float[INTERPRETATION_CHOICE_COUNT];
float[] interpretationChoiceY = new float[INTERPRETATION_CHOICE_COUNT];
float[] interpretationChoiceW = new float[INTERPRETATION_CHOICE_COUNT];
float[] interpretationChoiceH = new float[INTERPRETATION_CHOICE_COUNT];
int[] interpretationChoiceOrder = {0, 1, 2, 3, 4, 5, 6, 7};
float interpretationConfirmX, interpretationConfirmY;
float interpretationConfirmW, interpretationConfirmH;
float feedbackNextX, feedbackNextY, feedbackNextW, feedbackNextH;
boolean feedbackPlaybackComplete = false;
int feedbackLoopPauseStartedMillis = -1;

float homeStartX, homeStartY, homeStartW, homeStartH;
float homeReviewX, homeReviewY, homeReviewW, homeReviewH;
float homeExitX, homeExitY, homeExitW, homeExitH;
float homeOptionsX, homeOptionsY, homeOptionsW, homeOptionsH;
float homeOptionsPanelX, homeOptionsPanelY, homeOptionsPanelW, homeOptionsPanelH;
float homeShuffleX, homeShuffleY, homeShuffleW, homeShuffleH;
float homeResearchX, homeResearchY, homeResearchW, homeResearchH;
float homeDesignerX, homeDesignerY, homeDesignerW, homeDesignerH;
float homeHapticAmpX, homeHapticAmpY, homeHapticAmpW, homeHapticAmpH;
float homeHapticFreqX, homeHapticFreqY, homeHapticFreqW, homeHapticFreqH;
float hapticTuneRepeatX, hapticTuneRepeatY, hapticTuneRepeatW, hapticTuneRepeatH;
float researchPromptX, researchPromptY, researchPromptW, researchPromptH;
float researchPromptInputX, researchPromptInputY, researchPromptInputW, researchPromptInputH;
float researchPromptCancelX, researchPromptCancelY, researchPromptCancelW, researchPromptCancelH;
float researchPromptConfirmX, researchPromptConfirmY, researchPromptConfirmW, researchPromptConfirmH;
int homeSelectedOption = 2;
final int HOME_OPTION_COUNT = 5;
float[] homeOptionX = new float[HOME_OPTION_COUNT];
float[] homeOptionY = new float[HOME_OPTION_COUNT];
float[] homeOptionW = new float[HOME_OPTION_COUNT];
float[] homeOptionH = new float[HOME_OPTION_COUNT];

float isolatedBackX, isolatedBackY, isolatedBackW, isolatedBackH;
float isolatedPrevX, isolatedPrevY, isolatedPrevW, isolatedPrevH;

int placeholderActivity = 2;
int[] behaviorOrder = {0, 1, 2, 3, 4};
int[] activity3Order = {0, 1, 2, 3, 4, 5};

int activity1Step = 0;
int[] activity1MomentRelevance = {-1, -1, -1, -1};
int[] activity1MomentSignal = {-1, -1, -1, -1};
float[] activity1MomentX = new float[4];
float[] activity1MomentY = new float[4];
float[] activity1MomentW = new float[4];
float[] activity1MomentH = new float[4];
float[] activity1CardX = new float[4];
float[] activity1CardY = new float[4];
float[] activity1CardW = new float[4];
float[] activity1CardH = new float[4];
float activity1BackX, activity1BackY, activity1BackW, activity1BackH;
float activity1ResetX, activity1ResetY, activity1ResetW, activity1ResetH;
float activity1ConfirmX, activity1ConfirmY, activity1ConfirmW, activity1ConfirmH;
boolean activity1Dragging = false;
int activity1DragKind = 0;
int activity1DragValue = -1;

int activity2Step = 0;
int[] activity2SelectedMasks = {0, 0, 0, 0};
float[][] activity2OptionX = new float[4][4];
float[][] activity2OptionY = new float[4][4];
float[][] activity2OptionW = new float[4][4];
float[][] activity2OptionH = new float[4][4];
float activity2ResetX, activity2ResetY, activity2ResetW, activity2ResetH;
float activity2ConfirmX, activity2ConfirmY, activity2ConfirmW, activity2ConfirmH;

int activity3Step = 0;
int activity3SelectedGrowl = -1;
int activity3SelectedSoundMask = 0;
int activity3SelectedBehavior = -1;
float[] activity3GrowlX = new float[4];
float[] activity3GrowlY = new float[4];
float[] activity3GrowlW = new float[4];
float[] activity3GrowlH = new float[4];
float[] activity3GrowlPlayX = new float[4];
float[] activity3GrowlPlayY = new float[4];
float[] activity3GrowlPlayW = new float[4];
float[] activity3GrowlPlayH = new float[4];
float activity3ChosenGrowlPlayX, activity3ChosenGrowlPlayY;
float activity3ChosenGrowlPlayW, activity3ChosenGrowlPlayH;
float[] activity3SoundX = new float[12];
float[] activity3SoundY = new float[12];
float[] activity3SoundW = new float[12];
float[] activity3SoundH = new float[12];
float[] activity3BehaviorX = new float[4];
float[] activity3BehaviorY = new float[4];
float[] activity3BehaviorW = new float[4];
float[] activity3BehaviorH = new float[4];
float activity3SoundDropX, activity3SoundDropY, activity3SoundDropW, activity3SoundDropH;
float activity3BehaviorDropX, activity3BehaviorDropY, activity3BehaviorDropW, activity3BehaviorDropH;
float activity3ResetX, activity3ResetY, activity3ResetW, activity3ResetH;
float activity3ConfirmX, activity3ConfirmY, activity3ConfirmW, activity3ConfirmH;
boolean activity3Dragging = false;
int activity3DragKind = 0;
int activity3DragValue = -1;

final float TARGET_W = 1920.0;
final float TARGET_H = 1080.0;
final float TARGET_SCALE = 1.35;
int uiPixelDensity = 1;
int nativeFullscreenWidth = -1;
int nativeFullscreenHeight = -1;
boolean fullscreenSurfaceAdjusted = false;
float baseW = TARGET_W / TARGET_SCALE;
float baseH = TARGET_H / TARGET_SCALE;
float scaleFactor;

final float TYPE_HERO = 64.0 / TARGET_SCALE;
final float TYPE_TITLE = 44.0 / TARGET_SCALE;
final float TYPE_SECTION = 36.0 / TARGET_SCALE;
final float TYPE_SUBHEADING = 28.0 / TARGET_SCALE;
final float TYPE_BODY = 24.0 / TARGET_SCALE;
final float TYPE_LABEL = 20.0 / TARGET_SCALE;
final float TYPE_CAPTION = 16.0 / TARGET_SCALE;
final float LEADING_LARGE = 44.0 / TARGET_SCALE;
final float LEADING_BODY = 40.0 / TARGET_SCALE;
final float LEADING_COMPACT = 32.0 / TARGET_SCALE;

float margin, gutter;
float leftW, rightW;
float contentTop, contentBottom;
float v1x, v1y, v1w, v1h;
float v2x, v2y, v2w, v2h;

color bg         = color(5, 8, 16);
color card       = color(13, 19, 33);
color cardAlt    = color(19, 27, 45);
color strokeC    = color(46, 60, 86);
color purple     = color(105, 68, 245);
color purpleDim  = color(48, 34, 112);
color purpleText = color(142, 112, 255);
color white      = color(255);
color muted      = color(168, 178, 198);
color grey       = color(86, 96, 118);
color greyDark   = color(34, 42, 58);
color surfaceTop = color(18, 25, 42);
color surfaceLow = color(10, 15, 27);

int highlightedPart = -1;
int highlightTimer  = 0;

String[] titles = {
  "Abaixamento corporal",
  "Afastamento",
  "Desvio de cabeça e olhar",
  "Levantamento de pata dianteira",
  "Recuo corporal"
};

String[] videoFiles = {
  "activity4/videos/Abaixamento corporal_final 1080p.mp4",
  "activity4/videos/Afastamento_final_1080p.mp4",
  "activity4/videos/Desvio cabeça_final_1080p.mp4",
  "activity4/videos/Levantamento de Pata Dianteira_final_1080p.mp4",
  "activity4/videos/Recuo corporal_final_1080p.mp4"
};

String[] activity3VideoFiles = {
  "activity3/videos/Rosnado Amea\u00e7a Cenario 1.mp4",
  "activity3/videos/Rosnado Amea\u00e7a Cenario 2.mp4",
  "activity3/videos/Rosnado Guarda Alimento Cenario 1.mp4",
  "activity3/videos/Rosnado Guarda Alimento Cenario 2.mp4",
  "activity3/videos/Rosnado Ludico Cenario 1.mp4",
  "activity3/videos/Rosnado Ludico Cenario 2.mp4"
};

String[] activity3ScenarioTitles = {
  "Cen\u00e1rio 1",
  "Cen\u00e1rio 2",
  "Cen\u00e1rio 3",
  "Cen\u00e1rio 4",
  "Cen\u00e1rio 5",
  "Cen\u00e1rio 6"
};

float[] videoEndMargins = {
  VIDEO_END_MARGIN_SECONDS,
  VIDEO_END_MARGIN_SECONDS,
  VIDEO_END_MARGIN_SECONDS,
  VIDEO_END_MARGIN_SECONDS,
  0.70
};

String[][] observationPoints = {
  {
    "O cão fica visivelmente mais baixo durante a sequência.",
    "Observa se o tronco se aproxima do chão ou se os membros flectem.",
    "Repara na tensão do corpo, na cabeça, no olhar e na distância ao estímulo.",
    "Compara o que acontece antes e depois da mudança postural.",
    "Não leias o abaixamento como sinal isolado ou significado fixo."
  },
  {
    "O cão aumenta a distância em relação a uma pessoa, objeto ou estímulo.",
    "Observa se o movimento surge depois de aproximação, contacto ou pressão.",
    "Repara na direção da deslocação: lateral, diagonal, em curva ou para outro ponto.",
    "Compara a posição inicial e final do cão no espaço.",
    "Não assumas automaticamente medo ou rejeição sem observar o contexto."
  },
  {
    "O cão desvia primeiro o olhar e depois a cabeça/focinho.",
    "Observa as duas mudanças em momentos diferentes da sequência.",
    "Distingue o desvio dos olhos da rotação posterior da cabeça.",
    "Repara se surge após olhar direto, toque, aproximação ou pressão.",
    "Não assumas distração sem considerar o antes, o durante e o depois."
  },
  {
    "O cão levanta uma pata dianteira durante a sequência observada.",
    "Observa se a pata fica suspensa fora de uma passada normal.",
    "Repara na duração do levantamento e na distribuição do peso.",
    "Compara a postura geral, o olhar e a distância ao estímulo.",
    "Não transformes este movimento num significado único."
  },
  {
    "O cão desloca o corpo para trás, reduzindo a aproximação ao estímulo.",
    "Observa se o recuo surge perante aproximação, toque ou movimento do outro.",
    "Repara se continua parcialmente orientado para o estímulo.",
    "Compara o recuo com um afastamento mais amplo para outro ponto.",
    "Lê o movimento em conjunto com tensão, cabeça, olhar e sequência."
  }
};

String[] explanations = {
  "Mudança postural que pode ajudar a regular a intensidade da interação quando lida com corpo, tensão e contexto.",
  "Aumento de distância que pode estar associado à gestão da aproximação ou necessidade de espaço.",
  "Desvio do olhar e da cabeça que pode funcionar como regulação social perante aproximação ou pressão.",
  "Pista postural subtil que pode surgir em momentos de atenção, hesitação, incerteza ou pausa na ação.",
  "Redução da aproximação que pode indicar gestão de distância mantendo o estímulo em atenção."
};

String[] feedbackExplanations = {
  "Neste contexto, o abaixamento corporal é trabalhado como uma mudança postural visível: o cão reduz a altura do corpo e reorganiza a sua posição perante a situação. A interpretação não deve partir apenas do gesto de baixar, mas da forma como o corpo se apresenta no conjunto: tensão ou fluidez, distribuição do peso, cabeça, olhar, distância ao estímulo e resposta do outro interveniente. Aqui, o comportamento pode funcionar como pista de regulação da intensidade da interação, sobretudo quando surge numa sequência de aproximação ou pressão. Ainda assim, não permite concluir isoladamente um estado emocional específico.",
  "Neste contexto, o afastamento corresponde ao aumento da distância entre o cão e uma pessoa, objeto ou estímulo. A mudança é espacial e relacional: interessa perceber de onde o cão parte, para onde se desloca, se o movimento é lateral, diagonal, em curva ou para outro ponto, e o que acontece depois. O afastamento pode estar associado à gestão da aproximação, à procura de espaço ou à redução da intensidade da interação, mas não deve ser interpretado automaticamente como medo, rejeição ou fuga. A leitura torna-se mais rigorosa quando se articula distância, orientação corporal, velocidade e contexto.",
  "Neste contexto, o comportamento inclui duas mudanças: primeiro o desvio do olhar e depois o desvio da cabeça/focinho. O desvio do olhar pode ser uma alteração muito subtil da orientação da atenção, enquanto a rotação da cabeça torna a mudança corporal mais evidente. Quando surge perante aproximação, toque, pressão ou contacto visual direto, pode funcionar como pista de regulação social, ajudando o cão a gerir a intensidade da interação. A interpretação deve distinguir distração, exploração do ambiente e resposta ao estímulo principal, observando a sequência completa e outros sinais associados.",
  "Neste contexto, o levantamento de pata dianteira é tratado como pista postural subtil: uma pata fica suspensa fora da passada normal e interrompe a estabilidade habitual do corpo. Este movimento não prova, por si só, stress, medo ou ansiedade. Pode surgir em situações de atenção, antecipação, incerteza, hesitação ou pausa na ação, dependendo do contexto. Para o interpretar, é importante observar a duração da suspensão, a transferência de peso, a tensão corporal, a orientação da cabeça, o olhar e a proximidade do estímulo. O valor pedagógico está em aprender a ler o sinal com o corpo completo.",
  "Neste contexto, o recuo corporal mostra o cão a deslocar o corpo para trás, reduzindo a aproximação ao estímulo. Distingue-se do afastamento geral porque o cão pode continuar parcialmente orientado para aquilo que está à frente, mantendo atenção enquanto cria mais distância. Esta mudança pode funcionar como gestão da aproximação, tentativa de preservar espaço ou resposta a uma pressão contextual. A interpretação deve considerar se o recuo surge depois de aproximação, toque ou movimento do outro interveniente, e deve articular distância, tensão muscular, cabeça, olhar e sequência temporal."
};

String[] refinedExplanations = {
  "Neste contexto, baixar o corpo pode manifestar desconforto perante a presen\u00e7a humana, sobretudo quando surge com tens\u00e3o, pausa ou menor iniciativa.",
  "Neste contexto, afastar-se pode manifestar desconforto atrav\u00e9s do aumento de dist\u00e2ncia face \u00e0 pessoa ou \u00e0 aproxima\u00e7\u00e3o.",
  "Neste contexto, desviar cabe\u00e7a ou olhar pode manifestar desconforto ao reduzir contacto direto com a pessoa.",
  "Neste contexto, levantar a pata dianteira pode manifestar desconforto quando interrompe a a\u00e7\u00e3o perante a presen\u00e7a ou aproxima\u00e7\u00e3o humana.",
  "Neste contexto, recuar pode manifestar desconforto ao criar dist\u00e2ncia enquanto o c\u00e3o continua atento \u00e0 pessoa."
};

String[] refinedFeedbackExplanations = {
  "Neste contexto, o abaixamento corporal \u00e9 observado como poss\u00edvel manifesta\u00e7\u00e3o de desconforto antes da intera\u00e7\u00e3o humana. O c\u00e3o reduz a altura do corpo, redistribui o peso e altera a forma como se posiciona perante a pessoa.\n\nEsta mudan\u00e7a pode indicar que a aproxima\u00e7\u00e3o, a presen\u00e7a ou a aten\u00e7\u00e3o humana est\u00e3o a aumentar a tens\u00e3o da situa\u00e7\u00e3o. O corpo parece menos dispon\u00edvel para avan\u00e7ar e pode preparar uma pausa, bloqueio, recuo ou afastamento.\n\nObserva a rigidez do tronco, a distribui\u00e7\u00e3o do peso, a posi\u00e7\u00e3o da cabe\u00e7a, o olhar, a cauda e a continuidade do movimento. O sinal ganha significado quando surge dentro desta sequ\u00eancia de presen\u00e7a humana.",
  "Neste contexto, o afastamento \u00e9 observado como resposta espacial \u00e0 presen\u00e7a humana. O c\u00e3o aumenta a dist\u00e2ncia em rela\u00e7\u00e3o \u00e0 pessoa, reduzindo a proximidade antes de haver intera\u00e7\u00e3o direta.\n\nEsta a\u00e7\u00e3o pode manifestar desconforto porque cria mais espa\u00e7o e diminui a press\u00e3o da aproxima\u00e7\u00e3o. O importante n\u00e3o \u00e9 apenas o deslocamento, mas a rela\u00e7\u00e3o entre o movimento do c\u00e3o, a posi\u00e7\u00e3o da pessoa e o momento em que a dist\u00e2ncia aumenta.\n\nObserva se o c\u00e3o se afasta depois de uma aproxima\u00e7\u00e3o, contacto visual, toque ou mudan\u00e7a de postura humana. Repara tamb\u00e9m na velocidade, dire\u00e7\u00e3o, orienta\u00e7\u00e3o corporal e se continua atento \u00e0 pessoa.",
  "Neste contexto, o desvio de cabe\u00e7a e o desvio do olhar s\u00e3o tratados como duas manifesta\u00e7\u00f5es poss\u00edveis de desconforto perante a presen\u00e7a humana. O c\u00e3o reduz o contacto direto sem precisar de se afastar de imediato.\n\nO desvio do olhar pode ser muito subtil e deslocar apenas a aten\u00e7\u00e3o visual. O desvio da cabe\u00e7a torna mais vis\u00edvel a altera\u00e7\u00e3o da orienta\u00e7\u00e3o corporal. Em conjunto, estes sinais podem indicar tentativa de diminuir press\u00e3o social, sobretudo quando h\u00e1 aproxima\u00e7\u00e3o, olhar direto ou presen\u00e7a muito pr\u00f3xima.\n\nPor isso, a tarefa pede duas marca\u00e7\u00f5es. Observa quando cada mudan\u00e7a aparece, para onde o c\u00e3o deixa de olhar, como orienta o focinho e se depois permanece, congela, baixa o corpo, recua ou evita nova aproxima\u00e7\u00e3o.",
  "Neste contexto, o levantamento de pata dianteira \u00e9 observado como uma pausa corporal perante a presen\u00e7a humana. A pata fica suspensa fora da passada normal e interrompe momentaneamente a estabilidade do corpo.\n\nA suspens\u00e3o da pata pode manifestar desconforto, hesita\u00e7\u00e3o ou incerteza antes da intera\u00e7\u00e3o. O c\u00e3o parece interromper a a\u00e7\u00e3o enquanto avalia a proximidade da pessoa e decide se continua, fica parado, reduz contacto ou cria dist\u00e2ncia.\n\nObserva a dura\u00e7\u00e3o da pata levantada, a transfer\u00eancia de peso, a tens\u00e3o muscular, a posi\u00e7\u00e3o da cabe\u00e7a e o olhar. O sinal deve ser lido em conjunto com a aproxima\u00e7\u00e3o humana e com a resposta corporal que vem a seguir.",
  "Neste contexto, o recuo corporal \u00e9 observado como uma cria\u00e7\u00e3o imediata de dist\u00e2ncia perante a presen\u00e7a humana. O c\u00e3o desloca o corpo para tr\u00e1s, mas pode continuar orientado para a pessoa.\n\nEsta resposta pode manifestar desconforto porque reduz a aproxima\u00e7\u00e3o sem abandonar totalmente a situa\u00e7\u00e3o. O c\u00e3o mant\u00e9m aten\u00e7\u00e3o ao est\u00edmulo humano enquanto procura recuperar espa\u00e7o, controlar a proximidade e diminuir a press\u00e3o da intera\u00e7\u00e3o.\n\nObserva se o recuo aparece depois de aproxima\u00e7\u00e3o, toque, movimento brusco ou contacto visual. A leitura deve considerar dire\u00e7\u00e3o, velocidade, tens\u00e3o corporal, cauda, orelhas, olhar e o que acontece imediatamente depois."
};

String[] refinedInterpretationHints = {
  "Pode manifestar desconforto ao baixar o corpo perante a pessoa.",
  "Pode manifestar desconforto ao aumentar a dist\u00e2ncia face \u00e0 pessoa.",
  "Pode manifestar desconforto ao reduzir contacto direto com a pessoa.",
  "Pode manifestar desconforto atrav\u00e9s de uma pausa corporal.",
  "Pode manifestar desconforto ao recuar mantendo aten\u00e7\u00e3o \u00e0 pessoa."
};

String[] interpretationHints = {
  "Pode ajudar a regular a intensidade da interação.",
  "Pode indicar gestão de distância ou procura de espaço.",
  "Pode funcionar como regulação social perante pressão.",
  "Pode surgir em atenção, hesitação ou incerteza.",
  "Pode reduzir aproximação mantendo o estímulo em atenção."
};

String[] interpretationDecoyLabels = {
  "Bocejo",
  "Lamber o focinho",
  "Congelamento"
};

String[] interpretationDecoyHints = {
  "Pode surgir em transições de estado, tensão ou pausa.",
  "Pode aparecer em momentos de aproximação, espera ou incerteza.",
  "Pode indicar uma pausa súbita que exige leitura do contexto."
};

String[] refinedInterpretationDecoyHints = {
  "Pode manifestar tens\u00e3o quando surge perante aproxima\u00e7\u00e3o humana.",
  "Pode manifestar desconforto quando aparece em contexto de proximidade.",
  "Pode manifestar alerta ou desconforto perante a presen\u00e7a humana."
};

String[] homeActivityLabels = {
  "Atividade 1", "Atividade 2", "Atividade 3", "Atividade 4", "Sair"
};

String[] activity1MomentLabels = {
  "Momento 1", "Momento 2", "Momento 3", "Momento 4"
};

String[] activity1MomentTimes = {
  "00:00 - 00:02", "00:02 - 00:04", "00:04 - 00:07", "00:07 - 00:10"
};

String[] activity1RelevanceCards = {
  "Relevante", "Neutro"
};

String[] activity1SignalCards = {
  "Evitamento", "Tens\u00e3o corporal", "Ambos"
};

// Resposta da atividade provisoria da Atividade 1.
// Indices: activity1RelevanceCards -> 0 Relevante, 1 Neutro.
// Indices: activity1SignalCards -> 0 Evitamento, 1 Tensao corporal, 2 Ambos.
int[] activity1CorrectRelevance = {1, 1, 0, 0};
int[] activity1CorrectSignal = {-1, -1, 0, 1};
String activity1FeedbackExplanation =
  "Nesta sequ\u00eancia, os momentos relevantes distinguem movimentos neutros de pistas comportamentais. A leitura depende da dura\u00e7\u00e3o, da postura e do contexto, n\u00e3o de sinais isolados.";

String[] activity2ColumnTitles = {
  "Intervenientes", "Alvo", "Pistas Comportamentais", "Significado"
};

String[] activity2ColumnSubtitles = {
  "Quem est\u00e1 envolvido?",
  "Para onde o c\u00e3o est\u00e1 a dirigir a aten\u00e7\u00e3o?",
  "Que comportamentos sustentam a tua interpreta\u00e7\u00e3o?",
  "Qual o poss\u00edvel significado deste comportamento?"
};

String[][] activity2Options = {
  {"C\u00e3o", "Tutor"},
  {"Bola", "Porta"},
  {"Olhar para o tutor", "Olhar para o brinquedo", "Desviar o olhar"},
  {"Orientar a aten\u00e7\u00e3o", "Pedir aux\u00edlio", "Indicar inten\u00e7\u00e3o"}
};

String[] activity2ColumnHints = {
  "Podes selecionar mais do que um.",
  "Seleciona apenas um alvo principal.",
  "Podes selecionar v\u00e1rias pistas.",
  "Seleciona apenas um significado."
};

boolean[] activity2MultiSelect = {true, false, true, false};
int[] activity2CorrectOption = {0, 1, 0, 2};
String activity2FeedbackExplanation =
  "A rela\u00e7\u00e3o comunicativa constr\u00f3i-se ao ligar quem participa, para onde a aten\u00e7\u00e3o se dirige, que pistas sustentam a leitura e que significado \u00e9 plaus\u00edvel. O foco est\u00e1 na rela\u00e7\u00e3o espacial e temporal entre c\u00e3o, tutor e alvo.";

String[] activity3GrowlLabels = {
  "Rosnado A", "Rosnado B", "Rosnado C", "Rosnado D"
};

String[] activity3SoundClues = {
  "Som grave", "Som cont\u00ednuo", "Pausas curtas",
  "Som mais agudo", "Som intermitente", "Pausas longas",
  "Rosnado curto", "Ritmo r\u00e1pido", "Intensidade baixa",
  "Rosnado prolongado", "Ritmo lento", "Intensidade alta"
};

String[][] activity3BehaviorOptionsByScenario = {
  {"Pedido de aten\u00e7\u00e3o", "Pedido de dist\u00e2ncia / aviso", "Poss\u00edvel desconforto f\u00edsico", "Inseguran\u00e7a contextual"},
  {"Procura de contacto", "Poss\u00edvel desconforto f\u00edsico", "Pedido de dist\u00e2ncia / aviso", "Inseguran\u00e7a contextual"},
  {"Prote\u00e7\u00e3o de recurso alimentar", "Pedido de aten\u00e7\u00e3o", "Poss\u00edvel desconforto f\u00edsico", "Inseguran\u00e7a contextual"},
  {"Procura de contacto", "Poss\u00edvel desconforto f\u00edsico", "Inseguran\u00e7a contextual", "Prote\u00e7\u00e3o de recurso alimentar"},
  {"Pedido de aten\u00e7\u00e3o", "Brincadeira", "Poss\u00edvel desconforto f\u00edsico", "Frustra\u00e7\u00e3o"},
  {"Procura de contacto", "Poss\u00edvel desconforto f\u00edsico", "Brincadeira", "Frustra\u00e7\u00e3o"}
};

// Cada linha define que tipo de som cada card A/B/C/D toca.
// O papel 2 corresponde sempre ao rosnado correto, mas a posicao visual varia por cenario.
int[][] activity3GrowlCardRolesByScenario = {
  {0, 1, 2, 3},
  {2, 0, 1, 3},
  {0, 1, 3, 2},
  {0, 2, 1, 3},
  {0, 1, 2, 3},
  {2, 0, 1, 3}
};
int[][] activity3CorrectSoundCluesByScenario = {
  {0, 1, 9},
  {0, 1, 9},
  {0, 1, 9},
  {0, 1, 9},
  {6, 4, 2, 7},
  {6, 4, 2, 7}
};
int[] activity3CorrectBehaviors = {1, 2, 0, 3, 1, 2};
String activity3LegacyFeedbackExplanation =
  "A interpreta\u00e7\u00e3o do rosnado depende de dura\u00e7\u00e3o, ritmo, intensidade, pausas e contexto. A vocaliza\u00e7\u00e3o funciona como pista comunicativa quando articulada com a situa\u00e7\u00e3o observada, n\u00e3o como som isolado ou prova autom\u00e1tica de ameaça.";

String[] activity3FeedbackExplanations = {
  "Observa que a pessoa reduz a dist\u00e2ncia e o c\u00e3o responde com um rosnado grave, cont\u00ednuo e prolongado. A interpreta\u00e7\u00e3o mais forte \u00e9 pedido de dist\u00e2ncia / aviso porque a vocaliza\u00e7\u00e3o parece regular a aproxima\u00e7\u00e3o antes de uma poss\u00edvel escalada. Distingue este caso da prote\u00e7\u00e3o de recurso: aqui o foco n\u00e3o \u00e9 manter comida ou objeto, mas gerir a presen\u00e7a da pessoa. O som sozinho n\u00e3o chega; contexto, dura\u00e7\u00e3o e continuidade do rosnado sustentam a leitura.",
  "Neste v\u00eddeo, a presen\u00e7a junto \u00e0 porta cria uma situa\u00e7\u00e3o social inesperada. O rosnado grave, cont\u00ednuo e prolongado deve ser lido como pedido de dist\u00e2ncia / aviso porque comunica necessidade de espa\u00e7o perante a aproxima\u00e7\u00e3o ou presen\u00e7a da pessoa. N\u00e3o significa automaticamente ataque: o rosnado \u00e9 comunica\u00e7\u00e3o e pode evitar conflito. A pista principal \u00e9 a rela\u00e7\u00e3o entre o som, a porta e a proximidade humana.",
  "Aqui, o elemento decisivo \u00e9 a ta\u00e7a de comida. O c\u00e3o vocaliza quando existe aproxima\u00e7\u00e3o ao recurso, por isso a resposta esperada \u00e9 prote\u00e7\u00e3o de recurso alimentar. As pistas sonoras graves, cont\u00ednuas e prolongadas podem parecer semelhantes \u00e0s de aviso social, mas o contexto muda o significado: o rosnado comunica defesa ou controlo de acesso ao alimento, n\u00e3o apenas desconforto perante uma pessoa.",
  "Neste cen\u00e1rio, o osso organiza a interpreta\u00e7\u00e3o. O c\u00e3o est\u00e1 junto de um recurso valorizado e responde \u00e0 aproxima\u00e7\u00e3o com rosnado grave, cont\u00ednuo e prolongado. A leitura mais adequada \u00e9 prote\u00e7\u00e3o de recurso alimentar, n\u00e3o apenas pedido de dist\u00e2ncia geral, porque a vocaliza\u00e7\u00e3o est\u00e1 ligada \u00e0 manuten\u00e7\u00e3o do osso e ao controlo da proximidade da pessoa.",
  "Neste v\u00eddeo, o rosnado aparece dentro de uma brincadeira de puxar, com envolvimento volunt\u00e1rio entre c\u00e3o, pessoa e brinquedo. Mais do que procurar um som isoladamente mais agudo, observa a estrutura temporal: rosnados curtos, intermitentes, com pausas curtas e ritmo r\u00e1pido tendem a apoiar a leitura l\u00fadica quando o corpo continua envolvido na intera\u00e7\u00e3o. A resposta esperada \u00e9 brincadeira, n\u00e3o pedido de afastamento.",
  "Aqui, a bola e a postura corporal compat\u00edvel com convite l\u00fadico tornam o contexto central. O rosnado curto, intermitente, com pausas curtas e ritmo r\u00e1pido acompanha a aproxima\u00e7\u00e3o ao objeto e a continuidade da intera\u00e7\u00e3o. A resposta esperada \u00e9 brincadeira: o rosnado participa na excita\u00e7\u00e3o l\u00fadica e deve ser interpretado juntamente com corpo, objeto e sequ\u00eancia."
};

void settings(){
  configureFullscreenDpi();
  uiPixelDensity = displayDensity();
  fullScreen(P2D);
  pixelDensity(uiPixelDensity);
  smooth(4);
}

void setup(){
  detectNativeFullscreenSize();
  surface.setResizable(false);
  surface.setLocation(0, 0);
  background(bg);

  int fontResolution = ceil(72 * uiPixelDensity);
  PFont fonte = createFont("common/Inter-Regular.ttf", fontResolution, true);
  textFont(fonte);

  setupVibrationTimelines();
  printVibrationMarkingHelp();
  startupLoadingStartedMillis = millis();

  loadActivityObservationSlides();
  scheduleVideoLoading();

  startBHapticsBridge();
}

void configureFullscreenDpi(){
  try {
    System.setProperty("sun.java2d.dpiaware", "true");
    System.setProperty("sun.java2d.uiScale", "1.0");
  } catch(Exception ignored){}
}

void detectNativeFullscreenSize(){
  nativeFullscreenWidth = displayWidth;
  nativeFullscreenHeight = displayHeight;

  try {
    java.awt.DisplayMode mode = java.awt.GraphicsEnvironment
      .getLocalGraphicsEnvironment()
      .getDefaultScreenDevice()
      .getDisplayMode();
    nativeFullscreenWidth = max(nativeFullscreenWidth, mode.getWidth());
    nativeFullscreenHeight = max(nativeFullscreenHeight, mode.getHeight());
  } catch(Exception ignored){}

  try {
    float windowsScale = java.awt.Toolkit.getDefaultToolkit().getScreenResolution() / 96.0;
    nativeFullscreenWidth = max(nativeFullscreenWidth, round(displayWidth * windowsScale));
    nativeFullscreenHeight = max(nativeFullscreenHeight, round(displayHeight * windowsScale));
  } catch(Exception ignored){}

  println(
    "Fullscreen fisico: " + nativeFullscreenWidth + "x" + nativeFullscreenHeight +
    " | Processing: " + displayWidth + "x" + displayHeight
  );
}

void stabilizeFullscreenSurface(){
  if(fullscreenSurfaceAdjusted || frameCount < 2) return;
  fullscreenSurfaceAdjusted = true;

  if(nativeFullscreenWidth <= 0 || nativeFullscreenHeight <= 0) return;
  if(abs(width - nativeFullscreenWidth) <= 2 && abs(height - nativeFullscreenHeight) <= 2) return;
  if(nativeFullscreenWidth < width || nativeFullscreenHeight < height) return;

  surface.setLocation(0, 0);
  surface.setSize(nativeFullscreenWidth, nativeFullscreenHeight);
  println(
    "Fullscreen ajustado para superficie fisica: " +
    nativeFullscreenWidth + "x" + nativeFullscreenHeight
  );
}

void loadActivityObservationSlides(){
  for(int activityIndex = 0; activityIndex < activityObservationSlideFiles.length; activityIndex++){
    for(int slideIndex = 0; slideIndex < activityObservationSlideFiles[activityIndex].length; slideIndex++){
      String fileName = activityObservationSlideFiles[activityIndex][slideIndex];
      try {
        activityObservationSlides[activityIndex][slideIndex] = loadImage(fileName);
        if(activityObservationSlides[activityIndex][slideIndex] == null){
          println("Imagem de observa\u00e7\u00e3o n\u00e3o encontrada: " + fileName);
        } else {
          println("Imagem de observa\u00e7\u00e3o carregada: " + fileName);
        }
      } catch(Exception e){
        activityObservationSlides[activityIndex][slideIndex] = null;
        println("Erro ao carregar imagem de observa\u00e7\u00e3o: " + fileName + " -> " + e.getMessage());
      }
    }
  }
}

void startActivityObservationSlides(int activityIndex){
  if(activityIndex < 0 || activityIndex >= activityObservationSlideStartedMillis.length) return;
  activityObservationSlideStartedMillis[activityIndex] = millis();
}

void resetActivityObservationSlides(int activityIndex){
  if(activityIndex < 0 || activityIndex >= activityObservationSlideStartedMillis.length) return;
  activityObservationSlideStartedMillis[activityIndex] = -1;
}

void resetAllActivityObservationSlides(){
  for(int i = 0; i < activityObservationSlideStartedMillis.length; i++){
    activityObservationSlideStartedMillis[i] = -1;
  }
}

int activityObservationSlideIndex(int activityIndex){
  if(activityIndex < 0 || activityIndex >= activityObservationSlideStartedMillis.length) return 0;
  if(activityObservationSlideStartedMillis[activityIndex] < 0) startActivityObservationSlides(activityIndex);

  int elapsed = millis() - activityObservationSlideStartedMillis[activityIndex];
  return constrain(elapsed / ACTIVITY_OBSERVATION_SLIDE_DURATION_MS, 0, ACTIVITY_OBSERVATION_SLIDE_COUNT - 1);
}

boolean activityObservationSlidesComplete(int activityIndex){
  if(activityIndex < 0 || activityIndex >= activityObservationSlideStartedMillis.length) return true;
  if(activityObservationSlideStartedMillis[activityIndex] < 0) startActivityObservationSlides(activityIndex);

  int elapsed = millis() - activityObservationSlideStartedMillis[activityIndex];
  return elapsed >= ACTIVITY_OBSERVATION_SLIDE_COUNT * ACTIVITY_OBSERVATION_SLIDE_DURATION_MS;
}

void startBHapticsBridge(){
  if(bhapticsStarting || bhapticsProcess != null) return;

  bhapticsStarting = true;
  bhapticsStatusIsFailure = false;
  bhapticsStatusMessage = "Tactosy esquerda a ligar";
  thread("startBHapticsBridgeThread");
}

void startBHapticsBridgeThread(){
  String bridgePath = sketchPath("bhaptics_bridge.py");
  File bridgeFile = new File(bridgePath);

  if(!bridgeFile.exists()){
    bhapticsStarting = false;
    bhapticsStatusIsFailure = true;
    bhapticsStatusMessage = "Ponte bHaptics nao encontrada";
    println("bHaptics: ficheiro nao encontrado: " + bridgePath);
    return;
  }

  String localAppData = System.getenv("LOCALAPPDATA");
  String python312 = localAppData == null ? "" :
    localAppData + "\\Programs\\Python\\Python312\\python.exe";
  String python313 = localAppData == null ? "" :
    localAppData + "\\Programs\\Python\\Python313\\python.exe";
  String python311 = localAppData == null ? "" :
    localAppData + "\\Programs\\Python\\Python311\\python.exe";
  String python310 = localAppData == null ? "" :
    localAppData + "\\Programs\\Python\\Python310\\python.exe";
  String configuredPython = configuredBHapticsPythonPath();

  String[][] commands = {
    {configuredPython, bridgePath},
    {python313, bridgePath},
    {python312, bridgePath},
    {python311, bridgePath},
    {python310, bridgePath},
    {"C:\\Program Files\\Python313\\python.exe", bridgePath},
    {"C:\\Program Files\\Python312\\python.exe", bridgePath},
    {"C:\\Program Files\\Python311\\python.exe", bridgePath},
    {"C:\\Program Files\\Python310\\python.exe", bridgePath},
    {"py", "-3.12", bridgePath},
    {"py", "-3.13", bridgePath},
    {"py", "-3.11", bridgePath},
    {"py", "-3.10", bridgePath},
    {"python", bridgePath},
    {"python3", bridgePath}
  };

  Exception lastError = null;
  String attemptedCommands = "";

  for(int i = 0; i < commands.length; i++){
    if(commands[i][0].length() == 0) continue;

    try {
      if(attemptedCommands.length() > 0) attemptedCommands += ", ";
      attemptedCommands += commands[i][0];

      ProcessBuilder builder = new ProcessBuilder(commands[i]);
      builder.directory(new File(sketchPath("")));
      builder.redirectErrorStream(true);

      bhapticsProcess = builder.start();
      bhapticsInput = new BufferedWriter(new OutputStreamWriter(bhapticsProcess.getOutputStream(), "UTF-8"));
      bhapticsOutput = new BufferedReader(new InputStreamReader(bhapticsProcess.getInputStream(), "UTF-8"));
      bhapticsProcessStartedMillis = millis();
      bhapticsLastStatusMillis = -1;

      String firstLine = waitForBHapticsBridgeFirstLine(bhapticsProcess, bhapticsOutput, 2500);
      if(firstLine != null){
        println("bHaptics > " + firstLine);
        if(bhapticsLineIndicatesMissingPython(firstLine)){
          lastError = new Exception(firstLine);
          try {
            bhapticsProcess.destroy();
          } catch(Exception ignored){}
          bhapticsProcess = null;
          bhapticsInput = null;
          bhapticsOutput = null;
          continue;
        }
        handleBHapticsBridgeLine(firstLine);
      }

      thread("readBHapticsBridgeOutput");
      println("bHaptics: ponte iniciada com " + commands[i][0]);
      return;
    } catch(Exception e){
      lastError = e;
      bhapticsProcess = null;
      bhapticsInput = null;
      bhapticsOutput = null;
    }
  }

  bhapticsStarting = false;
  bhapticsConnected = false;
  bhapticsBridgeReady = false;
  bhapticsStatusIsFailure = true;
  bhapticsStatusMessage = "Python com SDK bHaptics nao encontrado";
  println("bHaptics: nao foi possivel iniciar a ponte: " +
    (lastError == null ? "erro desconhecido" : lastError.getMessage()));
  println("bHaptics: comandos Python tentados: " +
    (attemptedCommands.length() == 0 ? "nenhum" : attemptedCommands));
}

String configuredBHapticsPythonPath(){
  try {
    JSONObject config = loadJSONObject(sketchPath("bhaptics-config.json"));
    if(config != null && config.hasKey("pythonPath")){
      String path = trim(config.getString("pythonPath", ""));
      if(path.length() > 0) return path;
    }
  } catch(Exception e){
    println("bHaptics: nao foi possivel ler pythonPath: " + e.getMessage());
  }

  return "";
}

String waitForBHapticsBridgeFirstLine(Process process, BufferedReader output, int timeoutMs){
  int started = millis();

  while(millis() - started < timeoutMs){
    try {
      if(output != null && output.ready()) return output.readLine();
      if(process != null && !process.isAlive()){
        if(output != null && output.ready()) return output.readLine();
        return null;
      }
      Thread.sleep(50);
    } catch(Exception e){
      println("bHaptics: erro ao aguardar resposta inicial: " + e.getMessage());
      return null;
    }
  }

  return null;
}

boolean bhapticsLineIndicatesMissingPython(String line){
  if(line == null) return false;

  String lowerLine = line.toLowerCase();
  return lowerLine.contains("python nao foi encontrado") ||
         lowerLine.contains("python nÃ£o foi encontrado") ||
         lowerLine.contains("python was not found") ||
         lowerLine.contains("microsoft store") ||
         lowerLine.contains("no suitable python runtime");
}

void readBHapticsBridgeOutput(){
  try {
    String line;
    while(bhapticsOutput != null && (line = bhapticsOutput.readLine()) != null){
      handleBHapticsBridgeLine(line);
    }
  } catch(Exception e){
    println("bHaptics: erro ao ler a ponte: " + e.getMessage());
  } finally {
    bhapticsConnected = false;
    bhapticsBridgeReady = false;
    bhapticsStarting = false;
    bhapticsProcess = null;
    bhapticsInput = null;
    bhapticsOutput = null;

    if(!bhapticsStatusIsFailure){
      bhapticsStatusMessage = "Ponte bHaptics desligada";
    }
  }
}

void handleBHapticsBridgeLine(String line){
  if(line == null || line.length() == 0) return;

  println("bHaptics > " + line);
  bhapticsLastStatusMillis = millis();

  String lowerLine = line.toLowerCase();
  if(lowerLine.contains("python nao foi encontrado") ||
     lowerLine.contains("python não foi encontrado") ||
     lowerLine.contains("python was not found") ||
     lowerLine.contains("microsoft store") ||
     lowerLine.contains("no suitable python runtime")){
    bhapticsConnected = false;
    bhapticsStarting = false;
    bhapticsBridgeReady = false;
    bhapticsStatusIsFailure = true;
    bhapticsStatusMessage = "Falta Python com SDK bHaptics";
    return;
  }

  if(line.startsWith("STATUS|")){
    String[] parts = split(line, '|');
    if(parts.length >= 3){
      String state = parts[1];
      String message = join(subset(parts, 2), " ");
      bhapticsStarting = state.equals("STARTING");
      if(state.equals("SDK_READY") || state.equals("READY")){
        bhapticsBridgeReady = true;
        bhapticsConnected = true;
        bhapticsStatusIsFailure = false;
        bhapticsStatusMessage = "bHaptics ligada";
      } else if(state.equals("COMMAND_ERROR")){
        bhapticsBridgeReady = true;
        bhapticsConnected = true;
        bhapticsStatusIsFailure = true;
        bhapticsStatusMessage = message;
      } else if(state.equals("WAITING")){
        bhapticsBridgeReady = true;
        bhapticsConnected = false;
        bhapticsStatusIsFailure = false;
        bhapticsStatusMessage = message;
      } else if(state.equals("STARTING") || state.equals("ERROR")){
        bhapticsBridgeReady = false;
        bhapticsConnected = false;
        bhapticsStatusIsFailure = state.equals("ERROR");
        bhapticsStatusMessage = message;
      } else {
        bhapticsStatusMessage = message;
      }
    }
    return;
  }

  // O SDK nativo escreve mensagens internas noutra codificacao.
  // Todos os estados relevantes da ponte chegam com o prefixo STATUS|.
}

void updateBHapticsBridgeHealth(){
  if(!bhapticsStarting) return;
  if(bhapticsProcessStartedMillis < 0) return;
  if(bhapticsLastStatusMillis >= 0) return;

  if(millis() - bhapticsProcessStartedMillis > 8000){
    bhapticsStarting = false;
    bhapticsBridgeReady = false;
    bhapticsConnected = false;
    bhapticsStatusIsFailure = true;
    bhapticsStatusMessage = "Ponte bHaptics sem resposta";
    println("bHaptics: processo Python iniciou mas nao enviou STATUS em 8s");
  }
}

void scheduleVideoLoading(){
  videosLoadingScheduled = true;
  videosLoadingStarted = false;
  videosLoadingScheduledMillis = millis();
  println("Preparacao dos videos agendada.");
}

void updateDeferredVideoLoading(){
  if(!videosLoadingScheduled || videosLoadingStarted) return;
  if(frameCount < 3) return;
  if(millis() - videosLoadingScheduledMillis < VIDEO_LOADING_START_DELAY_MS) return;

  startVideoLoading();
}

void startVideoLoading(){
  if(videosLoading || videosLoadingStarted) return;
  videosLoadingStarted = true;
  videosLoadingScheduled = false;
  videosLoading = true;
  videosLoaded = false;
  videosLoadedCount = 0;
  activity3VideosLoadedCount = 0;
  moviesPrepared = false;
  moviesPreparedCount = 0;
  activity3MoviesPrepared = false;
  activity3MoviesPreparedCount = 0;
  activity3FilesPrepared = false;
  resetVideoWarmupState();
  thread("loadVideosThread");
}

void loadVideosThread(){
  try {
    loadVideos();
  } finally {
    videosLoading = false;
    videosLoaded = true;
    println("Preparacao dos videos terminada.");
  }
}

boolean videosReady(){
  return videosLoaded && !videosLoading && activity3MoviesPrepared && moviesPrepared && allVideosWarmed();
}

void loadVideos(){
  File tempDir = new File(System.getProperty("java.io.tmpdir"), "UserInterfaceBHapticsVideos");
  if(!tempDir.exists()){
    tempDir.mkdirs();
  }

  println("Pasta temporaria dos videos: " + tempDir.getAbsolutePath());

  for(int i = 0; i < activity3Videos.length; i++){
    File source = new File(dataPath(activity3VideoFiles[i]));
    File target = new File(tempDir, "activity3-video" + i + ".mp4");

    if(!source.exists()){
      activity3HasVideo[i] = false;
      activity3VideosLoadedCount = i + 1;
      println("Video da Atividade 3 nao encontrado em data: " + activity3VideoFiles[i]);
      continue;
    }

    try {
      if(!target.exists() || target.length() != source.length() || target.lastModified() < source.lastModified()){
        Files.copy(source.toPath(), target.toPath(), StandardCopyOption.REPLACE_EXISTING);
      }

      activity3PreparedVideoPaths[i] = target.getAbsolutePath().replace('\\', '/');
      activity3Videos[i] = null;
      activity3HasVideo[i] = false;
      println("Video da Atividade 3 preparado: " + activity3ScenarioTitles[i]);
    } catch(Exception e){
      activity3HasVideo[i] = false;
      println("Erro ao preparar video da Atividade 3: " + activity3VideoFiles[i] + " -> " + e.getMessage());
    }
    activity3VideosLoadedCount = i + 1;
  }
  activity3FilesPrepared = true;

  for(int i = 0; i < videos.length; i++){
    File source = new File(dataPath(videoFiles[i]));
    File target = new File(tempDir, "video" + i + ".mp4");

    if(!source.exists()){
      hasVideo[i] = false;
      videosLoadedCount = i + 1;
      println("Video nao encontrado em data: " + videoFiles[i]);
      continue;
    }

    try {
      if(!target.exists() || target.length() != source.length() || target.lastModified() < source.lastModified()){
        Files.copy(source.toPath(), target.toPath(), StandardCopyOption.REPLACE_EXISTING);
      }

      String moviePath = target.getAbsolutePath().replace('\\', '/');
      preparedVideoPaths[i] = moviePath;
      videos[i] = null;
      hasVideo[i] = false;
      videosLoadedCount = i + 1;
      println("Video preparado: " + titles[i] + " -> " + moviePath);
    } catch(Exception e){
      hasVideo[i] = false;
      videosLoadedCount = i + 1;
      println("Erro ao preparar video: " + videoFiles[i] + " -> " + e.getMessage());
    }
  }
}

void prepareNextMovieOnMainThread(){
  if(activity3FilesPrepared && !activity3MoviesPrepared){
    prepareNextActivity3MovieOnMainThread();
    return;
  }

  if(!videosLoaded || videosLoading || moviesPrepared) return;

  if(moviesPreparedCount >= videos.length){
    moviesPrepared = true;
    println("Videos prontos para reproducao.");
    return;
  }

  int i = moviesPreparedCount;

  if(preparedVideoPaths[i] == null){
    hasVideo[i] = false;
    moviesPreparedCount++;
    return;
  }

  try {
    videos[i] = new Movie(this, preparedVideoPaths[i]);
    videos[i].volume(currentVideoAudioVolume());
    hasVideo[i] = true;
    videoFrameDecoded[i] = false;
    println("Movie criado: " + titles[i]);
    if((appState == 1 || appState == 2) && i == screen){
      playCurrentVideo();
    }
  } catch(Exception e){
    videos[i] = null;
    hasVideo[i] = false;
    println("Erro ao criar Movie: " + titles[i] + " -> " + e.getMessage());
  }

  moviesPreparedCount++;

  if(moviesPreparedCount >= videos.length){
    moviesPrepared = true;
    println("Videos prontos para reproducao.");
  }
}

void prepareNextActivity3MovieOnMainThread(){
  if(!activity3FilesPrepared) return;
  if(activity3MoviesPrepared) return;

  if(activity3MoviesPreparedCount >= activity3Videos.length){
    activity3MoviesPrepared = true;
    println("Videos da Atividade 3 prontos para reproducao.");
    return;
  }

  int i = activity3MoviesPreparedCount;

  if(activity3PreparedVideoPaths[i] != null){
    try {
      activity3Videos[i] = new Movie(this, activity3PreparedVideoPaths[i]);
      activity3Videos[i].volume(currentVideoAudioVolume());
      activity3HasVideo[i] = true;
      activity3VideoFrameDecoded[i] = false;
      println("Movie da Atividade 3 criado: " + activity3ScenarioTitles[i]);
      if(appState == 6 && activity3Step == 0 && i == activity3VideoIndex){
        playCurrentActivity3Video();
      }
    } catch(Exception e){
      activity3Videos[i] = null;
      activity3HasVideo[i] = false;
      println("Erro ao criar Movie da Atividade 3: " + activity3ScenarioTitles[i] + " -> " + e.getMessage());
    }
  }

  activity3MoviesPreparedCount++;
  if(activity3MoviesPreparedCount >= activity3Videos.length){
    activity3MoviesPrepared = true;
    println("Videos da Atividade 3 prontos para reproducao.");
  }
}

void resetVideoWarmupState(){
  for(int i = 0; i < videoWarmed.length; i++){
    videoWarmed[i] = false;
    videoFrameDecoded[i] = false;
  }

  for(int i = 0; i < activity3VideoWarmed.length; i++){
    activity3VideoWarmed[i] = false;
    activity3VideoFrameDecoded[i] = false;
  }

  activity3VideoWarmupIndex = 0;
  videoWarmupIndex = 0;
  videoWarmupStartedMillis = -1;
}

boolean allVideosWarmed(){
  return activity3VideoWarmupIndex >= activity3Videos.length &&
         videoWarmupIndex >= videos.length;
}

int totalVideoWarmupCount(){
  return activity3Videos.length + videos.length;
}

int completedVideoWarmupCount(){
  int count = 0;

  for(int i = 0; i < activity3VideoWarmed.length; i++){
    if(activity3VideoWarmed[i]) count++;
  }

  for(int i = 0; i < videoWarmed.length; i++){
    if(videoWarmed[i]) count++;
  }

  return count;
}

void updateVideoWarmup(){
  if(!videosLoadingStarted) return;
  if(appState != APP_STATE_LOADING && appState != 0) return;

  if(activity3MoviesPrepared && activity3VideoWarmupIndex < activity3Videos.length){
    warmNextActivity3Video();
    return;
  }

  if(moviesPrepared && videoWarmupIndex < videos.length){
    warmNextActivity4Video();
  }
}

void warmNextActivity3Video(){
  int i = activity3VideoWarmupIndex;

  if(activity3VideoWarmed[i]){
    activity3VideoWarmupIndex++;
    videoWarmupStartedMillis = -1;
    return;
  }

  if(!activity3HasVideo[i] || activity3Videos[i] == null){
    activity3VideoWarmed[i] = true;
    activity3VideoWarmupIndex++;
    videoWarmupStartedMillis = -1;
    return;
  }

  if(warmMovieForStartup(activity3Videos[i], "Atividade 3 - " + activity3ScenarioTitles[i])){
    activity3VideoWarmed[i] = true;
    activity3VideoWarmupIndex++;
  }
}

void warmNextActivity4Video(){
  int i = videoWarmupIndex;

  if(videoWarmed[i]){
    videoWarmupIndex++;
    videoWarmupStartedMillis = -1;
    return;
  }

  if(!hasVideo[i] || videos[i] == null){
    videoWarmed[i] = true;
    videoWarmupIndex++;
    videoWarmupStartedMillis = -1;
    return;
  }

  if(warmMovieForStartup(videos[i], "Atividade 4 - " + titles[i])){
    videoWarmed[i] = true;
    videoWarmupIndex++;
  }
}

boolean warmMovieForStartup(Movie video, String label){
  if(video == null) return true;

  if(videoWarmupStartedMillis < 0){
    videoWarmupStartedMillis = millis();
    try {
      video.volume(VIDEO_MUTED_VOLUME);
      video.play();
      video.jump(0);
      video.volume(VIDEO_MUTED_VOLUME);
      println("A aquecer video: " + label);
    } catch(Exception e){
      println("Erro ao iniciar aquecimento do video: " + label + " -> " + e.getMessage());
      videoWarmupStartedMillis = -1;
      return true;
    }
  }

  int elapsed = millis() - videoWarmupStartedMillis;
  boolean hasFrame = movieFrameDecoded(video);
  boolean warmed = hasFrame && elapsed >= VIDEO_WARMUP_MIN_MS;
  boolean timedOut = elapsed >= VIDEO_WARMUP_TIMEOUT_MS;

  if(!warmed && !timedOut) return false;

  try {
    video.pause();
    video.volume(currentVideoAudioVolume());
  } catch(Exception ignored){}

  if(timedOut && !hasFrame){
    println("Aquecimento do video excedeu o tempo: " + label);
  } else {
    println("Video aquecido: " + label);
  }

  videoWarmupStartedMillis = -1;
  return true;
}

boolean sendHandVibration(int pointMask, int durationMs){
  return sendHandVibration(pointMask, durationMs, VIB_HIGH);
}

boolean sendHandVibration(int pointMask, int durationMs, int intensity){
  if(unisensoryMode){
    println("bHaptics: vibracao ignorada, condicao unissensorial ativa");
    return false;
  }

  pointMask = constrain(pointMask, 0, 7);
  durationMs = constrain(durationMs, 100, 5000);
  intensity = constrain(intensity, 0, 100);
  registerVibrationOverlay(pointMask, durationMs, intensity);

  if(!bhapticsBridgeReady || bhapticsInput == null){
    println("bHaptics: vibracao ignorada, ponte ainda indisponivel");
    return false;
  }

  int point1 = (pointMask & 1) != 0 ? intensity : 0;
  int point2 = (pointMask & 2) != 0 ? intensity : 0;
  int point3 = (pointMask & 4) != 0 ? intensity : 0;
  String command = "V|" + durationMs + "|" + point1 + "|" + point2 + "|" + point3;

  if(!sendBHapticsCommand(command)) return false;

  println(
    "bHaptics <- Tactosy esquerda " + durationMs + "ms pontos=[" +
    point1 + "," + point2 + "," + point3 + "]"
  );
  return true;
}

boolean sendBHapticsCommand(String command){
  if(bhapticsInput == null) return false;

  synchronized(bhapticsWriteLock){
    try {
      bhapticsInput.write(command);
      bhapticsInput.newLine();
      bhapticsInput.flush();
      return true;
    } catch(Exception e){
      bhapticsConnected = false;
      bhapticsBridgeReady = false;
      bhapticsStatusMessage = "Erro na ponte bHaptics";
      println("bHaptics: erro ao enviar comando: " + e.getMessage());
      return false;
    }
  }
}

void stopBHapticsVibration(){
  sendBHapticsCommand("S");
}

void startHapticTuningPreview(){
  if(unisensoryMode) return;

  hapticTunePreviewActive = true;
  hapticTunePreviewUntilMillis = millis() + HAPTIC_TUNE_PREVIEW_HOLD_MS;
  hapticTuneLastPulseMillis = -1;
}

void stopHapticTuningPreview(){
  hapticTunePreviewActive = false;
  hapticTunePreviewUntilMillis = -1;
  hapticTuneLastPulseMillis = -1;
  stopBHapticsVibration();
}

void updateHapticTuningPreview(){
  if(!hapticTunePreviewActive) return;

  if(!hapticTuningContextActive() || unisensoryMode){
    stopHapticTuningPreview();
    return;
  }

  int now = millis();
  if(now > hapticTunePreviewUntilMillis){
    stopHapticTuningPreview();
    return;
  }

  int intervalMs = max(120, round(1000.0f / hapticTuneFrequencyHz));
  if(hapticTuneLastPulseMillis < 0 || now - hapticTuneLastPulseMillis >= intervalMs){
    int pulseDurationMs = constrain(round(intervalMs * 0.46f), 70, 320);
    sendHandVibration(7, pulseDurationMs, hapticTuneAmplitude);
    hapticTuneLastPulseMillis = now;
  }
}

void setHapticTuneAmplitudeFromMouse(float mx){
  float norm = constrain((mx - homeHapticAmpX) / homeHapticAmpW, 0, 1);
  int value = round(HAPTIC_TUNE_MIN_AMPLITUDE + norm * (HAPTIC_TUNE_MAX_AMPLITUDE - HAPTIC_TUNE_MIN_AMPLITUDE));
  hapticTuneAmplitude = constrain(round(value / 5.0f) * 5, HAPTIC_TUNE_MIN_AMPLITUDE, HAPTIC_TUNE_MAX_AMPLITUDE);
  startHapticTuningPreview();
}

void setHapticTuneFrequencyFromMouse(float mx){
  float norm = constrain((mx - homeHapticFreqX) / homeHapticFreqW, 0, 1);
  float value = HAPTIC_TUNE_MIN_FREQUENCY + norm * (HAPTIC_TUNE_MAX_FREQUENCY - HAPTIC_TUNE_MIN_FREQUENCY);
  hapticTuneFrequencyHz = constrain(round(value * 2.0f) / 2.0f, HAPTIC_TUNE_MIN_FREQUENCY, HAPTIC_TUNE_MAX_FREQUENCY);
  startHapticTuningPreview();
}

boolean observationHapticTuningVisible(){
  return (appState == 1 && phase == 1) ||
         (appState == 3 && activity1Step == 0) ||
         (appState == 5 && activity2Step == 0) ||
         (appState == 6 && activity3Step == 0);
}

boolean hapticTuningContextActive(){
  return observationHapticTuningVisible();
}

boolean handleHapticTuningControlsMouse(float mx, float my){
  if(!hapticTuningContextActive()) return false;

  if(observationHapticTuningVisible() &&
     inside(mx, my, hapticTuneRepeatX, hapticTuneRepeatY, hapticTuneRepeatW, hapticTuneRepeatH)){
    repeatCurrentObservation();
    return true;
  }

  if(inside(mx, my, homeHapticAmpX, homeHapticAmpY, homeHapticAmpW, homeHapticAmpH)){
    if(!unisensoryMode){
      homeHapticAmpDragging = true;
      setHapticTuneAmplitudeFromMouse(mx);
    }
    return true;
  }

  if(inside(mx, my, homeHapticFreqX, homeHapticFreqY, homeHapticFreqW, homeHapticFreqH)){
    if(!unisensoryMode){
      homeHapticFreqDragging = true;
      setHapticTuneFrequencyFromMouse(mx);
    }
    return true;
  }

  return false;
}

boolean handleHomeOptionsMouse(float mx, float my){
  if(appState != 0) return false;

  if(inside(mx, my, homeOptionsX, homeOptionsY, homeOptionsW, homeOptionsH)){
    homeOptionsOverlayOpen = !homeOptionsOverlayOpen;
    return true;
  }

  if(!homeOptionsOverlayOpen) return false;

  if(inside(mx, my, homeShuffleX, homeShuffleY, homeShuffleW, homeShuffleH)){
    toggleBehaviorShuffle();
    return true;
  }

  if(inside(mx, my, homeResearchX, homeResearchY, homeResearchW, homeResearchH)){
    homeOptionsOverlayOpen = false;
    toggleResearchLogging();
    return true;
  }

  if(inside(mx, my, homeDesignerX, homeDesignerY, homeDesignerW, homeDesignerH)){
    toggleDesignerActivitiesVisibility();
    return true;
  }

  homeOptionsOverlayOpen = false;
  return true;
}

void repeatCurrentObservation(){
  stopHapticTuningPreview();
  stopBHapticsVibration();

  if(appState == 1 && phase == 1){
    guidedVideoFinishedMillis = -1;
    currentVideoEndFrozen = false;
    videoEndFreezePauseMillis = -1;
    playCurrentVideo();
    logResearchEvent("observation_repeat", "activity4", "observation", screen, "behavior=" + titles[screen]);
    return;
  }

  if(appState == 3 && activity1Step == 0){
    activity1ObservationFinishedMillis = -1;
    startActivityObservationSlides(0);
    logResearchEvent("observation_repeat", "activity1", "observation", -1, "slideshow=true");
    return;
  }

  if(appState == 5 && activity2Step == 0){
    activity2ObservationFinishedMillis = -1;
    startActivityObservationSlides(1);
    logResearchEvent("observation_repeat", "activity2", "observation", -1, "slideshow=true");
    return;
  }

  if(appState == 6 && activity3Step == 0){
    activity3ObservationFinishedMillis = -1;
    activity3VideoStarted = false;
    playCurrentActivity3Video();
    logResearchEvent("observation_repeat", "activity3", "observation", activity3CurrentScenarioIndex(), activity3ScenarioResearchDetails());
  }
}

void closeBHapticsBridge(){
  if(bhapticsClosing) return;
  bhapticsClosing = true;

  Process processToClose = bhapticsProcess;

  bhapticsConnected = false;
  bhapticsBridgeReady = false;
  bhapticsStarting = false;
  bhapticsProcess = null;
  bhapticsInput = null;
  bhapticsOutput = null;

  try {
    if(processToClose != null) processToClose.destroy();
  } catch(Exception ignored){}
}

void dispose(){
  closeBHapticsBridge();
}

void movieEvent(Movie m){
  m.read();
  markMovieFrameDecoded(m);
}

void markMovieFrameDecoded(Movie movie){
  if(movie == null) return;

  for(int i = 0; i < videos.length; i++){
    if(videos[i] == movie){
      videoFrameDecoded[i] = true;
      return;
    }
  }

  for(int i = 0; i < activity3Videos.length; i++){
    if(activity3Videos[i] == movie){
      activity3VideoFrameDecoded[i] = true;
      return;
    }
  }
}

boolean movieFrameDecoded(Movie movie){
  if(movie == null) return false;

  for(int i = 0; i < videos.length; i++){
    if(videos[i] == movie) return videoFrameDecoded[i];
  }

  for(int i = 0; i < activity3Videos.length; i++){
    if(activity3Videos[i] == movie) return activity3VideoFrameDecoded[i];
  }

  return false;
}

float currentVideoAudioVolume(){
  return unisensoryMode ? VIDEO_MUTED_VOLUME : VIDEO_AUDIO_VOLUME;
}

void applyVideoAudioMode(){
  for(int i = 0; i < videos.length; i++){
    if(videos[i] == null) continue;

    try {
      videos[i].volume(currentVideoAudioVolume());
    } catch(Exception ignored){}
  }

  for(int i = 0; i < activity3Videos.length; i++){
    if(activity3Videos[i] == null) continue;

    try {
      activity3Videos[i].volume(currentVideoAudioVolume());
    } catch(Exception ignored){}
  }

  for(int scenario = 0; scenario < activity3GrowlSounds.length; scenario++){
    for(int i = 0; i < activity3GrowlSounds[scenario].length; i++){
      if(activity3GrowlSounds[scenario][i] == null) continue;

      try {
        activity3GrowlSounds[scenario][i].volume(currentVideoAudioVolume());
      } catch(Exception ignored){}
    }
  }
}

void resetOrder(int[] order){
  for(int i = 0; i < order.length; i++){
    order[i] = i;
  }
}

void shuffleOrder(int[] order){
  for(int i = order.length - 1; i > 0; i--){
    int j = floor(random(i + 1));
    int temp = order[i];
    order[i] = order[j];
    order[j] = temp;
  }
}

void prepareBehaviorOrder(){
  resetOrder(behaviorOrder);
  if(shuffleBehaviorsEnabled) shuffleOrder(behaviorOrder);
  behaviorSequencePosition = 0;
}

void prepareActivity3Order(){
  resetOrder(activity3Order);
  if(shuffleBehaviorsEnabled) shuffleOrder(activity3Order);
  activity3SequencePosition = 0;
}

void resetPresentationOrders(){
  resetOrder(behaviorOrder);
  resetOrder(activity3Order);
  behaviorSequencePosition = 0;
  activity3SequencePosition = 0;
}

boolean onLastBehaviorStep(){
  return behaviorSequencePosition >= titles.length - 1;
}

boolean onLastActivity3Step(){
  return activity3SequencePosition >= ACTIVITY3_VIDEO_COUNT - 1;
}

void toggleBehaviorShuffle(){
  shuffleBehaviorsEnabled = !shuffleBehaviorsEnabled;
  resetPresentationOrders();
  logResearchEvent("shuffle_toggle", "menu", "options", -1, "enabled=" + shuffleBehaviorsEnabled);
  println("Shuffle de comportamentos: " + (shuffleBehaviorsEnabled ? "ligado" : "desligado"));
}

void toggleDesignerActivitiesVisibility(){
  designerActivitiesVisible = !designerActivitiesVisible;
  ensureHomeSelectionVisible();
  logResearchEvent("designer_activities_toggle", "menu", "options", -1, "visible=" + designerActivitiesVisible);
  println("Atividades 1 e 2 no menu: " + (designerActivitiesVisible ? "visiveis" : "ocultas"));
}

void toggleResearchLogging(){
  if(researchLoggingEnabled){
    logResearchEvent("research_logging_stop", "menu", "options", -1, "manual_toggle=true");
    closeResearchLog();
    researchLoggingEnabled = false;
    println("Recolha de dados: desligada");
    return;
  }

  researchParticipantPromptActive = true;
  researchParticipantDraft = "";
  researchParticipantPromptError = "";
  println("Recolha de dados: introduzir participant_id para iniciar");
}

void confirmResearchParticipantPrompt(){
  String participantId = researchParticipantDraft.trim();
  if(participantId.length() == 0){
    researchParticipantPromptError = "Introduz um participant_id para iniciar.";
    return;
  }

  if(startResearchLog(participantId)){
    researchParticipantPromptActive = false;
    researchParticipantPromptError = "";
    println("Recolha de dados: ligada para " + researchParticipantId);
  } else {
    researchParticipantPromptActive = true;
    println("Recolha de dados: falhou ao iniciar");
  }
}

void cancelResearchParticipantPrompt(){
  researchParticipantPromptActive = false;
  researchParticipantDraft = "";
  researchParticipantPromptError = "";
  println("Recolha de dados: cancelada");
}

boolean startResearchLog(String participantId){
  try {
    File logDir = new File(dataPath("research_logs"));
    if(!logDir.exists() && !logDir.mkdirs()){
      throw new IOException("Nao foi possivel criar a pasta research_logs.");
    }

    researchSessionId = "session_" + researchTimestampForFile();
    researchParticipantId = participantId.trim();
    researchSessionStartedMillis = millis();
    File logFile = new File(logDir, RESEARCH_DATA_FILE);
    boolean writeHeader = !logFile.exists() || logFile.length() == 0;
    researchLogWriter = new PrintWriter(new BufferedWriter(new OutputStreamWriter(new FileOutputStream(logFile, true), "UTF-8")));
    if(writeHeader){
      researchLogWriter.print("\ufeff");
      researchLogWriter.println(RESEARCH_DATA_HEADER);
    }

    researchLoggingEnabled = true;
    logResearchEvent("research_logging_start", "menu", "options", -1, "file=" + logFile.getAbsolutePath() + ";session=" + researchSessionId);
    return true;
  } catch(Exception e){
    researchLogWriter = null;
    researchLoggingEnabled = false;
    researchSessionId = "";
    researchParticipantId = "";
    researchSessionStartedMillis = -1;
    researchParticipantPromptError = "Nao foi possivel iniciar. Fecha o CSV no Excel e tenta novamente.";
    println("Erro ao iniciar recolha de dados: " + e.getMessage());
    return false;
  }
}

void closeResearchLog(){
  if(researchLogWriter != null){
    researchLogWriter.flush();
    researchLogWriter.close();
    researchLogWriter = null;
  }

  researchSessionId = "";
  researchParticipantId = "";
  researchSessionStartedMillis = -1;
}

void logResearchEvent(String event, String activity, String step, int scenarioIndex, String details){
  if(!researchLoggingEnabled || researchLogWriter == null) return;

  int elapsed = researchSessionStartedMillis >= 0 ? millis() - researchSessionStartedMillis : 0;
  String condition = unisensoryMode ? "unisensorial" : "multissensorial";
  String[] row = {
    "event",
    researchTimestamp(),
    researchParticipantId,
    researchSessionId,
    str(elapsed),
    str(appState),
    condition,
    str(shuffleBehaviorsEnabled),
    event,
    activity,
    step,
    str(scenarioIndex),
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    details
  };
  writeResearchDataRow(row);
}

void logStructuredResearchResponse(
  String activityId,
  String activityName,
  String itemId,
  String itemOrder,
  String markOrder,
  String stimulusId,
  String stimulusCategory,
  String responseStage,
  String selectedAnswer,
  String selectedCategory,
  String selectedOptionRole,
  String wrongSelectedAnswer,
  String correctAnswer,
  String correctCategory,
  String isCorrect,
  String errorType,
  String selectedOptionDistance,
  String closestWrongAnswer,
  String availableOptions,
  String selectedCues,
  String availableCues,
  String correctCues,
  String initialAnswer,
  String finalAnswer,
  String answerChanges,
  String stimulusReplayCount,
  String confidence,
  String answerBeforeFeedback,
  String answerAfterFeedback,
  String changedAfterFeedback,
  String correctBeforeFeedback,
  String correctAfterFeedback,
  String responseDistance,
  String responseSimilarity,
  String confusionType,
  String details
){
  if(!researchLoggingEnabled || researchLogWriter == null) return;

  int elapsed = researchSessionStartedMillis >= 0 ? millis() - researchSessionStartedMillis : 0;
  String condition = unisensoryMode ? "unisensorial" : "multissensorial";
  String[] row = {
    "response",
    researchTimestamp(),
    researchParticipantId,
    researchSessionId,
    str(elapsed),
    str(appState),
    condition,
    str(shuffleBehaviorsEnabled),
    "",
    activityId,
    responseStage,
    "",
    activityId,
    activityName,
    itemId,
    itemOrder,
    markOrder,
    stimulusId,
    stimulusCategory,
    responseStage,
    selectedAnswer,
    selectedCategory,
    selectedOptionRole,
    wrongSelectedAnswer,
    correctAnswer,
    correctCategory,
    isCorrect,
    errorType,
    selectedOptionDistance,
    closestWrongAnswer,
    availableOptions,
    selectedCues,
    availableCues,
    correctCues,
    initialAnswer,
    finalAnswer,
    answerChanges,
    stimulusReplayCount,
    answerBeforeFeedback,
    answerAfterFeedback,
    changedAfterFeedback,
    correctBeforeFeedback,
    correctAfterFeedback,
    responseDistance,
    responseSimilarity,
    confusionType,
    details
  };

  writeResearchDataRow(row);
}

void writeResearchDataRow(String[] row){
  if(!researchLoggingEnabled || researchLogWriter == null) return;

  for(int i = 0; i < row.length; i++){
    if(i > 0) researchLogWriter.print(RESEARCH_CSV_SEPARATOR);
    researchLogWriter.print(csvField(row[i]));
  }
  researchLogWriter.println();
  researchLogWriter.flush();
}

String csvField(String value){
  if(value == null) value = "";
  return "\"" + value.replace("\"", "\"\"").replace("\n", " ").replace("\r", " ") + "\"";
}

String researchTimestamp(){
  return nf(year(), 4) + "-" + nf(month(), 2) + "-" + nf(day(), 2) + " " +
         nf(hour(), 2) + ":" + nf(minute(), 2) + ":" + nf(second(), 2);
}

String researchTimestampForFile(){
  return nf(year(), 4) + nf(month(), 2) + nf(day(), 2) + "_" +
         nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2);
}

void draw(){
  stabilizeFullscreenSurface();
  background(bg);

  scaleFactor = min(width / baseW, height / baseH);

  pushMatrix();
  translate(
    (width  - baseW * scaleFactor) / 2,
    (height - baseH * scaleFactor) / 2
  );
  scale(scaleFactor);

  drawAppBackdrop();

  updateLayout();
  ensureCurrentVideoStarted();
  ensureCurrentActivity3VideoStarted();
  updateInterpretationVideoSeek();
  updateVideoEndFreezePause();
  updateVibrationTimeline();
  updateActivity3VibrationTimeline();
  updateFeedbackVideoLoop();
  updateGuidedAutoAdvance();
  updateIsolatedAutoAdvance();
  updateActivity1ObservationAutoAdvance();
  updateActivity2ObservationAutoAdvance();
  updateActivity3ObservationAutoAdvance();
  updateStartupLoadingScreen();
  updateBHapticsBridgeHealth();
  updateHapticTuningPreview();

  if(appState == APP_STATE_LOADING) drawStartupLoadingScreen();
  else if(appState == 0) drawHomeScreen();
  else if(appState == 1) drawGuidedScreen();
  else if(appState == 2) drawIsolatedReviewScreen();
  else if(appState == 3) drawActivity1Prototype();
  else if(appState == 4) drawActivityPlaceholder();
  else if(appState == 5) drawActivity2Prototype();
  else if(appState == 6) drawActivity3Prototype();

  drawVibrationOverlay();
  drawBHapticsStatus();
  drawResearchParticipantPrompt();

  updateDeferredVideoLoading();

  if(frameCount > MOVIE_PREPARATION_DELAY_FRAMES){
    prepareNextMovieOnMainThread();
    updateVideoWarmup();
  }

  popMatrix();
}

void drawAppBackdrop(){
  noStroke();
  fill(bg);
  rect(0, 0, baseW, baseH);

  stroke(color(80, 100, 145, 10));
  strokeWeight(1);
  for(float x = 80; x < baseW; x += 96){
    line(x, 0, x, baseH);
  }
  for(float y = 176; y < baseH; y += 96){
    line(0, y, baseW, y);
  }
  noStroke();
}


void drawBHapticsStatus(){
  if(unisensoryMode) return;
  if(appState != APP_STATE_LOADING && appState != 0) return;

  noStroke();
  color statusColor = bhapticsConnected ? color(0, 200, 100) :
                      (bhapticsStarting ? color(230, 170, 40) : color(200, 60, 60));
  fill(statusColor);
  ellipse(18, baseH - 18, 8, 8);

  fill(muted);
  textAlign(LEFT, CENTER);
  textSize(TYPE_BODY);
  text(bhapticsStatusMessage, 26, baseH - 18);
}

void registerVibrationOverlay(int pointMask, int durationMs, int intensity){
  if(!vibrationOverlayEnabled) return;
  if(pointMask <= 0 || intensity <= 0 || durationMs <= 0) return;

  int now = millis();
  vibrationOverlayStartedMillis = now;
  vibrationOverlayUntilMillis = max(vibrationOverlayUntilMillis, now + max(durationMs, VIBRATION_OVERLAY_MIN_VISIBLE_MS));
  vibrationOverlayPointMask = pointMask;
  vibrationOverlayIntensity = intensity;
  vibrationOverlayDurationMs = durationMs;
}

void prepareVibrationOverlay(){
  ensureVibrationOverlayPosition();
  vibrationOverlayUntilMillis = -1;
  vibrationOverlayPointMask = 7;
  vibrationOverlayIntensity = VIB_LOW;
  vibrationOverlayDurationMs = 0;
}

void drawVibrationOverlay(){
  if(!vibrationOverlayEnabled) return;
  ensureVibrationOverlayPosition();

  int now = millis();
  boolean active = vibrationOverlayUntilMillis >= 0 && now <= vibrationOverlayUntilMillis;
  float cx = vibrationOverlayX;
  float cy = vibrationOverlayY;
  float alpha = active ? 255 : 150;
  float pulse = active
    ? 0.5 + 0.5 * sin((now - vibrationOverlayStartedMillis) * 0.020)
    : 0;

  pushStyle();
  noStroke();
  fill(cardAlt, vibrationOverlayDragging ? 245 : 220);
  rect(cx - 34, cy - 34, 68, 68, 14);

  stroke(active ? purpleText : strokeC, active ? 190 : 160);
  strokeWeight(active ? 1.6 : 1.2);
  noFill();
  rect(cx - 34, cy - 34, 68, 68, 14);
  noStroke();

  fill(active ? purpleDim : greyDark, active ? 235 : 210);
  ellipse(cx, cy, 42 + pulse * 4, 42 + pulse * 4);

  stroke(active ? purpleText : muted, alpha);
  strokeWeight(active ? 2.3 : 1.8);
  strokeCap(ROUND);
  noFill();
  if(active){
    arc(cx - 2, cy, 22, 22, -HALF_PI, HALF_PI);
    arc(cx + 2, cy, 22, 22, HALF_PI, PI + HALF_PI);
    stroke(purpleText, alpha * (0.55 + pulse * 0.35));
    arc(cx - 2, cy, 34, 34, -HALF_PI, HALF_PI);
    arc(cx + 2, cy, 34, 34, HALF_PI, PI + HALF_PI);
  } else {
    line(cx - 13, cy, cx + 13, cy);
    line(cx, cy - 13, cx, cy + 13);
  }

  noStroke();
  fill(white, active ? alpha : 185);
  ellipse(cx, cy, 8, 8);

  fill(white, active ? alpha * 0.72 : 130);
  float dotY = cy + 20;
  if((vibrationOverlayPointMask & 1) != 0) ellipse(cx - 10, dotY, 4, 4);
  if((vibrationOverlayPointMask & 2) != 0) ellipse(cx, dotY, 4, 4);
  if((vibrationOverlayPointMask & 4) != 0) ellipse(cx + 10, dotY, 4, 4);
  popStyle();
}

void ensureVibrationOverlayPosition(){
  if(vibrationOverlayX < 0 || vibrationOverlayY < 0){
    vibrationOverlayX = baseW - margin - 72;
    vibrationOverlayY = 126;
  }
  vibrationOverlayX = constrain(vibrationOverlayX, vibrationOverlaySize / 2 + 8, baseW - vibrationOverlaySize / 2 - 8);
  vibrationOverlayY = constrain(vibrationOverlayY, vibrationOverlaySize / 2 + 8, baseH - vibrationOverlaySize / 2 - 8);
}

boolean insideVibrationOverlay(float mx, float my){
  if(!vibrationOverlayEnabled) return false;
  ensureVibrationOverlayPosition();
  return inside(
    mx, my,
    vibrationOverlayX - vibrationOverlaySize / 2,
    vibrationOverlayY - vibrationOverlaySize / 2,
    vibrationOverlaySize,
    vibrationOverlaySize
  );
}

void updateLayout(){
  margin = 64;
  gutter = 24;

  contentTop = 80;
  float bottomAreaH = 110;
  float bottomGap = 20;
  contentBottom = baseH - margin - bottomAreaH - bottomGap;

  leftW  = (baseW - margin * 2 - gutter) * 0.70;
  rightW = (baseW - margin * 2 - gutter) * 0.30;

  v1w = baseW * 0.65;
  v1h = baseH * 0.60;
  v1x = (baseW - v1w) / 2;
  v1y = 120;

  v2x = margin;
  v2y = contentTop;
  v2w = leftW;
  v2h = contentBottom - contentTop;
}

void drawHomeScreen(){
  float leftX = 76;
  float titleY = 128;
  float buttonX = leftX;
  float buttonY = 300;
  float buttonW = 280;
  float buttonH = 62;
  float buttonGap = 12;

  ensureHomeSelectionVisible();

  int visibleSlot = 0;
  for(int i = 0; i < HOME_OPTION_COUNT; i++){
    if(homeOptionVisible(i)){
      homeOptionX[i] = buttonX;
      homeOptionY[i] = buttonY + visibleSlot * (buttonH + buttonGap);
      homeOptionW[i] = buttonW;
      homeOptionH[i] = buttonH;
      visibleSlot++;
    } else {
      homeOptionX[i] = -1000;
      homeOptionY[i] = -1000;
      homeOptionW[i] = 0;
      homeOptionH[i] = 0;
    }
  }

  homeStartX = homeOptionX[3];
  homeStartY = homeOptionY[3];
  homeStartW = homeOptionW[3];
  homeStartH = homeOptionH[3];

  homeReviewX = -1;
  homeReviewY = -1;
  homeReviewW = 0;
  homeReviewH = 0;

  homeExitX = homeOptionX[4];
  homeExitY = homeOptionY[4];
  homeExitW = homeOptionW[4];
  homeExitH = homeOptionH[4];

  homeOptionsW = 164;
  homeOptionsH = 40;
  homeOptionsX = baseW - 76 - homeOptionsW;
  homeOptionsY = 28;

  fill(white);
  textAlign(LEFT, TOP);
  textSize(TYPE_HERO);
  text("Para Além da\nLinguagem Humana", leftX, titleY);

  fill(purpleText);
  textSize(TYPE_SECTION);
  text("Aprender a interpretar a comunicação canídea", leftX, titleY + 124);

  int homeHoverIndex = getHomeHoverIndex();

  for(int i = 0; i < HOME_OPTION_COUNT; i++){
    if(!homeOptionVisible(i)) continue;
    int iconType = i < 4 ? 10 + i + 1 : 2;
    drawHomeOption(
      homeOptionX[i], homeOptionY[i], homeOptionW[i], homeOptionH[i],
      homeActivityLabels[i], iconType, homeHoverIndex == i
    );
  }
  drawActivityAboutCard();
  drawHomeDesignerSignature();

  if(!videosReady()){
    fill(muted);
    textAlign(LEFT, CENTER);
    textSize(TYPE_LABEL);
    String loadingText;
    if(videosLoadingScheduled && !videosLoadingStarted){
      loadingText = "A preparar interface";
    } else if(videosLoaded && (!activity3MoviesPrepared || !moviesPrepared)){
      int preparedMovies = activity3MoviesPreparedCount + moviesPreparedCount;
      int totalMovies = activity3Videos.length + videos.length;
      loadingText = "A preparar reprodução dos vídeos " + preparedMovies + " / " + totalMovies;
    } else {
      int totalFiles = activity3Videos.length + videos.length;
      int preparedFiles = activity3VideosLoadedCount + videosLoadedCount;
      loadingText = "A preparar vídeos " + preparedFiles + " / " + totalFiles;
    }
    text(loadingText, leftX, baseH - 32);
  }

  drawHomeOptionsOverlay();
  drawHomeOptionsButton();
}

void drawHomeDesignerSignature(){
  fill(muted);
  textAlign(RIGHT, CENTER);
  textSize(TYPE_CAPTION);
  text("\u00a9 2026 Jo\u00e3o Lopes. Todos os direitos reservados.", baseW - 76, baseH - 32);
}

boolean homeOptionVisible(int index){
  if(index == 0 || index == 1) return designerActivitiesVisible;
  return true;
}

void ensureHomeSelectionVisible(){
  if(homeOptionVisible(homeSelectedOption)) return;

  for(int i = 0; i < HOME_OPTION_COUNT; i++){
    if(homeOptionVisible(i)){
      homeSelectedOption = i;
      return;
    }
  }
}

void drawHomeOptionsButton(){
  boolean hovered = inside(mouseXToInterface(), mouseYToInterface(), homeOptionsX, homeOptionsY, homeOptionsW, homeOptionsH);
  boolean active = homeOptionsOverlayOpen;

  noStroke();
  fill(hovered || active ? card : cardAlt);
  rect(homeOptionsX, homeOptionsY, homeOptionsW, homeOptionsH, 8);

  stroke(active ? purpleDim : strokeC);
  strokeWeight(active ? 1.3 : 1.0);
  noFill();
  rect(homeOptionsX, homeOptionsY, homeOptionsW, homeOptionsH, 8);
  noStroke();

  color fg = active ? purpleText : muted;
  drawOptionsIcon(homeOptionsX + 28, homeOptionsY + homeOptionsH / 2, 22, fg);

  fill(active ? white : muted);
  textAlign(LEFT, CENTER);
  textSize(TYPE_CAPTION);
  text("Opções", homeOptionsX + 52, homeOptionsY + homeOptionsH / 2 - 1);
}

void drawHomeOptionsOverlay(){
  if(!homeOptionsOverlayOpen) return;

  homeOptionsPanelW = 310;
  homeOptionsPanelH = 218;
  homeOptionsPanelX = baseW - 76 - homeOptionsPanelW;
  homeOptionsPanelY = homeOptionsY + homeOptionsH + 14;

  noStroke();
  fill(0, 88);
  rect(0, 0, baseW, baseH);

  fill(card, 246);
  rect(homeOptionsPanelX, homeOptionsPanelY, homeOptionsPanelW, homeOptionsPanelH, 8);

  stroke(strokeC);
  strokeWeight(1.1);
  noFill();
  rect(homeOptionsPanelX, homeOptionsPanelY, homeOptionsPanelW, homeOptionsPanelH, 8);
  noStroke();

  fill(white);
  textAlign(LEFT, TOP);
  textSize(TYPE_BODY);
  text("Opções", homeOptionsPanelX + 22, homeOptionsPanelY + 18);

  float rowX = homeOptionsPanelX + 18;
  float rowY = homeOptionsPanelY + 58;
  float rowW = homeOptionsPanelW - 36;
  float rowH = 42;
  float rowGap = 12;

  homeShuffleX = rowX;
  homeShuffleY = rowY;
  homeShuffleW = rowW;
  homeShuffleH = rowH;

  homeResearchX = rowX;
  homeResearchY = rowY + rowH + rowGap;
  homeResearchW = rowW;
  homeResearchH = rowH;

  homeDesignerX = rowX;
  homeDesignerY = rowY + (rowH + rowGap) * 2;
  homeDesignerW = rowW;
  homeDesignerH = rowH;

  drawHomeOptionsToggleButton(homeShuffleX, homeShuffleY, homeShuffleW, homeShuffleH, "Baralhar", shuffleBehaviorsEnabled, "shuffle");
  drawHomeOptionsToggleButton(homeResearchX, homeResearchY, homeResearchW, homeResearchH, "Recolha de dados", researchLoggingEnabled, "research");
  drawHomeOptionsToggleButton(homeDesignerX, homeDesignerY, homeDesignerW, homeDesignerH, "Atividades 1 e 2", designerActivitiesVisible, "designer");
}

void drawHomeShuffleButton(){
  drawHomeToggleButton(
    homeShuffleX, homeShuffleY, homeShuffleW, homeShuffleH,
    shuffleBehaviorsEnabled,
    "shuffle"
  );
}

void drawHomeResearchButton(){
  drawHomeToggleButton(
    homeResearchX, homeResearchY, homeResearchW, homeResearchH,
    researchLoggingEnabled,
    "research"
  );
}

void drawHomeOptionsToggleButton(float x, float y, float w, float h, String label, boolean enabled, String iconKind){
  boolean hovered = inside(mouseXToInterface(), mouseYToInterface(), x, y, w, h);

  noStroke();
  fill(hovered ? color(19, 27, 45) : cardAlt);
  rect(x, y, w, h, 8);

  stroke(enabled ? purpleDim : strokeC);
  strokeWeight(1);
  noFill();
  rect(x, y, w, h, 8);
  noStroke();

  color iconColor = enabled ? purpleText : muted;
  if(iconKind.equals("research")){
    drawResearchLogIcon(x + 24, y + h / 2, 20, iconColor);
  } else if(iconKind.equals("designer")){
    drawDesignerVisibilityIcon(x + 24, y + h / 2, 20, iconColor);
  } else {
    drawShuffleCardsIcon(x + 24, y + h / 2, 20, iconColor);
  }

  fill(enabled ? white : muted);
  textAlign(LEFT, CENTER);
  textSize(TYPE_CAPTION);
  text(label, x + 48, y + h / 2 - 1);

  float toggleW = 50;
  float toggleH = 22;
  float toggleX = x + w - toggleW - 14;
  float toggleY = y + (h - toggleH) / 2;

  fill(enabled ? purpleDim : color(48, 58, 78));
  rect(toggleX, toggleY, toggleW, toggleH, 11);
  fill(enabled ? color(210, 198, 255) : muted);
  ellipse(toggleX + (enabled ? toggleW - 12 : 12), toggleY + toggleH / 2, 14, 14);
}

void drawHomeHapticTuningButtons(){
  drawHomeHapticTuningButton(
    homeHapticAmpX, homeHapticAmpY, homeHapticAmpW, homeHapticAmpH,
    "Amplitude",
    hapticTuneAmplitude + "%",
    map(hapticTuneAmplitude, HAPTIC_TUNE_MIN_AMPLITUDE, HAPTIC_TUNE_MAX_AMPLITUDE, 0, 1)
  );
  drawHomeHapticTuningButton(
    homeHapticFreqX, homeHapticFreqY, homeHapticFreqW, homeHapticFreqH,
    "Frequência",
    hapticTuneFrequencyLabel(),
    map(hapticTuneFrequencyHz, HAPTIC_TUNE_MIN_FREQUENCY, HAPTIC_TUNE_MAX_FREQUENCY, 0, 1)
  );
}

String hapticTuneFrequencyLabel(){
  return nf(hapticTuneFrequencyHz, 0, 1).replace('.', ',') + " Hz";
}

void drawObservationHapticTuningControls(){
  if(!observationHapticTuningVisible()) return;

  float controlH = 52;
  float controlGap = 16;
  float ampW = 252;
  float freqW = 252;
  float repeatW = 132;
  float totalW = ampW + freqW + repeatW + controlGap * 2;
  float startX = (baseW - totalW) / 2;
  float y = baseH - 96;

  homeHapticAmpX = startX;
  homeHapticAmpY = y;
  homeHapticAmpW = ampW;
  homeHapticAmpH = controlH;

  homeHapticFreqX = homeHapticAmpX + homeHapticAmpW + controlGap;
  homeHapticFreqY = y;
  homeHapticFreqW = freqW;
  homeHapticFreqH = controlH;

  hapticTuneRepeatX = homeHapticFreqX + homeHapticFreqW + controlGap;
  hapticTuneRepeatY = y;
  hapticTuneRepeatW = repeatW;
  hapticTuneRepeatH = controlH;

  drawHomeHapticTuningButton(
    homeHapticAmpX, homeHapticAmpY, homeHapticAmpW, homeHapticAmpH,
    "Amplitude",
    hapticTuneAmplitude + "%",
    map(hapticTuneAmplitude, HAPTIC_TUNE_MIN_AMPLITUDE, HAPTIC_TUNE_MAX_AMPLITUDE, 0, 1)
  );

  drawHomeHapticTuningButton(
    homeHapticFreqX, homeHapticFreqY, homeHapticFreqW, homeHapticFreqH,
    "Frequência",
    hapticTuneFrequencyLabel(),
    map(hapticTuneFrequencyHz, HAPTIC_TUNE_MIN_FREQUENCY, HAPTIC_TUNE_MAX_FREQUENCY, 0, 1)
  );

  drawActionButton(
    hapticTuneRepeatX, hapticTuneRepeatY, hapticTuneRepeatW, hapticTuneRepeatH,
    "Repetir", "replay", false, true
  );
}

void drawHomeHapticTuningButton(float x, float y, float w, float h, String label, String value, float normalizedValue){
  boolean hovered = inside(mouseXToInterface(), mouseYToInterface(), x, y, w, h);
  boolean active = hapticTunePreviewActive && millis() <= hapticTunePreviewUntilMillis;
  boolean disabled = unisensoryMode;
  color accent = disabled ? muted : (active ? purpleText : color(120, 136, 170));

  noStroke();
  fill(hovered && !disabled ? card : cardAlt);
  rect(x, y, w, h, 8);

  stroke(disabled ? color(58, 68, 88) : (active ? purpleDim : strokeC));
  strokeWeight(active ? 1.3 : 1.0);
  noFill();
  rect(x, y, w, h, 8);
  noStroke();

  fill(disabled ? grey : muted);
  textAlign(LEFT, CENTER);
  textSize(TYPE_CAPTION);
  text(label, x + 16, y + h / 2 - 1);

  fill(disabled ? grey : white);
  textAlign(RIGHT, CENTER);
  textSize(TYPE_CAPTION);
  text(value, x + w - 16, y + h / 2 - 1);

  float barX = x + 16;
  float barY = y + h - 7;
  float barW = w - 32;
  float barH = 2;
  fill(color(48, 58, 78));
  rect(barX, barY, barW, barH, 2);
  fill(accent);
  rect(barX, barY, barW * constrain(normalizedValue, 0.0f, 1.0f), barH, 2);
  ellipse(barX + barW * constrain(normalizedValue, 0.0f, 1.0f), barY + barH / 2, 7, 7);
}

void drawHomeToggleButton(float x, float y, float w, float h, boolean enabled, String iconKind){
  boolean hovered = inside(mouseXToInterface(), mouseYToInterface(), x, y, w, h);

  noStroke();
  fill(hovered ? card : cardAlt);
  rect(x, y, w, h, 8);

  stroke(enabled ? purpleDim : strokeC);
  strokeWeight(1);
  noFill();
  rect(x, y, w, h, 8);
  noStroke();

  color iconColor = enabled ? purpleText : muted;
  if(iconKind.equals("research")){
    drawResearchLogIcon(x + 28, y + h / 2, 22, iconColor);
  } else {
    drawShuffleCardsIcon(x + 28, y + h / 2, 22, iconColor);
  }

  float toggleW = 50;
  float toggleH = 22;
  float toggleX = x + w - toggleW - 16;
  float toggleY = y + (h - toggleH) / 2;

  fill(enabled ? purpleDim : color(48, 58, 78));
  rect(toggleX, toggleY, toggleW, toggleH, 11);
  fill(enabled ? color(210, 198, 255) : muted);
  ellipse(toggleX + (enabled ? toggleW - 12 : 12), toggleY + toggleH / 2, 14, 14);

  fill(enabled ? purpleText : muted);
  textAlign(RIGHT, CENTER);
  textSize(TYPE_CAPTION);
  text(enabled ? "Ligado" : "Desligado", toggleX - 12, y + h / 2);
}

void drawResearchParticipantPrompt(){
  if(!researchParticipantPromptActive) return;

  noStroke();
  fill(0, 150);
  rect(0, 0, baseW, baseH);

  researchPromptW = 520;
  researchPromptH = 324;
  researchPromptX = (baseW - researchPromptW) / 2;
  researchPromptY = (baseH - researchPromptH) / 2;

  noStroke();
  fill(card);
  rect(researchPromptX, researchPromptY, researchPromptW, researchPromptH, 8);

  stroke(strokeC);
  strokeWeight(1);
  noFill();
  rect(researchPromptX, researchPromptY, researchPromptW, researchPromptH, 8);
  noStroke();

  fill(white);
  textAlign(LEFT, TOP);
  textSize(TYPE_SUBHEADING);
  text("Identificação do participante", researchPromptX + 32, researchPromptY + 30);

  fill(muted);
  textSize(TYPE_BODY);
  text(
    "Introduz o participant_id antes de iniciar a recolha de dados.",
    researchPromptX + 32, researchPromptY + 76,
    researchPromptW - 64, 56
  );

  researchPromptInputX = researchPromptX + 32;
  researchPromptInputY = researchPromptY + 132;
  researchPromptInputW = researchPromptW - 64;
  researchPromptInputH = 54;

  fill(surfaceLow);
  rect(researchPromptInputX, researchPromptInputY, researchPromptInputW, researchPromptInputH, 8);
  stroke(purple);
  strokeWeight(1.5);
  noFill();
  rect(researchPromptInputX, researchPromptInputY, researchPromptInputW, researchPromptInputH, 8);
  noStroke();

  fill(researchParticipantDraft.length() > 0 ? white : muted);
  textAlign(LEFT, CENTER);
  textSize(TYPE_BODY);
  String inputText = researchParticipantDraft.length() > 0 ? researchParticipantDraft : "Ex.: P01";
  text(inputText, researchPromptInputX + 18, researchPromptInputY + researchPromptInputH / 2);

  if((millis() / 500) % 2 == 0){
    float cursorX = researchPromptInputX + 18 + textWidth(researchParticipantDraft);
    stroke(white);
    strokeWeight(1.5);
    line(cursorX + 2, researchPromptInputY + 14, cursorX + 2, researchPromptInputY + researchPromptInputH - 14);
    noStroke();
  }

  if(researchParticipantPromptError.length() > 0){
    fill(255, 138, 138);
    textAlign(LEFT, TOP);
    textSize(TYPE_CAPTION);
    text(researchParticipantPromptError, researchPromptInputX, researchPromptInputY + researchPromptInputH + 14, researchPromptInputW, 44);
  }

  researchPromptCancelW = 132;
  researchPromptCancelH = 42;
  researchPromptConfirmW = 180;
  researchPromptConfirmH = 42;
  researchPromptConfirmX = researchPromptX + researchPromptW - 32 - researchPromptConfirmW;
  researchPromptCancelX = researchPromptConfirmX - 14 - researchPromptCancelW;
  researchPromptCancelY = researchPromptY + researchPromptH - 66;
  researchPromptConfirmY = researchPromptCancelY;

  drawResearchPromptButton(
    researchPromptCancelX, researchPromptCancelY,
    researchPromptCancelW, researchPromptCancelH,
    "Cancelar", false, true
  );
  drawResearchPromptButton(
    researchPromptConfirmX, researchPromptConfirmY,
    researchPromptConfirmW, researchPromptConfirmH,
    "Iniciar recolha", true, researchParticipantDraft.trim().length() > 0
  );
}

void drawResearchPromptButton(float x, float y, float w, float h, String label, boolean primary, boolean enabled){
  boolean hovered = enabled && inside(mouseXToInterface(), mouseYToInterface(), x, y, w, h);

  noStroke();
  if(primary){
    fill(enabled ? (hovered ? purple : purpleDim) : greyDark);
  } else {
    fill(hovered ? cardAlt : card);
  }
  rect(x, y, w, h, 8);

  stroke(primary && enabled ? purpleText : strokeC);
  strokeWeight(1);
  noFill();
  rect(x, y, w, h, 8);
  noStroke();

  fill(enabled ? white : muted);
  textAlign(CENTER, CENTER);
  textSize(TYPE_LABEL);
  text(label, x + w / 2, y + h / 2);
}

void handleResearchParticipantPromptKey(){
  if(key == ESC){
    key = 0;
    cancelResearchParticipantPrompt();
    return;
  }

  if(key == ENTER || key == RETURN){
    confirmResearchParticipantPrompt();
    return;
  }

  if(key == BACKSPACE){
    if(researchParticipantDraft.length() > 0){
      researchParticipantDraft = researchParticipantDraft.substring(0, researchParticipantDraft.length() - 1);
    }
    return;
  }

  if(key == DELETE){
    researchParticipantDraft = "";
    return;
  }

  if(key == CODED) return;
  if(key < 32 || key > 126) return;
  if(researchParticipantDraft.length() >= 32) return;

  researchParticipantDraft += key;
}

void handleResearchParticipantPromptMouse(float mx, float my){
  if(inside(mx, my, researchPromptCancelX, researchPromptCancelY, researchPromptCancelW, researchPromptCancelH)){
    cancelResearchParticipantPrompt();
    return;
  }

  if(inside(mx, my, researchPromptConfirmX, researchPromptConfirmY, researchPromptConfirmW, researchPromptConfirmH)){
    confirmResearchParticipantPrompt();
  }
}

void drawShuffleCardsIcon(float cx, float cy, float s, color iconColor){
  pushStyle();
  noFill();
  stroke(iconColor);
  strokeWeight(max(1.2, s * 0.08));

  pushMatrix();
  translate(cx - s * 0.12, cy);
  rotate(-0.18);
  rectMode(CENTER);
  rect(0, 0, s * 0.62, s * 0.82, 3);
  popMatrix();

  pushMatrix();
  translate(cx + s * 0.12, cy);
  rotate(0.18);
  rectMode(CENTER);
  rect(0, 0, s * 0.62, s * 0.82, 3);
  popMatrix();

  strokeWeight(max(1.3, s * 0.09));
  line(cx - s * 0.34, cy + s * 0.03, cx + s * 0.20, cy - s * 0.18);
  line(cx + s * 0.20, cy - s * 0.18, cx + s * 0.12, cy - s * 0.31);
  line(cx + s * 0.20, cy - s * 0.18, cx + s * 0.34, cy - s * 0.12);

  line(cx + s * 0.34, cy + s * 0.10, cx - s * 0.20, cy + s * 0.26);
  line(cx - s * 0.20, cy + s * 0.26, cx - s * 0.12, cy + s * 0.38);
  line(cx - s * 0.20, cy + s * 0.26, cx - s * 0.34, cy + s * 0.20);
  popStyle();
}

void drawResearchLogIcon(float cx, float cy, float s, color iconColor){
  pushStyle();
  noFill();
  stroke(iconColor);
  strokeWeight(max(1.2, s * 0.08));
  rectMode(CENTER);
  rect(cx, cy, s * 0.70, s * 0.86, 3);
  line(cx - s * 0.20, cy - s * 0.12, cx + s * 0.20, cy - s * 0.12);
  line(cx - s * 0.20, cy + s * 0.10, cx + s * 0.20, cy + s * 0.10);
  line(cx - s * 0.20, cy + s * 0.32, cx + s * 0.08, cy + s * 0.32);
  fill(iconColor);
  noStroke();
  ellipse(cx + s * 0.20, cy - s * 0.34, s * 0.14, s * 0.14);
  popStyle();
}

void drawOptionsIcon(float cx, float cy, float s, color iconColor){
  pushStyle();
  stroke(iconColor);
  strokeWeight(max(1.3, s * 0.08));
  strokeCap(ROUND);
  noFill();

  float left = cx - s * 0.34;
  float right = cx + s * 0.34;
  float y1 = cy - s * 0.24;
  float y2 = cy;
  float y3 = cy + s * 0.24;

  line(left, y1, right, y1);
  line(left, y2, right, y2);
  line(left, y3, right, y3);

  noStroke();
  fill(iconColor);
  ellipse(cx - s * 0.10, y1, s * 0.17, s * 0.17);
  ellipse(cx + s * 0.18, y2, s * 0.17, s * 0.17);
  ellipse(cx - s * 0.22, y3, s * 0.17, s * 0.17);
  popStyle();
}

void drawDesignerVisibilityIcon(float cx, float cy, float s, color iconColor){
  pushStyle();
  noFill();
  stroke(iconColor);
  strokeWeight(max(1.2, s * 0.08));
  rectMode(CENTER);
  rect(cx - s * 0.12, cy - s * 0.12, s * 0.52, s * 0.52, 3);
  rect(cx + s * 0.16, cy + s * 0.16, s * 0.52, s * 0.52, 3);
  line(cx - s * 0.26, cy + s * 0.16, cx + s * 0.30, cy + s * 0.16);
  line(cx + s * 0.16, cy - s * 0.12, cx + s * 0.16, cy + s * 0.42);
  popStyle();
}

void drawStartupLoadingScreen(){
  float panelW = 620;
  float panelX = (baseW - panelW) / 2;
  float titleY = 246;
  float barY = 446;
  float progress = startupLoadingProgress();

  fill(white);
  textAlign(CENTER, TOP);
  textSize(TYPE_TITLE);
  text("Para Além da Linguagem Humana", baseW / 2, titleY);

  fill(purpleText);
  textSize(TYPE_BODY);
  text("A preparar a experiência multissensorial", baseW / 2, titleY + 58);

  noStroke();
  fill(card);
  rect(panelX, barY, panelW, 10, 5);
  fill(purple);
  rect(panelX, barY, panelW * progress, 10, 5);

  fill(muted);
  textSize(TYPE_LABEL);
  text(startupLoadingMessage(), baseW / 2, barY + 34);
}

float startupLoadingProgress(){
  float totalFiles = activity3Videos.length + videos.length;
  float totalMovies = activity3Videos.length + videos.length;
  float totalWarmup = totalVideoWarmupCount();
  float total = totalFiles + totalMovies + totalWarmup;
  float complete = 0;

  if(videosLoadingStarted){
    complete += activity3VideosLoadedCount;
    complete += videosLoadedCount;
    complete += activity3MoviesPreparedCount;
    complete += moviesPreparedCount;
    complete += completedVideoWarmupCount();
  } else if(videosLoadingScheduled){
    complete = 0.5;
  }

  if(videosReady()) complete = total;
  return constrain(complete / total, 0, 1);
}

String startupLoadingMessage(){
  if(videosLoadingScheduled && !videosLoadingStarted){
    return "A iniciar recursos visuais";
  }

  if(videosLoading){
    int totalFiles = activity3Videos.length + videos.length;
    int preparedFiles = activity3VideosLoadedCount + videosLoadedCount;
    return "A preparar vídeos " + preparedFiles + " / " + totalFiles;
  }

  if(!activity3MoviesPrepared || !moviesPrepared){
    int preparedMovies = activity3MoviesPreparedCount + moviesPreparedCount;
    int totalMovies = activity3Videos.length + videos.length;
    return "A preparar reprodução " + preparedMovies + " / " + totalMovies;
  }

  if(!allVideosWarmed()){
    return "A confirmar videos " + completedVideoWarmupCount() + " / " + totalVideoWarmupCount();
  }

  return "Tudo pronto";
}

void updateStartupLoadingScreen(){
  if(appState != APP_STATE_LOADING) return;
  if(!videosReady()) return;
  if(startupLoadingStartedMillis >= 0 &&
     millis() - startupLoadingStartedMillis < STARTUP_LOADING_MIN_VISIBLE_MS) return;

  appState = 0;
}

int getHomeHoverIndex(){
  if(appState != 0) return -1;

  float mx = mouseXToInterface();
  float my = mouseYToInterface();

  for(int i = 0; i < HOME_OPTION_COUNT; i++){
    if(!homeOptionVisible(i)) continue;
    if(inside(mx, my, homeOptionX[i], homeOptionY[i], homeOptionW[i], homeOptionH[i])){
      return i;
    }
  }

  return -1;
}

void drawHomeOption(float x, float y, float w, float h, String label, int iconType, boolean hovered){
  if(hovered){
    noStroke();
    fill(purple);
    rect(x, y, w, h, 8);
  } else {
    noStroke();
    fill(color(15, 21, 36));
    rect(x, y, w, h, 8);
    noFill();
    stroke(color(112, 76, 246, 210));
    strokeWeight(1.2);
    rect(x, y, w, h, 8);
  }

  float iconX = x + 40;
  float iconY = y + h / 2;

  noStroke();
  fill(hovered ? color(130, 94, 255) : purpleDim);
  ellipse(iconX, iconY, 36, 36);

  if(iconType == 0){
    stroke(white);
    strokeWeight(2.4);
    noFill();
    line(iconX - 10, iconY, iconX + 10, iconY);
    line(iconX + 10, iconY, iconX + 2, iconY - 8);
    line(iconX + 10, iconY, iconX + 2, iconY + 8);
  } else if(iconType == 1){
    drawReviewIcon(iconX, iconY, 14, white);
  } else if(iconType >= 10){
    drawActivityMenuIcon(iconX, iconY, 15, white);
  } else {
    drawArrowIcon(iconX, iconY, 14, -1, white);
  }

  noStroke();
  fill(hovered ? white : color(235, 238, 248));
  textAlign(LEFT, CENTER);
  textSize(TYPE_BODY);
  text(label, x + 76, y + h / 2);
}

void drawActivityMenuIcon(float cx, float cy, float s, color iconColor){
  pushStyle();
  noFill();
  stroke(iconColor);
  strokeWeight(max(1.4, s * 0.10));
  strokeCap(ROUND);
  rectMode(CENTER);
  rect(cx, cy, s * 0.92, s * 0.72, 3);
  line(cx - s * 0.24, cy - s * 0.12, cx + s * 0.24, cy - s * 0.12);
  line(cx - s * 0.24, cy + s * 0.12, cx + s * 0.08, cy + s * 0.12);
  popStyle();
}

void drawActivity1Prototype(){
  drawActivity1Header();

  if(activity1Step == 0){
    drawActivity1Observation();
    return;
  }

  if(activity1Step == 3){
    drawActivity1Feedback();
    return;
  }

  String taskTitle = activity1Step == 1
    ? "Identifica os momentos relevantes"
    : "Identifica o tipo de sinal";
  String taskDesc = activity1Step == 1
    ? "Observa cada momento e distingue sinais relevantes de movimentos neutros."
    : "Atribui um tipo de sinal aos momentos que marcaste como relevantes.";

  float activityMargin = 104;

  fill(muted);
  textAlign(RIGHT, CENTER);
  textSize(TYPE_CAPTION);
  text("Tarefa interpretativa", baseW - activityMargin - 92, 68);

  fill(white);
  textAlign(RIGHT, TOP);
  textSize(TYPE_SECTION);
  text(taskTitle, baseW - activityMargin, 82);

  fill(muted);
  textSize(TYPE_BODY);
  text(taskDesc, baseW - activityMargin - 620, 112, 620, 58);

  drawActivity1ProgressDots();
  drawActivity1MomentCards();
  drawActivity1AvailablePanel();

  activity1ResetW = 110;
  activity1ResetH = 38;
  activity1ConfirmW = 120;
  activity1ConfirmH = 38;
  activity1ConfirmX = baseW - activityMargin - activity1ConfirmW;
  activity1ConfirmY = 730;
  activity1ResetX = activity1ConfirmX - activity1ResetW - 24;
  activity1ResetY = activity1ConfirmY;

  drawActionButton(activity1ResetX, activity1ResetY, activity1ResetW, activity1ResetH, "Refazer", "replay", false, true);
  drawActionButton(activity1ConfirmX, activity1ConfirmY, activity1ConfirmW, activity1ConfirmH, "Confirmar", "next", true, activity1CanConfirm());

  if(activity1Dragging){
    drawActivity1Chip(mouseXToInterface() - 64, mouseYToInterface() - 16, 128, 32, activity1DraggedLabel(), true);
  }
}

void drawActivity1Header(){
  activity1BackW = 110;
  activity1BackH = 38;
  activity1BackX = 104;
  activity1BackY = 48;
  drawActionButton(activity1BackX, activity1BackY, activity1BackW, activity1BackH, "Sair", "close", false, true);
}

void drawActivity1Observation(){
  float activityMargin = 104;

  fill(white);
  textAlign(RIGHT, CENTER);
  textSize(TYPE_SECTION);
  text("Observa\u00e7\u00e3o", baseW - activityMargin, 68);

  float videoW = baseW * 0.68;
  float videoH = baseH * 0.58;
  float videoX = (baseW - videoW) / 2;
  float videoY = 140;

  noStroke();
  fill(card);
  rect(videoX, videoY, videoW, videoH, 14);

  drawActivityObservationSlideshow(0, videoX, videoY, videoW, videoH);
  drawObservationHapticTuningControls();
}

void drawActivity1ProgressDots(){
  float activityMargin = 104;
  float dotSpacing = 14;
  float dotsStartX = baseW - activityMargin - 64;
  float dotsY = 68;

  fill(white);
  textAlign(RIGHT, CENTER);
  textSize(TYPE_CAPTION);
  text("1/5", dotsStartX - 10, dotsY);

  for(int i = 0; i < 5; i++){
    if(i == 0){
      fill(purple);
      ellipse(dotsStartX + i * dotSpacing, dotsY, 8, 8);
    } else {
      fill(color(210, 216, 226));
      ellipse(dotsStartX + i * dotSpacing, dotsY, 6, 6);
    }
  }
}

void drawActivity1MomentCards(){
  float activityMargin = 104;
  float cardsY = 224;
  float gap = 10;
  int visibleCount = activity1VisibleMomentCount();
  float cardW = (baseW - activityMargin * 2 - gap * 3) / 4;
  float cardH = 320;
  float cardsAreaW = baseW - activityMargin * 2;
  float visibleCardsW = cardW * visibleCount + gap * max(0, visibleCount - 1);
  float startX = activityMargin + max(0, (cardsAreaW - visibleCardsW) / 2);
  int visibleIndex = 0;

  for(int i = 0; i < 4; i++){
    if(!activity1MomentVisible(i)){
      activity1MomentX[i] = -1000;
      activity1MomentY[i] = -1000;
      activity1MomentW[i] = 0;
      activity1MomentH[i] = 0;
      continue;
    }

    float x = startX + visibleIndex * (cardW + gap);
    float y = cardsY;
    visibleIndex++;

    activity1MomentX[i] = x;
    activity1MomentY[i] = y;
    activity1MomentW[i] = cardW;
    activity1MomentH[i] = cardH;

    noStroke();
    fill(card);
    rect(x, y, cardW, cardH, 8);
    stroke(strokeC);
    strokeWeight(1);
    noFill();
    rect(x, y, cardW, cardH, 8);
    noStroke();

    fill(white);
    textAlign(LEFT, TOP);
    textSize(TYPE_LABEL);
    text(activity1MomentLabels[i], x + 18, y + 20);

    fill(muted);
    textAlign(RIGHT, TOP);
    textSize(TYPE_CAPTION);
    text(activity1MomentTimes[i], x + cardW - 18, y + 22);

    float imageX = x + 18;
    float imageY = y + 54;
    float imageW = cardW - 36;
    float imageH = 134;
    drawActivity1DogThumbnail(imageX, imageY, imageW, imageH, i);

    float dropX = x + 18;
    float dropY = y + 202;
    float dropW = cardW - 36;
    float dropH = 94;
    drawDashedRect(dropX, dropY, dropW, dropH, 8, activity1MomentHasAssignment(i) ? purple : strokeC);

    if(activity1MomentHasAssignment(i)){
      float chipW = min(180, dropW - 42);
      float chipH = 34;
      drawActivity1Chip(
        dropX + (dropW - chipW) / 2,
        dropY + (dropH - chipH) / 2,
        chipW,
        chipH,
        activity1MomentDropText(i),
        false
      );
    } else {
      fill(muted);
      textAlign(CENTER, CENTER);
      textSize(TYPE_LABEL);
      drawActivity1DragIcon(x + cardW / 2, dropY + dropH / 2 - 14, 12, purple);
      fill(muted);
      text(activity1MomentDropText(i), x + cardW / 2, dropY + dropH / 2 + 18);
    }
  }
}

boolean activity1MomentVisible(int index){
  if(activity1Step == 2) return activity1MomentRelevance[index] == 0;
  return true;
}

int activity1VisibleMomentCount(){
  if(activity1Step != 2) return 4;

  int count = 0;
  for(int i = 0; i < activity1MomentRelevance.length; i++){
    if(activity1MomentVisible(i)) count++;
  }

  return max(1, count);
}

void drawActivity1DogThumbnail(float x, float y, float w, float h, int index){
  noStroke();
  fill(color(245, 247, 252));
  rect(x, y, w, h, 4);

  fill(color(222, 228, 238));
  rect(x, y + h - 14, w, 14);

  float cx = x + w * (0.44 + 0.03 * (index % 2));
  float cy = y + h * 0.52;

  fill(color(48, 54, 64));
  ellipse(cx, cy, w * 0.24, h * 0.42);
  ellipse(cx + w * 0.15, cy - h * 0.08, w * 0.15, h * 0.22);
  rect(cx - w * 0.10, cy + h * 0.15, w * 0.04, h * 0.22);
  rect(cx + w * 0.04, cy + h * 0.15, w * 0.04, h * 0.22);

  stroke(color(48, 54, 64));
  strokeWeight(3);
  line(cx - w * 0.13, cy - h * 0.04, cx - w * 0.25, cy - h * 0.18);
  line(cx + w * 0.22, cy - h * 0.10, cx + w * 0.31, cy - h * 0.20);
  noStroke();

  fill(color(84, 98, 120));
  ellipse(x + w - 28, y + h - 12, 40, 24);
}

void drawActivity1AvailablePanel(){
  float activityMargin = 104;
  float panelX = activityMargin;
  float panelY = 568;
  float panelW = baseW - activityMargin * 2;
  float panelH = 120;

  noStroke();
  fill(card);
  rect(panelX, panelY, panelW, panelH, 8);
  stroke(strokeC);
  strokeWeight(1);
  noFill();
  rect(panelX, panelY, panelW, panelH, 8);
  noStroke();

  fill(white);
  textAlign(LEFT, TOP);
  textSize(TYPE_BODY);
  text("Cart\u00f5es dispon\u00edveis", panelX + 62, panelY + 28);

  fill(muted);
  textSize(TYPE_BODY);
  String desc = activity1Step == 1
    ? "Arrasta os cart\u00f5es para as zonas de destino acima."
    : "Arrasta os cart\u00f5es para as zonas de destino acima.";
  text(desc, panelX + 62, panelY + 56, 330, 44);

  stroke(strokeC);
  strokeWeight(1);
  line(panelX + 416, panelY + 28, panelX + 416, panelY + panelH - 28);
  noStroke();

  String[] cards = activity1Step == 1 ? activity1RelevanceCards : activity1SignalCards;
  float chipW = activity1Step == 1 ? 200 : 200;
  float chipH = 34;
  float gap = activity1Step == 1 ? 42 : 38;
  float startX = panelX + 448;
  float chipY = panelY + (panelH - chipH) / 2;

  for(int i = 0; i < cards.length; i++){
    activity1CardX[i] = startX + i * (chipW + gap);
    activity1CardY[i] = chipY;
    activity1CardW[i] = chipW;
    activity1CardH[i] = chipH;
    drawActivity1Chip(activity1CardX[i], chipY, chipW, chipH, cards[i], false);
  }
}

void drawActivity1Chip(float x, float y, float w, float h, String label, boolean floating){
  noStroke();
  fill(floating ? color(58, 42, 138) : cardAlt);
  rect(x, y, w, h, 8);
  stroke(floating ? purpleText : color(54, 68, 96));
  strokeWeight(floating ? 1.4 : 1);
  noFill();
  rect(x, y, w, h, 8);
  noStroke();

  fill(white);
  drawActivity1CardGrip(x + w * 0.34, y + h / 2, 8, purple);
  fill(white);
  textAlign(CENTER, CENTER);
  textSize(TYPE_LABEL);
  text(label, x + w / 2 + 12, y + h / 2 - 1);
}

void drawActivity1CardGrip(float cx, float cy, float s, color iconColor){
  noStroke();
  fill(iconColor);

  float dot = max(1.4, s * 0.18);
  float colGap = s * 0.45;
  float rowGap = s * 0.45;

  for(int row = -1; row <= 1; row++){
    ellipse(cx - colGap / 2, cy + row * rowGap, dot, dot);
    ellipse(cx + colGap / 2, cy + row * rowGap, dot, dot);
  }
}

void drawActivity1DragIcon(float cx, float cy, float s, color iconColor){
  pushStyle();
  color miraColor = color(124, 77, 255);
  stroke(miraColor);
  strokeWeight(max(1.0, s * 0.056));
  strokeCap(ROUND);
  strokeJoin(ROUND);
  ellipseMode(CENTER);
  noFill();

  float offset = s * 0.639;
  float petalShort = s * 0.266;
  float petalLong = s * 0.663;

  ellipse(cx, cy - offset, petalShort, petalLong);
  ellipse(cx, cy + offset, petalShort, petalLong);
  ellipse(cx + offset, cy, petalLong, petalShort);
  ellipse(cx - offset, cy, petalLong, petalShort);

  fill(miraColor);
  noStroke();
  ellipse(cx, cy, s * 0.367, s * 0.367);
  popStyle();
}

void drawDashedRect(float x, float y, float w, float h, float r, color strokeColor){
  stroke(strokeColor);
  strokeWeight(1);
  strokeCap(SQUARE);
  noFill();

  float dash = 4;
  float gap = 4;
  float x1 = x + r;
  float x2 = x + w - r;
  float y1 = y + r;
  float y2 = y + h - r;

  for(float xx = x1; xx < x2; xx += dash + gap){
    line(xx, y, min(xx + dash, x2), y);
    line(xx, y + h, min(xx + dash, x2), y + h);
  }
  for(float yy = y1; yy < y2; yy += dash + gap){
    line(x, yy, x, min(yy + dash, y2));
    line(x + w, yy, x + w, min(yy + dash, y2));
  }

  noStroke();
}

void drawActivity1Feedback(){
  float activityMargin = 104;

  fill(muted);
  textAlign(RIGHT, CENTER);
  textSize(TYPE_CAPTION);
  text("Feedback", baseW - activityMargin, 58);

  fill(white);
  textAlign(RIGHT, CENTER);
  textSize(TYPE_SECTION);
  text("Resposta da atividade", baseW - activityMargin, 82);

  float summaryX = activityMargin;
  float summaryY = 130;
  float summaryW = baseW - activityMargin * 2;
  float summaryH = 102;

  noStroke();
  fill(card);
  rect(summaryX, summaryY, summaryW, summaryH, 8);
  stroke(strokeC);
  strokeWeight(1);
  noFill();
  rect(summaryX, summaryY, summaryW, summaryH, 8);
  noStroke();

  fill(white);
  textAlign(LEFT, TOP);
  textSize(TYPE_BODY);
  text("Momentos esperados", summaryX + 28, summaryY + 20);

  fill(muted);
  textSize(TYPE_BODY);
  text(
    "A resposta da atividade mostra os momentos relevantes e o tipo de comportamento associado.",
    summaryX + 28, summaryY + 48, summaryW * 0.48, 44
  );

  stroke(strokeC);
  strokeWeight(1);
  line(summaryX + summaryW * 0.52, summaryY + 20, summaryX + summaryW * 0.52, summaryY + summaryH - 20);
  noStroke();

  drawActivity1FeedbackSummaryList(summaryX + summaryW * 0.56, summaryY + 22);

  drawActivity1FeedbackMomentCards();
  drawActivity1FeedbackExplanation();

  activity1ConfirmW = 180;
  activity1ConfirmH = 44;
  activity1ConfirmX = baseW - activityMargin - activity1ConfirmW;
  activity1ConfirmY = 710;
  drawActionButton(activity1ConfirmX, activity1ConfirmY, activity1ConfirmW, activity1ConfirmH, "Concluir", "next", true, true);
}

void drawActivity1FeedbackSummaryList(float x, float y){
  fill(white);
  textAlign(LEFT, TOP);
  textSize(TYPE_LABEL);

  int row = 0;
  for(int i = 0; i < activity1CorrectRelevance.length; i++){
    if(activity1CorrectRelevance[i] != 0) continue;
    text(activity1MomentLabels[i] + "  \u2192  " + activity1CorrectAnswerText(i), x, y + row * 28);
    row++;
  }
}

void drawActivity1FeedbackMomentCards(){
  float activityMargin = 104;
  float gap = 10;
  float cardW = (baseW - activityMargin * 2 - gap * 3) / 4;
  float cardH = 310;
  float cardY = 238;
  int correctCount = activity1CorrectMomentCount();
  float cardsAreaW = baseW - activityMargin * 2;
  float correctCardsW = cardW * correctCount + gap * max(0, correctCount - 1);
  float startX = activityMargin + max(0, (cardsAreaW - correctCardsW) / 2);
  int visibleIndex = 0;

  for(int i = 0; i < 4; i++){
    if(activity1CorrectRelevance[i] != 0) continue;

    float x = startX + visibleIndex * (cardW + gap);
    visibleIndex++;

    noStroke();
    fill(cardAlt);
    rect(x, cardY, cardW, cardH, 8);
    stroke(purple);
    strokeWeight(1.6);
    noFill();
    rect(x, cardY, cardW, cardH, 8);
    noStroke();

    fill(white);
    textAlign(LEFT, TOP);
    textSize(TYPE_LABEL);
    text(activity1MomentLabels[i], x + 18, cardY + 18);

    fill(muted);
    textAlign(RIGHT, TOP);
    textSize(TYPE_CAPTION);
    text(activity1MomentTimes[i], x + cardW - 18, cardY + 20);

    float imageX = x + 18;
    float imageY = cardY + 52;
    float imageW = cardW - 36;
    float imageH = 104;
    drawActivity1DogThumbnail(imageX, imageY, imageW, imageH, i);

    fill(muted);
    textAlign(LEFT, TOP);
    textSize(TYPE_CAPTION);
    text("RELEV\u00c2NCIA", x + 18, cardY + 174);

    drawActivity1FeedbackChip(
      x + 18, cardY + 196, cardW - 36, 32,
      activity1RelevanceCards[activity1CorrectRelevance[i]],
      purple
    );

    fill(muted);
    textAlign(LEFT, TOP);
    textSize(TYPE_CAPTION);
    text("TIPO DE COMPORTAMENTO", x + 18, cardY + 244);

    drawActivity1FeedbackChip(
      x + 18, cardY + 266, cardW - 36, 32,
      activity1CorrectAnswerText(i),
      purple
    );
  }
}

void drawActivity1FeedbackExplanation(){
  float activityMargin = 104;
  float x = activityMargin;
  float y = 572;
  float w = baseW - activityMargin * 2;
  float h = 112;

  noStroke();
  fill(card);
  rect(x, y, w, h, 8);
  stroke(strokeC);
  strokeWeight(1);
  noFill();
  rect(x, y, w, h, 8);
  noStroke();

  fill(purpleDim);
  ellipse(x + 42, y + 40, 44, 44);
  drawBookIcon(x + 42, y + 40, 15, purpleText);

  fill(white);
  textAlign(LEFT, TOP);
  textSize(TYPE_SUBHEADING);
  text("Sobre este comportamento", x + 76, y + 20);

  fill(muted);
  textSize(TYPE_BODY);
  text(activity1FeedbackExplanation, x + 76, y + 50, w - 104, h - 58);
}

int activity1CorrectMomentCount(){
  int count = 0;
  for(int i = 0; i < activity1CorrectRelevance.length; i++){
    if(activity1CorrectRelevance[i] == 0) count++;
  }
  return max(1, count);
}

void drawActivity1FeedbackChip(float x, float y, float w, float h, String label, color borderColor){
  noStroke();
  fill(cardAlt);
  rect(x, y, w, h, 8);
  stroke(borderColor);
  strokeWeight(1);
  noFill();
  rect(x, y, w, h, 8);
  noStroke();

  fill(white);
  textAlign(CENTER, CENTER);
  textSize(TYPE_LABEL);
  text(label, x + w / 2, y + h / 2 - 1);
}

String activity1CorrectAnswerText(int index){
  if(activity1CorrectRelevance[index] == 1) return "Movimento neutro";
  return activity1SignalCards[activity1CorrectSignal[index]];
}

boolean activity1MomentHasAssignment(int index){
  if(activity1Step == 1) return activity1MomentRelevance[index] >= 0;
  if(activity1MomentRelevance[index] == 1) return true;
  return activity1MomentSignal[index] >= 0;
}

String activity1MomentDropText(int index){
  if(activity1Step == 1){
    if(activity1MomentRelevance[index] < 0) return "Arrasta para aqui";
    return activity1RelevanceCards[activity1MomentRelevance[index]];
  }

  if(activity1MomentRelevance[index] == 1) return "Movimento neutro";
  if(activity1MomentSignal[index] < 0) return "Arrasta para aqui";
  return activity1SignalCards[activity1MomentSignal[index]];
}

String activity1DraggedLabel(){
  if(activity1DragKind == 1) return activity1RelevanceCards[activity1DragValue];
  if(activity1DragKind == 2) return activity1SignalCards[activity1DragValue];
  return "";
}

boolean activity1CanConfirm(){
  if(activity1Step == 1){
    for(int i = 0; i < activity1MomentRelevance.length; i++){
      if(activity1MomentRelevance[i] < 0) return false;
    }
    return true;
  }

  if(activity1Step == 2){
    for(int i = 0; i < activity1MomentSignal.length; i++){
      if(activity1MomentRelevance[i] == 0 && activity1MomentSignal[i] < 0) return false;
    }
    return true;
  }

  return true;
}

void startActivity1Drag(float mx, float my){
  if(activity1Step != 1 && activity1Step != 2) return;

  String[] cards = activity1Step == 1 ? activity1RelevanceCards : activity1SignalCards;
  for(int i = 0; i < cards.length; i++){
    if(inside(mx, my, activity1CardX[i], activity1CardY[i], activity1CardW[i], activity1CardH[i])){
      activity1Dragging = true;
      activity1DragKind = activity1Step;
      activity1DragValue = i;
      return;
    }
  }
}

void finishActivity1Drag(float mx, float my){
  if(!activity1Dragging) return;

  for(int i = 0; i < activity1MomentX.length; i++){
    if(inside(mx, my, activity1MomentX[i], activity1MomentY[i], activity1MomentW[i], activity1MomentH[i])){
      if(activity1DragKind == 1){
        activity1MomentRelevance[i] = activity1DragValue;
        activity1MomentSignal[i] = -1;
      } else if(activity1DragKind == 2 && activity1MomentRelevance[i] == 0){
        activity1MomentSignal[i] = activity1DragValue;
      }
      break;
    }
  }

  activity1Dragging = false;
  activity1DragKind = 0;
  activity1DragValue = -1;
}

void resetActivity1Step(){
  if(activity1Step == 1){
    for(int i = 0; i < activity1MomentRelevance.length; i++){
      activity1MomentRelevance[i] = -1;
      activity1MomentSignal[i] = -1;
    }
  } else if(activity1Step == 2){
    for(int i = 0; i < activity1MomentSignal.length; i++){
      activity1MomentSignal[i] = -1;
    }
  }
}

void confirmActivity1Step(){
  if(activity1Step == 0){
    logResearchEvent("activity_observation_confirm", "activity1", "observation", -1, "entered_interpretation=true");
    enterActivity1Tasks();
    return;
  }

  if(!activity1CanConfirm()) return;

  if(activity1Step == 1){
    logResearchEvent("activity_response_confirm", "activity1", "relevance", -1, activity1RelevanceResearchDetails());
    activity1Step = 2;
  } else if(activity1Step == 2){
    logResearchEvent("activity_response_confirm", "activity1", "signal_type", -1, activity1SignalResearchDetails());
    activity1Step = 3;
  } else {
    logResearchEvent("activity_feedback_confirm", "activity1", "feedback", -1, "return_home=true");
    handleBack();
  }
}

void enterActivity1Tasks(){
  stopAllVideos();
  stopBHapticsVibration();
  clearInterpretationSeek();
  activity1ObservationFinishedMillis = -1;
  resetActivityObservationSlides(0);
  replayVibrationActive = false;
  activity1Step = 1;
  resetActivity1Step();
}

void drawActivity2Prototype(){
  drawActivity1Header();

  if(activity2Step == 0){
    drawActivity2Observation();
    return;
  }

  if(activity2Step == 1){
    drawActivity2Task();
    return;
  }

  drawActivity2Feedback();
}

void drawActivity2Observation(){
  float activityMargin = 104;

  fill(white);
  textAlign(RIGHT, CENTER);
  textSize(TYPE_SECTION);
  text("Observa\u00e7\u00e3o", baseW - activityMargin, 68);

  float videoW = baseW * 0.68;
  float videoH = baseH * 0.58;
  float videoX = (baseW - videoW) / 2;
  float videoY = 140;

  noStroke();
  fill(card);
  rect(videoX, videoY, videoW, videoH, 14);

  drawActivityObservationSlideshow(1, videoX, videoY, videoW, videoH);
  drawObservationHapticTuningControls();
}

void drawActivity2Task(){
  drawActivity2TaskHeader("Tarefa interpretativa", "Constr\u00f3i a rela\u00e7\u00e3o comunicativa");
  drawActivity2Columns();

  activity2ResetW = 110;
  activity2ResetH = 38;
  activity2ConfirmW = 120;
  activity2ConfirmH = 38;
  activity2ConfirmX = baseW - 104 - activity2ConfirmW;
  activity2ConfirmY = 730;
  activity2ResetX = activity2ConfirmX - activity2ResetW - 24;
  activity2ResetY = activity2ConfirmY;

  drawActionButton(activity2ResetX, activity2ResetY, activity2ResetW, activity2ResetH, "Refazer", "replay", false, true);
  drawActionButton(activity2ConfirmX, activity2ConfirmY, activity2ConfirmW, activity2ConfirmH, "Confirmar", "next", true, activity2CanConfirm());
}

void drawActivity2TaskHeader(String headerLabel, String title){
  float activityMargin = 104;
  float dotsStartX = baseW - activityMargin - 64;
  float dotsY = 68;

  fill(muted);
  textAlign(RIGHT, CENTER);
  textSize(TYPE_CAPTION);
  text(headerLabel, dotsStartX - 72, dotsY);

  fill(white);
  textAlign(RIGHT, TOP);
  textSize(TYPE_SECTION);
  text(title, baseW - activityMargin, 86);

  fill(muted);
  textSize(TYPE_BODY);
  text(
    "Observa os sinais do c\u00e3o e liga-os aos elementos da situa\u00e7\u00e3o. Mostra como o comportamento cria uma rela\u00e7\u00e3o entre o c\u00e3o, o tutor e o alvo.",
    baseW - activityMargin - 620, 124, 620, 62
  );

  drawActivity2ProgressDots(dotsStartX, dotsY);
}

void drawActivity2ProgressDots(float dotsStartX, float dotsY){
  float dotSpacing = 14;

  fill(white);
  textAlign(RIGHT, CENTER);
  textSize(TYPE_CAPTION);
  text("1/5", dotsStartX - 10, dotsY);

  for(int i = 0; i < 5; i++){
    if(i == 0){
      fill(purple);
      ellipse(dotsStartX + i * dotSpacing, dotsY, 8, 8);
    } else {
      fill(color(210, 216, 226));
      ellipse(dotsStartX + i * dotSpacing, dotsY, 6, 6);
    }
  }
}

void drawActivity2Columns(){
  float columnW = 220;
  float columnH = 500;
  float gap = 44;
  float startX = (baseW - (columnW * 4 + gap * 3)) / 2;
  float columnY = 204;

  for(int c = 0; c < 4; c++){
    float x = startX + c * (columnW + gap);
    drawActivity2Column(c, x, columnY, columnW, columnH);
  }
}

void drawActivity2Column(int column, float x, float y, float w, float h){
  noStroke();
  fill(card);
  rect(x, y, w, h, 14);
  stroke(color(52, 67, 96));
  strokeWeight(1.3);
  noFill();
  rect(x, y, w, h, 14);
  noStroke();

  fill(white);
  textAlign(CENTER, TOP);
  textSize(TYPE_BODY);
  text(activity2ColumnTitles[column], x + w / 2, y + 24);

  fill(muted);
  textSize(TYPE_LABEL);
  text(activity2ColumnSubtitles[column], x + 22, y + 50, w - 44, 52);

  float optionW = w - 40;
  float optionH = 58;
  float optionX = x + 20;
  float optionY = y + 128;
  float optionGap = 22;

  for(int i = 0; i < activity2Options[column].length; i++){
    float oy = optionY + i * (optionH + optionGap);
    activity2OptionX[column][i] = optionX;
    activity2OptionY[column][i] = oy;
    activity2OptionW[column][i] = optionW;
    activity2OptionH[column][i] = optionH;

    boolean selected = (activity2SelectedMasks[column] & (1 << i)) != 0;
    drawActivity2Option(optionX, oy, optionW, optionH, activity2Options[column][i], selected);
  }

  float footerH = 56;
  fill(color(37, 52, 76));
  rect(x, y + h - footerH, w, footerH, 0, 0, 14, 14);

  stroke(white);
  strokeWeight(1.4);
  noFill();
  ellipse(x + 32, y + h - 28, 15, 15);
  noStroke();
  fill(white);
  textAlign(CENTER, CENTER);
  textSize(TYPE_CAPTION);
  text("i", x + 32, y + h - 29);

  fill(white);
  textAlign(LEFT, CENTER);
  textSize(TYPE_CAPTION);
  text(activity2ColumnHints[column], x + 46, y + h - 28, w - 58, 24);
}

void drawActivity2Option(float x, float y, float w, float h, String label, boolean selected){
  noStroke();
  fill(selected ? color(35, 28, 82) : cardAlt);
  rect(x, y, w, h, 8);
  stroke(selected ? purpleText : strokeC);
  strokeWeight(selected ? 1.4 : 1);
  noFill();
  rect(x, y, w, h, 8);
  noStroke();

  fill(white);
  textAlign(CENTER, CENTER);
  textSize(TYPE_LABEL);
  text(label, x + w / 2, y + h / 2 - 1);
}

void drawActivity2Feedback(){
  float activityMargin = 104;
  float dotsStartX = baseW - activityMargin - 64;
  float dotsY = 68;

  fill(white);
  textAlign(RIGHT, CENTER);
  textSize(TYPE_BODY);
  text("Feedback", dotsStartX - 72, dotsY);
  drawActivity2ProgressDots(dotsStartX, dotsY);

  float blockW = 168;
  float blockH = 58;
  float gap = 58;
  float startX = (baseW - (blockW * 4 + gap * 3)) / 2;
  float userY = 198;
  float correctY = 302;

  fill(white);
  textAlign(LEFT, BOTTOM);
  textSize(TYPE_BODY);
  text("A tua interpreta\u00e7\u00e3o", startX, userY - 24);
  text("Interpreta\u00e7\u00e3o da atividade", startX, correctY - 24);

  for(int c = 0; c < 4; c++){
    float x = startX + c * (blockW + gap);
    drawActivity2SequenceBlock(x, userY, blockW, blockH, activity2SelectedText(c), purpleText);
    drawActivity2SequenceBlock(x, correctY, blockW, blockH, activity2CorrectText(c), color(0, 220, 125));
  }

  drawActivity2FeedbackExplanation();

  activity2ResetW = 110;
  activity2ResetH = 38;
  activity2ConfirmW = 120;
  activity2ConfirmH = 38;
  activity2ConfirmX = baseW - activityMargin - activity2ConfirmW;
  activity2ConfirmY = 710;
  activity2ResetX = activity2ConfirmX - activity2ResetW - 24;
  activity2ResetY = activity2ConfirmY;

  drawActionButton(activity2ResetX, activity2ResetY, activity2ResetW, activity2ResetH, "Refazer", "replay", false, true);
  drawActionButton(activity2ConfirmX, activity2ConfirmY, activity2ConfirmW, activity2ConfirmH, "Confirmar", "next", true, true);
}

void drawActivity2SequenceBlock(float x, float y, float w, float h, String label, color borderColor){
  noStroke();
  fill(cardAlt);
  rect(x, y, w, h, 8);
  stroke(borderColor);
  strokeWeight(1.6);
  noFill();
  rect(x, y, w, h, 8);
  noStroke();

  fill(white);
  textAlign(CENTER, CENTER);
  textSize(TYPE_LABEL);
  text(label, x + 10, y + 2, w - 20, h - 4);
}

void drawActivity2FeedbackExplanation(){
  float x = 104;
  float y = 388;
  float w = baseW - 208;
  float h = 224;

  noStroke();
  fill(card);
  rect(x, y, w, h, 8);

  fill(purpleText);
  drawBookIcon(x + 34, y + 34, 18, purpleText);

  fill(white);
  textAlign(LEFT, TOP);
  textSize(TYPE_BODY);
  text(activity2FeedbackExplanation, x + 70, y + 36, w - 100, h - 60);
}

boolean activity2CanConfirm(){
  for(int i = 0; i < activity2SelectedMasks.length; i++){
    if(activity2SelectedMasks[i] == 0) return false;
  }
  return true;
}

void resetActivity2Selections(){
  for(int i = 0; i < activity2SelectedMasks.length; i++){
    activity2SelectedMasks[i] = 0;
  }
}

void confirmActivity2Step(){
  if(activity2Step == 0){
    logResearchEvent("activity_observation_confirm", "activity2", "observation", -1, "entered_interpretation=true");
    enterActivity2Task();
    return;
  }

  if(activity2Step == 1){
    if(!activity2CanConfirm()) return;
    logResearchEvent("activity_response_confirm", "activity2", "interpretation", -1, activity2ResearchDetails());
    activity2Step = 2;
    return;
  }

  logResearchEvent("activity_feedback_confirm", "activity2", "feedback", -1, "return_home=true");
  handleBack();
}

void enterActivity2Task(){
  stopAllVideos();
  stopBHapticsVibration();
  clearInterpretationSeek();
  activity2ObservationFinishedMillis = -1;
  resetActivityObservationSlides(1);
  replayVibrationActive = false;
  activity2Step = 1;
}

void toggleActivity2Option(int column, int option){
  if(activity2MultiSelect[column]){
    activity2SelectedMasks[column] ^= (1 << option);
  } else {
    activity2SelectedMasks[column] = 1 << option;
  }
}

String activity2SelectedText(int column){
  String result = "";
  for(int i = 0; i < activity2Options[column].length; i++){
    if((activity2SelectedMasks[column] & (1 << i)) == 0) continue;
    if(result.length() > 0) result += " + ";
    result += activity2Options[column][i];
  }
  return result.length() > 0 ? result : "Por selecionar";
}

String activity2CorrectText(int column){
  return activity2Options[column][activity2CorrectOption[column]];
}

String activity1RelevanceResearchDetails(){
  String result = "";
  int correctCount = 0;
  for(int i = 0; i < activity1MomentRelevance.length; i++){
    boolean correct = activity1MomentRelevance[i] == activity1CorrectRelevance[i];
    if(correct) correctCount++;
    if(result.length() > 0) result += " | ";
    result += activity1MomentLabels[i] +
      ":selected=" + activity1RelevanceCards[activity1MomentRelevance[i]] +
      ";correct=" + activity1RelevanceCards[activity1CorrectRelevance[i]] +
      ";ok=" + correct;
  }
  return "correct_count=" + correctCount + "/" + activity1MomentRelevance.length + "; " + result;
}

String activity1SignalResearchDetails(){
  String result = "";
  int required = 0;
  int correctCount = 0;
  for(int i = 0; i < activity1MomentSignal.length; i++){
    if(activity1CorrectSignal[i] < 0) continue;
    required++;
    boolean correct = activity1MomentSignal[i] == activity1CorrectSignal[i];
    if(correct) correctCount++;
    if(result.length() > 0) result += " | ";
    result += activity1MomentLabels[i] +
      ":selected=" + activity1SignalResearchLabel(activity1MomentSignal[i]) +
      ";correct=" + activity1SignalCards[activity1CorrectSignal[i]] +
      ";ok=" + correct;
  }
  return "correct_count=" + correctCount + "/" + required + "; " + result;
}

String activity1SignalResearchLabel(int index){
  if(index < 0 || index >= activity1SignalCards.length) return "Por selecionar";
  return activity1SignalCards[index];
}

String activity2ResearchDetails(){
  String result = "";
  int correctCount = 0;
  for(int c = 0; c < activity2Options.length; c++){
    boolean correct = activity2SelectedMasks[c] == (1 << activity2CorrectOption[c]);
    if(correct) correctCount++;
    if(result.length() > 0) result += " | ";
    result += activity2ColumnTitles[c] +
      ":selected=" + activity2SelectedText(c) +
      ";correct=" + activity2CorrectText(c) +
      ";ok=" + correct;
  }
  return "correct_count=" + correctCount + "/" + activity2Options.length + "; " + result;
}

String joinLabels(String[] labels, String separator){
  String result = "";
  for(int i = 0; i < labels.length; i++){
    if(result.length() > 0) result += separator;
    result += labels[i];
  }
  return result;
}

String joinIndexedLabels(int[] indices, String[] labels, String separator){
  String result = "";
  for(int i = 0; i < indices.length; i++){
    int index = indices[i];
    if(index < 0 || index >= labels.length) continue;
    if(result.length() > 0) result += separator;
    result += labels[index];
  }
  return result;
}

String boolText(boolean value){
  return value ? "true" : "false";
}

String nf2(float value){
  return nf(value, 0, 2);
}

void logActivity1StructuredResponses(String stage){
  if(stage.equals("relevance")){
    for(int i = 0; i < activity1MomentRelevance.length; i++){
      int selected = activity1MomentRelevance[i];
      int correct = activity1CorrectRelevance[i];
      logStructuredResearchResponse(
        "activity1",
        "Atividade 1",
        "moment_" + (i + 1),
        str(i + 1),
        "",
        activity1MomentTimes[i],
        "momento_video",
        "relevance",
        selected >= 0 ? activity1RelevanceCards[selected] : "Por selecionar",
        "",
        "",
        selected != correct ? (selected >= 0 ? activity1RelevanceCards[selected] : "Por selecionar") : "",
        activity1RelevanceCards[correct],
        "",
        boolText(selected == correct),
        selected == correct ? "correto" : "erro_resposta",
        "",
        "",
        joinLabels(activity1RelevanceCards, " | "),
        "",
        "",
        "",
        "",
        selected >= 0 ? activity1RelevanceCards[selected] : "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        activity1RelevanceResearchDetails()
      );
    }
    return;
  }

  if(stage.equals("signal_type")){
    for(int i = 0; i < activity1MomentSignal.length; i++){
      if(activity1CorrectSignal[i] < 0) continue;
      int selected = activity1MomentSignal[i];
      int correct = activity1CorrectSignal[i];
      logStructuredResearchResponse(
        "activity1",
        "Atividade 1",
        "moment_" + (i + 1),
        str(i + 1),
        "",
        activity1MomentTimes[i],
        "momento_video",
        "signal_type",
        activity1SignalResearchLabel(selected),
        "",
        "",
        selected != correct ? activity1SignalResearchLabel(selected) : "",
        activity1SignalCards[correct],
        "",
        boolText(selected == correct),
        selected == correct ? "correto" : "erro_resposta",
        "",
        "",
        joinLabels(activity1SignalCards, " | "),
        "",
        "",
        "",
        "",
        activity1SignalResearchLabel(selected),
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        activity1SignalResearchDetails()
      );
    }
  }
}

void logActivity2StructuredResponses(){
  for(int c = 0; c < activity2Options.length; c++){
    boolean correct = activity2SelectedMasks[c] == (1 << activity2CorrectOption[c]);
    logStructuredResearchResponse(
      "activity2",
      "Atividade 2",
      "column_" + (c + 1),
      str(c + 1),
      "",
      activity2ColumnTitles[c],
      "relacao_comunicativa",
      "interpretation",
      activity2SelectedText(c),
      "",
      "",
      correct ? "" : activity2SelectedText(c),
      activity2CorrectText(c),
      "",
      boolText(correct),
      correct ? "correto" : "erro_resposta",
      "",
      "",
      joinLabels(activity2Options[c], " | "),
      "",
      "",
      "",
      "",
      activity2SelectedText(c),
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      activity2ResearchDetails()
    );
  }
}

String activity3GrowlRoleLabel(int roleIndex){
  if(roleIndex == 2) return "correto";
  if(roleIndex == 0) return "distrator plausivel";
  if(roleIndex == 1) return "distrator semelhante";
  return "distrator contrastante";
}

String activity3GrowlErrorType(int roleIndex){
  if(roleIndex == 2) return "correto";
  if(roleIndex == 1) return "erro_proximo";
  if(roleIndex == 0) return "erro_plausivel";
  return "erro_distante";
}

String activity3GrowlDistance(int roleIndex){
  if(roleIndex == 2) return "0";
  if(roleIndex == 1) return "1";
  if(roleIndex == 0) return "2";
  return "3";
}

String activity3GrowlClosestWrongAnswer(int scenarioIndex){
  for(int i = 0; i < 4; i++){
    if(activity3GrowlRoleForCard(scenarioIndex, i) == 1) return activity3GrowlLabels[i];
  }
  return "";
}

String activity3GrowlAvailableOptionsText(int scenarioIndex){
  String result = "";
  for(int i = 0; i < 4; i++){
    if(result.length() > 0) result += " | ";
    int role = activity3GrowlRoleForCard(scenarioIndex, i);
    result += activity3GrowlLabels[i] + "=" + activity3GrowlRoleLabel(role);
  }
  return result;
}

String activity3ResearchItemId(int scenarioIndex){
  if(scenarioIndex == 0) return "rosnado_ameaca_cenario_1";
  if(scenarioIndex == 1) return "rosnado_ameaca_cenario_2";
  if(scenarioIndex == 2) return "rosnado_guarda_alimento_cenario_1";
  if(scenarioIndex == 3) return "rosnado_guarda_alimento_cenario_2";
  if(scenarioIndex == 4) return "rosnado_ludico_cenario_1";
  if(scenarioIndex == 5) return "rosnado_ludico_cenario_2";
  return "rosnado_cenario_" + (scenarioIndex + 1);
}

void logActivity3GrowlStructuredResponse(){
  int scenarioIndex = activity3CurrentScenarioIndex();
  int selectedRole = activity3GrowlRoleForCard(scenarioIndex, activity3SelectedGrowl);
  int correctGrowl = activity3CurrentCorrectGrowl();
  boolean correct = activity3SelectedGrowl == correctGrowl;

  logStructuredResearchResponse(
    "activity3",
    "Atividade 3",
    activity3ResearchItemId(scenarioIndex),
    str(activity3SequencePosition + 1),
    "",
    activity3VideoFiles[scenarioIndex],
    "rosnado_contextual",
    "growl_choice",
    activity3GrowlLabels[activity3SelectedGrowl],
    activity3GrowlRoleLabel(selectedRole),
    activity3GrowlRoleLabel(selectedRole),
    correct ? "" : activity3GrowlLabels[activity3SelectedGrowl],
    activity3GrowlLabels[correctGrowl],
    "correto",
    boolText(correct),
    activity3GrowlErrorType(selectedRole),
    activity3GrowlDistance(selectedRole),
    activity3GrowlClosestWrongAnswer(scenarioIndex),
    activity3GrowlAvailableOptionsText(scenarioIndex),
    "",
    "",
    "",
    "",
    activity3GrowlLabels[activity3SelectedGrowl],
    "",
    str(activity3GrowlPlayCounts[scenarioIndex][activity3SelectedGrowl]),
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    activity3GrowlResearchDetails()
  );
}

void logActivity3JustificationStructuredResponses(){
  int scenarioIndex = activity3CurrentScenarioIndex();
  boolean soundCorrect = activity3SelectedSoundMask == activity3CorrectSoundMask();
  boolean behaviorCorrect = activity3SelectedBehavior == activity3CurrentCorrectBehavior();

  logStructuredResearchResponse(
    "activity3",
    "Atividade 3",
    activity3ResearchItemId(scenarioIndex),
    str(activity3SequencePosition + 1),
    "",
    activity3VideoFiles[scenarioIndex],
    "pistas_sonoras",
    "justification_sound_cues",
    activity3SelectedSoundSummary(),
    "",
    "",
    soundCorrect ? "" : activity3SelectedSoundSummary(),
    activity3CorrectSoundSummary(),
    "",
    boolText(soundCorrect),
    soundCorrect ? "correto" : "erro_pistas_sonoras",
    "",
    "",
    "",
    activity3SelectedSoundSummary(),
    joinLabels(activity3SoundClues, " | "),
    activity3CorrectSoundSummary(),
    "",
    activity3SelectedSoundSummary(),
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    soundCorrect ? "" : "pistas_sonoras_incorretas",
    activity3JustificationResearchDetails()
  );

  logStructuredResearchResponse(
    "activity3",
    "Atividade 3",
    activity3ResearchItemId(scenarioIndex),
    str(activity3SequencePosition + 1),
    "",
    activity3VideoFiles[scenarioIndex],
    "comportamento_provavel",
    "justification_behavior",
    activity3CurrentBehaviorLabel(activity3SelectedBehavior),
    "",
    "",
    behaviorCorrect ? "" : activity3CurrentBehaviorLabel(activity3SelectedBehavior),
    activity3CurrentCorrectBehaviorLabel(),
    "",
    boolText(behaviorCorrect),
    behaviorCorrect ? "correto" : "erro_comportamento_provavel",
    "",
    "",
    joinLabels(activity3CurrentBehaviorOptions(), " | "),
    "",
    "",
    "",
    "",
    activity3CurrentBehaviorLabel(activity3SelectedBehavior),
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    behaviorCorrect ? "" : "comportamento_provavel_incorreto",
    activity3JustificationResearchDetails()
  );
}

float interpretationTimeDistanceForMark(int behaviorIndex, int markIndex){
  float markedTime = interpretationMarkedTimes[behaviorIndex][markIndex];
  if(markedTime < 0) return -1;
  float startTime = correctInterpretationStartForMark(behaviorIndex, markIndex);
  float endTime = correctInterpretationEndForMark(behaviorIndex, markIndex);
  if(markedTime >= startTime && markedTime <= endTime) return 0;
  return min(abs(markedTime - startTime), abs(markedTime - endTime));
}

String activity4ResearchItemId(int behaviorIndex, int markIndex){
  if(behaviorIndex == 0) return "abaixamento_corporal";
  if(behaviorIndex == 1) return "afastamento";
  if(behaviorIndex == 2){
    if(markIndex == 0) return "desvio_olhar_primeira_marcacao";
    if(markIndex == 1) return "desvio_cabeca_segunda_marcacao";
    return "desvio_cabeca_olhar_marcacao_" + (markIndex + 1);
  }
  if(behaviorIndex == 3) return "levantamento_pata_dianteira";
  if(behaviorIndex == 4) return "recuo_corporal";
  return "comportamento_" + (behaviorIndex + 1) + "_marcacao_" + (markIndex + 1);
}

String activity4ErrorType(boolean timeCorrect, boolean behaviorCorrect){
  if(timeCorrect && behaviorCorrect) return "correto";
  if(!timeCorrect && behaviorCorrect) return "erro_tempo";
  if(timeCorrect && !behaviorCorrect) return "erro_comportamento";
  return "erro_tempo_e_comportamento";
}

void logActivity4StructuredResponses(){
  int required = requiredInterpretationMarkCount(screen);
  for(int i = 0; i < required; i++){
    boolean timeCorrect = interpretationTimeMatchesMark(screen, i);
    boolean behaviorCorrect = interpretationMarkedChoices[screen][i] == correctInterpretationChoiceForMark(screen, i);
    boolean correct = timeCorrect && behaviorCorrect;
    float distance = interpretationTimeDistanceForMark(screen, i);
    String selectedBehavior = interpretationChoiceLabel(interpretationMarkedChoices[screen][i]);
    String correctBehavior = interpretationChoiceLabel(correctInterpretationChoiceForMark(screen, i));

    logStructuredResearchResponse(
      "activity4",
      "Atividade 4",
      activity4ResearchItemId(screen, i),
      str(behaviorSequencePosition + 1),
      str(i + 1),
      titles[screen],
      "marcacao_video",
      "interpretation",
      selectedBehavior,
      "",
      "",
      behaviorCorrect ? "" : selectedBehavior,
      correctBehavior,
      "",
      boolText(correct),
      activity4ErrorType(timeCorrect, behaviorCorrect),
      "",
      "",
      correctInterpretationBehaviorsText(screen),
      "",
      "",
      "",
      "",
      selectedBehavior,
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      distance >= 0 ? nf2(distance) : "",
      "",
      correct ? "" : activity4ErrorType(timeCorrect, behaviorCorrect),
      "marked_time=" + (interpretationMarkedTimes[screen][i] >= 0 ? formatVideoTime(interpretationMarkedTimes[screen][i]) : "Por marcar") +
        ";correct_interval=" + formatVideoTime(correctInterpretationStartForMark(screen, i)) + "-" + formatVideoTime(correctInterpretationEndForMark(screen, i)) +
        ";time_ok=" + timeCorrect +
        ";behavior_ok=" + behaviorCorrect
    );
  }
}

void drawActivity3Prototype(){
  drawActivity1Header();

  if(activity3Step == 0){
    drawActivity3Observation();
    return;
  }

  if(activity3Step == 1){
    drawActivity3GrowlChoice();
    return;
  }

  if(activity3Step == 2){
    drawActivity3Justification();
    return;
  }

  drawActivity3Feedback();
}

void drawActivity3Observation(){
  drawActivity3Header(
    "Observa\u00e7\u00e3o",
    "Observa o rosnado no contexto",
    "V\u00ea o cen\u00e1rio completo antes de interpretares a correspond\u00eancia."
  );

  float videoW = baseW * 0.68;
  float videoH = baseH * 0.54;
  float videoX = (baseW - videoW) / 2;
  float videoY = 176;

  noStroke();
  fill(card);
  rect(videoX, videoY, videoW, videoH, 14);

  if(activity3CurrentVideoReady()){
    drawVideoFit(activity3Videos[activity3VideoIndex], videoX, videoY, videoW, videoH);
  } else {
    drawActivity3VideoUnavailableState(videoX, videoY, videoW, videoH);
  }

  drawObservationHapticTuningControls();
}

void drawActivity3VideoUnavailableState(float x, float y, float w, float h){
  fill(greyDark);
  rect(x, y, w, h, 14);

  String message = "A preparar v\u00eddeo";
  if(activity3FilesPrepared && !activity3MoviesPrepared){
    message = "A preparar reprodu\u00e7\u00e3o";
  }
  if(activity3FilesPrepared && activity3MoviesPrepared &&
     activity3PreparedVideoPaths[activity3VideoIndex] == null){
    message = "V\u00eddeo n\u00e3o encontrado";
  }

  fill(muted);
  textAlign(CENTER, CENTER);
  textSize(TYPE_LABEL);
  text(message, x + w / 2, y + h / 2);
}

void drawVideoUnavailableState(float x, float y, float w, float h, int videoIndex){
  noStroke();
  fill(greyDark);
  rect(x, y, w, h, 14);

  String message = "A preparar v\u00eddeo";
  if(videosLoaded && !videosLoading && preparedVideoPaths[videoIndex] == null){
    message = "V\u00eddeo n\u00e3o encontrado";
  } else if(videosLoaded && !moviesPrepared){
    message = "A preparar reprodu\u00e7\u00e3o";
  }

  fill(muted);
  textAlign(CENTER, CENTER);
  textSize(TYPE_LABEL);
  text(message, x + w / 2, y + h / 2);
}

void drawActivityObservationSlideshow(int activityIndex, float x, float y, float w, float h){
  int slideIndex = activityObservationSlideIndex(activityIndex);
  PImage slide = null;

  if(activityIndex >= 0 && activityIndex < activityObservationSlides.length &&
     slideIndex >= 0 && slideIndex < activityObservationSlides[activityIndex].length){
    slide = activityObservationSlides[activityIndex][slideIndex];
  }

  if(slide != null && slide.width > 0 && slide.height > 0){
    drawImageFit(slide, x, y, w, h);
  } else {
    fill(greyDark);
    rect(x, y, w, h, 14);
    fill(muted);
    textAlign(CENTER, CENTER);
    textSize(TYPE_LABEL);
    text("Imagem de observa\u00e7\u00e3o em prepara\u00e7\u00e3o", x + w / 2, y + h / 2);
  }

  float dotSpacing = 16;
  float dotsStartX = x + w / 2 - ((ACTIVITY_OBSERVATION_SLIDE_COUNT - 1) * dotSpacing) / 2;
  float dotsY = y + h + 22;
  for(int i = 0; i < ACTIVITY_OBSERVATION_SLIDE_COUNT; i++){
    if(i == slideIndex){
      fill(purple);
      ellipse(dotsStartX + i * dotSpacing, dotsY, 8, 8);
    } else {
      fill(grey);
      ellipse(dotsStartX + i * dotSpacing, dotsY, 6, 6);
    }
  }
}

void drawImageFit(PImage img, float x, float y, float w, float h){
  if(img == null || img.width <= 0 || img.height <= 0) return;

  float ir = (float)img.width / img.height;
  float br = w / h;
  float dw, dh;

  if(ir > br){
    dw = w;
    dh = w / ir;
  } else {
    dh = h;
    dw = h * ir;
  }

  image(img, x + (w - dw) / 2, y + (h - dh) / 2, dw, dh);
}

void drawActivity3GrowlChoice(){
  drawActivity3TaskHeader(
    "Constr\u00f3i a rela\u00e7\u00e3o comunicativa",
    "Ouve cada op\u00e7\u00e3o e escolhe o rosnado que mais se assemelha ao som ouvido no v\u00eddeo."
  );

  float activityMargin = 104;
  float gap = 18;
  float cardW = (baseW - activityMargin * 2 - gap * 3) / 4;
  float cardH = 260;
  float startX = activityMargin;
  float y = 204;

  for(int i = 0; i < 4; i++){
    float x = startX + i * (cardW + gap);
    activity3GrowlX[i] = x;
    activity3GrowlY[i] = y;
    activity3GrowlW[i] = cardW;
    activity3GrowlH[i] = cardH;
    drawActivity3GrowlCard(i, x, y, cardW, cardH);
  }

  activity3ConfirmW = 120;
  activity3ConfirmH = 38;
  activity3ConfirmX = baseW - activityMargin - activity3ConfirmW;
  activity3ConfirmY = 730;
  drawActionButton(activity3ConfirmX, activity3ConfirmY, activity3ConfirmW, activity3ConfirmH, "Confirmar", "next", true, activity3SelectedGrowl >= 0);
}

void drawActivity3GrowlCard(int index, float x, float y, float w, float h){
  boolean selected = activity3SelectedGrowl == index;
  boolean playing = activity3GrowlIsPlaying(index);
  float playCx = x + w / 2 - 24;
  float playCy = y + 172;
  activity3GrowlPlayX[index] = playCx - 22;
  activity3GrowlPlayY[index] = playCy - 22;
  activity3GrowlPlayW[index] = 44;
  activity3GrowlPlayH[index] = 44;
  boolean playHovered = inside(mouseXToInterface(), mouseYToInterface(), activity3GrowlPlayX[index], activity3GrowlPlayY[index], activity3GrowlPlayW[index], activity3GrowlPlayH[index]);

  noStroke();
  fill(card);
  rect(x, y, w, h, 8);
  stroke(selected ? purpleText : strokeC);
  strokeWeight(selected ? 1.8 : 1);
  noFill();
  rect(x, y, w, h, 8);
  noStroke();

  fill(white);
  textAlign(CENTER, TOP);
  textSize(TYPE_LABEL);
  text(activity3GrowlLabels[index], x + w / 2, y + 28);

  drawActivity3Waveform(x + w / 2, y + 102, w * 0.62, 58, index, playing);

  fill(playing || playHovered ? color(128, 91, 255) : purple);
  ellipse(playCx, playCy, 32, 32);
  fill(white);
  if(playing){
    rect(playCx - 7, playCy - 7, 14, 14, 2);
  } else {
    triangle(playCx - 5, playCy - 10, playCx - 5, playCy + 10, playCx + 11, playCy);
  }

  fill(white);
  textAlign(LEFT, CENTER);
  textSize(TYPE_LABEL);
  text(playing ? "Parar" : "Ouvir", x + w / 2, y + 172);

  noFill();
  stroke(selected ? purpleText : white);
  strokeWeight(1.2);
  ellipse(x + w / 2, y + h - 42, 24, 24);
  if(selected){
    noStroke();
    fill(purpleText);
    ellipse(x + w / 2, y + h - 42, 12, 12);
  }
  noStroke();
}

void drawActivity3Waveform(float cx, float cy, float w, float h, int variant, boolean animated){
  stroke(purpleText);
  strokeWeight(2);
  strokeCap(ROUND);

  int bars = 31;
  int scenarioIndex = activity3CurrentScenarioIndex();
  float[] envelope = activity3GrowlEnvelopeForCard(scenarioIndex, variant);

  for(int i = 0; i < bars; i++){
    float n = (float)i / (bars - 1);
    float x = cx - w / 2 + n * w;
    float amp = activity3WaveformBarAmplitude(envelope, scenarioIndex, variant, i, bars, h, animated);
    line(x, cy - amp / 2, x, cy + amp / 2);
  }
  noStroke();
}

float activity3WaveformBarAmplitude(float[] envelope, int scenarioIndex, int growlIndex, int barIndex, int barCount, float h, boolean animated){
  if(envelope == null || envelope.length == 0){
    float amp = (sin((barIndex + 1 + growlIndex) * 0.85) * 0.5 + 0.5) * h * 0.58 + h * 0.12;
    if(animated){
      float pulse = sin(millis() * 0.018 + barIndex * 0.72 + growlIndex);
      amp *= 0.78 + pulse * 0.26;
    }
    if(barIndex % 5 == 0) amp *= 1.25;
    return constrain(amp, h * 0.12, h * 0.95);
  }

  float samplePosition;
  if(animated && activity3PlayingGrowlScenario == scenarioIndex && activity3PlayingGrowlIndex == growlIndex && activity3PlayingGrowlStartedMillis > 0){
    int durationMs = activity3GrowlEnvelopeDurationsMs[scenarioIndex][growlIndex];
    float progress = durationMs > 0 ? constrain((millis() - activity3PlayingGrowlStartedMillis) / (float)durationMs, 0, 1) : 0;
    float center = progress * (envelope.length - 1);
    float window = max(4, envelope.length * 0.18);
    float offset = map(barIndex, 0, barCount - 1, -window * 0.5, window * 0.5);
    samplePosition = center + offset;
  } else {
    samplePosition = map(barIndex, 0, barCount - 1, 0, envelope.length - 1);
  }

  float loudness = activity3SampleEnvelope(envelope, samplePosition);
  float amp = h * 0.14 + loudness * h * 0.76;
  if(animated){
    amp *= 0.96 + sin(millis() * 0.012 + barIndex * 0.48) * 0.05;
  }
  if(barIndex == 0 || barIndex == barCount - 1) amp = max(amp, h * 0.78);
  return constrain(amp, h * 0.12, h * 0.96);
}

float activity3SampleEnvelope(float[] envelope, float position){
  if(envelope == null || envelope.length == 0) return 0;
  if(envelope.length == 1) return envelope[0];

  float safePosition = constrain(position, 0, envelope.length - 1);
  int left = floor(safePosition);
  int right = min(left + 1, envelope.length - 1);
  float amount = safePosition - left;
  return lerp(envelope[left], envelope[right], amount);
}

void drawActivity3Justification(){
  drawActivity3TaskHeader(
    "Justifica a correspond\u00eancia",
    "Arrasta para o centro os aspetos que tiveste em considera\u00e7\u00e3o para associar o rosnado \u00e0 situa\u00e7\u00e3o."
  );

  drawActivity3ChosenGrowlPanel();
  drawActivity3ConsideredPanel();
  drawActivity3BehaviorPanel();
  drawActivity3AvailableSoundPanel();
  drawActivity3AvailableBehaviorPanel();

  activity3ResetW = 110;
  activity3ResetH = 38;
  activity3ConfirmW = 120;
  activity3ConfirmH = 38;
  activity3ConfirmX = baseW - 104 - activity3ConfirmW;
  activity3ConfirmY = 730;
  activity3ResetX = activity3ConfirmX - activity3ResetW - 24;
  activity3ResetY = activity3ConfirmY;

  drawActionButton(activity3ResetX, activity3ResetY, activity3ResetW, activity3ResetH, "Refazer", "replay", false, true);
  drawActionButton(activity3ConfirmX, activity3ConfirmY, activity3ConfirmW, activity3ConfirmH, "Confirmar", "next", true, activity3CanConfirm());

  if(activity3Dragging){
    drawActivity3SmallChip(mouseXToInterface() - 88, mouseYToInterface() - 14, 176, 28, activity3DraggedLabel(), true);
  }
}

void drawActivity3TaskHeader(String title, String description){
  drawActivity3Header("Tarefa interpretativa", title, description);
}

void drawActivity3Header(String label, String title, String description){
  float activityMargin = 104;
  float dotSpacing = 14;
  float dotsTotal = ACTIVITY3_VIDEO_COUNT * dotSpacing;
  float dotsStartX = baseW - activityMargin - dotsTotal;
  float dotsY = 68;

  fill(muted);
  textAlign(RIGHT, CENTER);
  textSize(TYPE_CAPTION);
  text(label, dotsStartX - 72, dotsY);

  drawActivity3ScenarioProgressDots(dotsStartX, dotsY);

  fill(white);
  textAlign(RIGHT, TOP);
  textSize(TYPE_SECTION);
  text(title, baseW - activityMargin, 88);

  fill(muted);
  textSize(TYPE_BODY);
  text(description, baseW - activityMargin - 620, 132, 620, 62);
}

void drawActivity3ScenarioProgressDots(float dotsStartX, float dotsY){
  float dotSpacing = 14;
  int stepIndex = constrain(activity3SequencePosition, 0, ACTIVITY3_VIDEO_COUNT - 1);

  fill(white);
  textAlign(RIGHT, CENTER);
  textSize(TYPE_CAPTION);
  text((stepIndex + 1) + "/" + ACTIVITY3_VIDEO_COUNT, dotsStartX - 10, dotsY);

  for(int i = 0; i < ACTIVITY3_VIDEO_COUNT; i++){
    if(i == stepIndex){
      fill(purple);
      ellipse(dotsStartX + i * dotSpacing, dotsY, 8, 8);
    } else if(i < stepIndex){
      fill(purpleDim);
      ellipse(dotsStartX + i * dotSpacing, dotsY, 6, 6);
    } else {
      fill(color(210, 216, 226));
      ellipse(dotsStartX + i * dotSpacing, dotsY, 6, 6);
    }
  }
}

void drawActivity3ChosenGrowlPanel(){
  float x = 104;
  float y = 204;
  float w = 300;
  float h = 216;

  drawActivity3Panel(x, y, w, h, "Rosnado Escolhido");
  drawActivity3MiniGrowl(x + 48, y + 50, w - 96, h - 82, activity3SelectedGrowl);
}

void drawActivity3MiniGrowl(float x, float y, float w, float h, int growlIndex){
  int safeGrowlIndex = max(0, growlIndex);
  boolean playing = growlIndex >= 0 && activity3GrowlIsPlaying(growlIndex);
  float playCx = x + w / 2 - 32;
  float playCy = y + 108;
  activity3ChosenGrowlPlayX = playCx - 22;
  activity3ChosenGrowlPlayY = playCy - 22;
  activity3ChosenGrowlPlayW = 176;
  activity3ChosenGrowlPlayH = 44;
  boolean playHovered = inside(mouseXToInterface(), mouseYToInterface(), activity3ChosenGrowlPlayX, activity3ChosenGrowlPlayY, activity3ChosenGrowlPlayW, activity3ChosenGrowlPlayH);

  noStroke();
  fill(cardAlt);
  rect(x, y, w, h, 8);

  fill(white);
  textAlign(CENTER, TOP);
  textSize(TYPE_CAPTION);
  text(activity3GrowlLabels[safeGrowlIndex], x + w / 2, y + 18);

  drawActivity3Waveform(x + w / 2, y + 64, w * 0.58, 42, safeGrowlIndex, playing);

  fill(playing || playHovered ? color(128, 91, 255) : purple);
  ellipse(playCx, playCy, 24, 24);
  fill(white);
  if(playing){
    rect(playCx - 5, playCy - 5, 10, 10, 2);
  } else {
    triangle(playCx - 4, playCy - 8, playCx - 4, playCy + 8, playCx + 8, playCy);
  }
  fill(white);
  textAlign(LEFT, CENTER);
  textSize(TYPE_CAPTION);
  text(playing ? "Parar" : "Ouvir novamente", x + w / 2 - 12, y + 108);
}

void drawActivity3ConsideredPanel(){
  float x = 430;
  float y = 204;
  float w = 526;
  float h = 216;
  drawActivity3Panel(x, y, w, h, "Pistas Sonoras Consideradas");

  activity3SoundDropX = x + 18;
  activity3SoundDropY = y + 42;
  activity3SoundDropW = w - 36;
  activity3SoundDropH = h - 54;

  int[] selected = activity3SelectedSoundIndices();
  float chipW = 240;
  float chipH = 25;
  int visibleSelected = min(selected.length, 10);
  for(int i = 0; i < visibleSelected; i++){
    int col = i % 2;
    int row = i / 2;
    float cx = x + 18 + col * (chipW + 10);
    float cy = y + 48 + row * (chipH + 7);
    drawActivity3SmallChip(cx, cy, chipW, chipH, activity3SoundClues[selected[i]], true);
  }

  if(visibleSelected < 10){
    int placeholderIndex = visibleSelected;
    int col = placeholderIndex % 2;
    int row = placeholderIndex / 2;
    float cx = x + 18 + col * (chipW + 10);
    float cy = y + 48 + row * (chipH + 7);
    drawActivity3SmallChip(cx, cy, chipW, chipH, "+  Arrasta para aqui", false);
  }
}

void drawActivity3BehaviorPanel(){
  float x = 982;
  float y = 204;
  float w = 336;
  float h = 216;
  drawActivity3Panel(x, y, w, h, "Comportamento Prov\u00e1vel");
  activity3BehaviorDropX = x + 48;
  activity3BehaviorDropY = y + 42;
  activity3BehaviorDropW = w - 96;
  activity3BehaviorDropH = 42;
  String label = activity3SelectedBehavior >= 0 ? activity3CurrentBehaviorLabel(activity3SelectedBehavior) : "+  Seleciona comportamento";
  drawActivity3SmallChip(x + 48, y + 46, w - 96, 28, label, activity3SelectedBehavior >= 0);
}

void drawActivity3AvailableSoundPanel(){
  float x = 104;
  float y = 444;
  float w = 852;
  float h = 212;
  drawActivity3Panel(x, y, w, h, "Pistas Sonoras Dispon\u00edveis");

  float chipW = 236;
  float chipH = 28;
  float gapX = 24;
  float gapY = 8;
  for(int i = 0; i < activity3SoundClues.length; i++){
    int col = i % 3;
    int row = i / 3;
    float cx = x + 56 + col * (chipW + gapX);
    float cy = y + 50 + row * (chipH + gapY);
    activity3SoundX[i] = cx;
    activity3SoundY[i] = cy;
    activity3SoundW[i] = chipW;
    activity3SoundH[i] = chipH;
    boolean selected = (activity3SelectedSoundMask & (1 << i)) != 0;
    drawActivity3SmallChip(cx, cy, chipW, chipH, activity3SoundClues[i], selected);
  }
}

void drawActivity3AvailableBehaviorPanel(){
  float x = 982;
  float y = 444;
  float w = 336;
  float h = 212;
  drawActivity3Panel(x, y, w, h, "Comportamentos dispon\u00edveis");

  float chipW = w - 88;
  float chipH = 28;
  String[] behaviorOptions = activity3CurrentBehaviorOptions();
  for(int i = 0; i < behaviorOptions.length; i++){
    float cy = y + 50 + i * 36;
    activity3BehaviorX[i] = x + 44;
    activity3BehaviorY[i] = cy;
    activity3BehaviorW[i] = chipW;
    activity3BehaviorH[i] = chipH;
    drawActivity3SmallChip(x + 44, cy, chipW, chipH, behaviorOptions[i], activity3SelectedBehavior == i);
  }
}

void drawActivity3Panel(float x, float y, float w, float h, String title){
  noStroke();
  fill(card);
  rect(x, y, w, h, 8);
  stroke(color(52, 67, 96));
  strokeWeight(1.1);
  noFill();
  rect(x, y, w, h, 8);
  noStroke();

  fill(white);
  textAlign(CENTER, TOP);
  textSize(TYPE_LABEL);
  text(title, x + w / 2, y + 14);
}

void drawActivity3SmallChip(float x, float y, float w, float h, String label, boolean selected){
  noStroke();
  fill(selected ? color(35, 28, 82) : cardAlt);
  rect(x, y, w, h, 4);
  stroke(selected ? purpleText : strokeC);
  strokeWeight(selected ? 1.25 : 0.9);
  noFill();
  rect(x, y, w, h, 4);
  noStroke();

  fill(selected ? white : muted);
  boolean hasGrip = !label.startsWith("+");
  float labelSize = TYPE_CAPTION;
  float labelMaxW = hasGrip ? w - 58 : w - 18;
  textSize(labelSize);
  while(textWidth(label) > labelMaxW && labelSize > 8){
    labelSize -= 0.5;
    textSize(labelSize);
  }
  textAlign(CENTER, CENTER);

  if(hasGrip){
    drawActivity1CardGrip(x + 24, y + h / 2, 7, purpleText);
    fill(selected ? white : muted);
    text(label, x + 38, y, w - 46, h - 1);
  } else {
    text(label, x + 9, y, w - 18, h - 1);
  }
}

void drawActivity3Feedback(){
  float activityMargin = 104;
  drawActivity3Header(
    "Feedback",
    "Feedback do cen\u00e1rio",
    "Compara a tua interpreta\u00e7\u00e3o com a correspond\u00eancia esperada."
  );

  float startX = activityMargin;
  float contentW = baseW - activityMargin * 2;
  float gap = 24;
  float growlW = 190;
  float behaviorW = 338;
  float soundW = contentW - growlW - behaviorW - gap * 2;
  float blockH = 82;
  float userY = 190;
  float correctY = 318;

  fill(white);
  textAlign(LEFT, BOTTOM);
  textSize(TYPE_BODY);
  text("A tua interpreta\u00e7\u00e3o", startX, userY - 24);
  text("Interpreta\u00e7\u00e3o da atividade", startX, correctY - 24);

  String[] fieldLabels = {
    "Rosnado",
    "Pistas sonoras",
    "Comportamento"
  };

  String[] userBlocks = {
    activity3SelectedGrowl >= 0 ? activity3GrowlLabels[activity3SelectedGrowl] : "Por selecionar",
    activity3SelectedSoundSummary(),
    activity3SelectedBehavior >= 0 ? activity3CurrentBehaviorLabel(activity3SelectedBehavior) : "Por selecionar"
  };
  String[] correctBlocks = {
    activity3GrowlLabels[activity3CurrentCorrectGrowl()],
    activity3CorrectSoundSummary(),
    activity3CurrentCorrectBehaviorLabel()
  };
  float[] blockWidths = {growlW, soundW, behaviorW};

  float x = startX;
  for(int i = 0; i < 3; i++){
    drawActivity3ComparisonBlock(x, userY, blockWidths[i], blockH, fieldLabels[i], userBlocks[i], purpleText);
    drawActivity3ComparisonBlock(x, correctY, blockWidths[i], blockH, fieldLabels[i], correctBlocks[i], color(0, 220, 125));
    x += blockWidths[i] + gap;
  }

  drawActivity3FeedbackExplanation();

  activity3ResetW = 110;
  activity3ResetH = 38;
  activity3ConfirmW = 120;
  activity3ConfirmH = 38;
  activity3ConfirmX = baseW - activityMargin - activity3ConfirmW;
  activity3ConfirmY = 710;
  activity3ResetX = activity3ConfirmX - activity3ResetW - 24;
  activity3ResetY = activity3ConfirmY;
  String confirmLabel = !onLastActivity3Step() ? "Seguinte" : "Confirmar";
  drawActionButton(activity3ResetX, activity3ResetY, activity3ResetW, activity3ResetH, "Refazer", "replay", false, true);
  drawActionButton(activity3ConfirmX, activity3ConfirmY, activity3ConfirmW, activity3ConfirmH, confirmLabel, "next", true, true);
}

void drawActivity3ComparisonBlock(float x, float y, float w, float h, String title, String value, color borderColor){
  noStroke();
  fill(cardAlt);
  rect(x, y, w, h, 8);
  stroke(borderColor);
  strokeWeight(1.6);
  noFill();
  rect(x, y, w, h, 8);
  noStroke();

  fill(muted);
  textAlign(LEFT, TOP);
  textSize(TYPE_CAPTION);
  text(title, x + 18, y + 12);

  fill(white);
  textSize(TYPE_LABEL);
  textLeading(LEADING_COMPACT);
  text(value, x + 18, y + 34, w - 36, h - 42);
  textLeading(LEADING_COMPACT);
}

void drawActivity3FeedbackExplanation(){
  float x = 104;
  float y = 432;
  float w = baseW - 208;
  float h = 240;

  noStroke();
  fill(card);
  rect(x, y, w, h, 8);

  fill(purpleText);
  drawBookIcon(x + 34, y + 34, 18, purpleText);

  fill(white);
  textAlign(LEFT, TOP);
  textSize(TYPE_BODY);
  text("Sobre esta correspond\u00eancia", x + 70, y + 26);

  fill(muted);
  textSize(TYPE_BODY);
  text(activity3CurrentFeedbackExplanation(), x + 70, y + 62, w - 100, h - 82);
}

boolean activity3CanConfirm(){
  if(activity3Step == 1) return activity3SelectedGrowl >= 0;
  if(activity3Step == 2) return activity3SelectedSoundMask != 0 && activity3SelectedBehavior >= 0;
  return true;
}

String activity3GrowlOptionCode(int index){
  if(index == 0) return "A";
  if(index == 1) return "B";
  if(index == 2) return "C";
  return "D";
}

String activity3GrowlSoundPath(int scenarioIndex, int growlIndex){
  if(scenarioIndex < 0 || scenarioIndex >= ACTIVITY3_VIDEO_COUNT || growlIndex < 0 || growlIndex >= 4) return null;
  if(activity3GrowlResolvedSoundPaths[scenarioIndex][growlIndex] != null) return activity3GrowlResolvedSoundPaths[scenarioIndex][growlIndex];

  int roleIndex = activity3GrowlRoleForCard(scenarioIndex, growlIndex);
  String folder = "activity3/growls/scenario" + (scenarioIndex + 1);
  String code = activity3GrowlOptionCode(roleIndex);
  String[] extensions = {"mp3", "wav", "aiff", "ogg", "m4a"};

  for(int i = 0; i < extensions.length; i++){
    String candidate = folder + "/rosnado_" + code + "." + extensions[i];
    File soundFile = new File(dataPath(candidate));
    if(soundFile.exists()){
      activity3GrowlResolvedSoundPaths[scenarioIndex][growlIndex] = soundFile.getAbsolutePath();
      return activity3GrowlResolvedSoundPaths[scenarioIndex][growlIndex];
    }
  }

  File descriptiveFolder = activity3DescriptiveGrowlFolder(scenarioIndex);
  if(descriptiveFolder != null){
    File mappedFile = activity3FindDescriptiveGrowlFile(descriptiveFolder, scenarioIndex, roleIndex);
    if(mappedFile != null){
      activity3GrowlResolvedSoundPaths[scenarioIndex][growlIndex] = mappedFile.getAbsolutePath();
      return activity3GrowlResolvedSoundPaths[scenarioIndex][growlIndex];
    }
  }

  return null;
}

int activity3GrowlRoleForCard(int scenarioIndex, int cardIndex){
  scenarioIndex = constrain(scenarioIndex, 0, ACTIVITY3_VIDEO_COUNT - 1);
  cardIndex = constrain(cardIndex, 0, 3);
  return activity3GrowlCardRolesByScenario[scenarioIndex][cardIndex];
}

int activity3CardForGrowlRole(int scenarioIndex, int roleIndex){
  scenarioIndex = constrain(scenarioIndex, 0, ACTIVITY3_VIDEO_COUNT - 1);
  for(int i = 0; i < 4; i++){
    if(activity3GrowlCardRolesByScenario[scenarioIndex][i] == roleIndex) return i;
  }
  return 2;
}

File activity3DescriptiveGrowlFolder(int scenarioIndex){
  String basePath = dataPath("activity3/sons rosnado");
  File baseFolder = new File(basePath);
  if(!baseFolder.exists() || !baseFolder.isDirectory()) return null;

  String[] keywords = activity3DescriptiveFolderKeywords(scenarioIndex);
  File[] folders = baseFolder.listFiles();
  if(folders == null) return null;

  for(int i = 0; i < folders.length; i++){
    if(!folders[i].isDirectory()) continue;
    String normalizedName = activity3NormalizeSoundName(folders[i].getName());
    boolean match = true;
    for(int k = 0; k < keywords.length; k++){
      if(!normalizedName.contains(keywords[k])){
        match = false;
        break;
      }
    }
    if(match) return folders[i];
  }

  return null;
}

String[] activity3DescriptiveFolderKeywords(int scenarioIndex){
  if(scenarioIndex == 0) return new String[]{"ameaca", "cenario 1"};
  if(scenarioIndex == 1) return new String[]{"ameaca", "cenario 2"};
  if(scenarioIndex == 2) return new String[]{"guarda", "alimento", "cenario 1"};
  if(scenarioIndex == 3) return new String[]{"guarda", "alimento", "cenario 2"};
  if(scenarioIndex == 4) return new String[]{"ludico", "cenario 1"};
  return new String[]{"ludico", "cenario 2"};
}

File activity3FindDescriptiveGrowlFile(File folder, int scenarioIndex, int growlIndex){
  File[] files = folder.listFiles();
  if(files == null) return null;

  File mapped = activity3FindAudioFileByAllKeywords(files, activity3DescriptiveFileKeywords(scenarioIndex, growlIndex));
  if(mapped != null) return mapped;

  if(growlIndex == 2) return activity3FindAudioFileByKeywords(files, new String[]{"correto"});

  int fallbackTarget = growlIndex == 3 ? 2 : growlIndex;
  int fallbackIndex = 0;
  for(int i = 0; i < files.length; i++){
    if(!activity3IsAudioFile(files[i])) continue;
    if(activity3NormalizeSoundName(files[i].getName()).contains("correto")) continue;
    if(fallbackIndex == fallbackTarget) return files[i];
    fallbackIndex++;
  }

  return null;
}

String[] activity3DescriptiveFileKeywords(int scenarioIndex, int growlIndex){
  if(growlIndex == 2) return new String[]{"correto"};

  if(scenarioIndex == 0){
    if(growlIndex == 0) return new String[]{"desconforto"};
    if(growlIndex == 1) return new String[]{"protecao", "recurso"};
    return new String[]{"diferente", "brincadeira"};
  }

  if(scenarioIndex == 1){
    if(growlIndex == 0) return new String[]{"inseguranca"};
    if(growlIndex == 1) return new String[]{"protecao", "recurso"};
    return new String[]{"brincadeira"};
  }

  if(scenarioIndex == 2){
    if(growlIndex == 0) return new String[]{"aviso", "geral"};
    if(growlIndex == 1) return new String[]{"desconforto"};
    return new String[]{"diferente", "dor"};
  }

  if(scenarioIndex == 3){
    if(growlIndex == 0) return new String[]{"aviso", "geral"};
    if(growlIndex == 1) return new String[]{"ameaca", "social"};
    return new String[]{"diferente", "desconforto"};
  }

  if(scenarioIndex == 4){
    if(growlIndex == 0) return new String[]{"frustracao"};
    if(growlIndex == 1) return new String[]{"protecao", "comida"};
    return new String[]{"aviso"};
  }

  if(growlIndex == 0) return new String[]{"excitacao"};
  if(growlIndex == 1) return new String[]{"guarda", "recurso"};
  return new String[]{"aviso", "leve"};
}

File activity3FindAudioFileByAllKeywords(File[] files, String[] keywords){
  for(int i = 0; i < files.length; i++){
    if(!activity3IsAudioFile(files[i])) continue;
    String normalizedName = activity3NormalizeSoundName(files[i].getName());
    boolean match = true;
    for(int k = 0; k < keywords.length; k++){
      if(!normalizedName.contains(keywords[k])){
        match = false;
        break;
      }
    }
    if(match) return files[i];
  }
  return null;
}

File activity3FindAudioFileByKeywords(File[] files, String[] keywords){
  for(int i = 0; i < files.length; i++){
    if(!activity3IsAudioFile(files[i])) continue;
    String normalizedName = activity3NormalizeSoundName(files[i].getName());
    for(int k = 0; k < keywords.length; k++){
      if(normalizedName.contains(keywords[k])) return files[i];
    }
  }
  return null;
}

boolean activity3IsAudioFile(File file){
  if(file == null || !file.isFile()) return false;
  String normalizedName = activity3NormalizeSoundName(file.getName());
  return normalizedName.endsWith(".mp3") ||
    normalizedName.endsWith(".wav") ||
    normalizedName.endsWith(".aiff") ||
    normalizedName.endsWith(".ogg") ||
    normalizedName.endsWith(".m4a");
}

String activity3NormalizeSoundName(String value){
  String normalized = value.toLowerCase();
  normalized = normalized.replace("\u00e1", "a").replace("\u00e0", "a").replace("\u00e2", "a").replace("\u00e3", "a");
  normalized = normalized.replace("\u00e9", "e").replace("\u00ea", "e");
  normalized = normalized.replace("\u00ed", "i");
  normalized = normalized.replace("\u00f3", "o").replace("\u00f4", "o").replace("\u00f5", "o");
  normalized = normalized.replace("\u00fa", "u");
  normalized = normalized.replace("\u00e7", "c");
  return normalized;
}

float[] activity3GrowlEnvelopeForCard(int scenarioIndex, int growlIndex){
  if(scenarioIndex < 0 || scenarioIndex >= ACTIVITY3_VIDEO_COUNT || growlIndex < 0 || growlIndex >= 4) return null;

  String soundPath = activity3GrowlSoundPath(scenarioIndex, growlIndex);
  if(soundPath == null) return null;

  if(activity3GrowlAmplitudeEnvelopes[scenarioIndex][growlIndex] == null ||
     !soundPath.equals(activity3GrowlEnvelopeLoadedPaths[scenarioIndex][growlIndex])){
    activity3GrowlAmplitudeEnvelopes[scenarioIndex][growlIndex] = activity3BuildWavAmplitudeEnvelope(soundPath, scenarioIndex, growlIndex, 96);
    activity3GrowlEnvelopeLoadedPaths[scenarioIndex][growlIndex] = soundPath;
  }

  return activity3GrowlAmplitudeEnvelopes[scenarioIndex][growlIndex];
}

float[] activity3BuildWavAmplitudeEnvelope(String soundPath, int scenarioIndex, int growlIndex, int envelopeSize){
  activity3GrowlEnvelopeDurationsMs[scenarioIndex][growlIndex] = 0;

  String lowerPath = soundPath.toLowerCase();
  if(!lowerPath.endsWith(".wav")){
    return null;
  }

  try {
    byte[] bytes = Files.readAllBytes(new File(soundPath).toPath());
    if(bytes.length < 44 || !activity3ReadAscii4(bytes, 0).equals("RIFF") || !activity3ReadAscii4(bytes, 8).equals("WAVE")){
      return null;
    }

    int audioFormat = 0;
    int channels = 0;
    int sampleRate = 0;
    int bitsPerSample = 0;
    int dataStart = -1;
    int dataSize = 0;
    int offset = 12;

    while(offset + 8 <= bytes.length){
      String chunkId = activity3ReadAscii4(bytes, offset);
      int chunkSize = activity3ReadLE32(bytes, offset + 4);
      int chunkDataStart = offset + 8;
      if(chunkSize < 0 || chunkDataStart + chunkSize > bytes.length) break;

      if(chunkId.equals("fmt ") && chunkSize >= 16){
        audioFormat = activity3ReadLE16(bytes, chunkDataStart);
        channels = activity3ReadLE16(bytes, chunkDataStart + 2);
        sampleRate = activity3ReadLE32(bytes, chunkDataStart + 4);
        bitsPerSample = activity3ReadLE16(bytes, chunkDataStart + 14);
      } else if(chunkId.equals("data")){
        dataStart = chunkDataStart;
        dataSize = chunkSize;
      }

      offset = chunkDataStart + chunkSize + (chunkSize % 2);
    }

    if(audioFormat != 1 || channels <= 0 || sampleRate <= 0 || dataStart < 0 || dataSize <= 0) return null;

    int bytesPerSample = bitsPerSample / 8;
    if(bytesPerSample <= 0 || bitsPerSample < 8 || bitsPerSample > 32) return null;

    int frameSize = channels * bytesPerSample;
    int totalFrames = dataSize / frameSize;
    if(totalFrames <= 0) return null;

    activity3GrowlEnvelopeDurationsMs[scenarioIndex][growlIndex] = round(totalFrames * 1000.0f / sampleRate);

    float[] envelope = new float[envelopeSize];
    int framesPerBucket = max(1, totalFrames / envelopeSize);
    float maxValue = 0.0001f;

    for(int bucket = 0; bucket < envelopeSize; bucket++){
      int startFrame = bucket * totalFrames / envelopeSize;
      int endFrame = min(totalFrames, startFrame + framesPerBucket);
      float sum = 0;
      int sampleCount = 0;

      for(int frame = startFrame; frame < endFrame; frame++){
        int frameOffset = dataStart + frame * frameSize;
        for(int channel = 0; channel < channels; channel++){
          int sampleOffset = frameOffset + channel * bytesPerSample;
          float sample = activity3ReadPcmSample(bytes, sampleOffset, bitsPerSample);
          sum += sample * sample;
          sampleCount++;
        }
      }

      float value = sampleCount > 0 ? sqrt(sum / sampleCount) : 0;
      envelope[bucket] = value;
      maxValue = max(maxValue, value);
    }

    for(int i = 0; i < envelope.length; i++){
      envelope[i] = sqrt(constrain(envelope[i] / maxValue, 0, 1));
    }

    return envelope;
  } catch(Exception e){
    println("Nao foi possivel ler a forma do rosnado: " + e.getMessage());
    return null;
  }
}

String activity3ReadAscii4(byte[] bytes, int offset){
  if(offset < 0 || offset + 4 > bytes.length) return "";
  return "" + (char)(bytes[offset] & 0xff) + (char)(bytes[offset + 1] & 0xff) + (char)(bytes[offset + 2] & 0xff) + (char)(bytes[offset + 3] & 0xff);
}

int activity3ReadLE16(byte[] bytes, int offset){
  if(offset < 0 || offset + 2 > bytes.length) return 0;
  return (bytes[offset] & 0xff) | ((bytes[offset + 1] & 0xff) << 8);
}

int activity3ReadLE32(byte[] bytes, int offset){
  if(offset < 0 || offset + 4 > bytes.length) return 0;
  return (bytes[offset] & 0xff) |
         ((bytes[offset + 1] & 0xff) << 8) |
         ((bytes[offset + 2] & 0xff) << 16) |
         ((bytes[offset + 3] & 0xff) << 24);
}

float activity3ReadPcmSample(byte[] bytes, int offset, int bitsPerSample){
  if(offset < 0 || offset + bitsPerSample / 8 > bytes.length) return 0;

  if(bitsPerSample == 8){
    return ((bytes[offset] & 0xff) - 128) / 128.0f;
  }

  if(bitsPerSample == 16){
    int value = activity3ReadLE16(bytes, offset);
    if(value >= 32768) value -= 65536;
    return value / 32768.0f;
  }

  if(bitsPerSample == 24){
    int value = (bytes[offset] & 0xff) | ((bytes[offset + 1] & 0xff) << 8) | ((bytes[offset + 2] & 0xff) << 16);
    if((value & 0x800000) != 0) value |= 0xff000000;
    return value / 8388608.0f;
  }

  if(bitsPerSample == 32){
    int value = activity3ReadLE32(bytes, offset);
    return value / 2147483648.0f;
  }

  return 0;
}

boolean activity3GrowlIsPlaying(int growlIndex){
  int scenarioIndex = activity3CurrentScenarioIndex();
  if(activity3PlayingGrowlScenario != scenarioIndex || activity3PlayingGrowlIndex != growlIndex) return false;

  int durationMs = activity3GrowlEnvelopeDurationsMs[scenarioIndex][growlIndex];
  int stopAfterMs = durationMs > 0 ? durationMs + 250 : 6500;
  if(activity3PlayingGrowlStartedMillis > 0 && millis() - activity3PlayingGrowlStartedMillis > stopAfterMs){
    clearActivity3GrowlPlaybackState();
    return false;
  }

  return true;
}

void clearActivity3GrowlPlaybackState(){
  activity3PlayingGrowlScenario = -1;
  activity3PlayingGrowlIndex = -1;
  activity3PlayingGrowlStartedMillis = -1;
}

void playActivity3GrowlSound(int growlIndex){
  int scenarioIndex = activity3CurrentScenarioIndex();
  if(growlIndex < 0 || growlIndex >= 4) return;

  if(unisensoryMode){
    stopActivity3GrowlSounds();
    println("Som de rosnado desativado na condicao unissensorial.");
    return;
  }

  String soundPath = activity3GrowlSoundPath(scenarioIndex, growlIndex);
  if(soundPath == null){
    println("Som da Atividade 3 ainda nao encontrado: scenario" + (scenarioIndex + 1) + " / rosnado " + activity3GrowlOptionCode(growlIndex));
    return;
  }

  stopActivity3GrowlSounds();

  try {
    if(activity3GrowlAudioClips[scenarioIndex][growlIndex] == null ||
       !soundPath.equals(activity3GrowlAudioLoadedPaths[scenarioIndex][growlIndex])){
      clearActivity3GrowlAudioClip(scenarioIndex, growlIndex);
      URL soundUrl = new File(soundPath).toURI().toURL();
      activity3GrowlAudioClips[scenarioIndex][growlIndex] = Applet.newAudioClip(soundUrl);
      activity3GrowlAudioLoadedPaths[scenarioIndex][growlIndex] = soundPath;
    }

    AudioClip growlAudio = activity3GrowlAudioClips[scenarioIndex][growlIndex];
    growlAudio.stop();
    growlAudio.play();

    activity3PlayingGrowlScenario = scenarioIndex;
    activity3PlayingGrowlIndex = growlIndex;
    activity3PlayingGrowlStartedMillis = millis();
    activity3GrowlPlayCounts[scenarioIndex][growlIndex]++;
    logResearchEvent("activity3_growl_sound_play", "activity3", "growl_choice", scenarioIndex, "growl=" + activity3GrowlLabels[growlIndex] + ";role=" + activity3GrowlRoleForCard(scenarioIndex, growlIndex) + ";file=" + soundPath);
  } catch(Exception e){
    clearActivity3GrowlPlaybackState();
    println("Erro ao reproduzir rosnado da Atividade 3: " + e.getMessage());
  }
}

void toggleActivity3GrowlSound(int growlIndex){
  int scenarioIndex = activity3CurrentScenarioIndex();
  if(growlIndex < 0 || growlIndex >= 4) return;

  if(activity3GrowlIsPlaying(growlIndex)){
    stopActivity3GrowlSounds();
    logResearchEvent("activity3_growl_sound_stop", "activity3", "growl_choice", scenarioIndex, "growl=" + activity3GrowlLabels[growlIndex] + ";role=" + activity3GrowlRoleForCard(scenarioIndex, growlIndex));
    return;
  }

  playActivity3GrowlSound(growlIndex);
}

void stopActivity3GrowlSounds(){
  for(int scenario = 0; scenario < activity3GrowlAudioClips.length; scenario++){
    for(int i = 0; i < activity3GrowlAudioClips[scenario].length; i++){
      if(activity3GrowlAudioClips[scenario][i] == null) continue;

      try {
        activity3GrowlAudioClips[scenario][i].stop();
      } catch(Exception ignored){}
    }
  }

  for(int scenario = 0; scenario < activity3GrowlSounds.length; scenario++){
    for(int i = 0; i < activity3GrowlSounds[scenario].length; i++){
      if(activity3GrowlSounds[scenario][i] == null) continue;

      try {
        activity3GrowlSounds[scenario][i].pause();
      } catch(Exception ignored){}
    }
  }

  clearActivity3GrowlPlaybackState();
}

void clearActivity3GrowlAudioClip(int scenarioIndex, int growlIndex){
  if(activity3GrowlAudioClips[scenarioIndex][growlIndex] != null){
    try {
      activity3GrowlAudioClips[scenarioIndex][growlIndex].stop();
    } catch(Exception ignored){}
  }
  activity3GrowlAudioClips[scenarioIndex][growlIndex] = null;
  activity3GrowlAudioLoadedPaths[scenarioIndex][growlIndex] = null;
}

void resetActivity3Justification(){
  activity3SelectedSoundMask = 0;
  activity3SelectedBehavior = -1;
  activity3Dragging = false;
  activity3DragKind = 0;
  activity3DragValue = -1;
}

void resetActivity3VideoWatchdog(){
  activity3VideoWatchdogIndex = activity3VideoIndex;
  activity3VideoWatchdogLastTime = -1;
  activity3VideoWatchdogLastProgressMillis = millis();
}

void resetActivity3All(){
  activity3SelectedGrowl = -1;
  activity3VideoStartMillis = 0;
  resetActivity3VideoWatchdog();
  for(int i = 0; i < activity3VideoRestartAttempts.length; i++){
    activity3VideoRestartAttempts[i] = 0;
  }
  resetActivity3Justification();
}

void confirmActivity3Step(){
  if(activity3Step == 0){
    if(canAdvanceActivity3Observation()){
      logResearchEvent("activity_observation_confirm", "activity3", "observation", activity3CurrentScenarioIndex(), activity3ScenarioResearchDetails());
      advanceActivity3Observation();
    }
    return;
  }

  if(activity3Step == 1){
    if(!activity3CanConfirm()) return;
    logResearchEvent("activity_response_confirm", "activity3", "growl_choice", activity3CurrentScenarioIndex(), activity3GrowlResearchDetails());
    logActivity3GrowlStructuredResponse();
    stopActivity3GrowlSounds();
    activity3Step = 2;
    return;
  }

  if(activity3Step == 2){
    if(!activity3CanConfirm()) return;
    logResearchEvent("activity_response_confirm", "activity3", "justification", activity3CurrentScenarioIndex(), activity3JustificationResearchDetails());
    logActivity3JustificationStructuredResponses();
    activity3Step = 3;
    return;
  }

  logResearchEvent("activity_feedback_confirm", "activity3", "feedback", activity3CurrentScenarioIndex(), activity3ScenarioResearchDetails());
  advanceActivity3AfterFeedback();
}

void enterActivity3GrowlChoice(){
  stopAllVideos();
  stopActivity3GrowlSounds();
  stopBHapticsVibration();
  clearInterpretationSeek();
  activity3ObservationFinishedMillis = -1;
  activity3VideoStarted = false;
  resetActivity3VideoWatchdog();
  replayVibrationActive = false;
  activity3Step = 1;
}

void toggleActivity3SoundClue(int index){
  activity3SelectedSoundMask ^= (1 << index);
}

String activity3DraggedLabel(){
  if(activity3DragKind == 1) return activity3SoundClues[activity3DragValue];
  if(activity3DragKind == 2) return activity3CurrentBehaviorLabel(activity3DragValue);
  return "";
}

void startActivity3Drag(float mx, float my){
  if(activity3Step != 2) return;

  for(int i = 0; i < activity3SoundClues.length; i++){
    if(inside(mx, my, activity3SoundX[i], activity3SoundY[i], activity3SoundW[i], activity3SoundH[i])){
      activity3Dragging = true;
      activity3DragKind = 1;
      activity3DragValue = i;
      return;
    }
  }

  String[] behaviorOptions = activity3CurrentBehaviorOptions();
  for(int i = 0; i < behaviorOptions.length; i++){
    if(inside(mx, my, activity3BehaviorX[i], activity3BehaviorY[i], activity3BehaviorW[i], activity3BehaviorH[i])){
      activity3Dragging = true;
      activity3DragKind = 2;
      activity3DragValue = i;
      return;
    }
  }
}

void finishActivity3Drag(float mx, float my){
  if(!activity3Dragging) return;

  if(activity3DragKind == 1 && inside(mx, my, activity3SoundDropX, activity3SoundDropY, activity3SoundDropW, activity3SoundDropH)){
    activity3SelectedSoundMask |= (1 << activity3DragValue);
  } else if(activity3DragKind == 2 && inside(mx, my, activity3BehaviorDropX, activity3BehaviorDropY, activity3BehaviorDropW, activity3BehaviorDropH)){
    activity3SelectedBehavior = activity3DragValue;
  }

  activity3Dragging = false;
  activity3DragKind = 0;
  activity3DragValue = -1;
}

int[] activity3SelectedSoundIndices(){
  int count = 0;
  for(int i = 0; i < activity3SoundClues.length; i++){
    if((activity3SelectedSoundMask & (1 << i)) != 0) count++;
  }

  int[] selected = new int[count];
  int cursor = 0;
  for(int i = 0; i < activity3SoundClues.length; i++){
    if((activity3SelectedSoundMask & (1 << i)) != 0){
      selected[cursor] = i;
      cursor++;
    }
  }
  return selected;
}

String activity3SelectedSoundSummary(){
  int[] selected = activity3SelectedSoundIndices();
  if(selected.length == 0) return "Por selecionar";

  String result = "";
  for(int i = 0; i < selected.length; i++){
    if(result.length() > 0) result += " + ";
    result += activity3SoundClues[selected[i]];
  }
  return result;
}

int activity3CurrentScenarioIndex(){
  return constrain(activity3VideoIndex, 0, ACTIVITY3_VIDEO_COUNT - 1);
}

int activity3CurrentCorrectGrowl(){
  return activity3CardForGrowlRole(activity3CurrentScenarioIndex(), 2);
}

int[] activity3CurrentCorrectSoundClues(){
  return activity3CorrectSoundCluesByScenario[activity3CurrentScenarioIndex()];
}

int activity3CurrentCorrectBehavior(){
  return activity3CorrectBehaviors[activity3CurrentScenarioIndex()];
}

String[] activity3CurrentBehaviorOptions(){
  return activity3BehaviorOptionsByScenario[activity3CurrentScenarioIndex()];
}

String activity3CurrentBehaviorLabel(int index){
  String[] behaviorOptions = activity3CurrentBehaviorOptions();
  if(index < 0 || index >= behaviorOptions.length) return "Por selecionar";
  return behaviorOptions[index];
}

String activity3CurrentCorrectBehaviorLabel(){
  return activity3CurrentBehaviorLabel(activity3CurrentCorrectBehavior());
}

String activity3CurrentFeedbackExplanation(){
  return activity3FeedbackExplanations[activity3CurrentScenarioIndex()];
}

String activity3CorrectSoundSummary(){
  String result = "";
  int[] correctSoundClues = activity3CurrentCorrectSoundClues();
  for(int i = 0; i < correctSoundClues.length; i++){
    if(result.length() > 0) result += " + ";
    result += activity3SoundClues[correctSoundClues[i]];
  }
  return result;
}

String activity3ScenarioResearchDetails(){
  return "sequence_position=" + activity3SequencePosition +
    ";scenario_index=" + activity3CurrentScenarioIndex() +
    ";video_file=" + activity3VideoFiles[activity3CurrentScenarioIndex()];
}

String activity3GrowlResearchDetails(){
  boolean correct = activity3SelectedGrowl == activity3CurrentCorrectGrowl();
  int scenarioIndex = activity3CurrentScenarioIndex();
  return activity3ScenarioResearchDetails() +
    ";selected=" + activity3GrowlLabels[activity3SelectedGrowl] +
    ";selected_role=" + activity3GrowlRoleForCard(scenarioIndex, activity3SelectedGrowl) +
    ";correct=" + activity3GrowlLabels[activity3CurrentCorrectGrowl()] +
    ";correct_role=2" +
    ";ok=" + correct;
}

String activity3JustificationResearchDetails(){
  boolean soundCorrect = activity3SelectedSoundMask == activity3CorrectSoundMask();
  boolean behaviorCorrect = activity3SelectedBehavior == activity3CurrentCorrectBehavior();
  return activity3ScenarioResearchDetails() +
    ";selected_sound=" + activity3SelectedSoundSummary() +
    ";correct_sound=" + activity3CorrectSoundSummary() +
    ";sound_ok=" + soundCorrect +
    ";selected_behavior=" + activity3CurrentBehaviorLabel(activity3SelectedBehavior) +
    ";correct_behavior=" + activity3CurrentCorrectBehaviorLabel() +
    ";behavior_ok=" + behaviorCorrect;
}

int activity3CorrectSoundMask(){
  int mask = 0;
  int[] correctSoundClues = activity3CurrentCorrectSoundClues();
  for(int i = 0; i < correctSoundClues.length; i++){
    mask |= (1 << correctSoundClues[i]);
  }
  return mask;
}

String activity4ResearchDetails(){
  return "behavior=" + titles[screen] +
    ";sequence_position=" + behaviorSequencePosition +
    ";required_marks=" + requiredInterpretationMarkCount(screen) +
    ";user_times=" + userInterpretationMarksText(screen) +
    ";correct_times=" + correctIntervalsText(screen) +
    ";time_ok=" + interpretationTimeMatchesAllMarks(screen) +
    ";user_behaviors=" + userInterpretationBehaviorsText(screen) +
    ";correct_behaviors=" + correctInterpretationBehaviorsText(screen) +
    ";behavior_ok=" + interpretationBehaviorMatchesAllMarks(screen);
}

void drawActivityPlaceholder(){
  drawActivity1Header();

  fill(muted);
  textAlign(RIGHT, TOP);
  textSize(TYPE_CAPTION);
  text("Atividade " + placeholderActivity, baseW - margin, 58);

  fill(white);
  textAlign(RIGHT, TOP);
  textSize(TYPE_SECTION);
  text("Prot\u00f3tipo por integrar", baseW - margin, 78);

  float x = margin;
  float y = 180;
  float w = baseW - margin * 2;
  float h = 270;

  noStroke();
  fill(card);
  rect(x, y, w, h, 8);
  stroke(strokeC);
  strokeWeight(1);
  noFill();
  rect(x, y, w, h, 8);
  noStroke();

  fill(white);
  textAlign(LEFT, TOP);
  textSize(TYPE_SECTION);
  text("Atividade " + placeholderActivity, x + 28, y + 30);

  fill(muted);
  textSize(TYPE_BODY);
  textLeading(LEADING_BODY);
  text(
    "Este acesso j\u00e1 est\u00e1 criado no menu principal. O ecr\u00e3 fica reservado para codificar a atividade quando avan\u00e7armos para os respetivos frames.",
    x + 28, y + 88, w - 56, 90
  );
  textLeading(LEADING_COMPACT);
}

float mouseXToInterface(){
  return (mouseX - (width - baseW * scaleFactor) / 2) / scaleFactor;
}

float mouseYToInterface(){
  return (mouseY - (height - baseH * scaleFactor) / 2) / scaleFactor;
}

void drawBookIcon(float cx, float cy, float s, color iconColor){
  stroke(iconColor);
  strokeWeight(max(1.4, s * 0.12));
  strokeCap(ROUND);
  strokeJoin(ROUND);
  noFill();

  float pageW = s * 0.78;
  float topY = cy - s * 0.58;
  float bottomY = cy + s * 0.58;

  line(cx, topY + s * 0.08, cx, bottomY + s * 0.12);

  beginShape();
  vertex(cx, topY + s * 0.08);
  vertex(cx - pageW, topY - s * 0.06);
  vertex(cx - pageW, bottomY - s * 0.08);
  vertex(cx, bottomY + s * 0.12);
  endShape();

  beginShape();
  vertex(cx, topY + s * 0.08);
  vertex(cx + pageW, topY - s * 0.06);
  vertex(cx + pageW, bottomY - s * 0.08);
  vertex(cx, bottomY + s * 0.12);
  endShape();

  line(cx - pageW * 0.68, cy - s * 0.18, cx - pageW * 0.22, cy - s * 0.10);
  line(cx + pageW * 0.22, cy - s * 0.10, cx + pageW * 0.68, cy - s * 0.18);
  line(cx - pageW * 0.68, cy + s * 0.14, cx - pageW * 0.22, cy + s * 0.22);
  line(cx + pageW * 0.22, cy + s * 0.22, cx + pageW * 0.68, cy + s * 0.14);

  strokeCap(SQUARE);
  strokeJoin(MITER);
  noStroke();
}

void drawParagraphText(String content, float x, float y, float w, float maxH, float leading, float paragraphGap){
  String[] paragraphs = content.split("\\n\\n");
  float cursorY = y;

  for(int i = 0; i < paragraphs.length; i++){
    String paragraph = paragraphs[i].trim();
    if(paragraph.length() == 0) continue;

    int lineCount = estimateWrappedLineCount(paragraph, w);
    float paragraphH = lineCount * leading + 2;
    if(cursorY + paragraphH > y + maxH){
      paragraphH = max(leading, y + maxH - cursorY);
    }

    text(paragraph, x, cursorY, w, paragraphH);
    cursorY += paragraphH + paragraphGap;
    if(cursorY >= y + maxH) break;
  }
}

int estimateWrappedLineCount(String paragraph, float w){
  String[] words = splitTokens(paragraph, " ");
  if(words == null || words.length == 0) return 1;

  int lines = 1;
  float lineW = 0;
  float spaceW = textWidth(" ");

  for(int i = 0; i < words.length; i++){
    float wordW = textWidth(words[i]);
    if(lineW > 0 && lineW + spaceW + wordW > w){
      lines++;
      lineW = wordW;
    } else {
      if(lineW > 0) lineW += spaceW;
      lineW += wordW;
    }
  }

  return lines;
}

void drawArrowIcon(float cx, float cy, float s, int direction, color iconColor){
  stroke(iconColor);
  strokeWeight(max(1.5, s * 0.16));
  strokeCap(ROUND);
  noFill();

  float startX = cx - direction * s * 0.45;
  float endX = cx + direction * s * 0.45;
  line(startX, cy, endX, cy);
  line(endX, cy, endX - direction * s * 0.32, cy - s * 0.30);
  line(endX, cy, endX - direction * s * 0.32, cy + s * 0.30);

  strokeCap(SQUARE);
  noStroke();
}

void drawReplayIcon(float cx, float cy, float s, color iconColor){
  stroke(iconColor);
  strokeWeight(max(1.5, s * 0.15));
  strokeCap(ROUND);
  strokeJoin(ROUND);
  noFill();

  float r = s * 0.66;
  float startAngle = -PI * 0.05;
  float endAngle = PI * 1.35;
  arc(cx, cy, r * 2, r * 2, startAngle, endAngle);

  float tipX = cx + cos(endAngle) * r;
  float tipY = cy + sin(endAngle) * r;
  line(tipX, tipY, tipX - s * 0.34, tipY - s * 0.02);
  line(tipX, tipY, tipX - s * 0.12, tipY + s * 0.32);

  strokeCap(SQUARE);
  strokeJoin(MITER);
  noStroke();
}
void drawReviewIcon(float cx, float cy, float s, color iconColor){
  stroke(iconColor);
  strokeWeight(max(1.8, s * 0.15));
  strokeCap(ROUND);
  strokeJoin(ROUND);
  noFill();

  arc(cx, cy, s * 1.45, s * 1.45, PI * 0.18, PI * 1.82);

  float headX = cx + s * 0.62;
  float headY = cy - s * 0.36;
  line(headX - s * 0.52, headY, headX, headY);
  line(headX, headY - s * 0.52, headX, headY);

  strokeCap(SQUARE);
  strokeJoin(MITER);
  noStroke();
}

void drawCloseIcon(float cx, float cy, float s, color iconColor){
  stroke(iconColor);
  strokeWeight(max(1.8, s * 0.16));
  strokeCap(ROUND);
  strokeJoin(ROUND);
  noFill();

  line(cx - s * 0.42, cy - s * 0.42, cx + s * 0.42, cy + s * 0.42);
  line(cx + s * 0.42, cy - s * 0.42, cx - s * 0.42, cy + s * 0.42);

  strokeCap(SQUARE);
  strokeJoin(MITER);
  noStroke();
}

void drawButtonIcon(String iconName, float cx, float cy, float s, color iconColor){
  if(iconName.equals("back")){
    drawArrowIcon(cx, cy, s, -1, iconColor);
  } else if(iconName.equals("next")){
    drawArrowIcon(cx, cy, s, 1, iconColor);
  } else if(iconName.equals("replay")){
    drawReplayIcon(cx, cy, s, iconColor);
  } else if(iconName.equals("review")){
    drawReviewIcon(cx, cy, s, iconColor);
  } else if(iconName.equals("book")){
    drawBookIcon(cx, cy, s, iconColor);
  } else if(iconName.equals("close")){
    drawCloseIcon(cx, cy, s, iconColor);
  }
}

void drawActionButton(float x, float y, float w, float h, String label, String iconName, boolean filled, boolean enabled){
  if(filled){
    noStroke();
    fill(enabled ? purple : greyDark);
  } else {
    noStroke();
    fill(enabled ? color(13, 18, 32) : color(12, 15, 24));
    rect(x, y, w, h, 8);
    noFill();
    stroke(enabled ? purpleText : strokeC);
    strokeWeight(1.2);
  }
  rect(x, y, w, h, 8);

  color fg = enabled ? white : grey;
  fill(fg);
  noStroke();
  textAlign(LEFT, CENTER);
  textSize(TYPE_BODY);

  float iconSize = iconName.equals("review") ? 11 : 14;
  float gap = 10;
  float groupW = iconSize * 1.4 + gap + textWidth(label);
  float iconX = x + (w - groupW) / 2 + iconSize * 0.65;
  float textX = iconX + iconSize * 0.8 + gap;

  drawButtonIcon(iconName, iconX, y + h / 2, iconSize, fg);
  fill(fg);
  text(label, textX, y + h / 2 - 1);
}
void drawActivityAboutCard(){
  float w = 560;
  float x = baseW - 76 - w;
  float y = 90;
  float h = 592;

  noStroke();
  fill(card);
  rect(x, y, w, h, 14);

  noFill();
  stroke(color(58, 72, 105));
  strokeWeight(1.1);
  rect(x, y, w, h, 14);

  noStroke();
  fill(color(105, 68, 245, 22));
  rect(x, y, w, 92, 14, 14, 0, 0);

  drawActivityIcon(x + 100, y + 98, 52);

  fill(white);
  textAlign(LEFT, TOP);
  textSize(TYPE_TITLE);
  text("Acerca da atividade", x + 48, y + 205);

  fill(muted);
  textSize(TYPE_BODY);
  textLeading(LEADING_LARGE);
  text(
    "Esta atividade utiliza a multissensorialidade para apoiar a aprendizagem da interpretação da comunicação canídea. Ao longo da atividade, vais observar diferentes comportamentos através de estímulos visuais, sonoros e táteis.\n\nPara realizar a atividade, utiliza os controlos apresentados no ecrã. Para sentir os estímulos táteis, coloca o Tactosy for Hands na mão esquerda.",
    x + 48, y + 266, w - 96, h - 310
  );
  textLeading(LEADING_COMPACT);
}

void drawActivityIcon(float cx, float cy, float r){
  noStroke();
  fill(purpleDim);
  ellipse(cx, cy, r * 2, r * 2);

  noFill();
  stroke(purpleText);
  strokeWeight(1.5);
  ellipse(cx, cy, r * 2, r * 2);

  noStroke();
  fill(color(182, 156, 255));
  ellipse(cx - 14, cy - 11, 10, 14);
  ellipse(cx, cy - 17, 10, 15);
  ellipse(cx + 14, cy - 11, 10, 14);
  ellipse(cx - 24, cy + 2, 9, 12);
  ellipse(cx + 24, cy + 2, 9, 12);

  fill(color(164, 135, 255));
  ellipse(cx, cy + 14, 32, 25);
}
void drawDogIcon(float cx, float cy, float r){
  noFill();
  stroke(purpleText);
  strokeWeight(2.0);
  ellipse(cx, cy, r * 1.6, r * 1.4);
  arc(cx - r * 0.55, cy - r * 0.4, r * 0.7, r * 0.9, PI, TWO_PI * 0.85);
  noFill();
  arc(cx + r * 0.1, cy + r * 0.1, r * 0.55, r * 0.4, 0, PI);
  noStroke();
}

void drawFeatureCard(float x, float y, float w, float h,
                     int iconType, String title, String desc, String btnLabel){
  noStroke();
  fill(card);
  rect(x, y, w, h, 16);

  fill(purpleDim);
  ellipse(x + 54, y + 52, 58, 58);

  stroke(purpleText);
  strokeWeight(2.5);
  noFill();

  if(iconType == 0){
    arc(x + 54, y + 52, 22, 22, PI * 0.2, PI * 1.9);
    float ax = x + 54 + 11 * cos(PI * 0.2);
    float ay = y + 52 + 11 * sin(PI * 0.2);
    line(ax, ay, ax - 6, ay - 3);
    line(ax, ay, ax + 2, ay - 7);
  } else {
    ellipse(x + 54, y + 52, 22, 22);
    line(x + 54, y + 44, x + 54, y + 52);
    line(x + 54, y + 52, x + 60, y + 52);
  }

  noStroke();
  fill(white);
  textAlign(LEFT, TOP);
  textSize(TYPE_SUBHEADING);
  text(title, x + 20, y + 90);

  fill(muted);
  textSize(TYPE_LABEL);
  text(desc, x + 20, y + 116, w - 40, 40);

  noFill();
  stroke(strokeC);
  strokeWeight(1);
  rect(x + 20, y + h - 48, w - 40, 34, 8);

  fill(white);
  textAlign(CENTER, CENTER);
  textSize(TYPE_LABEL);
  text(btnLabel + " ->", x + w/2, y + h - 31);
}

void drawGuidedScreen(){
  updateAnimation();
  drawHeader();

  if(phase == 1){
    drawVideo();
  } else if(phase == 2){
    drawInterpretationTask();
  } else if(phase == 3){
    drawFeedbackScreen();
  }
}

void updateAnimation(){
  if(animating){
    t += 0.05;
    if(t >= 1){
      t = 1;
      animating = false;
      phase = 2;
      replayVibrationActive = false;
      enterInterpretationTask();
    }
  }
}

void drawHeader(){
  backW = 110;
  backH = 38;
  backX = margin;
  backY = 22;
  drawActionButton(backX, backY, backW, backH, "Sair", "close", false, true);

  float dotSpacing = 14;
  float dotsTotal = titles.length * dotSpacing;
  float dotsStartX = baseW - margin - dotsTotal;
  float dotsY = backY + backH/2;

  for(int i = 0; i < titles.length; i++){
    float dx = dotsStartX + i * dotSpacing;
    if(i == behaviorSequencePosition){
      fill(purple);
      ellipse(dx, dotsY, 8, 8);
    } else if(i < behaviorSequencePosition){
      fill(purpleDim);
      ellipse(dx, dotsY, 6, 6);
    } else {
      fill(greyDark);
      ellipse(dx, dotsY, 6, 6);
    }
  }

  fill(muted);
  textAlign(RIGHT, CENTER);
  textSize(TYPE_LABEL);
  text((behaviorSequencePosition + 1) + " / " + titles.length, baseW - margin - dotsTotal - 16, dotsY);

  fill(white);
  textAlign(RIGHT, CENTER);
  textSize(TYPE_SECTION);
  String headerTitle = phase == 1 ? "Observação" :
                       (phase == 2 ? "Tarefa interpretativa" : "Feedback");
  text(headerTitle, baseW - margin - dotsTotal - 60, dotsY);
}

void drawVideo(){
  float x = lerp(v1x, v2x, easeInOut(t));
  float y = lerp(v1y, v2y, easeInOut(t));
  float w = lerp(v1w, v2w, easeInOut(t));
  float h = lerp(v1h, v2h, easeInOut(t));

  noStroke();
  fill(card);
  rect(x, y, w, h, 14);

  if(hasVideo[screen] && videoReadyForDrawing(videos[screen])){
    drawVideoFit(videos[screen], x, y, w, h);
  } else {
    fill(greyDark);
    rect(x, y, w, h, 14);
    fill(grey);
    textAlign(CENTER, CENTER);
    textSize(TYPE_BODY);
    text("Video " + (behaviorSequencePosition + 1), x + w/2, y + h/2);
  }

  if(appState == 1 && phase == 1){
    drawObservationHapticTuningControls();
  }
}

boolean videoReadyForDrawing(Movie vid){
  if(vid == null) return false;
  if(vid.width <= 0 || vid.height <= 0) return false;
  return true;
}

float easeInOut(float t){
  return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
}

void drawVideoFit(Movie vid, float x, float y, float w, float h){
  if(!videoReadyForDrawing(vid)) return;

  float vr = (float)vid.width / vid.height;
  float br = w / h;
  float dw, dh;

  if(vr > br){
    dw = w;
    dh = w / vr;
  } else {
    dh = h;
    dw = h * vr;
  }

  try {
    image(vid, x + (w - dw) / 2, y + (h - dh) / 2, dw, dh);
  } catch(Exception e){
    if(millis() - lastVideoDrawErrorMillis > 1000){
      println("Frame de video ignorado: " + e.getMessage());
      lastVideoDrawErrorMillis = millis();
    }
  }
}

int requiredInterpretationMarkCount(int behaviorIndex){
  if(behaviorIndex < 0 || behaviorIndex >= requiredInterpretationMarks.length) return 1;
  int value = requiredInterpretationMarks[behaviorIndex];
  if(value < 1) return 1;
  if(value > MAX_INTERPRETATION_MARKS) return MAX_INTERPRETATION_MARKS;
  return value;
}

boolean currentBehaviorNeedsMultipleMarks(){
  return requiredInterpretationMarkCount(screen) > 1;
}

String interpretationChoiceLabel(int candidateIndex){
  if(candidateIndex == CHOICE_DESVIO_CABECA) return "Desvio de cabe\u00e7a";
  if(candidateIndex == CHOICE_DESVIO_OLHAR) return "Desvio do olhar";

  if(candidateIndex >= 0 && candidateIndex < titles.length) return titles[candidateIndex];

  int decoyIndex = candidateIndex - titles.length;
  if(decoyIndex >= 0 && decoyIndex < interpretationDecoyLabels.length){
    return interpretationDecoyLabels[decoyIndex];
  }

  return "Por selecionar";
}

String interpretationChoiceHint(int candidateIndex){
  if(candidateIndex == CHOICE_DESVIO_CABECA){
    return "Pode manifestar desconforto ao virar cabe\u00e7a ou focinho perante a pessoa.";
  }
  if(candidateIndex == CHOICE_DESVIO_OLHAR){
    return "Pode manifestar desconforto ao desviar o olhar e reduzir contacto direto.";
  }

  if(candidateIndex >= 0 && candidateIndex < refinedInterpretationHints.length) return refinedInterpretationHints[candidateIndex];

  int decoyIndex = candidateIndex - titles.length;
  if(decoyIndex >= 0 && decoyIndex < refinedInterpretationDecoyHints.length){
    return refinedInterpretationDecoyHints[decoyIndex];
  }

  return "Seleciona ou passa sobre um comportamento para veres uma pista breve.";
}

int interpretationChoiceBehaviorIndex(int candidateIndex){
  if(candidateIndex == CHOICE_DESVIO_CABECA || candidateIndex == CHOICE_DESVIO_OLHAR){
    return 2;
  }
  if(candidateIndex >= 0 && candidateIndex < titles.length) return candidateIndex;
  return -1;
}

boolean interpretationChoiceMatchesScreen(int candidateIndex){
  return interpretationChoiceBehaviorIndex(candidateIndex) == screen;
}

int interpretationChoiceForBehavior(int behaviorIndex){
  if(behaviorIndex >= 0 && behaviorIndex < titles.length) return behaviorIndex;
  return -1;
}

int correctInterpretationChoiceForMark(int behaviorIndex, int markIndex){
  if(behaviorIndex == 2){
    if(markIndex == 0) return CHOICE_DESVIO_OLHAR;
    if(markIndex == 1) return CHOICE_DESVIO_CABECA;
  }

  return interpretationChoiceForBehavior(behaviorIndex);
}

void shuffleInterpretationChoicesForCurrentScreen(){
  randomSeed((long)millis() + (long)frameCount * 101 + (long)screen * 7919);

  int[] candidates = {0, 1, 2, 3, 4, 5, 6, 7};
  if(screen == 2){
    candidates = new int[] {
      0, 1,
      CHOICE_DESVIO_CABECA, CHOICE_DESVIO_OLHAR,
      3, 4,
      5, 6
    };
  }

  for(int i = 0; i < interpretationChoiceOrder.length; i++){
    interpretationChoiceOrder[i] = candidates[i];
  }

  for(int i = interpretationChoiceOrder.length - 1; i > 0; i--){
    int j = (int)random(i + 1);
    int tmp = interpretationChoiceOrder[i];
    interpretationChoiceOrder[i] = interpretationChoiceOrder[j];
    interpretationChoiceOrder[j] = tmp;
  }
}

void clearInterpretationAnswerForScreen(int index){
  if(index < 0 || index >= interpretationTimes.length) return;

  interpretationTimes[index] = -1;
  interpretationChoices[index] = -1;
  interpretationMarkCounts[index] = 0;

  for(int i = 0; i < MAX_INTERPRETATION_MARKS; i++){
    interpretationMarkedTimes[index][i] = -1;
    interpretationMarkedChoices[index][i] = -1;
  }
}

void resetCurrentInterpretationDraft(){
  interpretationTimes[screen] = -1;
  interpretationChoices[screen] = -1;
  interpretationTaskStage = INTERPRETATION_STAGE_TIME;
  clearInterpretationSeek();
  seekInterpretationVideo(0);
}

void commitCurrentInterpretationMark(){
  int markIndex = interpretationMarkCounts[screen];
  if(markIndex < 0 || markIndex >= requiredInterpretationMarkCount(screen)) return;

  interpretationMarkedTimes[screen][markIndex] = interpretationTimes[screen];
  interpretationMarkedChoices[screen][markIndex] = interpretationChoices[screen];
  interpretationMarkCounts[screen] = markIndex + 1;
}

int currentInterpretationMarkIndex(){
  int required = requiredInterpretationMarkCount(screen);
  return constrain(interpretationMarkCounts[screen], 0, required - 1);
}

String currentInterpretationChangeLabel(){
  int required = requiredInterpretationMarkCount(screen);
  int markIndex = currentInterpretationMarkIndex();
  if(required <= 1) return "1.\u00aa mudan\u00e7a";
  return (markIndex + 1) + ".\u00aa mudan\u00e7a";
}

float correctInterpretationStartForMark(int behaviorIndex, int markIndex){
  if(markIndex == 1) return correctInterpretationSecondStarts[behaviorIndex];
  return correctInterpretationStarts[behaviorIndex];
}

float correctInterpretationEndForMark(int behaviorIndex, int markIndex){
  if(markIndex == 1) return correctInterpretationSecondEnds[behaviorIndex];
  return correctInterpretationEnds[behaviorIndex];
}

String correctIntervalsText(int behaviorIndex){
  int required = requiredInterpretationMarkCount(behaviorIndex);
  if(required == 1){
    return formatVideoTime(correctInterpretationStarts[behaviorIndex]) + " a " +
      formatVideoTime(correctInterpretationEnds[behaviorIndex]);
  }

  String result = "";
  for(int i = 0; i < required; i++){
    if(result.length() > 0) result += "\n";
    result += (i + 1) + ": " +
      formatVideoTime(correctInterpretationStartForMark(behaviorIndex, i)) + " a " +
      formatVideoTime(correctInterpretationEndForMark(behaviorIndex, i));
  }
  return result;
}

String userInterpretationMarksText(int behaviorIndex){
  int required = requiredInterpretationMarkCount(behaviorIndex);
  String result = "";

  for(int i = 0; i < required; i++){
    if(result.length() > 0) result += "\n";
    String timeText = interpretationMarkedTimes[behaviorIndex][i] >= 0
      ? formatVideoTime(interpretationMarkedTimes[behaviorIndex][i])
      : "Por marcar";
    result += required > 1 ? (i + 1) + ": " + timeText : timeText;
  }

  return result;
}

String userInterpretationBehaviorsText(int behaviorIndex){
  int required = requiredInterpretationMarkCount(behaviorIndex);
  String result = "";

  for(int i = 0; i < required; i++){
    if(result.length() > 0) result += "\n";
    String behaviorText = interpretationMarkedChoices[behaviorIndex][i] >= 0
      ? interpretationChoiceLabel(interpretationMarkedChoices[behaviorIndex][i])
      : "Por selecionar";
    result += required > 1 ? (i + 1) + ": " + behaviorText : behaviorText;
  }

  return result;
}

String correctInterpretationBehaviorsText(int behaviorIndex){
  int required = requiredInterpretationMarkCount(behaviorIndex);
  String result = "";

  for(int i = 0; i < required; i++){
    if(result.length() > 0) result += "\n";
    String behaviorText = interpretationChoiceLabel(correctInterpretationChoiceForMark(behaviorIndex, i));
    result += required > 1 ? (i + 1) + ": " + behaviorText : behaviorText;
  }

  return result;
}

boolean interpretationTimeMatchesMark(int behaviorIndex, int markIndex){
  float markedTime = interpretationMarkedTimes[behaviorIndex][markIndex];
  if(markedTime < 0) return false;
  return markedTime >= correctInterpretationStartForMark(behaviorIndex, markIndex) &&
    markedTime <= correctInterpretationEndForMark(behaviorIndex, markIndex);
}

boolean interpretationTimeMatchesAllMarks(int behaviorIndex){
  int required = requiredInterpretationMarkCount(behaviorIndex);
  for(int i = 0; i < required; i++){
    if(!interpretationTimeMatchesMark(behaviorIndex, i)) return false;
  }
  return true;
}

boolean interpretationBehaviorMatchesAllMarks(int behaviorIndex){
  int required = requiredInterpretationMarkCount(behaviorIndex);
  for(int i = 0; i < required; i++){
    if(interpretationMarkedChoices[behaviorIndex][i] != correctInterpretationChoiceForMark(behaviorIndex, i)){
      return false;
    }
  }
  return true;
}

String savedMarkLabelForChoice(int candidateIndex){
  String result = "";

  for(int i = 0; i < interpretationMarkCounts[screen]; i++){
    if(interpretationMarkedChoices[screen][i] != candidateIndex) continue;
    if(result.length() > 0) result += ",";
    result += str(i + 1);
  }

  return result;
}

float feedbackSeekTimeForBehavior(int behaviorIndex){
  return (correctInterpretationStarts[behaviorIndex] + correctInterpretationEnds[behaviorIndex]) / 2.0;
}

void drawInterpretationTask(){
  float videoX = margin;
  float videoY = 82;
  float availableW = baseW - margin * 2 - gutter;
  float videoW = availableW * 0.62;
  float videoH = 392;
  float panelX = videoX + videoW + gutter;
  float panelY = videoY;
  float panelW = baseW - margin - panelX;
  float panelH = videoH;

  noStroke();
  fill(card);
  rect(videoX, videoY, videoW, videoH, 8);

  if(hasVideo[screen] && videoReadyForDrawing(videos[screen])){
    drawVideoFit(videos[screen], videoX, videoY, videoW, videoH);
  } else {
    fill(greyDark);
    rect(videoX, videoY, videoW, videoH, 8);
    fill(grey);
    textAlign(CENTER, CENTER);
    textSize(TYPE_BODY);
    text("Vídeo em preparação", videoX + videoW / 2, videoY + videoH / 2);
  }

  fill(card);
  rect(panelX, panelY, panelW, panelH, 8);

  fill(purpleText);
  textAlign(LEFT, TOP);
  textSize(TYPE_LABEL);
  text("TAREFA INTERPRETATIVA", panelX + 24, panelY + 24);

  fill(white);
  textSize(TYPE_SECTION);
  String changeLabel = currentInterpretationChangeLabel();
  String taskTitle = currentBehaviorNeedsMultipleMarks()
    ? (interpretationTaskStage == INTERPRETATION_STAGE_TIME
      ? "Marca a " + changeLabel + "\nna timeline"
      : "Escolhe o sinal da\n" + changeLabel)
    : (interpretationTaskStage == INTERPRETATION_STAGE_TIME
      ? "Marca a 1.\u00aa mudan\u00e7a\nna timeline"
      : "Escolhe o sinal\nobservado");
  text(taskTitle, panelX + 24, panelY + 54);

  fill(muted);
  textSize(TYPE_BODY);
  textLeading(LEADING_BODY);
  String taskDescription = interpretationTaskStage == INTERPRETATION_STAGE_TIME
    ? "Clica na timeline para marcar o momento da " + changeLabel + " observada. Depois confirma para escolher o comportamento correspondente."
    : "Agora escolhe o comportamento que corresponde à " + changeLabel + " marcada.";
  text(
    taskDescription,
    panelX + 24, panelY + 122, panelW - 48, 74
  );
  textLeading(LEADING_COMPACT);

  stroke(strokeC);
  strokeWeight(1);
  line(panelX + 24, panelY + 216, panelX + panelW - 24, panelY + 216);
  noStroke();

  fill(muted);
  textSize(TYPE_LABEL);
  String selectedMomentLabel = currentBehaviorNeedsMultipleMarks()
    ? "MUDANÇA ATUAL " + (currentInterpretationMarkIndex() + 1) + " / " + requiredInterpretationMarkCount(screen)
    : "MOMENTO DA 1.\u00aa MUDAN\u00c7A";
  float selectedMomentLabelY = panelY + 240;
  float selectedTimeY = panelY + 264;

  text(selectedMomentLabel, panelX + 24, selectedMomentLabelY);
  fill(white);
  textSize(TYPE_SECTION);
  String selectedTime = interpretationTimes[screen] >= 0
    ? formatVideoTime(interpretationTimes[screen])
    : "Por selecionar";
  text(selectedTime, panelX + 24, selectedTimeY);

  if(interpretationTaskStage == INTERPRETATION_STAGE_CHOICE){
    fill(muted);
    textSize(TYPE_LABEL);
    text("COMPORTAMENTO RELACIONADO", panelX + 24, panelY + 316);
    fill(white);
    textSize(TYPE_BODY);
    String selectedBehavior = interpretationChoices[screen] >= 0
      ? interpretationChoiceLabel(interpretationChoices[screen])
      : "Por selecionar";
    float selectedBehaviorW = panelW - 48;
    if(currentBehaviorNeedsMultipleMarks()){
      float savedMarksW = min(220, panelW * 0.36);
      selectedBehaviorW -= savedMarksW + 28;
    }
    text(selectedBehavior, panelX + 24, panelY + 340, max(180, selectedBehaviorW), 34);
  }

  if(currentBehaviorNeedsMultipleMarks()){
    drawSavedInterpretationMarksPanel(panelX, panelY, panelW);
  }

  if(interpretationTaskStage == INTERPRETATION_STAGE_TIME){
    drawInterpretationTimeline();
  } else {
    drawInterpretationChoices();
  }

  interpretationConfirmW = 220;
  interpretationConfirmH = 44;
  interpretationConfirmX = baseW - margin - interpretationConfirmW;
  interpretationConfirmY = 710;

  if(interpretationTaskStage == INTERPRETATION_STAGE_CHOICE){
    drawInterpretationHint();
  } else {
    drawInterpretationTimelinePrompt();
  }

  String confirmLabel = interpretationTaskStage == INTERPRETATION_STAGE_TIME
    ? "Confirmar momento"
    : "Confirmar escolha";
  drawActionButton(
    interpretationConfirmX, interpretationConfirmY,
    interpretationConfirmW, interpretationConfirmH,
    confirmLabel, "next", true, currentInterpretationStageComplete()
  );
}

void drawInterpretationTimeline(){
  interpretationTimelineX = margin;
  interpretationTimelineY = 532;
  interpretationTimelineW = baseW - margin * 2;
  interpretationTimelineH = 64;

  fill(white);
  textAlign(LEFT, BOTTOM);
  textSize(TYPE_LABEL);
  String timelineLabel = "Timeline da " + currentInterpretationChangeLabel();
  text(timelineLabel, interpretationTimelineX, 516);

  float pulse = 0.5 + 0.5 * sin(millis() * 0.004);
  noStroke();
  fill(cardAlt);
  rect(interpretationTimelineX, interpretationTimelineY, interpretationTimelineW, interpretationTimelineH, 8);
  stroke(purpleText, 80 + 90 * pulse);
  strokeWeight(1.5);
  noFill();
  rect(interpretationTimelineX, interpretationTimelineY, interpretationTimelineW, interpretationTimelineH, 8);

  float trackY = interpretationTimelineY + interpretationTimelineH / 2;
  stroke(greyDark);
  strokeWeight(8);
  strokeCap(ROUND);
  line(interpretationTimelineX + 22, trackY,
       interpretationTimelineX + interpretationTimelineW - 22, trackY);

  float duration = getCurrentVideoDuration();
  if(duration > 0){
    for(int i = 0; i < interpretationMarkCounts[screen]; i++){
      if(interpretationMarkedTimes[screen][i] < 0) continue;
      float normalizedSaved = constrain(interpretationMarkedTimes[screen][i] / duration, 0, 1);
      float savedProgressX = interpretationTimelineX + 22 + (interpretationTimelineW - 44) * normalizedSaved;

      stroke(purpleDim);
      strokeWeight(8);
      line(interpretationTimelineX + 22, trackY, savedProgressX, trackY);
    }
  }

  for(int i = 0; i < interpretationMarkCounts[screen]; i++){
    if(interpretationMarkedTimes[screen][i] < 0 || duration <= 0) continue;
    float normalizedSaved = constrain(interpretationMarkedTimes[screen][i] / duration, 0, 1);
    float savedX = interpretationTimelineX + 22 + (interpretationTimelineW - 44) * normalizedSaved;

    stroke(purpleText);
    strokeWeight(2);
    line(savedX, trackY - 13, savedX, trackY + 13);
    noStroke();
    fill(purpleDim);
    ellipse(savedX, trackY, 18, 18);
    fill(white);
    textAlign(CENTER, CENTER);
    textSize(TYPE_CAPTION);
    text(str(i + 1), savedX, trackY - 1);
  }

  if(interpretationTimes[screen] >= 0 && duration > 0){
    float normalized = constrain(interpretationTimes[screen] / duration, 0, 1);
    float markerX = interpretationTimelineX + 22 + (interpretationTimelineW - 44) * normalized;

    stroke(purple);
    strokeWeight(8);
    line(interpretationTimelineX + 22, trackY, markerX, trackY);
    strokeWeight(2);
    line(markerX, trackY - 16, markerX, trackY + 16);
    noStroke();
    fill(white);
    ellipse(markerX, trackY, 14, 14);
  }

  noStroke();
  fill(muted);
  textSize(TYPE_CAPTION);
  textAlign(LEFT, TOP);
  text("00:00", interpretationTimelineX + 22, trackY + 20);
  textAlign(RIGHT, TOP);
  text(formatVideoTime(duration), interpretationTimelineX + interpretationTimelineW - 22, trackY + 20);
}

void drawInterpretationTimelinePrompt(){
  float promptX = margin;
  float promptY = 624;
  float promptW = baseW - margin * 2 - interpretationConfirmW - 24;
  float promptH = 64;

  noStroke();
  fill(card);
  rect(promptX, promptY, promptW, promptH, 8);

  stroke(purpleDim);
  strokeWeight(1);
  noFill();
  rect(promptX, promptY, promptW, promptH, 8);
  noStroke();

  fill(purpleText);
  textAlign(LEFT, TOP);
  textSize(TYPE_CAPTION);
  text("AÇÃO", promptX + 16, promptY + 10);

  fill(white);
  textSize(TYPE_LABEL);
  String promptText = "Clica na timeline para marcar o momento da " +
    currentInterpretationChangeLabel() + " e confirma.";
  text(promptText, promptX + 16, promptY + 30, promptW - 32, 24);
}

void drawInterpretationChoices(){
  float optionsY = 600;
  float gap = 12;
  float optionW = (baseW - margin * 2 - gap * 3) / 4;
  float optionH = 38;
  int hoverIndex = getInterpretationHoverIndex();

  fill(white);
  textAlign(LEFT, BOTTOM);
  textSize(TYPE_LABEL);
  text("Comportamento relacionado", margin, 588);

  for(int i = 0; i < INTERPRETATION_CHOICE_COUNT; i++){
    int candidateIndex = interpretationChoiceOrder[i];
    int column = i % 4;
    int row = i / 4;
    float x = margin + column * (optionW + gap);
    float y = optionsY + row * (optionH + 10);
    boolean selected = interpretationChoices[screen] == candidateIndex;
    boolean hovered = hoverIndex == candidateIndex;

    interpretationChoiceX[i] = x;
    interpretationChoiceY[i] = y;
    interpretationChoiceW[i] = optionW;
    interpretationChoiceH[i] = optionH;

    if(selected){
      noStroke();
      fill(purpleDim);
      rect(x, y, optionW, optionH, 6);
      stroke(purple);
      strokeWeight(1.5);
      noFill();
      rect(x, y, optionW, optionH, 6);
    } else if(hovered){
      noStroke();
      fill(cardAlt);
      rect(x, y, optionW, optionH, 6);
      stroke(purpleText);
      strokeWeight(1.5);
      noFill();
      rect(x, y, optionW, optionH, 6);
    } else {
      noFill();
      stroke(strokeC);
      strokeWeight(1);
      rect(x, y, optionW, optionH, 6);
    }

    noStroke();
    fill((selected || hovered) ? white : muted);
    textAlign(CENTER, CENTER);
    textSize(TYPE_LABEL);
    text(interpretationChoiceLabel(candidateIndex), x + 10, y + 2, optionW - 20, optionH - 4);

    String savedLabel = savedMarkLabelForChoice(candidateIndex);
    if(savedLabel.length() > 0){
      float badgeW = savedLabel.length() > 1 ? 30 : 18;
      noStroke();
      fill(purpleText);
      rect(x + optionW - badgeW - 6, y + 5, badgeW, 18, 9);
      fill(card);
      textAlign(CENTER, CENTER);
      textSize(TYPE_CAPTION);
      text(savedLabel, x + optionW - badgeW / 2 - 6, y + 13);
    }
  }
}

void drawSavedInterpretationMarksPanel(float panelX, float panelY, float panelW){
  float columnW = min(220, panelW * 0.36);
  float columnX = panelX + panelW - 24 - columnW;
  float labelY = panelY + 240;

  fill(muted);
  textAlign(LEFT, TOP);
  textSize(TYPE_LABEL);
  text("MARCAS GUARDADAS", columnX, labelY);

  float chipY = labelY + 28;
  float chipW = columnW;
  float chipH = 42;
  float gap = 10;
  int required = requiredInterpretationMarkCount(screen);

  for(int i = 0; i < required; i++){
    float x = columnX;
    float y = chipY + i * (chipH + gap);
    boolean saved = i < interpretationMarkCounts[screen];
    noStroke();
    fill(saved ? cardAlt : color(12, 18, 31));
    rect(x, y, chipW, chipH, 6);
    stroke(saved ? purpleText : strokeC);
    strokeWeight(1);
    noFill();
    rect(x, y, chipW, chipH, 6);
    noStroke();

    fill(saved ? white : muted);
    textAlign(LEFT, CENTER);
    textSize(TYPE_CAPTION);
    String markText = saved
      ? (i + 1) + ": " + formatVideoTime(interpretationMarkedTimes[screen][i])
      : (i + 1) + ": por assinalar";
    text(markText, x + 14, y + chipH / 2 - 1);
  }
}

void drawInterpretationHint(){
  int hoverIndex = getInterpretationHoverIndex();
  int activeIndex = hoverIndex >= 0 ? hoverIndex : interpretationChoices[screen];

  float hintX = margin;
  float hintY = 710;
  float hintW = baseW - margin * 2 - interpretationConfirmW - 24;
  float hintH = 48;

  noStroke();
  fill(card);
  rect(hintX, hintY, hintW, hintH, 8);

  stroke(activeIndex >= 0 ? purple : strokeC);
  strokeWeight(1);
  noFill();
  rect(hintX, hintY, hintW, hintH, 8);
  noStroke();

  fill(activeIndex >= 0 ? purpleText : muted);
  textAlign(LEFT, TOP);
  textSize(TYPE_CAPTION);
  text("PISTA BREVE", hintX + 16, hintY + 8);

  fill(activeIndex >= 0 ? white : muted);
  textSize(TYPE_LABEL);
  String hintText = activeIndex >= 0
    ? interpretationChoiceHint(activeIndex)
    : "Seleciona ou passa sobre um comportamento para veres uma pista breve.";
  text(hintText, hintX + 16, hintY + 26, hintW - 32, 20);
}

int getInterpretationHoverIndex(){
  if(appState != 1 || phase != 2) return -1;

  float mx = getInterfaceMouseX();
  float my = getInterfaceMouseY();

  for(int i = 0; i < INTERPRETATION_CHOICE_COUNT; i++){
    if(inside(
      mx, my,
      interpretationChoiceX[i], interpretationChoiceY[i],
      interpretationChoiceW[i], interpretationChoiceH[i]
    )){
      return interpretationChoiceOrder[i];
    }
  }

  return -1;
}

float getInterfaceMouseX(){
  return (mouseX - (width - baseW * scaleFactor) / 2) / scaleFactor;
}

float getInterfaceMouseY(){
  return (mouseY - (height - baseH * scaleFactor) / 2) / scaleFactor;
}

float getCurrentVideoDuration(){
  if(hasVideo[screen] && videos[screen] != null){
    try {
      return max(0, videos[screen].duration());
    } catch(Exception ignored){}
  }
  return 0;
}

String formatVideoTime(float secondsValue){
  int totalTenths = max(0, round(secondsValue * 10));
  int totalSeconds = totalTenths / 10;
  int minutesPart = totalSeconds / 60;
  int secondsPart = totalSeconds % 60;
  int tenthsPart = totalTenths % 10;
  return nf(minutesPart, 2) + ":" + nf(secondsPart, 2) + "." + tenthsPart;
}

boolean interpretationSelectionComplete(){
  return interpretationTimes[screen] >= 0 && interpretationChoices[screen] >= 0;
}

boolean interpretationTimeSelectionComplete(){
  return interpretationTimes[screen] >= 0;
}

boolean interpretationChoiceSelectionComplete(){
  return interpretationChoices[screen] >= 0;
}

boolean currentInterpretationStageComplete(){
  if(interpretationTaskStage == INTERPRETATION_STAGE_TIME){
    return interpretationTimeSelectionComplete();
  }
  return interpretationChoiceSelectionComplete();
}

void enterInterpretationTask(){
  interpretationDragging = false;
  interpretationTaskStage = INTERPRETATION_STAGE_TIME;
  clearInterpretationSeek();
  replayVibrationActive = false;
  stopBHapticsVibration();
  shuffleInterpretationChoicesForCurrentScreen();

  if(!hasVideo[screen] || videos[screen] == null) return;

  float targetTime = interpretationTimes[screen] >= 0
    ? interpretationTimes[screen]
    : 0;

  seekInterpretationVideo(targetTime);
}

void setInterpretationTimeFromMouse(float mx){
  float duration = getCurrentVideoDuration();
  if(duration <= 0) return;

  float normalized = constrain(
    (mx - (interpretationTimelineX + 22)) / max(1, interpretationTimelineW - 44),
    0, 1
  );
  float targetTime = min(duration - 0.04, duration * normalized);
  interpretationTimes[screen] = max(0, targetTime);

  seekInterpretationVideo(interpretationTimes[screen]);
}

void seekInterpretationVideo(float targetTime){
  if(!hasVideo[screen] || videos[screen] == null) return;

  interpretationRequestedTime = max(0, targetTime);
  interpretationSeekPending = true;
}

void updateInterpretationVideoSeek(){
  if(appState != 1 || (phase != 2 && phase != 3)) return;
  if(!hasVideo[screen] || videos[screen] == null) return;

  int now = millis();

  if(interpretationRequestedTime >= 0 && now - interpretationLastSeekMillis >= 35){
    float targetTime = interpretationRequestedTime;
    interpretationRequestedTime = -1;

    try {
      videos[screen].volume(VIDEO_MUTED_VOLUME);
      videos[screen].play();
      videos[screen].jump(targetTime);
      interpretationLastSeekMillis = now;
      interpretationPauseAtMillis = now + 120;
    } catch(Exception e){
      interpretationSeekPending = false;
      interpretationPauseAtMillis = -1;
      println("Erro ao ajustar video na linha temporal: " + e.getMessage());
    }
    return;
  }

  if(interpretationPauseAtMillis > 0 &&
     now >= interpretationPauseAtMillis &&
     interpretationRequestedTime < 0){
    try {
      videos[screen].pause();
      if(phase == 3) videos[screen].volume(currentVideoAudioVolume());
    } catch(Exception ignored){}

    interpretationPauseAtMillis = -1;
    interpretationSeekPending = false;
  }
}

void clearInterpretationSeek(){
  interpretationSeekPending = false;
  interpretationRequestedTime = -1;
  interpretationPauseAtMillis = -1;
}

void restoreInterpretationVideoAudio(){
  clearInterpretationSeek();

  try {
    if(hasVideo[screen] && videos[screen] != null) videos[screen].volume(currentVideoAudioVolume());
  } catch(Exception ignored){}
}

void drawFeedbackScreen(){
  float videoX = margin;
  float videoY = 88;
  float availableW = baseW - margin * 2 - gutter;
  float videoW = availableW * 0.58;
  float videoH = 388;
  float panelX = videoX + videoW + gutter;
  float panelY = videoY;
  float panelW = baseW - margin - panelX;
  float panelH = videoH;

  noStroke();
  fill(card);
  rect(videoX, videoY, videoW, videoH, 8);

  if(hasVideo[screen] && videoReadyForDrawing(videos[screen])){
    drawVideoFit(videos[screen], videoX, videoY, videoW, videoH);
  } else {
    fill(greyDark);
    rect(videoX, videoY, videoW, videoH, 8);
    fill(grey);
    textAlign(CENTER, CENTER);
    textSize(TYPE_BODY);
    text("Vídeo em preparação", videoX + videoW / 2, videoY + videoH / 2);
  }

  fill(card);
  rect(panelX, panelY, panelW, panelH, 8);

  fill(purpleText);
  textAlign(LEFT, TOP);
  textSize(TYPE_LABEL);
  text("RESPOSTA DA ATIVIDADE", panelX + 26, panelY + 24);

  fill(muted);
  textSize(TYPE_LABEL);
  text("INTERVALO ESPERADO", panelX + 26, panelY + 58);
  fill(white);
  textSize(currentBehaviorNeedsMultipleMarks() ? TYPE_BODY : TYPE_SECTION);
  String correctInterval = correctIntervalsText(screen);
  text(correctInterval, panelX + 26, panelY + 78, panelW - 52, 62);

  boolean timeCorrect = interpretationTimeMatchesAllMarks(screen);
  color timeResultColor = timeCorrect
    ? color(55, 200, 125)
    : color(235, 175, 70);
  fill(timeResultColor);
  ellipse(panelX + 31, panelY + 137, 8, 8);
  fill(muted);
  textSize(TYPE_LABEL);
  String userMarksLabel = currentBehaviorNeedsMultipleMarks()
    ? "As tuas marcas:\n" + userInterpretationMarksText(screen)
    : "A tua marca: " + userInterpretationMarksText(screen);
  text(userMarksLabel, panelX + 44, panelY + 124, panelW - 70, 58);

  stroke(strokeC);
  strokeWeight(1);
  float feedbackDividerY = currentBehaviorNeedsMultipleMarks() ? panelY + 194 : panelY + 174;
  line(panelX + 26, feedbackDividerY, panelX + panelW - 26, feedbackDividerY);
  noStroke();

  fill(muted);
  textSize(TYPE_LABEL);
  text("COMPORTAMENTO CORRETO", panelX + 26, feedbackDividerY + 24);
  fill(white);
  textSize(currentBehaviorNeedsMultipleMarks() ? TYPE_BODY : TYPE_SECTION);
  String correctBehaviorText = correctInterpretationBehaviorsText(screen);
  text(correctBehaviorText, panelX + 26, feedbackDividerY + 46, panelW - 52, 72);

  boolean behaviorCorrect = interpretationBehaviorMatchesAllMarks(screen);
  fill(behaviorCorrect ? color(55, 200, 125) : color(235, 175, 70));
  float userBehaviorY = currentBehaviorNeedsMultipleMarks() ? feedbackDividerY + 120 : feedbackDividerY + 110;
  ellipse(panelX + 31, userBehaviorY + 8, 8, 8);
  fill(muted);
  textSize(TYPE_LABEL);
  String userBehavior = currentBehaviorNeedsMultipleMarks()
    ? userInterpretationBehaviorsText(screen)
    : userInterpretationBehaviorsText(screen);
  text("A tua resposta: " + userBehavior, panelX + 44, userBehaviorY, panelW - 70, 62);

  float explainX = margin;
  float explainY = panelY + panelH + gutter;
  float explainW = baseW - margin * 2;
  float explainH = 224;

  fill(card);
  rect(explainX, explainY, explainW, explainH, 8);

  fill(purpleDim);
  ellipse(explainX + 42, explainY + 40, 44, 44);
  drawBookIcon(explainX + 42, explainY + 40, 15, purpleText);

  fill(white);
  textAlign(LEFT, TOP);
  textSize(TYPE_SUBHEADING);
  text("Sobre este comportamento", explainX + 76, explainY + 24);

  fill(muted);
  textSize(TYPE_LABEL);
  textLeading(LEADING_COMPACT);
  drawParagraphText(
    refinedFeedbackExplanations[screen],
    explainX + 76, explainY + 54, explainW - 104, explainH - 66,
    LEADING_COMPACT, 7
  );
  textLeading(LEADING_COMPACT);

  feedbackNextW = 180;
  feedbackNextH = 44;
  feedbackNextX = baseW - margin - feedbackNextW;
  feedbackNextY = explainY + explainH + gutter;
  drawActionButton(
    feedbackNextX, feedbackNextY, feedbackNextW, feedbackNextH,
    "Continuar", "next", true, feedbackCanAdvance()
  );
}

void enterFeedbackScreen(){
  interpretationDragging = false;
  clearInterpretationSeek();
  stopBHapticsVibration();
  startFeedbackPlayback();
}

boolean feedbackCanAdvance(){
  if(appState != 1 || phase != 3) return true;
  if(!hasVideo[screen] || videos[screen] == null) return true;
  return feedbackPlaybackComplete;
}

void startFeedbackPlayback(){
  feedbackPlaybackComplete = false;
  restartFeedbackPlayback();
}

void restartFeedbackPlayback(){
  feedbackLoopPauseStartedMillis = -1;
  clearInterpretationSeek();
  clearVideoEndFreezeState();
  resetVibrationTimelineForCurrentVideo();

  if(!hasVideo[screen] || videos[screen] == null){
    feedbackPlaybackComplete = true;
    return;
  }

  videoStartMillis = millis();
  videoRestartAttempts = 0;

  try {
    videos[screen].pause();
    videos[screen].volume(currentVideoAudioVolume());
    videos[screen].play();
    videos[screen].jump(0);
    videos[screen].volume(currentVideoAudioVolume());
  } catch(Exception e){
    feedbackPlaybackComplete = true;
    println("Erro ao iniciar video no feedback: " + titles[screen] + " -> " + e.getMessage());
  }
}

void updateFeedbackVideoLoop(){
  if(appState != 1 || phase != 3){
    feedbackLoopPauseStartedMillis = -1;
    return;
  }

  if(!hasVideo[screen] || videos[screen] == null){
    feedbackPlaybackComplete = true;
    return;
  }

  if(feedbackLoopPauseStartedMillis >= 0){
    if(millis() - feedbackLoopPauseStartedMillis >= FEEDBACK_LOOP_PAUSE_MS){
      restartFeedbackPlayback();
    }
    return;
  }

  if(currentVideoFinished()){
    feedbackPlaybackComplete = true;
    stopBHapticsVibration();
    freezeCurrentVideoAtSafeEnd();
    feedbackLoopPauseStartedMillis = millis();
  }
}

void clearFeedbackPlaybackState(){
  feedbackPlaybackComplete = false;
  feedbackLoopPauseStartedMillis = -1;
}

void drawRightPanel(){
  float x = margin + leftW + gutter;
  float y = contentTop;
  float w = rightW;
  float h = contentBottom - contentTop;

  noStroke();
  fill(card);
  rect(x, y, w, h, 14);

  fill(white);
  textAlign(LEFT, TOP);
  textSize(TYPE_SECTION);
  text(titles[screen], x + 22, y + 18);

  fill(muted);
  textSize(TYPE_LABEL);
  text("O que observar", x + 22, y + 45);

  stroke(strokeC);
  strokeWeight(1);
  line(x + 22, y + 70, x + w - 22, y + 70);
  noStroke();

  String[] points = observationPoints[screen];
  float lineX = x + 38;
  float listTop = y + 88;
  float availableH = h - 112;
  float itemH = availableH / points.length;
  float textW = w - 82;
  float textH = itemH - 8;

  stroke(grey);
  strokeWeight(1.5);
  line(lineX, listTop + 10, lineX, listTop + itemH * (points.length - 1) + 10);
  noStroke();

  for(int i = 0; i < points.length; i++){
    float cy = listTop + i * itemH + 10;
    float progression = points.length <= 1 ? 0 : (float)i / (points.length - 1);
    color stepColor = lerpColor(purple, color(58, 82, 120), progression);

    fill(stepColor);
    ellipse(lineX, cy, 18, 18);

    fill(white);
    textAlign(CENTER, CENTER);
    textSize(TYPE_CAPTION);
    text(str(i + 1), lineX, cy);

    fill(lerpColor(white, color(178, 188, 210), min(1, progression * 0.85)));
    textAlign(LEFT, TOP);
    textSize(TYPE_LABEL);
    text(points[i], lineX + 22, cy - 11, textW, textH);
  }
}
void drawBottomSection(){
  float y = contentBottom + 20;
  float bh = 100;

  float explainX = margin;
  float explainW = leftW;

  noStroke();
  fill(card);
  rect(explainX, y, explainW, bh, 14);

  fill(purpleDim);
  float iconCenterY = y + 24;
  ellipse(explainX + 42, iconCenterY, 44, 44);
  drawBookIcon(explainX + 42, iconCenterY, 15, purpleText);

  fill(white);
  textAlign(LEFT, TOP);
  textSize(TYPE_LABEL);
  text("O que é este comportamento", explainX + 72, y + 14);

  fill(muted);
  textSize(TYPE_LABEL);
  text(refinedExplanations[screen], explainX + 72, y + 34, explainW - 90, bh - 42);

  float buttonsX = margin + leftW + gutter;
  float btnH = 42;
  float btnGap = 12;

  replayW = (rightW - btnGap) / 2;
  replayH = btnH;
  replayX = buttonsX;
  replayY = y + (bh - btnH) / 2;

  phase2NextW = replayW;
  phase2NextH = btnH;
  phase2NextX = buttonsX + replayW + btnGap;
  phase2NextY = replayY;
  drawActionButton(replayX, replayY, replayW, replayH, "Rever", "review", false, true);
  drawActionButton(phase2NextX, phase2NextY, phase2NextW, phase2NextH, "Avançar", "next", true, true);
}


void drawIsolatedReviewScreen(){
  isolatedBackW = 110;
  isolatedBackH = 38;
  isolatedBackX = margin;
  isolatedBackY = 22;
  drawActionButton(isolatedBackX, isolatedBackY, isolatedBackW, isolatedBackH, "Sair", "close", false, true);

  fill(white);
  textAlign(CENTER, CENTER);
  textSize(TYPE_SECTION);
  text("Rever isoladamente", baseW/2, 41);

  float dotSpacing = 14;
  float dotsTotal = titles.length * dotSpacing;
  float dotsStartX = baseW - margin - dotsTotal;
  float dotsY = 41;

  for(int i = 0; i < titles.length; i++){
    float dx = dotsStartX + i * dotSpacing;
    if(i == screen){
      fill(purple);
      ellipse(dx, dotsY, 8, 8);
    } else if(i < screen){
      fill(purpleDim);
      ellipse(dx, dotsY, 6, 6);
    } else {
      fill(greyDark);
      ellipse(dx, dotsY, 6, 6);
    }
  }

  fill(muted);
  textAlign(RIGHT, CENTER);
  textSize(TYPE_LABEL);
  text((behaviorSequencePosition + 1) + " / " + titles.length, baseW - margin - dotsTotal - 16, dotsY);

  fill(white);
  textAlign(LEFT, CENTER);
  textSize(TYPE_SUBHEADING);
  text(titles[screen], margin + isolatedBackW + 20, 41);

  float vw = baseW * 0.70;
  float vh = baseH * 0.58;
  float vx = (baseW - vw) / 2;
  float vy = 78;

  noStroke();
  fill(card);
  rect(vx, vy, vw, vh, 14);

  if(hasVideo[screen] && videoReadyForDrawing(videos[screen])){
    drawVideoFit(videos[screen], vx, vy, vw, vh);
  } else {
    fill(greyDark);
    rect(vx, vy, vw, vh, 14);
    fill(grey);
    textAlign(CENTER, CENTER);
    textSize(TYPE_BODY);
    text("Video " + (behaviorSequencePosition + 1), vx + vw/2, vy + vh/2);
  }

  isolatedPrevW = 160;
  isolatedPrevH = 48;
  isolatedPrevX = baseW/2 - isolatedPrevW/2;
  isolatedPrevY = vy + vh + 28;
  drawActionButton(isolatedPrevX, isolatedPrevY, isolatedPrevW, isolatedPrevH, "Anterior", "back", false, behaviorSequencePosition > 0);
}

void drawRoundedButton(float x, float y, float w, float h,
                       color bg_, color fg_, String label, boolean arrow){
  noStroke();
  fill(bg_);
  rect(x, y, w, h, 12);

  fill(fg_);
  textAlign(CENTER, CENTER);
  textSize(TYPE_SUBHEADING);
  text(label + (arrow ? "  ->" : ""), x + w/2, y + h/2);
}

void startActivity1Prototype(){
  logResearchEvent("activity_start", "activity1", "observation", -1, "direct_start=true");
  stopAllVideos();
  stopBHapticsVibration();
  clearInterpretationSeek();
  replayVibrationActive = false;
  guidedVideoFinishedMillis = -1;
  isolatedVideoFinishedMillis = -1;
  activity1ObservationFinishedMillis = -1;
  resetActivityObservationSlides(0);
  phase = 1;
  t = 0;
  animating = false;
  activity1Step = 0;
  activity1Dragging = false;
  activity1DragKind = 0;
  activity1DragValue = -1;
  resetActivity1Step();
  appState = 3;
  startActivityObservationSlides(0);
}

void startActivity2Prototype(){
  logResearchEvent("activity_start", "activity2", "observation", -1, "direct_start=true");
  stopAllVideos();
  stopBHapticsVibration();
  clearInterpretationSeek();
  replayVibrationActive = false;
  guidedVideoFinishedMillis = -1;
  isolatedVideoFinishedMillis = -1;
  activity2ObservationFinishedMillis = -1;
  resetActivityObservationSlides(1);
  phase = 1;
  t = 0;
  animating = false;
  activity2Step = 0;
  resetActivity2Selections();
  appState = 5;
  startActivityObservationSlides(1);
}

void startActivity3Prototype(){
  logResearchEvent("activity_start", "activity3", "observation", -1, "direct_start=true");
  if(!videosLoadingStarted){
    startVideoLoading();
  }

  stopAllVideos();
  stopBHapticsVibration();
  clearInterpretationSeek();
  replayVibrationActive = false;
  guidedVideoFinishedMillis = -1;
  isolatedVideoFinishedMillis = -1;
  activity3ObservationFinishedMillis = -1;
  resetActivity3GrowlPlayCounts();
  prepareActivity3Order();
  activity3VideoIndex = activity3Order[activity3SequencePosition];
  logResearchEvent("activity3_scenario_start", "activity3", "observation", activity3VideoIndex, activity3ScenarioResearchDetails());
  activity3VideoStarted = false;
  phase = 1;
  t = 0;
  animating = false;
  activity3Step = 0;
  activity3Dragging = false;
  activity3DragKind = 0;
  activity3DragValue = -1;
  resetActivity3All();
  appState = 6;
  playCurrentActivity3Video();
}

void resetActivity3GrowlPlayCounts(){
  for(int scenario = 0; scenario < activity3GrowlPlayCounts.length; scenario++){
    for(int i = 0; i < activity3GrowlPlayCounts[scenario].length; i++){
      activity3GrowlPlayCounts[scenario][i] = 0;
    }
  }
}

void startActivityPlaceholder(int activityNumber){
  stopAllVideos();
  stopBHapticsVibration();
  clearInterpretationSeek();
  replayVibrationActive = false;
  placeholderActivity = activityNumber;
  appState = 4;
}

void startGuidedExperience(){
  if(!videosReady()){
    if(!videosLoadingStarted){
      startVideoLoading();
    }
    println("A experiencia ainda nao iniciou: videos em preparacao.");
    return;
  }

  stopCurrentVideo();
  for(int i = 0; i < interpretationTimes.length; i++){
    clearInterpretationAnswerForScreen(i);
  }
  interpretationDragging = false;
  interpretationTaskStage = INTERPRETATION_STAGE_TIME;
  clearInterpretationSeek();
  prepareBehaviorOrder();
  screen = behaviorOrder[behaviorSequencePosition];
  phase = 1;
  t = 0;
  animating = false;
  guidedVideoFinishedMillis = -1;
  isolatedVideoFinishedMillis = -1;
  replayVibrationActive = false;
  appState = 1;
  logResearchEvent("activity_start", "activity4", "observation", screen, "behavior=" + titles[screen] + ";sequence_position=" + behaviorSequencePosition);
  playCurrentVideo();
}

void startIsolatedReview(){
  if(!videosReady()){
    if(!videosLoadingStarted){
      startVideoLoading();
    }
    println("A revisao ainda nao iniciou: videos em preparacao.");
    return;
  }

  stopCurrentVideo();
  prepareBehaviorOrder();
  screen = behaviorOrder[behaviorSequencePosition];
  phase = 1;
  t = 0;
  animating = false;
  guidedVideoFinishedMillis = -1;
  isolatedVideoFinishedMillis = -1;
  replayVibrationActive = false;
  appState = 2;
  playCurrentVideo();
}

void setupVibrationTimelines(){
  clearAllVibrationCues();
  clearAllActivity3VibrationCues();

  if(ENABLE_TEST_VIBRATION_CUES){
    for(int i = 0; i < titles.length; i++){
      addProgrammedCue(i, 1.00, 7, 350);
    }
  }

  // Timings finais neste formato:
  // addProgrammedCue(videoIndex, tempoEmSegundos, pontos, duracaoMs, intensidade);
  //
  // Mapeamento dos tres pontos da Tactosy esquerda no bitmask:
  // ponto 1 = 1, ponto 2 = 2, ponto 3 = 4, todos = 7.
  // Intensidades: VIB_LOW, VIB_MEDIUM, VIB_HIGH.
  //
  // Os comportamentos foram atualizados para cinco novos videos. Os timings
  // antigos foram removidos para nao ativar vibracoes incongruentes.
  // Atividade 4: interpretacao de sinais de desconforto associados a presenca humana.
  // Os timings usam a intensidade do feedback.
  // Durante a observacao, a interface aplica uma escala mais subtil.
  // Continuos longos usam uma intensidade ainda mais suave para nao sugerir perigo.

  // 1) Abaixamento corporal
  addProgrammedCue(0, 5.00, 7, 300, VIB_LOW);
  addProgrammedCue(0, 7.00, 7, 2000, VIB_LOW);

  // 2) Afastamento
  addProgrammedCue(1, 2.00, 7, 300, VIB_LOW);
  addProgrammedCue(1, 5.00, 7, 300, VIB_LOW);
  addProgrammedCue(1, 8.00, 7, 300, VIB_LOW);

  // 3) Desvio de cabeca e olhar
  addProgrammedCue(2, 2.50, 7, 300, VIB_LOW);
  addProgrammedCue(2, 7.00, 7, 2000, VIB_LOW);

  // 4) Levantamento de pata dianteira
  addProgrammedCue(3, 2.50, 7, 3500, VIB_LONG_LOW);

  // 5) Recuo corporal
  addProgrammedCue(4, 3.00, 7, 300, VIB_LOW);
  addProgrammedCue(4, 6.00, 7, 300, VIB_LOW);
  addProgrammedCue(4, 8.00, 7, 300, VIB_LOW);

  // Atividade 3: rosnados no contexto.
  // Indices: 0 ameaca cenario 1, 1 ameaca cenario 2,
  // 2 guarda alimento cenario 1, 3 guarda alimento cenario 2,
  // 4 ludico cenario 1, 5 ludico cenario 2.
  // Continuos leves usam VIB_LONG_LOW para nao antecipar uma resposta forte.

  // 1) Ameaca cenario 1
  addActivity3ProgrammedCue(0, 5.00, 7, 4000, VIB_LONG_LOW);

  // 2) Ameaca cenario 2
  addActivity3ProgrammedCue(1, 6.00, 7, 3000, VIB_LONG_LOW);

  // 3) Guarda alimento cenario 1
  addActivity3ProgrammedCue(2, 6.00, 7, 180, VIB_LOW);
  addActivity3ProgrammedCue(2, 8.00, 7, 2000, VIB_LONG_LOW);

  // 4) Guarda alimento cenario 2
  addActivity3ProgrammedCue(3, 5.00, 7, 300, VIB_LOW);
  addActivity3ProgrammedCue(3, 8.00, 7, 2000, VIB_LONG_LOW);

  // 5) Ludico cenario 1
  addActivity3ProgrammedCue(4, 3.00, 7, 2000, VIB_LONG_LOW);
  addActivity3ProgrammedCue(4, 6.00, 7, 2000, VIB_LONG_LOW);

  // 6) Ludico cenario 2
  addActivity3ProgrammedCue(5, 1.00, 7, 300, VIB_LOW);
  addActivity3ProgrammedCue(5, 4.00, 7, 2000, VIB_LONG_LOW);
}

void clearAllVibrationCues(){
  for(int i = 0; i < vibrationCueCounts.length; i++){
    vibrationCueCounts[i] = 0;
    vibrationCueCursor[i] = 0;
  }
}

void clearAllActivity3VibrationCues(){
  for(int i = 0; i < activity3VibrationCueCounts.length; i++){
    activity3VibrationCueCounts[i] = 0;
    activity3VibrationCueCursor[i] = 0;
  }
}

void addProgrammedCue(int videoIndex, float timeSeconds, int pointMask, int durationMs){
  addProgrammedCue(videoIndex, timeSeconds, pointMask, durationMs, VIB_HIGH);
}

void addProgrammedCue(int videoIndex, float timeSeconds, int pointMask, int durationMs, int intensity){
  if(videoIndex < 0 || videoIndex >= vibrationCueCounts.length) return;
  if(vibrationCueCounts[videoIndex] >= MAX_VIBRATION_CUES) return;

  int index = vibrationCueCounts[videoIndex];
  vibrationCueTimes[videoIndex][index] = max(0.0f, timeSeconds);
  vibrationCuePointMasks[videoIndex][index] = constrain(pointMask, 0, 7);
  vibrationCueDurations[videoIndex][index] = constrain(durationMs, 100, 5000);
  vibrationCueIntensities[videoIndex][index] = constrain(intensity, 0, 100);
  vibrationCueCounts[videoIndex]++;
  sortVibrationCues(videoIndex);
}

void addActivity3ProgrammedCue(int videoIndex, float timeSeconds, int pointMask, int durationMs, int intensity){
  if(videoIndex < 0 || videoIndex >= activity3VibrationCueCounts.length) return;
  if(activity3VibrationCueCounts[videoIndex] >= MAX_VIBRATION_CUES) return;

  int index = activity3VibrationCueCounts[videoIndex];
  activity3VibrationCueTimes[videoIndex][index] = max(0.0f, timeSeconds);
  activity3VibrationCuePointMasks[videoIndex][index] = constrain(pointMask, 0, 7);
  activity3VibrationCueDurations[videoIndex][index] = constrain(durationMs, 100, 5000);
  activity3VibrationCueIntensities[videoIndex][index] = constrain(intensity, 0, 100);
  activity3VibrationCueCounts[videoIndex]++;
  sortActivity3VibrationCues(videoIndex);
}

void sortVibrationCues(int videoIndex){
  int count = vibrationCueCounts[videoIndex];

  for(int i = 0; i < count - 1; i++){
    for(int j = i + 1; j < count; j++){
      if(vibrationCueTimes[videoIndex][j] < vibrationCueTimes[videoIndex][i]){
        float timeSwap = vibrationCueTimes[videoIndex][i];
        int maskSwap = vibrationCuePointMasks[videoIndex][i];
        int durationSwap = vibrationCueDurations[videoIndex][i];
        int intensitySwap = vibrationCueIntensities[videoIndex][i];

        vibrationCueTimes[videoIndex][i] = vibrationCueTimes[videoIndex][j];
        vibrationCuePointMasks[videoIndex][i] = vibrationCuePointMasks[videoIndex][j];
        vibrationCueDurations[videoIndex][i] = vibrationCueDurations[videoIndex][j];
        vibrationCueIntensities[videoIndex][i] = vibrationCueIntensities[videoIndex][j];

        vibrationCueTimes[videoIndex][j] = timeSwap;
        vibrationCuePointMasks[videoIndex][j] = maskSwap;
        vibrationCueDurations[videoIndex][j] = durationSwap;
        vibrationCueIntensities[videoIndex][j] = intensitySwap;
      }
    }
  }
}

void sortActivity3VibrationCues(int videoIndex){
  int count = activity3VibrationCueCounts[videoIndex];

  for(int i = 0; i < count - 1; i++){
    for(int j = i + 1; j < count; j++){
      if(activity3VibrationCueTimes[videoIndex][j] < activity3VibrationCueTimes[videoIndex][i]){
        float timeSwap = activity3VibrationCueTimes[videoIndex][i];
        int maskSwap = activity3VibrationCuePointMasks[videoIndex][i];
        int durationSwap = activity3VibrationCueDurations[videoIndex][i];
        int intensitySwap = activity3VibrationCueIntensities[videoIndex][i];

        activity3VibrationCueTimes[videoIndex][i] = activity3VibrationCueTimes[videoIndex][j];
        activity3VibrationCuePointMasks[videoIndex][i] = activity3VibrationCuePointMasks[videoIndex][j];
        activity3VibrationCueDurations[videoIndex][i] = activity3VibrationCueDurations[videoIndex][j];
        activity3VibrationCueIntensities[videoIndex][i] = activity3VibrationCueIntensities[videoIndex][j];

        activity3VibrationCueTimes[videoIndex][j] = timeSwap;
        activity3VibrationCuePointMasks[videoIndex][j] = maskSwap;
        activity3VibrationCueDurations[videoIndex][j] = durationSwap;
        activity3VibrationCueIntensities[videoIndex][j] = intensitySwap;
      }
    }
  }
}

void resetVibrationTimelineForCurrentVideo(){
  if(screen >= 0 && screen < vibrationCueCursor.length){
    vibrationCueCursor[screen] = 0;
  }
}

void resetActivity3VibrationTimelineForCurrentVideo(){
  if(activity3VideoIndex >= 0 && activity3VideoIndex < activity3VibrationCueCursor.length){
    activity3VibrationCueCursor[activity3VideoIndex] = 0;
  }
}

void skipElapsedVibrationCuesForCurrentVideo(){
  if(screen < 0 || screen >= vibrationCueCounts.length) return;

  float elapsed = currentVideoElapsedSeconds() + 0.02;
  int cursor = vibrationCueCursor[screen];

  while(cursor < vibrationCueCounts[screen] && vibrationCueTimes[screen][cursor] <= elapsed){
    cursor++;
  }

  vibrationCueCursor[screen] = cursor;
}

void updateVibrationTimeline(){
  if(appState != 1 || (phase != 1 && phase != 3)) return;
  if(phase == 3 && feedbackLoopPauseStartedMillis >= 0) return;
  if(screen < 0 || screen >= vibrationCueCounts.length) return;
  if(!hasVideo[screen] || videos[screen] == null) return;
  if(!videoReadyForDrawing(videos[screen])) return;

  int count = vibrationCueCounts[screen];
  int cursor = vibrationCueCursor[screen];
  if(cursor >= count){
    return;
  }

  float elapsed = currentVideoElapsedSeconds();

  while(cursor < count && elapsed >= vibrationCueTimes[screen][cursor]){
    sendHandVibration(
      vibrationCuePointMasks[screen][cursor],
      vibrationCueDurations[screen][cursor],
      vibrationIntensityForCurrentPhase(vibrationCueIntensities[screen][cursor])
    );

    cursor++;
  }

  vibrationCueCursor[screen] = cursor;
}

void updateActivity3VibrationTimeline(){
  if(appState != 6 || activity3Step != 0) return;
  if(activity3VideoIndex < 0 || activity3VideoIndex >= activity3VibrationCueCounts.length) return;
  if(!activity3VideoStarted) return;
  if(!activity3HasVideo[activity3VideoIndex] || activity3Videos[activity3VideoIndex] == null) return;

  int count = activity3VibrationCueCounts[activity3VideoIndex];
  int cursor = activity3VibrationCueCursor[activity3VideoIndex];
  if(cursor >= count) return;

  float elapsed = currentActivity3VideoElapsedSeconds();

  while(cursor < count && elapsed >= activity3VibrationCueTimes[activity3VideoIndex][cursor]){
    sendHandVibration(
      activity3VibrationCuePointMasks[activity3VideoIndex][cursor],
      activity3VibrationCueDurations[activity3VideoIndex][cursor],
      activity3VibrationCueIntensities[activity3VideoIndex][cursor]
    );

    cursor++;
  }

  activity3VibrationCueCursor[activity3VideoIndex] = cursor;
}

int vibrationIntensityForCurrentPhase(int intensity){
  if(appState == 1 && phase == 1){
    return constrain(
      max(OBSERVATION_VIBRATION_MIN_INTENSITY, round(intensity * OBSERVATION_VIBRATION_SCALE)),
      0,
      100
    );
  }

  return intensity;
}

float currentVideoMarkTimeSeconds(){
  if(hasVideo[screen] && videos[screen] != null){
    try {
      float movieTime = videos[screen].time();
      if(movieTime >= 0) return movieTime;
    } catch(Exception e){}
  }

  return currentVideoElapsedSeconds();
}

void addMarkedVibrationCue(int pointMask){
  if(appState == 0){
    println("Marca ignorada: abre primeiro um video.");
    return;
  }

  float timeSeconds = currentVideoMarkTimeSeconds();
  addProgrammedCue(screen, timeSeconds, pointMask, DEFAULT_MARK_DURATION_MS);
  sendHandVibration(pointMask, DEFAULT_MARK_DURATION_MS);
  skipElapsedVibrationCuesForCurrentVideo();

  println(
    "MARCA video " + screen + " (" + titles[screen] + ")  " +
    nf(timeSeconds, 0, 2) + "s  pontos=" + pointMask +
    "  duracao=" + DEFAULT_MARK_DURATION_MS + "ms"
  );
}

void printVibrationMarkingHelp(){
  println("");
  println("MODO DE MARCACAO DE VIBRACOES");
  println("M = ligar/desligar modo de marcacao");
  println("1/2/3 = marcar ponto da Tactosy no tempo atual do video");
  println("A = marcar todos os pontos");
  println("T = testar vibracao direta em todos os pontos");
  println("P = imprimir timings do video atual");
  println("O = imprimir timings de todos os videos");
  println("C = limpar timings do video atual");
  println("");
}

void printCurrentVideoCues(){
  printVideoCues(screen);
}

void printAllVideoCues(){
  for(int i = 0; i < titles.length; i++){
    printVideoCues(i);
  }
}

void printVideoCues(int videoIndex){
  println("");
  println("// " + videoIndex + " - " + titles[videoIndex]);

  for(int i = 0; i < vibrationCueCounts[videoIndex]; i++){
    println(
      "addProgrammedCue(" + videoIndex + ", " +
      nf(vibrationCueTimes[videoIndex][i], 0, 2) + ", " +
      vibrationCuePointMasks[videoIndex][i] + ", " +
      vibrationCueDurations[videoIndex][i] + ", " +
      vibrationCueIntensities[videoIndex][i] + ");"
    );
  }
}

void clearCurrentVideoCues(){
  if(appState == 0) return;

  vibrationCueCounts[screen] = 0;
  vibrationCueCursor[screen] = 0;
  println("Timings limpos para video " + screen + " - " + titles[screen]);
}

float currentVideoElapsedSeconds(){
  if(hasVideo[screen] && videos[screen] != null){
    try {
      float movieTime = videos[screen].time();
      if(movieTime >= 0){
        return movieTime;
      }
    } catch(Exception e){}
  }

  return max(0.0f, (millis() - videoStartMillis) / 1000.0f);
}

float currentVideoEndMarginSeconds(){
  if(screen >= 0 && screen < videoEndMargins.length){
    return max(VIDEO_END_MARGIN_SECONDS, videoEndMargins[screen]);
  }

  return VIDEO_END_MARGIN_SECONDS;
}

void clearVideoEndFreezeState(){
  currentVideoEndFrozen = false;
  videoEndFreezePauseMillis = -1;
}

void freezeCurrentVideoAtSafeEnd(){
  if(currentVideoEndFrozen) return;
  if(!hasVideo[screen] || videos[screen] == null) return;

  try {
    float duration = videos[screen].duration();
    if(duration <= 0) return;

    float safeTime = max(0, duration - currentVideoEndMarginSeconds());
    videos[screen].volume(currentVideoAudioVolume());
    videos[screen].play();
    videos[screen].jump(safeTime);
    videoEndFreezePauseMillis = millis() + VIDEO_END_FREEZE_SETTLE_MS;
    currentVideoEndFrozen = true;
  } catch(Exception e){
    println("Erro ao congelar frame final: " + titles[screen] + " -> " + e.getMessage());
  }
}

void updateVideoEndFreezePause(){
  if(videoEndFreezePauseMillis < 0) return;
  if(millis() < videoEndFreezePauseMillis) return;

  try {
    if(hasVideo[screen] && videos[screen] != null){
      videos[screen].pause();
      videos[screen].volume(currentVideoAudioVolume());
    }
  } catch(Exception ignored){}

  videoEndFreezePauseMillis = -1;
}

boolean currentVideoFinished(){
  if(!hasVideo[screen] || videos[screen] == null) return false;
  if(millis() - videoStartMillis < 500) return false;

  try {
    float duration = videos[screen].duration();
    if(duration <= 0) return false;

    float elapsedByClock = max(0.0f, (millis() - videoStartMillis) / 1000.0f);
    float elapsedByMovie = 0;

    try {
      elapsedByMovie = max(0.0f, videos[screen].time());
    } catch(Exception ignored){}

    float elapsed = max(elapsedByClock, elapsedByMovie);
    return elapsed >= max(0, duration - currentVideoEndMarginSeconds());
  } catch(Exception e){
    return false;
  }
}

void updateActivity1ObservationAutoAdvance(){
  if(appState != 3 || activity1Step != 0){
    activity1ObservationFinishedMillis = -1;
    resetActivityObservationSlides(0);
    return;
  }

  if(!activityObservationSlidesComplete(0)){
    activity1ObservationFinishedMillis = -1;
    return;
  }

  if(activity1ObservationFinishedMillis < 0){
    activity1ObservationFinishedMillis = millis();
    return;
  }

  if(millis() - activity1ObservationFinishedMillis >= ACTIVITY1_OBSERVATION_AUTO_ADVANCE_DELAY_MS){
    enterActivity1Tasks();
  }
}

void updateActivity2ObservationAutoAdvance(){
  if(appState != 5 || activity2Step != 0){
    activity2ObservationFinishedMillis = -1;
    resetActivityObservationSlides(1);
    return;
  }

  if(!activityObservationSlidesComplete(1)){
    activity2ObservationFinishedMillis = -1;
    return;
  }

  if(activity2ObservationFinishedMillis < 0){
    activity2ObservationFinishedMillis = millis();
    return;
  }

  if(millis() - activity2ObservationFinishedMillis >= ACTIVITY2_OBSERVATION_AUTO_ADVANCE_DELAY_MS){
    enterActivity2Task();
  }
}

void updateActivity3ObservationAutoAdvance(){
  if(appState != 6 || activity3Step != 0){
    activity3ObservationFinishedMillis = -1;
    return;
  }

  if(!activity3CurrentVideoFinished()){
    activity3ObservationFinishedMillis = -1;
    return;
  }

  if(activity3ObservationFinishedMillis < 0){
    try {
      activity3Videos[activity3VideoIndex].pause();
      activity3Videos[activity3VideoIndex].volume(currentVideoAudioVolume());
    } catch(Exception ignored){}
    activity3ObservationFinishedMillis = millis();
    return;
  }

  if(millis() - activity3ObservationFinishedMillis >= ACTIVITY3_OBSERVATION_AUTO_ADVANCE_DELAY_MS){
    advanceActivity3Observation();
  }
}

boolean activity3CurrentVideoReady(){
  if(activity3VideoIndex < 0 || activity3VideoIndex >= activity3Videos.length) return false;
  if(!activity3HasVideo[activity3VideoIndex] || activity3Videos[activity3VideoIndex] == null) return false;
  return videoReadyForDrawing(activity3Videos[activity3VideoIndex]);
}

boolean activity3VideoPlaybackStalled(){
  if(appState != 6 || activity3Step != 0) return false;
  if(!activity3VideoStarted) return false;
  if(activity3VideoIndex < 0 || activity3VideoIndex >= activity3Videos.length) return false;
  if(activity3Videos[activity3VideoIndex] == null) return false;
  if(millis() - activity3VideoStartMillis < 900) return false;

  if(activity3VideoWatchdogIndex != activity3VideoIndex){
    resetActivity3VideoWatchdog();
    return false;
  }

  try {
    Movie video = activity3Videos[activity3VideoIndex];
    float duration = video.duration();
    float currentTime = max(0, video.time());

    if(duration <= 0 || currentTime >= max(0, duration - VIDEO_END_MARGIN_SECONDS)){
      activity3VideoWatchdogLastTime = currentTime;
      activity3VideoWatchdogLastProgressMillis = millis();
      return false;
    }

    if(activity3VideoWatchdogLastTime < 0 ||
       currentTime > activity3VideoWatchdogLastTime + ACTIVITY3_VIDEO_STALL_EPSILON ||
       currentTime < activity3VideoWatchdogLastTime - ACTIVITY3_VIDEO_STALL_EPSILON){
      activity3VideoWatchdogLastTime = currentTime;
      activity3VideoWatchdogLastProgressMillis = millis();
      return false;
    }

    return millis() - activity3VideoWatchdogLastProgressMillis >= ACTIVITY3_VIDEO_STALL_GRACE_MS;
  } catch(Exception ignored){
    return false;
  }
}

void wakeCurrentActivity3Video(String reason){
  if(activity3VideoIndex < 0 || activity3VideoIndex >= activity3Videos.length) return;
  if(!activity3HasVideo[activity3VideoIndex] || activity3Videos[activity3VideoIndex] == null) return;
  if(millis() - activity3VideoStartMillis < 700) return;
  if(activity3VideoRestartAttempts[activity3VideoIndex] >= 6) return;

  activity3VideoRestartAttempts[activity3VideoIndex]++;
  activity3VideoStartMillis = millis();
  resetActivity3VideoWatchdog();
  println(
    "A tentar acordar video da Atividade 3 (" + reason + "): " +
    activity3ScenarioTitles[activity3VideoIndex] +
    " tentativa " + activity3VideoRestartAttempts[activity3VideoIndex]
  );

  try {
    Movie video = activity3Videos[activity3VideoIndex];
    video.stop();
    video.volume(currentVideoAudioVolume());
    video.play();
    video.jump(0);
    video.volume(currentVideoAudioVolume());
    resetActivity3VibrationTimelineForCurrentVideo();
  } catch(Exception e){
    println("Erro ao reativar video da Atividade 3: " + activity3ScenarioTitles[activity3VideoIndex] + " -> " + e.getMessage());
  }

  if(activity3VideoRestartAttempts[activity3VideoIndex] == 3 &&
     activity3PreparedVideoPaths[activity3VideoIndex] != null){
    try {
      activity3Videos[activity3VideoIndex].stop();
      activity3Videos[activity3VideoIndex] = new Movie(this, activity3PreparedVideoPaths[activity3VideoIndex]);
      activity3Videos[activity3VideoIndex].volume(currentVideoAudioVolume());
      activity3Videos[activity3VideoIndex].play();
      activity3Videos[activity3VideoIndex].jump(0);
      activity3Videos[activity3VideoIndex].volume(currentVideoAudioVolume());
      resetActivity3VibrationTimelineForCurrentVideo();
      resetActivity3VideoWatchdog();
      activity3HasVideo[activity3VideoIndex] = true;
      activity3VideoFrameDecoded[activity3VideoIndex] = false;
      println("Video da Atividade 3 recriado: " + activity3ScenarioTitles[activity3VideoIndex]);
    } catch(Exception e){
      activity3Videos[activity3VideoIndex] = null;
      activity3HasVideo[activity3VideoIndex] = false;
      activity3VideoStarted = false;
      println("Erro ao recriar video da Atividade 3: " + activity3ScenarioTitles[activity3VideoIndex] + " -> " + e.getMessage());
    }
  }
}

void ensureCurrentActivity3VideoStarted(){
  if(appState != 6 || activity3Step != 0) return;
  if(activity3VideoIndex < 0 || activity3VideoIndex >= activity3Videos.length) return;
  if(!activity3HasVideo[activity3VideoIndex] || activity3Videos[activity3VideoIndex] == null) return;

  if(!activity3VideoStarted){
    playCurrentActivity3Video();
    return;
  }

  if(activity3CurrentVideoReady()){
    if(activity3VideoPlaybackStalled()){
      wakeCurrentActivity3Video("tempo parado");
    }
    return;
  }

  wakeCurrentActivity3Video("sem frame pronto");
}

void playCurrentActivity3Video(){
  if(activity3VideoIndex < 0 || activity3VideoIndex >= activity3Videos.length) return;
  if(!activity3HasVideo[activity3VideoIndex] || activity3Videos[activity3VideoIndex] == null) return;

  pauseActivity3VideosExcept(activity3VideoIndex);
  activity3ObservationFinishedMillis = -1;
  activity3VideoStarted = true;
  activity3VideoStartMillis = millis();
  activity3VideoRestartAttempts[activity3VideoIndex] = 0;
  resetActivity3VibrationTimelineForCurrentVideo();
  resetActivity3VideoWatchdog();

  try {
    Movie video = activity3Videos[activity3VideoIndex];
    video.pause();
    video.volume(currentVideoAudioVolume());
    video.play();
    video.jump(0);
    video.volume(currentVideoAudioVolume());
  } catch(Exception e){
    activity3VideoStarted = false;
    println("Erro ao iniciar video da Atividade 3: " + activity3ScenarioTitles[activity3VideoIndex] + " -> " + e.getMessage());
  }
}

float currentActivity3VideoElapsedSeconds(){
  if(!activity3VideoStarted || activity3VideoIndex < 0 || activity3VideoIndex >= activity3Videos.length) return 0;
  Movie video = activity3Videos[activity3VideoIndex];
  if(video == null) return 0;

  try {
    return max(0, video.time());
  } catch(Exception ignored){
    return 0;
  }
}

boolean activity3CurrentVideoFinished(){
  if(!activity3VideoStarted || activity3VideoIndex < 0 || activity3VideoIndex >= activity3Videos.length) return false;
  Movie video = activity3Videos[activity3VideoIndex];
  if(video == null) return false;

  try {
    float duration = video.duration();
    return duration > 0 && video.time() >= max(0, duration - VIDEO_END_MARGIN_SECONDS);
  } catch(Exception ignored){
    return false;
  }
}

boolean canAdvanceActivity3Observation(){
  if(activity3VideoIndex < 0 || activity3VideoIndex >= activity3Videos.length) return true;
  if(activity3FilesPrepared && activity3MoviesPrepared && !activity3HasVideo[activity3VideoIndex]) return true;
  return currentActivity3VideoElapsedSeconds() >= MIN_SECONDS_BEFORE_ADVANCE || activity3CurrentVideoFinished();
}

void advanceActivity3Observation(){
  enterActivity3GrowlChoice();
}

void advanceActivity3AfterFeedback(){
  if(!onLastActivity3Step()){
    activity3SequencePosition++;
    activity3VideoIndex = activity3Order[activity3SequencePosition];
    activity3VideoStarted = false;
    activity3VideoStartMillis = 0;
    activity3ObservationFinishedMillis = -1;
    resetActivity3All();
    activity3Step = 0;
    logResearchEvent("activity3_scenario_start", "activity3", "observation", activity3VideoIndex, activity3ScenarioResearchDetails());
    playCurrentActivity3Video();
    return;
  }

  returnToHomeMenu();
}

void updateGuidedAutoAdvance(){
  if(appState != 1 || phase != 1){
    guidedVideoFinishedMillis = -1;
    return;
  }

  if(!currentVideoFinished()){
    guidedVideoFinishedMillis = -1;
    return;
  }

  if(guidedVideoFinishedMillis < 0){
    freezeCurrentVideoAtSafeEnd();
    guidedVideoFinishedMillis = millis();
    return;
  }

  if(millis() - guidedVideoFinishedMillis >= GUIDED_AUTO_ADVANCE_DELAY_MS){
    phase = 2;
    t = 0;
    animating = false;
    guidedVideoFinishedMillis = -1;
    enterInterpretationTask();
  }
}

void updateIsolatedAutoAdvance(){
  if(appState != 2){
    isolatedVideoFinishedMillis = -1;
    return;
  }

  if(onLastBehaviorStep()){
    if(currentVideoFinished()){
      freezeCurrentVideoAtSafeEnd();
    }
    return;
  }

  if(!currentVideoFinished()){
    isolatedVideoFinishedMillis = -1;
    return;
  }

  if(isolatedVideoFinishedMillis < 0){
    freezeCurrentVideoAtSafeEnd();
    isolatedVideoFinishedMillis = millis();
    return;
  }

  if(millis() - isolatedVideoFinishedMillis >= ISOLATED_AUTO_ADVANCE_DELAY_MS){
    goNextScreen();
  }
}

boolean canAdvanceCurrentVideo(){
  if(appState == 0) return true;
  return currentVideoElapsedSeconds() >= MIN_SECONDS_BEFORE_ADVANCE || currentVideoFinished();
}

float secondsUntilAdvanceAllowed(){
  if(canAdvanceCurrentVideo()) return 0;
  return max(0, MIN_SECONDS_BEFORE_ADVANCE - currentVideoElapsedSeconds());
}

void handleAdvanceInput(){
  if(appState == 0){
    moveHomeSelection(1);
    return;
  }

  if(appState == 1){
    if(phase == 1){
      if(!canAdvanceCurrentVideo()) return;

      logResearchEvent("activity_observation_confirm", "activity4", "observation", screen, "behavior=" + titles[screen] + ";sequence_position=" + behaviorSequencePosition);
      phase = 2;
      t = 0;
      animating = false;
      guidedVideoFinishedMillis = -1;
      enterInterpretationTask();
      return;
    }

    if(phase == 2){
      if(interpretationTaskStage == INTERPRETATION_STAGE_TIME){
        if(!interpretationTimeSelectionComplete()) return;
        interpretationDragging = false;
        interpretationChoices[screen] = -1;
        interpretationTaskStage = INTERPRETATION_STAGE_CHOICE;
        return;
      }

      if(!interpretationSelectionComplete()) return;

      commitCurrentInterpretationMark();
      if(interpretationMarkCounts[screen] < requiredInterpretationMarkCount(screen)){
        resetCurrentInterpretationDraft();
        return;
      }

      logResearchEvent("activity_response_confirm", "activity4", "interpretation", screen, activity4ResearchDetails());
      logActivity4StructuredResponses();
      interpretationDragging = false;
      phase = 3;
      t = 0;
      enterFeedbackScreen();
      sendAdvanceFeedbackVibration();
      return;
    }

    if(phase == 3){
      logResearchEvent("activity_feedback_confirm", "activity4", "feedback", screen, "behavior=" + titles[screen] + ";last=" + onLastBehaviorStep());
      restoreInterpretationVideoAudio();
      sendAdvanceFeedbackVibration();
      if(onLastBehaviorStep()){
        returnToHomeMenu();
        return;
      }
      goNextScreen();
      return;
    }
  }

  if(appState == 2){
    goNextScreen();
    return;
  }

  if(appState == 3){
    if(activity1Step == 0){
      logResearchEvent("activity_observation_confirm", "activity1", "observation", -1, "entered_interpretation=true");
      enterActivity1Tasks();
      return;
    }

    confirmActivity1Step();
    return;
  }

  if(appState == 5){
    if(activity2Step == 0){
      logResearchEvent("activity_observation_confirm", "activity2", "observation", -1, "entered_interpretation=true");
      enterActivity2Task();
      return;
    }

    confirmActivity2Step();
    return;
  }

  if(appState == 6){
    if(activity3Step == 0){
      if(canAdvanceActivity3Observation()){
        logResearchEvent("activity_observation_confirm", "activity3", "observation", activity3CurrentScenarioIndex(), activity3ScenarioResearchDetails());
        advanceActivity3Observation();
      }
      return;
    }

    confirmActivity3Step();
    return;
  }
}

void handleDesignSkipInput(){
  if(appState == 0){
    activateHomeSelection();
    return;
  }

  if(appState == 1){
    if(phase == 1){
      phase = 2;
      t = 0;
      animating = false;
      guidedVideoFinishedMillis = -1;
      enterInterpretationTask();
      return;
    }

    if(phase == 2){
      while(interpretationMarkCounts[screen] < requiredInterpretationMarkCount(screen)){
        int markIndex = interpretationMarkCounts[screen];
        interpretationTimes[screen] =
          (correctInterpretationStartForMark(screen, markIndex) +
           correctInterpretationEndForMark(screen, markIndex)) / 2.0;
        interpretationChoices[screen] = correctInterpretationChoiceForMark(screen, markIndex);
        commitCurrentInterpretationMark();
      }

      interpretationDragging = false;
      phase = 3;
      t = 0;
      enterFeedbackScreen();
      sendAdvanceFeedbackVibration();
      return;
    }

    if(phase == 3){
      restoreInterpretationVideoAudio();
      sendAdvanceFeedbackVibration();
      if(onLastBehaviorStep()){
        returnToHomeMenu();
        return;
      }
      goNextScreen();
      return;
    }
  }

  if(appState == 2){
    if(onLastBehaviorStep()){
      returnToHomeMenu();
      return;
    }
    goNextScreen();
    return;
  }

  if(appState == 3){
    if(activity1Step == 0){
      enterActivity1Tasks();
      return;
    }

    if(activity1Step == 1){
      for(int i = 0; i < activity1MomentRelevance.length; i++){
        activity1MomentRelevance[i] = activity1CorrectRelevance[i];
        activity1MomentSignal[i] = -1;
      }
      activity1Step = 2;
      return;
    }

    if(activity1Step == 2){
      for(int i = 0; i < activity1MomentSignal.length; i++){
        activity1MomentSignal[i] = activity1CorrectSignal[i];
      }
      activity1Step = 3;
      return;
    }

    handleBack();
    return;
  }

  if(appState == 5){
    if(activity2Step == 0){
      enterActivity2Task();
      return;
    }

    if(activity2Step == 1){
      for(int i = 0; i < activity2SelectedMasks.length; i++){
        activity2SelectedMasks[i] = 1 << activity2CorrectOption[i];
      }
      activity2Step = 2;
      return;
    }

    handleBack();
    return;
  }

  if(appState == 6){
    if(activity3Step == 0){
      advanceActivity3Observation();
      return;
    }

    if(activity3Step == 1){
      activity3SelectedGrowl = activity3CurrentCorrectGrowl();
      activity3Step = 2;
      return;
    }

    if(activity3Step == 2){
      activity3SelectedSoundMask = 0;
      int[] correctSoundClues = activity3CurrentCorrectSoundClues();
      for(int i = 0; i < correctSoundClues.length; i++){
        activity3SelectedSoundMask |= (1 << correctSoundClues[i]);
      }
      activity3SelectedBehavior = activity3CurrentCorrectBehavior();
      activity3Step = 3;
      return;
    }

    advanceActivity3AfterFeedback();
    return;
  }

  if(appState == 4){
    handleBack();
  }
}

void handleBackInput(){
  if(appState == 0){
    moveHomeSelection(-1);
    return;
  }

  handleBack();
}

void handleRepeatInput(){
  if(appState == 0){
    activateHomeSelection();
    return;
  }

  if(appState == 3){
    if(activity1Step == 0){
      guidedVideoFinishedMillis = -1;
      isolatedVideoFinishedMillis = -1;
      activity1ObservationFinishedMillis = -1;
      startActivityObservationSlides(0);
      return;
    }

    resetActivity1Step();
    return;
  }

  if(appState == 5){
    if(activity2Step == 0){
      guidedVideoFinishedMillis = -1;
      isolatedVideoFinishedMillis = -1;
      activity2ObservationFinishedMillis = -1;
      startActivityObservationSlides(1);
      return;
    }

    resetActivity2Selections();
    activity2Step = 1;
    return;
  }

  if(appState == 6){
    if(activity3Step == 0){
      guidedVideoFinishedMillis = -1;
      isolatedVideoFinishedMillis = -1;
      activity3ObservationFinishedMillis = -1;
      activity3Dragging = false;
      activity3DragKind = 0;
      activity3DragValue = -1;
      activity3VideoStarted = false;
      playCurrentActivity3Video();
      return;
    }

    if(activity3Step == 1){
      resetActivity3All();
    } else if(activity3Step == 2){
      resetActivity3Justification();
    } else {
      activity3Step = 1;
      resetActivity3All();
    }
    return;
  }

  if(appState != 1 && appState != 2) return;

  guidedVideoFinishedMillis = -1;
  isolatedVideoFinishedMillis = -1;
  replayCurrentVideo();
}

void handleExitInput(){
  if(exitRequested) return;
  exitRequested = true;
  noLoop();
  thread("finishExitThread");
}

void finishExitThread(){
  try {
    logResearchEvent("app_exit", "app", "exit", -1, "exit_requested=true");
    closeResearchLog();
  } catch(Exception ignored){}

  try {
    closeBHapticsBridge();
  } catch(Exception ignored){}

  try {
    Thread.sleep(150);
  } catch(Exception ignored){}

  Runtime.getRuntime().halt(0);
}

void moveHomeSelection(int direction){
  int current = homeSelectedOption;
  for(int step = 0; step < HOME_OPTION_COUNT; step++){
    current = (current + direction + HOME_OPTION_COUNT) % HOME_OPTION_COUNT;
    if(homeOptionVisible(current)){
      homeSelectedOption = current;
      return;
    }
  }
}

void activateHomeSelection(){
  stopHapticTuningPreview();
  homeOptionsOverlayOpen = false;
  if(!homeOptionVisible(homeSelectedOption)){
    ensureHomeSelectionVisible();
    return;
  }

  if(homeSelectedOption == 0){
    startActivity1Prototype();
  } else if(homeSelectedOption == 1){
    startActivity2Prototype();
  } else if(homeSelectedOption == 2){
    startActivity3Prototype();
  } else if(homeSelectedOption == 3){
    startGuidedExperience();
  } else if(homeSelectedOption == 4){
    handleExitInput();
  }
}
void sendAdvanceFeedbackVibration(){
  sendHandVibration(7, ADVANCE_FEEDBACK_DURATION_MS, VIB_LOW);
}

void toggleUnisensoryMode(){
  unisensoryMode = !unisensoryMode;

  if(unisensoryMode){
    stopHapticTuningPreview();
    stopBHapticsVibration();
    stopActivity3GrowlSounds();
    vibrationOverlayEnabled = false;
    vibrationOverlayUntilMillis = -1;
    vibrationOverlayDragging = false;
  }

  applyVideoAudioMode();

  println(
    "Condicao unissensorial: " +
    (unisensoryMode ? "ativa (sem som e sem vibracao)" : "inativa (som e vibracao ativos)")
  );
  logResearchEvent("condition_toggle", "app", "condition", -1, "unisensory=" + unisensoryMode);
}

void toggleVibrationOverlay(){
  if(unisensoryMode){
    vibrationOverlayEnabled = false;
    vibrationOverlayUntilMillis = -1;
    vibrationOverlayDragging = false;
    println("Overlay visual de vibracao indisponivel na condicao unissensorial");
    return;
  }

  vibrationOverlayEnabled = !vibrationOverlayEnabled;
  if(vibrationOverlayEnabled){
    prepareVibrationOverlay();
  } else {
    vibrationOverlayUntilMillis = -1;
    vibrationOverlayDragging = false;
  }
  println("Overlay visual de vibracao: " + (vibrationOverlayEnabled ? "ligado" : "desligado"));
}

void keyPressed(){
  if(researchParticipantPromptActive){
    handleResearchParticipantPromptKey();
    return;
  }

  if(key == ESC){
    key = 0;
    return;
  }

  char k = Character.toLowerCase(key);

  if(k == 'x'){
    toggleUnisensoryMode();
    return;
  }

  if(k == 's'){
    handleDesignSkipInput();
    return;
  }

  if(k == 'v'){
    toggleVibrationOverlay();
    return;
  }

  if(k == 'm'){
    vibrationMarkingMode = !vibrationMarkingMode;
    println("Modo de marcacao: " + (vibrationMarkingMode ? "ligado" : "desligado"));
    return;
  }

  if(k == 'p'){
    printCurrentVideoCues();
    return;
  }

  if(k == 'o'){
    printAllVideoCues();
    return;
  }

  if(k == 'c'){
    clearCurrentVideoCues();
    return;
  }

  if(k == 't'){
    sendHandVibration(7, 500);
    return;
  }

  if(!vibrationMarkingMode) return;

  if(key == '1') addMarkedVibrationCue(1);
  else if(key == '2') addMarkedVibrationCue(2);
  else if(key == '3') addMarkedVibrationCue(4);
  else if(k == 'a') addMarkedVibrationCue(7);
}

void mousePressed(){
  float mx = (mouseX - (width  - baseW * scaleFactor) / 2) / scaleFactor;
  float my = (mouseY - (height - baseH * scaleFactor) / 2) / scaleFactor;

  if(researchParticipantPromptActive){
    handleResearchParticipantPromptMouse(mx, my);
    return;
  }

  if(handleHapticTuningControlsMouse(mx, my)){
    return;
  }

  if(handleHomeOptionsMouse(mx, my)){
    return;
  }

  if(insideVibrationOverlay(mx, my)){
    vibrationOverlayDragging = true;
    vibrationOverlayDragOffsetX = mx - vibrationOverlayX;
    vibrationOverlayDragOffsetY = my - vibrationOverlayY;
    return;
  }

  if(appState == 0){
    for(int i = 0; i < HOME_OPTION_COUNT; i++){
      if(!homeOptionVisible(i)) continue;
      if(inside(mx, my, homeOptionX[i], homeOptionY[i], homeOptionW[i], homeOptionH[i])){
        homeSelectedOption = i;
        activateHomeSelection();
        return;
      }
    }
  }

  if(appState == 3){
    if(inside(mx, my, activity1BackX, activity1BackY, activity1BackW, activity1BackH)){
      handleBack();
      return;
    }

    if(activity1Step > 0 && activity1Step < 3 && inside(mx, my, activity1ResetX, activity1ResetY, activity1ResetW, activity1ResetH)){
      logResearchEvent("activity_reset", "activity1", "step_" + activity1Step, -1, "manual_reset=true");
      resetActivity1Step();
      return;
    }

    if(activity1Step > 0 && inside(mx, my, activity1ConfirmX, activity1ConfirmY, activity1ConfirmW, activity1ConfirmH)){
      confirmActivity1Step();
      return;
    }

    startActivity1Drag(mx, my);
    return;
  }

  if(appState == 5){
    if(inside(mx, my, activity1BackX, activity1BackY, activity1BackW, activity1BackH)){
      handleBack();
      return;
    }

    if(activity2Step == 1){
      if(inside(mx, my, activity2ResetX, activity2ResetY, activity2ResetW, activity2ResetH)){
        logResearchEvent("activity_reset", "activity2", "interpretation", -1, "manual_reset=true");
        resetActivity2Selections();
        return;
      }

      if(activity2CanConfirm() && inside(mx, my, activity2ConfirmX, activity2ConfirmY, activity2ConfirmW, activity2ConfirmH)){
        confirmActivity2Step();
        return;
      }

      for(int c = 0; c < activity2Options.length; c++){
        for(int i = 0; i < activity2Options[c].length; i++){
          if(inside(mx, my, activity2OptionX[c][i], activity2OptionY[c][i], activity2OptionW[c][i], activity2OptionH[c][i])){
            toggleActivity2Option(c, i);
            return;
          }
        }
      }
      return;
    }

    if(activity2Step == 2){
      if(inside(mx, my, activity2ResetX, activity2ResetY, activity2ResetW, activity2ResetH)){
        logResearchEvent("activity_reset", "activity2", "feedback", -1, "manual_reset=true");
        resetActivity2Selections();
        activity2Step = 1;
        return;
      }

      if(inside(mx, my, activity2ConfirmX, activity2ConfirmY, activity2ConfirmW, activity2ConfirmH)){
        confirmActivity2Step();
        return;
      }
      return;
    }

    return;
  }

  if(appState == 6){
    if(inside(mx, my, activity1BackX, activity1BackY, activity1BackW, activity1BackH)){
      handleBack();
      return;
    }

    if(activity3Step == 1){
      for(int i = 0; i < activity3GrowlLabels.length; i++){
        if(inside(mx, my, activity3GrowlPlayX[i], activity3GrowlPlayY[i], activity3GrowlPlayW[i], activity3GrowlPlayH[i])){
          toggleActivity3GrowlSound(i);
          return;
        }
      }

      for(int i = 0; i < activity3GrowlLabels.length; i++){
        if(inside(mx, my, activity3GrowlX[i], activity3GrowlY[i], activity3GrowlW[i], activity3GrowlH[i])){
          activity3SelectedGrowl = i;
          return;
        }
      }

      if(activity3CanConfirm() && inside(mx, my, activity3ConfirmX, activity3ConfirmY, activity3ConfirmW, activity3ConfirmH)){
        confirmActivity3Step();
        return;
      }
      return;
    }

    if(activity3Step == 2){
      if(activity3SelectedGrowl >= 0 && inside(mx, my, activity3ChosenGrowlPlayX, activity3ChosenGrowlPlayY, activity3ChosenGrowlPlayW, activity3ChosenGrowlPlayH)){
        toggleActivity3GrowlSound(activity3SelectedGrowl);
        return;
      }

      if(inside(mx, my, activity3ResetX, activity3ResetY, activity3ResetW, activity3ResetH)){
        logResearchEvent("activity_reset", "activity3", "justification", activity3CurrentScenarioIndex(), "manual_reset=true;" + activity3ScenarioResearchDetails());
        resetActivity3Justification();
        return;
      }

      if(activity3CanConfirm() && inside(mx, my, activity3ConfirmX, activity3ConfirmY, activity3ConfirmW, activity3ConfirmH)){
        confirmActivity3Step();
        return;
      }

      startActivity3Drag(mx, my);
      return;
    }

    if(activity3Step == 3){
      if(inside(mx, my, activity3ResetX, activity3ResetY, activity3ResetW, activity3ResetH)){
        logResearchEvent("activity_reset", "activity3", "feedback", activity3CurrentScenarioIndex(), "manual_reset=true;" + activity3ScenarioResearchDetails());
        activity3Step = 1;
        resetActivity3All();
        return;
      }

      if(inside(mx, my, activity3ConfirmX, activity3ConfirmY, activity3ConfirmW, activity3ConfirmH)){
        confirmActivity3Step();
        return;
      }
      return;
    }
  }

  if(appState == 4){
    if(inside(mx, my, activity1BackX, activity1BackY, activity1BackW, activity1BackH)){
      handleBack();
      return;
    }
  }

  if(appState == 1){
    if(inside(mx, my, backX, backY, backW, backH)){
      handleBack();
      return;
    }


    if(phase == 2 &&
      interpretationTaskStage == INTERPRETATION_STAGE_TIME &&
      inside(
      mx, my,
      interpretationTimelineX, interpretationTimelineY,
      interpretationTimelineW, interpretationTimelineH
    )){
      interpretationDragging = true;
      setInterpretationTimeFromMouse(mx);
      return;
    }

    if(phase == 2){
      if(interpretationTaskStage == INTERPRETATION_STAGE_CHOICE){
        for(int i = 0; i < INTERPRETATION_CHOICE_COUNT; i++){
          if(inside(
            mx, my,
            interpretationChoiceX[i], interpretationChoiceY[i],
            interpretationChoiceW[i], interpretationChoiceH[i]
          )){
            interpretationChoices[screen] = interpretationChoiceOrder[i];
            return;
          }
        }
      }

      if(currentInterpretationStageComplete() && inside(
        mx, my,
        interpretationConfirmX, interpretationConfirmY,
        interpretationConfirmW, interpretationConfirmH
      )){
        handleAdvanceInput();
        return;
      }
    }

    if(phase == 3 && inside(
      mx, my,
      feedbackNextX, feedbackNextY, feedbackNextW, feedbackNextH
    )){
      handleAdvanceInput();
      return;
    }

  }

  if(appState == 2){
    if(inside(mx, my, isolatedBackX, isolatedBackY, isolatedBackW, isolatedBackH)){
      stopAllVideos();
      stopBHapticsVibration();
      replayVibrationActive = false;
      appState = 0;
      return;
    }

    if(inside(mx, my, isolatedPrevX, isolatedPrevY, isolatedPrevW, isolatedPrevH) && behaviorSequencePosition > 0){
      goPreviousScreen();
      return;
    }

  }
}

void mouseDragged(){
  if(homeHapticAmpDragging || homeHapticFreqDragging){
    if(!hapticTuningContextActive() || unisensoryMode){
      homeHapticAmpDragging = false;
      homeHapticFreqDragging = false;
      stopHapticTuningPreview();
      return;
    }

    float mx = (mouseX - (width - baseW * scaleFactor) / 2) / scaleFactor;
    if(homeHapticAmpDragging) setHapticTuneAmplitudeFromMouse(mx);
    if(homeHapticFreqDragging) setHapticTuneFrequencyFromMouse(mx);
    return;
  }

  if(vibrationOverlayDragging){
    float mx = (mouseX - (width - baseW * scaleFactor) / 2) / scaleFactor;
    float my = (mouseY - (height - baseH * scaleFactor) / 2) / scaleFactor;
    vibrationOverlayX = mx - vibrationOverlayDragOffsetX;
    vibrationOverlayY = my - vibrationOverlayDragOffsetY;
    ensureVibrationOverlayPosition();
    return;
  }

  if(!interpretationDragging ||
     appState != 1 ||
     phase != 2 ||
     interpretationTaskStage != INTERPRETATION_STAGE_TIME) return;

  float mx = (mouseX - (width - baseW * scaleFactor) / 2) / scaleFactor;
  setInterpretationTimeFromMouse(mx);
}

void mouseReleased(){
  if(homeHapticAmpDragging || homeHapticFreqDragging){
    homeHapticAmpDragging = false;
    homeHapticFreqDragging = false;
    return;
  }

  if(vibrationOverlayDragging){
    vibrationOverlayDragging = false;
    return;
  }

  if(appState == 3){
    float mx = (mouseX - (width - baseW * scaleFactor) / 2) / scaleFactor;
    float my = (mouseY - (height - baseH * scaleFactor) / 2) / scaleFactor;
    finishActivity1Drag(mx, my);
  }

  if(appState == 6){
    float mx = (mouseX - (width - baseW * scaleFactor) / 2) / scaleFactor;
    float my = (mouseY - (height - baseH * scaleFactor) / 2) / scaleFactor;
    finishActivity3Drag(mx, my);
  }

  interpretationDragging = false;
}

void handleBack(){
  stopHapticTuningPreview();
  stopAllVideos();
  stopBHapticsVibration();
  clearInterpretationSeek();
  interpretationDragging = false;
  interpretationTaskStage = INTERPRETATION_STAGE_TIME;
  replayVibrationActive = false;
  guidedVideoFinishedMillis = -1;
  isolatedVideoFinishedMillis = -1;
  activity1Dragging = false;
  activity1DragKind = 0;
  activity1DragValue = -1;
  activity2ObservationFinishedMillis = -1;
  activity2Step = 0;
  resetActivity2Selections();
  activity3ObservationFinishedMillis = -1;
  activity3VideoIndex = 0;
  activity3SequencePosition = 0;
  activity3VideoStarted = false;
  activity3Step = 0;
  activity3Dragging = false;
  activity3DragKind = 0;
  activity3DragValue = -1;
  resetActivity3All();
  resetAllActivityObservationSlides();
  screen = 0;
  behaviorSequencePosition = 0;
  phase = 1;
  t = 0;
  animating = false;
  appState = 0;
}

void goNextScreen(){
  if(behaviorSequencePosition < titles.length - 1){
    behaviorSequencePosition++;
    changeScreen(behaviorOrder[behaviorSequencePosition]);
  } else {
    returnToHomeMenu();
  }
}

void goPreviousScreen(){
  if(behaviorSequencePosition > 0){
    behaviorSequencePosition--;
    changeScreen(behaviorOrder[behaviorSequencePosition]);
  }
}

void returnToHomeMenu(){
  stopHapticTuningPreview();
  stopAllVideos();
  stopBHapticsVibration();
  clearInterpretationSeek();
  clearVideoEndFreezeState();
  interpretationDragging = false;
  interpretationTaskStage = INTERPRETATION_STAGE_TIME;
  replayVibrationActive = false;
  guidedVideoFinishedMillis = -1;
  isolatedVideoFinishedMillis = -1;
  activity1ObservationFinishedMillis = -1;
  activity2ObservationFinishedMillis = -1;
  activity3ObservationFinishedMillis = -1;
  activity3VideoIndex = 0;
  activity3SequencePosition = 0;
  activity3VideoStarted = false;
  activity1Dragging = false;
  activity1DragKind = 0;
  activity1DragValue = -1;
  activity2Step = 0;
  resetActivity2Selections();
  activity3Step = 0;
  activity3Dragging = false;
  activity3DragKind = 0;
  activity3DragValue = -1;
  resetActivity3All();
  resetAllActivityObservationSlides();
  screen = 0;
  behaviorSequencePosition = 0;
  phase = 1;
  t = 0;
  animating = false;
  appState = 0;
}

void changeScreen(int newScreen){
  stopHapticTuningPreview();
  stopAllVideos();
  stopBHapticsVibration();
  screen = constrain(newScreen, 0, titles.length - 1);
  phase = 1;
  t = 0;
  animating = false;
  guidedVideoFinishedMillis = -1;
  isolatedVideoFinishedMillis = -1;
  replayVibrationActive = false;
  interpretationDragging = false;
  interpretationTaskStage = INTERPRETATION_STAGE_TIME;
  clearInterpretationSeek();
  if(appState == 1){
    logResearchEvent("activity4_behavior_start", "activity4", "observation", screen, "behavior=" + titles[screen] + ";sequence_position=" + behaviorSequencePosition);
  } else if(appState == 2){
    logResearchEvent("isolated_review_behavior_start", "review", "observation", screen, "behavior=" + titles[screen] + ";sequence_position=" + behaviorSequencePosition);
  }
  playCurrentVideo();
}

void stopAllVideos(){
  clearInterpretationSeek();
  clearVideoEndFreezeState();
  clearFeedbackPlaybackState();
  for(int i = 0; i < videos.length; i++){
    if(videos[i] != null){
      try {
        videos[i].pause();
      } catch(Exception e){}
    }
  }
  stopActivity3Videos();
  stopActivity3GrowlSounds();
}

void stopActivity3Videos(){
  for(int i = 0; i < activity3Videos.length; i++){
    if(activity3Videos[i] != null){
      try {
        activity3Videos[i].pause();
      } catch(Exception e){}
    }
  }
}

void pauseActivity3VideosExcept(int keepIndex){
  for(int i = 0; i < activity3Videos.length; i++){
    if(i == keepIndex || activity3Videos[i] == null) continue;

    try {
      activity3Videos[i].pause();
      activity3Videos[i].volume(currentVideoAudioVolume());
    } catch(Exception ignored){}
  }
}

void playCurrentVideo(){
  clearInterpretationSeek();
  clearVideoEndFreezeState();
  if(hasVideo[screen] && videos[screen] != null){
    videoStartMillis = millis();
    videoRestartAttempts = 0;
    resetVibrationTimelineForCurrentVideo();

    try {
      videos[screen].pause();
      videos[screen].volume(currentVideoAudioVolume());
      videos[screen].play();
      videos[screen].jump(0);
      videos[screen].volume(currentVideoAudioVolume());

    } catch(Exception e){
      println("Erro ao iniciar video: " + titles[screen] + " -> " + e.getMessage());
    }
  }
}

void replayCurrentVideo(){
  stopBHapticsVibration();
  clearInterpretationSeek();
  clearVideoEndFreezeState();

  if(hasVideo[screen] && videos[screen] != null){
    videoStartMillis = millis();
    videoRestartAttempts = 0;
    resetVibrationTimelineForCurrentVideo();
    replayVibrationActive = true;

    try {
      videos[screen].pause();
      videos[screen].volume(currentVideoAudioVolume());
      videos[screen].play();
      videos[screen].jump(0);
      videos[screen].volume(currentVideoAudioVolume());

    } catch(Exception e){
      println("Erro ao rever video: " + titles[screen] + " -> " + e.getMessage());
    }
  }

}

void stopCurrentVideo(){
  clearVideoEndFreezeState();
  if(hasVideo[screen] && videos[screen] != null){
    try {
      videos[screen].pause();
    } catch(Exception e){}
  }
}

void ensureCurrentVideoStarted(){
  if(appState != 1 && appState != 2) return;
  if(!hasVideo[screen] || videos[screen] == null) return;
  if((appState == 2 || (appState == 1 && phase == 1)) && currentVideoFinished()) return;
  if(videoReadyForDrawing(videos[screen])) return;
  if(videoRestartAttempts >= 6) return;
  if(millis() - videoStartMillis < 700) return;

  videoRestartAttempts++;
  videoStartMillis = millis();
  println("A tentar acordar video: " + titles[screen] + " tentativa " + videoRestartAttempts);

  try {
    videos[screen].stop();
    videos[screen].volume(currentVideoAudioVolume());
    videos[screen].play();
    videos[screen].jump(0);
    videos[screen].volume(currentVideoAudioVolume());
  } catch(Exception e){
    println("Erro ao reativar video: " + titles[screen] + " -> " + e.getMessage());
  }

  if(videoRestartAttempts == 3 && preparedVideoPaths[screen] != null){
    try {
      videos[screen].pause();
      videos[screen] = new Movie(this, preparedVideoPaths[screen]);
      videos[screen].volume(currentVideoAudioVolume());
      videos[screen].play();
      videos[screen].jump(0);
      videos[screen].volume(currentVideoAudioVolume());
      videoFrameDecoded[screen] = false;

      println("Video recriado: " + titles[screen]);
    } catch(Exception e){
      println("Erro ao recriar video: " + titles[screen] + " -> " + e.getMessage());
    }
  }
}

boolean inside(float mx, float my, float x, float y, float w, float h){
  return mx > x && mx < x + w && my > y && my < y + h;
}
