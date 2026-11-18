// Observation specification, 2026-09-17. Times are milliseconds of VIDEO time.
// Provisional where unspecified: pulses 100 ms, all motors, threat/recoil 10%,
// first two playful-1 intervals 20%/30%. Feedback keeps its separate schedule.
final int OBSERVATION_PULSE_MS = 100;
ObservationHapticCue[][] observationHaptics3;
ObservationHapticCue[][] observationHaptics4;
int observationHapticOwner = -1;
int observationHapticLastTime = -1;
int observationHapticNextTime = -1;
boolean observationHapticOutputActive = false;
int observationHapticUnavailableOwner = -1;

// Movie.jump(0) is asynchronous. After an observation is repeated, wait until
// the decoder has actually returned to the start before scheduling its cues.
boolean observationHapticReplayPending = false;
int observationHapticReplayOwner = -1;
final float OBSERVATION_HAPTIC_REPLAY_START_WINDOW_SECONDS = 0.25f;

class ObservationHapticCue {
  int start, end, mask, intensity;
  ObservationHapticCue(int start, int end, int mask, int intensity){
    this.start = start;
    this.end = end;
    this.mask = mask;
    this.intensity = intensity;
  }
}

ObservationHapticCue observationCue(int start, int end, int mask, int intensity){
  return new ObservationHapticCue(start, end, mask, intensity);
}

ObservationHapticCue observationPulse(int start, int mask, int intensity){
  return observationCue(start, start + OBSERVATION_PULSE_MS, mask, intensity);
}

void setupObservationHaptics(){
  observationHaptics3 = new ObservationHapticCue[][] {
    { observationCue(5000, 9000, 7, 10) },
    { observationPulse(2545, 7, 10), observationPulse(2790, 7, 10),
      observationPulse(3200, 7, 10), observationCue(6000, 10000, 7, 10) },
    { observationCue(5800, 6800, 7, 20), observationCue(8360, 10000, 7, 30) },
    { observationCue(4670, 5198, 7, 20), observationCue(8400, 10000, 7, 30) },
    { observationCue(770, 3000, 7, 20), observationCue(3500, 5800, 7, 30),
      observationCue(5850, 8698, 2, 40),
      observationPulse(6277, 5, 40), observationPulse(6623, 5, 40),
      observationPulse(6907, 5, 40), observationPulse(7976, 5, 40),
      observationPulse(8200, 5, 40) },
    { observationCue(1700, 4166, 7, 10), observationCue(4400, 4850, 7, 20),
      observationCue(5200, 6700, 7, 20) }
  };
  observationHaptics4 = new ObservationHapticCue[][] {
    { observationCue(0, 3300, 2, 1), observationCue(5400, 9200, 7, 10) },
    { observationCue(1400, 9200, 7, 15) },
    { observationCue(2439, 5892, 7, 15), observationCue(6648, 9282, 7, 15) },
    { observationCue(2107, 7467, 2, 12) },
    { observationPulse(3446, 7, 30), observationPulse(3718, 7, 30),
      observationPulse(4235, 7, 30), observationPulse(4836, 7, 30),
      observationPulse(5586, 7, 30), observationPulse(6069, 7, 30),
      observationPulse(7070, 7, 30), observationPulse(7715, 7, 30),
      observationPulse(8376, 7, 30), observationPulse(9165, 7, 30) }
  };
  resetObservationHapticPlayback();
}

void resetObservationHapticPlayback(){
  observationHapticOwner = -1;
  observationHapticLastTime = -1;
  observationHapticNextTime = -1;
  observationHapticOutputActive = false;
  observationHapticUnavailableOwner = -1;
  observationHapticReplayPending = false;
  observationHapticReplayOwner = -1;
}

void armObservationHapticReplay(int owner){
  resetObservationHapticPlayback();
  observationHapticReplayPending = true;
  observationHapticReplayOwner = owner;
}

