import asyncio
import json
import os
import sys
import time
from pathlib import Path


PREFERRED_HAND_POSITION = 4
POSITION_CANDIDATES = [4, 5]
MOTOR_COUNT = 3
running = True
active_position = None
send_to_all_candidate_positions = False
last_playing_status_time = -1.0
PLAYING_STATUS_INTERVAL_SECONDS = 0.75


def emit(state: str, message: str) -> None:
    clean_message = message.replace("|", " ").replace("\n", " ")
    print(f"STATUS|{state}|{clean_message}", flush=True)


def emit_playing(positions, force: bool = False) -> None:
    """Report delivery sparingly; rapid waveform updates must not flood stdout."""
    global last_playing_status_time

    now = time.monotonic()
    if not force and now - last_playing_status_time < PLAYING_STATUS_INTERVAL_SECONDS:
        return

    last_playing_status_time = now
    emit("PLAYING", f"Vibracao enviada para posicoes {positions}")


def reset_playing_status_throttle() -> None:
    global last_playing_status_time
    last_playing_status_time = -1.0


def load_credentials() -> tuple[str, str]:
    app_id = os.environ.get("BHAPTICS_APP_ID", "").strip()
    api_key = os.environ.get("BHAPTICS_API_KEY", "").strip()

    config_path = Path(__file__).with_name("bhaptics-config.json")
    if config_path.exists():
        try:
            config = json.loads(config_path.read_text(encoding="utf-8"))
            app_id = app_id or str(config.get("appId", "")).strip()
            api_key = api_key or str(config.get("apiKey", "")).strip()
        except (OSError, ValueError) as error:
            raise RuntimeError(f"Configuracao bHaptics invalida: {error}") from error

    if not app_id or not api_key:
        raise RuntimeError("Configurar App ID e API Key em bhaptics-config.json")

    return app_id, api_key


async def find_connected_position(bhaptics_python):
    connected_positions = []

    for position in POSITION_CANDIDATES:
        try:
            if await bhaptics_python.is_bhaptics_device_connected(position):
                connected_positions.append(position)
        except Exception:
            pass

    if PREFERRED_HAND_POSITION in connected_positions:
        return PREFERRED_HAND_POSITION, connected_positions
    if connected_positions:
        return connected_positions[0], connected_positions
    return None, connected_positions


async def monitor_left_hand(bhaptics_python) -> None:
    global active_position, send_to_all_candidate_positions

    last_connected = None
    last_position = None

    while running:
        try:
            position, connected_positions = await find_connected_position(bhaptics_python)
            connected = position is not None
            player_connected = False

            try:
                player_connected = await bhaptics_python.is_connected()
            except Exception:
                player_connected = False

            active_position = position
            send_to_all_candidate_positions = not connected and player_connected

            if connected != last_connected or position != last_position:
                if connected and position == PREFERRED_HAND_POSITION:
                    emit("READY", f"Tactosy esquerda ligada na posicao {position}")
                elif connected:
                    emit("READY", f"Dispositivo bHaptics ligado na posicao {position}")
                elif player_connected:
                    emit(
                        "COMPATIBILITY",
                        "Player ligado; Tactosy nao confirmada, envio nas posicoes "
                        f"{POSITION_CANDIDATES}",
                    )
                else:
                    emit(
                        "WAITING",
                        "Ligar Tactosy no bHaptics Player "
                        f"(posicoes testadas: {POSITION_CANDIDATES})",
                    )
                last_connected = connected
                last_position = position
        except Exception as error:
            emit("ERROR", f"Erro ao verificar Tactosy: {error}")

        await asyncio.sleep(1.5)


