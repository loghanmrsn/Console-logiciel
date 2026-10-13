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
