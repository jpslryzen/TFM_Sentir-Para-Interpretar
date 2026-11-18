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
final int OBSERVATION_HAPTIC_REPLAY_SETTLE_MS = 80;
final int OBSERVATION_HAPTIC_REPLAY_TIMEOUT_MS = 1500;
final int OBSERVATION_HAPTIC_TIME_REGRESSION_TOLERANCE_MS = 150;
// A Movie frame may arrive well after a 100 ms pulse ended. Retain the most
// recent missed step long enough to recover from ordinary decoder/frame stalls.
// This changes neither its authored video time nor its 100 ms tactile duration.
final int OBSERVATION_HAPTIC_MISSED_PULSE_GRACE_MS = 380;
int observationHapticReplayArmedMillis = -1;
float observationHapticReplayPreviousSeconds = -1;
float observationHapticReplayLowestSeconds = -1;
int observationHapticReplayStableSinceMillis = -1;

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
  observationHapticReplayArmedMillis = -1;
  observationHapticReplayPreviousSeconds = -1;
  observationHapticReplayLowestSeconds = -1;
  observationHapticReplayStableSinceMillis = -1;
}

void armObservationHapticReplay(int owner, float previousSeconds){
  resetObservationHapticPlayback();
  observationHapticReplayPending = true;
  observationHapticReplayOwner = owner;
  observationHapticReplayArmedMillis = millis();
  observationHapticReplayPreviousSeconds = max(0, previousSeconds);
}

boolean observationHapticReplayReady(int owner, float seconds){
  if(!observationHapticReplayPending) return true;
  if(owner != observationHapticReplayOwner) return false;

  int now = millis();
  boolean rewound = seconds <= OBSERVATION_HAPTIC_REPLAY_START_WINDOW_SECONDS ||
    (observationHapticReplayPreviousSeconds > OBSERVATION_HAPTIC_REPLAY_START_WINDOW_SECONDS &&
     seconds + 0.05f < observationHapticReplayPreviousSeconds);

  // Movie.jump(0) can briefly report an old time, then a small time, and then
  // zero. Wait for the returned clock to settle so the first cue is not sent
  // twice or scheduled against the previous playback.
  if(observationHapticReplayLowestSeconds < 0){
    if(!rewound){
      if(now - observationHapticReplayArmedMillis < OBSERVATION_HAPTIC_REPLAY_TIMEOUT_MS) return false;
      println("bHaptics: reinicio do video sem confirmacao; a retomar haptico.");
      resetObservationHapticPlayback();
      return true;
    }
    observationHapticReplayLowestSeconds = seconds;
    observationHapticReplayStableSinceMillis = now;
    return false;
  }

  if(seconds < observationHapticReplayLowestSeconds - 0.005f){
    observationHapticReplayLowestSeconds = seconds;
    observationHapticReplayStableSinceMillis = now;
    return false;
  }

  if(now - observationHapticReplayStableSinceMillis < OBSERVATION_HAPTIC_REPLAY_SETTLE_MS) return false;

  resetObservationHapticPlayback();
  return true;
}

boolean observationHapticReplayWaiting(int owner){
  return observationHapticReplayPending && observationHapticReplayOwner == owner;
}

ObservationHapticCue recentlyMissedObservationPulse(ObservationHapticCue[] cues, int previousTime, int time){
  if(previousTime < 0 || time <= previousTime) return null;

  ObservationHapticCue missed = null;
  for(ObservationHapticCue cue : cues){
    if(cue.end - cue.start > OBSERVATION_PULSE_MS) continue;
    // Recover only a pulse skipped entirely between two decoded video times.
    // A pulse that was already active in the preceding frame must not be
    // retransmitted after it ends, otherwise it becomes a delayed duplicate.
    if(previousTime < cue.start && time >= cue.end && time - cue.end <= OBSERVATION_HAPTIC_MISSED_PULSE_GRACE_MS){
      missed = cue;
    }
  }
  return missed;
}

