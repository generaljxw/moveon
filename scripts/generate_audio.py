# generate_audio.py — Generate MoveOn audio assets
import struct, wave, math, os

def create_wav(path, freq, duration, sample_rate=44100):
    """Generate a simple sine wave WAV file with fade-out"""
    n_samples = int(sample_rate * duration)
    samples = []
    for i in range(n_samples):
        t = i / sample_rate
        envelope = max(0.0, 1.0 - t / duration)  # linear fade out
        sample = int(32767 * 0.6 * envelope * math.sin(2.0 * math.pi * freq * t))
        samples.append(sample)

    with wave.open(path, 'w') as wf:
        wf.setnchannels(1)  # mono
        wf.setsampwidth(2)  # 16-bit PCM
        wf.setframerate(sample_rate)
        wf.writeframes(struct.pack('<' + 'h' * len(samples), *samples))

base = os.path.dirname(os.path.abspath(__file__))
audio_dir = os.path.join(base, '..', 'assets', 'audio')
os.makedirs(audio_dir, exist_ok=True)

# 铛铛铛洪亮音：880 Hz, 0.3s 短促高音（最后一秒用）
create_wav(os.path.join(audio_dir, 'countdown_beep.wav'), 880, 0.3)
# 柔和提示音：440 Hz, 0.15s 低沉短音（前四秒用）
create_wav(os.path.join(audio_dir, 'countdown_soft.wav'), 440, 0.15)
# 锻炼完成：520 Hz, 1.5s 舒缓长音
create_wav(os.path.join(audio_dir, 'workout_complete.wav'), 520, 1.5)

print('Audio files generated successfully')
