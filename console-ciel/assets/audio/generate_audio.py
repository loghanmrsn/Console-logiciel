"""Original CC0 audio synthesis recipe for Console CIEL.
Use Python 3; standard library only. Run from assets/audio/."""
import math
import struct
import wave
from pathlib import Path

RATE = 22050
ROOT = Path(__file__).parent

def write(name, samples):
    with wave.open(str(ROOT / name), "wb") as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(RATE)
        stream.writeframes(struct.pack("<%dh" % len(samples), *samples))

notes = [261.63, 329.63, 392, 329.63, 293.66, 349.23, 440, 349.23, 261.63, 329.63, 392, 523.25, 293.66, 349.23, 392, 329.63]
samples = []
for note in notes:
    for i in range(RATE):
        t = i / RATE
        env = (1 - math.exp(-t * 12)) * math.exp(-t * 3.5)
        signal = .085 * env * (math.sin(2 * math.pi * note * t) + .12 * math.sin(2 * math.pi * 2 * note * t))
        samples.append(int(signal * 32767))
write("menu.wav", samples)
samples = []
for i in range(int(RATE * .16)):
    t = i / RATE
    env = math.sin(math.pi * t / .16) ** 2
    samples.append(int(.16 * env * math.sin(2 * math.pi * (660 + 420 * t / .16) * t) * 32767))
write("confirm.wav", samples)

# Three additional original, seamless 16-second compositions (CC0).
for style, sequence in {
    'ambient': [130.81, 164.81, 196.00, 146.83, 174.61, 220.00, 196.00, 164.81],
    'electro': [130.81, 196.00, 261.63, 196.00, 146.83, 220.00, 293.66, 220.00],
    'chiptune': [261.63, 329.63, 392.00, 523.25, 440.00, 349.23, 293.66, 392.00],
}.items():
    samples = []
    for i in range(RATE * 16):
        t = i / RATE
        beat = 2.0 if style == 'ambient' else 0.5
        phase = t % beat
        note = sequence[int(t / beat) % len(sequence)]
        envelope = min(1, phase / 0.015) * min(1, (beat-phase) / 0.06)
        if style == 'ambient':
            envelope *= math.sin(math.pi * phase / beat)**2
            value = sum(math.sin(2*math.pi*note*ratio*t) for ratio in (1,1.25,1.5)) / 3
        elif style == 'electro':
            value = math.sin(2*math.pi*note*t) * math.exp(-phase*5)
            value += .3*math.sin(2*math.pi*55*t)*math.exp(-phase*22)
        else:
            # Band-limited square timbre, no harsh discontinuities.
            value = sum(math.sin(2*math.pi*note*h*t)/h for h in (1,3,5))*.65
            envelope *= math.exp(-phase*3)
        samples.append(int(32767*.12*value*envelope))
    write(style+'.wav', samples)
