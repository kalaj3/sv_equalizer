import numpy as np

# Simulate receiving PDM data
# In a real scenario, you'd receive this data from your FPGA or a file
# For demonstration, let's create a random PDM bitstream


sample_rate = 3_072_000 # 3.072 MHz
pdm_data = np.random.randint(0, 2, size=sample_rate)  # 1 second of PDM at sample_rate
#could/should be replaced with function to read from file//gen file for visibility 


target_pcm_rate = 48_000  # 48 kHz // standard pcm 
decimation_factor = sample_rate // target_pcm_rate #64

pdm_bipolar = pdm_data * 2 - 1  # Convert to bipolar - filters expect this (do they in sv?)

cutoff_freq = 24_000  # 24 kHz human hearing range 

