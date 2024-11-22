import numpy as np
from matplotlib import pyplot as plt


# Function to generate different types of stimuli
def generate_stimulus(signal_type, f0, fs, N):
    """
    Generate a stimulus signal based on the specified type.

    Parameters:
    - signal_type: 'positive_full_scale', 'negative_full_scale', 'alternate_high_low'
    - f0: Frequency of the signal (not used for constant signals)
    - fs: Sampling frequency
    - N: Number of samples

    Returns:
    - stim: Generated stimulus signal as a numpy array
    """
    if signal_type == "positive_full_scale":
        stim = np.ones(N)  # Constant high
    elif signal_type == "negative_full_scale":
        stim = np.zeros(N)  # Constant low
    elif signal_type == "alternate_high_low":
        stim = np.tile([1, 0], N // 2)
        if N % 2:
            stim = np.append(stim, 1)  # Handle odd N
    else:
        # For other types like 'cosine', you can extend this function
        w = 2 * np.pi * (f0 / fs) * np.arange(0, N)
        stim = np.cos(w)  # Original cosine stimulus with DC offset
    return stim


# Function to convert stimulus to PDM
def convert_to_pdm(stim, IMPULSE_HEIGHT, THRESHOLD):
    """
    Convert a stimulus signal to PDM.

    Parameters:
    - stim: Input stimulus signal
    - IMPULSE_HEIGHT: Maximum value of the stimulus
    - THRESHOLD: Threshold value for PDM conversion

    Returns:
    - output_pdm: Binary PDM signal
    """
    output_pdm = np.zeros_like(stim)
    running_sum = 0

    for i, sample in enumerate(stim):
        running_sum += sample
        if running_sum > THRESHOLD:
            running_sum -= IMPULSE_HEIGHT
            output_pdm[i] = 1

    return output_pdm


# Function to save PDM signal to a text file
def save_pdm(pdm_signal, filename):
    """
    Save the PDM signal to a text file.

    Parameters:
    - pdm_signal: Binary PDM signal
    - filename: Name of the output file
    """
    np.savetxt(filename, pdm_signal, fmt="%d")


# Function to plot PDM and stimulus signals
def plot_signals(pdm_signals, stim_signals, labels, N_plot=1000):
    """
    Plot PDM and stimulus signals.

    Parameters:
    - pdm_signals: List of PDM signals
    - stim_signals: List of stimulus signals
    - labels: List of labels for each signal
    - N_plot: Number of samples to plot
    """
    plt.figure(figsize=(15, 8))

    for idx, (pdm, stim, label) in enumerate(zip(pdm_signals, stim_signals, labels)):
        plt.subplot(len(pdm_signals), 2, 2 * idx + 1)
        plt.plot(stim[:N_plot])
        plt.title(f"Stimulus: {label}")
        plt.xlabel("Sample")
        plt.ylabel("Amplitude")
        plt.grid(True)

        plt.subplot(len(pdm_signals), 2, 2 * idx + 2)
        plt.step(range(N_plot), pdm[:N_plot], where="post")
        plt.ylim(-0.2, 1.2)
        plt.title(f"PDM Output: {label}")
        plt.xlabel("Sample")
        plt.ylabel("PDM Bit")
        plt.grid(True)

    plt.tight_layout()
    plt.show()


# Main function to generate, save, and plot PDM signals
def main():
    # Parameters
    fs = 3e6  # Sampling frequency: 3 MHz
    N = 2**14  # Number of samples: 16384
    f0 = 1e3  # Frequency: 1 kHz (only used for non-constant signals)

    # Define the three signal types
    signal_types = [
        "positive_full_scale",
        "negative_full_scale",
        "alternate_high_low",
        "cosine",
    ]

    # Corresponding filenames
    filenames = [
        "pdm_positive_full_scale.txt",
        "pdm_negative_full_scale.txt",
        "pdm_alternate_high_low.txt",
        "pdm_cosine.txt",
    ]

    # Lists to store signals for plotting
    pdm_signals = []
    stim_signals = []
    labels = []

    for signal_type, filename in zip(signal_types, filenames):
        # Generate stimulus
        stim = generate_stimulus(signal_type, f0, fs, N)
        stim_signals.append(stim)
        labels.append(signal_type.replace("_", " ").title())

        # Determine IMPULSE_HEIGHT and THRESHOLD based on stimulus
        IMPULSE_HEIGHT = np.amax(stim)
        THRESHOLD = IMPULSE_HEIGHT / 2

        # Convert to PDM
        pdm = convert_to_pdm(stim, IMPULSE_HEIGHT, THRESHOLD)
        pdm_signals.append(pdm)

        # Save PDM to file
        save_pdm(pdm, filename)
        print(f"Generated and saved {signal_type} to {filename}")

    # Plot the signals
    plot_signals(pdm_signals, stim_signals, labels, N_plot=1000)


if __name__ == "__main__":
    main()
    # main()
