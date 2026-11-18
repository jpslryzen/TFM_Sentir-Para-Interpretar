import asyncio
import json
import os
import sys
from pathlib import Path


PREFERRED_HAND_POSITION = 4
POSITION_CANDIDATES = [4, 5]
MOTOR_COUNT = 3
running = True
active_position = None
send_to_all_candidate_positions = False


def emit(state: str, message: str) -> None:
    clean_message = message.replace("|", " ").replace("\n", " ")
    print(f"STATUS|{state}|{clean_message}", flush=True)


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
                        "READY",
                        "Ponte ligada; envio haptico em modo compatibilidade",
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

    if command == "V":
        if len(parts) != 5:
            raise ValueError("Comando V requer duracao e tres intensidades")

        duration = max(100, min(5000, int(parts[1])))
        values = [max(0, min(100, int(value))) for value in parts[2:5]]
        if len(values) != MOTOR_COUNT:
            raise ValueError("A Tactosy esquerda requer tres intensidades")

        if active_position is None:
            active_position, _ = await find_connected_position(bhaptics_python)

        attempted_positions = []
        if active_position is not None:
            attempted_positions.append(active_position)

        for position in POSITION_CANDIDATES:
            if position not in attempted_positions:
                attempted_positions.append(position)

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
            emit("PLAYING", f"Vibracao enviada para posicoes {attempted_positions}")
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
