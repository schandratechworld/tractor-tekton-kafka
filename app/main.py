import json
import os
import time

from app.telemetry import generate_telemetry


def main():
    records = int(os.getenv("RECORDS", "12"))
    continuous = os.getenv("CONTINUOUS", "false").lower() == "true"
    interval = float(os.getenv("INTERVAL_SECONDS", "5"))

    index = 0

    while True:
        event = generate_telemetry(index)
        print(json.dumps(event), flush=True)

        index += 1

        if not continuous and index >= records:
            break

        time.sleep(interval)


if __name__ == "__main__":
    main()
