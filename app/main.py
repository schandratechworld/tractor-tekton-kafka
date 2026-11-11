import json
import os
from app.telemetry import generate_telemetry


def main():
    records = int(os.getenv("RECORDS", "12"))

    for i in range(records):
        event = generate_telemetry(i)
        print(json.dumps(event), flush=True)


if __name__ == "__main__":
    main()
