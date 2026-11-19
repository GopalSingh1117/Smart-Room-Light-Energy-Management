from app.services.energy_service import calculate_power_watts

def test_power_calculation():
    # 0% duty -> 0 Watts
    assert calculate_power_watts(0, True, 10.0) == 0.0
    # Light OFF -> 0 Watts
    assert calculate_power_watts(100, False, 10.0) == 0.0
    # 100% duty on 10W LED -> 10.0 Watts
    assert calculate_power_watts(100, True, 10.0) == 10.0
    # 60% duty on 10W LED -> 6.0 Watts
    assert calculate_power_watts(60, True, 10.0) == 6.0
    # 30% duty on 10W LED -> 3.0 Watts
    assert calculate_power_watts(30, True, 10.0) == 3.0
