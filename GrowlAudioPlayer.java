import java.io.File;
import javax.sound.sampled.AudioInputStream;
import javax.sound.sampled.AudioSystem;
import javax.sound.sampled.Clip;

// Java Sound wrapper kept outside PDE preprocessing for reliable WAV playback.
public final class GrowlAudioPlayer {
  private Clip clip;
  private String loadedPath;

  public boolean isLoadedFor(String path) {
    return clip != null && clip.isOpen() && path != null && path.equals(loadedPath);
  }

  public void load(String path) throws Exception {
    close();
    AudioInputStream stream = AudioSystem.getAudioInputStream(new File(path));
    try {
      Clip nextClip = AudioSystem.getClip();
      nextClip.open(stream);
      clip = nextClip;
      loadedPath = path;
    } finally {
      stream.close();
    }
  }

  public void playFromStart() {
    if (clip == null) return;
    clip.stop();
    clip.setFramePosition(0);
    clip.start();
  }

  public void stopAndRewind() {
    if (clip == null) return;
    clip.stop();
    clip.setFramePosition(0);
  }

  public boolean isRunning() {
    return clip != null && clip.isRunning();
  }

  public int getPositionMillis() {
    if (clip == null) return -1;
    long micros = clip.getMicrosecondPosition();
    if (micros < 0) return -1;
    return (int) Math.min(Integer.MAX_VALUE, micros / 1000L);
  }

  public void close() {
    if (clip != null) {
      try {
        clip.stop();
        clip.close();
      } catch (Exception ignored) {
      }
    }
    clip = null;
    loadedPath = null;
  }
}