// Render the complete motor state until the next boundary. Overlapping cues
// use max intensity per motor, so lateral pulses retain the central vibration.
void updateObservationHaptics(ObservationHapticCue[] cues, int owner, float seconds){
  if(unisensoryMode && !scenarioBrowserHapticPreviewOpen()) return;
  if(scenarioBrowserHapticPreviewOpen() && !bhapticsConnected) return;
  if(!bhapticsBridgeReady || bhapticsInput == null){
    if(observationHapticUnavailableOwner != owner){
      observationHapticUnavailableOwner = owner;
      logObservationHapticUnavailable(owner);
    }
    return;
  }
  observationHapticUnavailableOwner = -1;
  int time = max(0, floor(seconds * 1000.0f));
  boolean ownerChanged = owner != observationHapticOwner;
  boolean significantRewind = !ownerChanged && observationHapticLastTime >= 0 &&
    time + OBSERVATION_HAPTIC_TIME_REGRESSION_TOLERANCE_MS < observationHapticLastTime;
  if(ownerChanged || significantRewind){
    if(observationHapticOutputActive) sendBHapticsCommand("S");
    resetObservationHapticPlayback();
    observationHapticOwner = owner;
  }
  int previousTime = observationHapticLastTime;
  observationHapticLastTime = max(observationHapticLastTime, time);
  if(time < observationHapticNextTime) return;

  int[] values = new int[3];
  int next = Integer.MAX_VALUE;
  int nextCueStart = Integer.MAX_VALUE;
  boolean activeShortPulse = false;
  boolean activeLongCue = false;
  for(ObservationHapticCue cue : cues){
    if(cue.start > time){
      next = min(next, cue.start);
      nextCueStart = min(nextCueStart, cue.start);
    }
    if(cue.start <= time && time < cue.end){
      next = min(next, cue.end);
      if(cue.end - cue.start <= OBSERVATION_PULSE_MS) activeShortPulse = true;
      else activeLongCue = true;
      for(int motor = 0; motor < 3; motor++){
        if((cue.mask & (1 << motor)) != 0){
          values[motor] = max(values[motor], cue.intensity);
        }
      }
    }
  }
  ObservationHapticCue missedPulse = recentlyMissedObservationPulse(cues, previousTime, time);
  if(missedPulse != null){
    for(int motor = 0; motor < 3; motor++){
      if((missedPulse.mask & (1 << motor)) != 0){
        values[motor] = max(values[motor], missedPulse.intensity);
      }
    }
    next = min(next, time + OBSERVATION_PULSE_MS);
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
    // Do not reduce a planned 100 ms step to a few milliseconds merely because
    // its first decoded frame arrived near the visual pulse's end. Long cues
    // remain governed by their exact next boundary, including mixed timelines.
    boolean retainFullPulse = missedPulse != null || (activeShortPulse && !activeLongCue);
    if(retainFullPulse){
      int availableUntilNextCue = nextCueStart == Integer.MAX_VALUE ?
        OBSERVATION_PULSE_MS : max(1, nextCueStart - time);
      duration = min(OBSERVATION_PULSE_MS, availableUntilNextCue);
      next = time + duration;
    }
    String command = "O|" + duration + "|" + values[0] + "|" + values[1] + "|" + values[2];
    if(!sendBHapticsCommand(command)) return;
    registerVibrationOverlay(mask, duration, intensity);
    logObservationHapticActivation(owner, time, duration, values);
    if(missedPulse != null) logObservationHapticPulseCatchup(owner, missedPulse.start, time);
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

void logObservationHapticPulseCatchup(int owner, int scheduledStartMs, int dispatchedAtMs){
  if(!researchLoggingEnabled) return;

  boolean activity4 = owner >= 400;
  String activity = activity4 ? "activity4" : "activity3";
  int scenarioIndex = activity4 ? owner - 400 : owner - 300;
  logResearchEvent(
    "observation_haptic_pulse_catchup",
    activity,
    "observation_haptic",
    scenarioIndex,
    "scheduled_start_ms=" + scheduledStartMs +
      ";dispatched_at_ms=" + dispatchedAtMs +
      ";late_by_ms=" + max(0, dispatchedAtMs - scheduledStartMs)
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
