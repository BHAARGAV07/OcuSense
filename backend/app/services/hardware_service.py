def get_hardware_reading() -> dict:
    """
    TEMP MOCK — real Arduino/pyserial integration arrives after
    hardware is delivered. Swap this function body only; nothing
    downstream should need to change when the real sensor is wired in.
    """
    return {"dust": 421, "humidity": 76, "temperature": 31}
