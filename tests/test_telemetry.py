from datetime import datetime
import pytest

from app.telemetry import generate_telemetry


def test_tractor_id():
    event = generate_telemetry(0)
    assert event["tractor_id"] == "TRACTOR-001"


def test_tractor_rotation():
    assert generate_telemetry(1)["tractor_id"] == "TRACTOR-002"
    assert generate_telemetry(2)["tractor_id"] == "TRACTOR-003"
    assert generate_telemetry(3)["tractor_id"] == "TRACTOR-001"


def test_engine_temperature():
    event = generate_telemetry(0)
    assert event["engine_temp_c"] == 72.0


def test_speed():
    event = generate_telemetry(0)
    assert event["speed_kph"] == 8.0


def test_gps_coordinates():
    event = generate_telemetry(0)
    assert event["latitude"] == 52.13
    assert event["longitude"] == -106.67


def test_timestamp():
    event = generate_telemetry(0)
    datetime.fromisoformat(event["timestamp"])


def test_negative_index():
    with pytest.raises(ValueError):
        generate_telemetry(-1)