boolean observationHapticReplayReady(int owner, float seconds){
  if(!observationHapticReplayPending) return true;
  if(owner != observationHapticReplayOwner) return false;

  // Do not evaluate stale movie.time() values from the previous playback.
  if(seconds > OBSERVATION_HAPTIC_REPLAY_START_WINDOW_SECONDS) return false;

  resetObservationHapticPlayback();
  return true;
}

boolean observationHapticReplayWaiting(int owner){
  return observationHapticReplayPending && observationHapticReplayOwner == owner;
}

// Render the complete motor state until the next boundary. Overlapping cues
// use max intensity per motor, so lateral pulses retain the central vibration.
void updateObservationHaptics(ObservationHapticCue[] cues, int owner, float seconds){
  if(unisensoryMode) return;
  if(!bhapticsBridgeReady || bhapticsInput == null){
    if(observationHapticUnavailableOwner != owner){
      observationHapticUnavailableOwner = owner;
      logObservationHapticUnavailable(owner);
    }
    return;
  }
  observationHapticUnavailableOwner = -1;
  int time = max(0, floor(seconds * 1000.0f));
  if(owner != observationHapticOwner || time < observationHapticLastTime){
    if(observationHapticOutputActive) sendBHapticsCommand("S");
    resetObservationHapticPlayback();
    observationHapticOwner = owner;
  }
  observationHapticLastTime = time;
  if(time < observationHapticNextTime) return;

  int[] values = new int[3];
  int next = Integer.MAX_VALUE;
  for(ObservationHapticCue cue : cues){
    if(cue.start > time) next = min(next, cue.start);
    if(cue.start <= time && time < cue.end){
      next = min(next, cue.end);
      for(int motor = 0; motor < 3; motor++){
        if((cue.mask & (1 << motor)) != 0){
          values[motor] = max(values[motor], cue.intensity);
        }
      }
    }
  }
  int mask = 0;
  int intensity = 0;
  for(int motor = 0; motor < 3; motor++){
    if(values[motor] > 0) mask |= 1 << motor;
    intensity = max(intensity, values[motor]);
  }
  if(mask == 0){
    if(observationHapticOutputActive && !sendBHapticsCommand("S")) return;
    observationHapticOutputActive = false;
  } else {
    int duration = min(60000, next - time);
    String command = "O|" + duration + "|" + values[0] + "|" + values[1] + "|" + values[2];
    if(!sendBHapticsCommand(command)) return;
    registerVibrationOverlay(mask, duration, intensity);
    logObservationHapticActivation(owner, time, duration, values);
    observationHapticOutputActive = true;
    next = min(next, time + duration);
  }
  observationHapticNextTime = next;
}

// Persist only haptic output that was actually accepted by the bridge. This
// keeps AV rows free of haptic activations while making AVH playback auditable.
void logObservationHapticActivation(int owner, int videoTimeMs, int durationMs, int[] values){
  if(!researchLoggingEnabled) return;

  boolean activity4 = owner >= 400;
  String activity = activity4 ? "activity4" : "activity3";
  int scenarioIndex = activity4 ? owner - 400 : owner - 300;
  logResearchEvent(
    "observation_haptic_activation",
    activity,
    "observation_haptic",
    scenarioIndex,
    "video_time_ms=" + videoTimeMs +
      ";duration_ms=" + durationMs +
      ";motor_1=" + values[0] +
      ";motor_2=" + values[1] +
      ";motor_3=" + values[2]
  );
}

void logObservationHapticUnavailable(int owner){
  if(!researchLoggingEnabled) return;

  boolean activity4 = owner >= 400;
  String activity = activity4 ? "activity4" : "activity3";
  int scenarioIndex = activity4 ? owner - 400 : owner - 300;
  logResearchEvent(
    "observation_haptic_unavailable",
    activity,
    "observation_haptic",
    scenarioIndex,
    "bridge_ready=" + bhapticsBridgeReady +
      ";connected=" + bhapticsConnected +
      ";status=" + bhapticsStatusMessage
  );
}
