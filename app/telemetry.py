from datetime import datetime, timezone


def generate_telemetry(index: int) -> dict:
    """Generate a simulated tractor telemetry event."""

    if index < 0:
        raise ValueError("Telemetry index cannot be negative")

    tractor_id = f"TRACTOR-{(index % 3) + 1:03d}"

    return {
        "tractor_id": tractor_id,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "speed_kph": round(8 + (index * 3.7) % 35, 1),
        "engine_temp_c": round(72 + (index * 2.4) % 35, 1),
        "fuel_pct": round(90 - index * 1.8, 1),
        "latitude": round(52.13 + index * 0.0002, 6),
        "longitude": round(-106.67 - index * 0.0002, 6),
    }
