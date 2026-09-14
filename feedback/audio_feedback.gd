class_name AudioFeedback
extends Node

const SAMPLE_RATE: int = 22050
var _player: AudioStreamPlayer
var _settings: FeedbackSettings

func setup(settings: FeedbackSettings) -> void:
    _settings = settings
    _player = AudioStreamPlayer.new()
    add_child(_player)

func play(event_name: String) -> void:
    if _settings == null or not _settings.sfx_enabled:
        return
    var spec: Dictionary = _spec(event_name)
    if spec.is_empty():
        return
    _player.volume_db = linear_to_db(maxf(0.001, _settings.sfx_volume))
    _player.stream = _tone(float(spec["hz"]), float(spec["seconds"]), float(spec["gain"]))
    _player.play()

func _spec(event_name: String) -> Dictionary:
    match event_name:
        "arterial": return {"hz": 540.0, "seconds": 0.055, "gain": 0.30}
        "goal": return {"hz": 760.0, "seconds": 0.12, "gain": 0.34}
        "tier": return {"hz": 920.0, "seconds": 0.18, "gain": 0.38}
        "widen": return {"hz": 430.0, "seconds": 0.075, "gain": 0.28}
        "demolish": return {"hz": 220.0, "seconds": 0.075, "gain": 0.24}
        "insufficient": return {"hz": 165.0, "seconds": 0.10, "gain": 0.24}
        _: return {}

func _tone(hz: float, seconds: float, gain: float) -> AudioStreamWAV:
    var frames: int = maxi(1, int(seconds * SAMPLE_RATE))
    var bytes: PackedByteArray = PackedByteArray()
    bytes.resize(frames * 2)
    for i: int in range(frames):
        var t: float = float(i) / float(SAMPLE_RATE)
        var envelope: float = 1.0 - float(i) / float(frames)
        var sample: int = int(sin(TAU * hz * t) * gain * envelope * 32767.0)
        bytes[i * 2] = sample & 0xff
        bytes[i * 2 + 1] = (sample >> 8) & 0xff
    var wav: AudioStreamWAV = AudioStreamWAV.new()
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.mix_rate = SAMPLE_RATE
    wav.stereo = false
    wav.data = bytes
    return wav