async def handle_command(bhaptics_python, line: str) -> bool:
    global active_position, send_to_all_candidate_positions

    parts = line.strip().split("|")
    if not parts or not parts[0]:
        return True

    command = parts[0].upper()

    # Resolve the wearable before the observation starts.  Unlike O/V this
    # never calls play_dot, so it cannot create a tactile study stimulus.
    if command == "W":
        # The next actual cue should always be reported, even after a sequence
        # of high-frequency comparison-growl waveform updates.
        reset_playing_status_throttle()
        if active_position is None:
            active_position, _ = await find_connected_position(bhaptics_python)

        if active_position is None:
            # Some Player versions accept haptic output for a connected Tactosy
            # even when their position query does not resolve it. Keep the
            # compatibility path usable: reset stale output and let O target
            # both hand mappings. This command never produces stimulation.
            player_connected = False
            try:
                player_connected = await bhaptics_python.is_connected()
            except Exception:
                player_connected = False

            if player_connected:
                await bhaptics_python.stop_all()
                send_to_all_candidate_positions = True
                emit(
                    "COMPATIBILITY",
                    "Observacao preparada em modo compatibilidade nas posicoes "
                    f"{POSITION_CANDIDATES}",
                )
            else:
                emit("WAITING", "Tactosy nao detetada para preparar a observacao")
            return True

        await bhaptics_python.stop_all()
        emit("READY", f"Tactosy preparada na posicao {active_position}")
        return True

    if command in ("V", "O"):
        if len(parts) != 5:
            raise ValueError("Comando V requer duracao e tres intensidades")

        # Observation frames replace the complete state and use video intervals.
        # Keep the legacy V command limits for feedback and manual tests.
        duration = max(1, min(60000, int(parts[1]))) if command == "O" else max(100, min(5000, int(parts[1])))
        values = [max(0, min(100, int(value))) for value in parts[2:5]]
        if len(values) != MOTOR_COUNT:
            raise ValueError("A Tactosy esquerda requer tres intensidades")

        if active_position is None:
            active_position, _ = await find_connected_position(bhaptics_python)

        # Video observation commands must reach the hand reliably. The
        # bHaptics Player has reported the same physical Tactosy through
        # either compatible hand position (4 or 5) on this setup. Dispatch
        # O to both mappings; an unavailable mapping simply rejects it, while
        # the connected one receives the identical cue.
        if command == "O":
            attempted_positions = list(POSITION_CANDIDATES)
        elif active_position is not None:
            attempted_positions = [active_position]
        elif send_to_all_candidate_positions:
            attempted_positions = list(POSITION_CANDIDATES)
        else:
            emit("COMMAND_ERROR", "Tactosy nao detetada para receber vibracao")
            return True

        if command == "O":
            await bhaptics_python.stop_all()

        sent = False
        last_error = None
        for position in attempted_positions:
            try:
                await bhaptics_python.play_dot(position, duration, values)
                sent = True
            except Exception as error:
                last_error = error

        if not sent:
            emit("COMMAND_ERROR", f"Comando haptico nao foi aceite: {last_error}")
        else:
            emit_playing(attempted_positions)
        return True

    if command == "S":
        await bhaptics_python.stop_all()
        return True

    if command == "CLOSE":
        await bhaptics_python.stop_all()
        return False

    raise ValueError(f"Comando desconhecido: {command}")


async def main() -> int:
    global running

    emit("STARTING", f"Python ativo: {sys.executable}")

    try:
        import bhaptics_python
    except ImportError:
        emit("ERROR", "SDK bhaptics-python nao instalado")
        return 2

    try:
        app_id, api_key = load_credentials()
    except RuntimeError as error:
        emit("ERROR", str(error))
        return 3

    emit("STARTING", "A ligar ao bHaptics Player")

    try:
        initialized = await bhaptics_python.registry_and_initialize(
            app_id, api_key, ""
        )
        if not initialized:
            emit("ERROR", "Nao foi possivel ligar ao bHaptics Player")
            return 4

        emit("SDK_READY", "Ponte bHaptics ligada")
        monitor_task = asyncio.create_task(monitor_left_hand(bhaptics_python))

        while running:
            line = await asyncio.to_thread(sys.stdin.readline)
            if not line:
                break

            try:
                running = await handle_command(bhaptics_python, line)
            except Exception as error:
                emit("COMMAND_ERROR", f"Comando haptico falhou: {error}")

        running = False
        monitor_task.cancel()
        try:
            await monitor_task
        except asyncio.CancelledError:
            pass

        return 0
    except Exception as error:
        emit("ERROR", f"Ponte bHaptics falhou: {error}")
        return 5
    finally:
        try:
            await bhaptics_python.stop_all()
            await bhaptics_python.close()
        except Exception:
            pass


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
