import numpy as np


def generate_pcm_cosine_wave(frequency, sample_rate, duration, amplitude, output_file):
    """
    Generate a PCM cosine wave and save it to a text file.

    Parameters:
    - frequency (float): Frequency of the cosine wave in Hz.
    - sample_rate (int): Sampling rate in samples per second.
    - duration (float): Duration of the wave in seconds.
    - amplitude (float): Amplitude of the wave.
    - output_file (str): Path to the output text file.
    """
    # Time array
    t = np.linspace(0, duration, int(sample_rate * duration), endpoint=False)

    # Generate cosine wave
    wave = amplitude * np.cos(2 * np.pi * frequency * t)

    # Quantize the wave to integer PCM values (e.g., 16-bit signed integers)
    pcm_wave = np.int16(wave)

    # Save to text file
    with open(output_file, "w") as file:
        for sample in pcm_wave:
            file.write(f"{sample}\n")

    print(f"PCM cosine wave saved to {output_file}")


# Parameters
frequency = 440.0  # Frequency in Hz (e.g., A4 note)
sample_rate = 44100  # Sample rate in Hz (CD quality)
duration = 1.0  # Duration in seconds
amplitude = 127  # Amplitude (max for 16-bit signed integers)
output_file = "pcm_cosine_wave.txt"

# Generate and save the PCM cosine wave
generate_pcm_cosine_wave(frequency, sample_rate, duration, amplitude, output_file)
