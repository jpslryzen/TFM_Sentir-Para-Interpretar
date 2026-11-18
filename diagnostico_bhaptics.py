import asyncio
import json
from pathlib import Path

import bhaptics_python


async def main():
    config_path = Path(__file__).with_name("bhaptics-config.json")
    config = json.loads(config_path.read_text(encoding="utf-8"))

    print("A ligar ao bHaptics Player...")
    initialized = await bhaptics_python.registry_and_initialize(
        config["appId"], config["apiKey"], ""
    )
    print("initialized:", initialized)
    print("player_running:", await bhaptics_python.is_bhaptics_player_running())
    print("is_connected:", await bhaptics_python.is_connected())
    print("device_info_json:", await bhaptics_python.get_device_info_json())

    for position in range(0, 30):
        try:
            connected = await bhaptics_python.is_bhaptics_device_connected(position)
            if connected:
                print("connected_position:", position)
        except Exception as error:
            print("position_error:", position, error)

    await bhaptics_python.close()


asyncio.run(main())
