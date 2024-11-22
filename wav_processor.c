#include <stdio.h>
#include <stdlib.h>
#include <sndfile.h>
#include "kissfft/kiss_fft.h"

#define FFT_SIZE 1024  // FFT size, should be a power of 2

// Function to load a WAV file
float* load_wav(const char *inputFile, SNDFILE **infile, SF_INFO *sfinfo, sf_count_t *numSamples) {
    if ((*infile = sf_open(inputFile, SFM_READ, sfinfo)) == NULL) {
        fprintf(stderr, "Error: Could not open file '%s'\n", inputFile);
        fprintf(stderr, "%s\n", sf_strerror(NULL));
        return NULL;
    }

    *numSamples = sfinfo->frames * sfinfo->channels;
    float *buffer = (float *)malloc(*numSamples * sizeof(float));
    if (!buffer) {
        fprintf(stderr, "Error: Could not allocate memory for buffer\n");
        sf_close(*infile);
        return NULL;
    }

    sf_count_t samplesRead = sf_read_float(*infile, buffer, *numSamples);
    if (samplesRead != *numSamples) {
        fprintf(stderr, "Warning: Expected %lld samples but read %lld samples\n", (long long)*numSamples, (long long)samplesRead);
    }

    return buffer;
}

// Function to write the WAV file
void write_wav_file(const char *outputFile, float *buffer, sf_count_t numSamples, int sampleRate, int channels) {
    SF_INFO sfinfo;
    sfinfo.samplerate = sampleRate;
    sfinfo.channels = channels;
    sfinfo.format = SF_FORMAT_WAV | SF_FORMAT_PCM_16;

    SNDFILE *outfile = sf_open(outputFile, SFM_WRITE, &sfinfo);
    if (outfile == NULL) {
        fprintf(stderr, "Error: Could not open output file '%s'\n", outputFile);
        fprintf(stderr, "%s\n", sf_strerror(NULL));
        return;
    }

    sf_count_t written = sf_write_float(outfile, buffer, numSamples);
    if (written != numSamples) {
        fprintf(stderr, "Error: Could not write all samples to file (wrote %lld out of %lld)\n", (long long)written, (long long)numSamples);
    }

    sf_close(outfile);
}

void apply_filter(float *buffer, sf_count_t numSamples, int sampleRate) {
    // Total number of blocks (with 50% overlap)
    int numBlocks = (numSamples + (FFT_SIZE / 2)) / (FFT_SIZE / 2);

    // Allocate temporary buffer for FFT/IFFT processing
    kiss_fft_cfg cfg = kiss_fft_alloc(FFT_SIZE, 0, NULL, NULL);
    kiss_fft_cfg ifft_cfg = kiss_fft_alloc(FFT_SIZE, 1, NULL, NULL);

    // Check if kiss_fft_alloc failed
    if (cfg == NULL || ifft_cfg == NULL) {
        fprintf(stderr, "Error: Failed to allocate FFT configuration.\n");
        return;
    }

    kiss_fft_cpx *fft_input = (kiss_fft_cpx*) malloc(sizeof(kiss_fft_cpx) * FFT_SIZE);
    kiss_fft_cpx *fft_output = (kiss_fft_cpx*) malloc(sizeof(kiss_fft_cpx) * FFT_SIZE);
    kiss_fft_cpx *ifft_output = (kiss_fft_cpx*) malloc(sizeof(kiss_fft_cpx) * FFT_SIZE);

    // Check if memory allocation failed
    if (fft_input == NULL || fft_output == NULL || ifft_output == NULL) {
        fprintf(stderr, "Error: Failed to allocate memory for FFT buffers.\n");
        kiss_fft_free(cfg);
        kiss_fft_free(ifft_cfg);
        return;
    }

    // Prepare overlap-add buffer (initialize with zeroes)
    float *overlapBuffer = (float *)calloc(FFT_SIZE, sizeof(float));

    // Process each block of data with overlap
    for (int block = 0; block < numBlocks; block++) {
        // Calculate the start of the current block
        int start = block * (FFT_SIZE / 2);  // 50% overlap

        // Ensure that the end of the block does not exceed the buffer length
        int end = start + FFT_SIZE;
        if (end > numSamples) {
            end = numSamples;
        }

        // Zero-pad the current block if needed
        for (int i = 0; i < FFT_SIZE; i++) {
            if (i + start < numSamples) {
                fft_input[i].r = buffer[i + start];  // Real part
            } else {
                fft_input[i].r = 0.0f;  // Zero padding
            }
            fft_input[i].i = 0.0f;  // Imaginary part
        }

        // Apply a Hamming window to the signal before FFT
        for (int i = 0; i < FFT_SIZE; i++) {
            float window = 0.54 - 0.46 * cos(2 * M_PI * i / (FFT_SIZE - 1));
            fft_input[i].r *= window;
        }

        // Apply FFT to the block
        kiss_fft(cfg, fft_input, fft_output);

        // Apply lowpass filter in the frequency domain (remove frequencies above 80Hz)
        for (int i = 0; i < FFT_SIZE; i++) {
            float freq = i * (float)sampleRate / FFT_SIZE;
            if (freq < 500) {
                fft_output[i].r = 0;
                fft_output[i].i = 0;
            }
        }

        // Apply IFFT to get the filtered time-domain signal
        kiss_fft(ifft_cfg, fft_output, ifft_output);

        // Add the result to the overlap buffer and copy to the output
        for (int i = 0; i < FFT_SIZE; i++) {
            // Scale by FFT_SIZE to prevent clipping
            overlapBuffer[i] += ifft_output[i].r / FFT_SIZE;
        }

        // Copy the non-overlapping part to the original buffer
        for (int i = 0; i < FFT_SIZE / 2; i++) {  // Overlap section
            if (start + i < numSamples) {
                buffer[start + i] = overlapBuffer[i];
            }
        }

        // Copy the remaining part to the buffer
        for (int i = FFT_SIZE / 2; i < (end - start); i++) {
            if (start + i < numSamples) {
                buffer[start + i] = overlapBuffer[i];
            }
        }

        // Update the overlap buffer (shift the previous part)
        memmove(overlapBuffer, overlapBuffer + FFT_SIZE / 2, (FFT_SIZE / 2) * sizeof(float));
        memset(overlapBuffer + (FFT_SIZE / 2), 0, (FFT_SIZE / 2) * sizeof(float));
    }

    // Clean up
    free(fft_input);
    free(fft_output);
    free(ifft_output);
    free(overlapBuffer);
    kiss_fft_free(cfg);
    kiss_fft_free(ifft_cfg);
}




int main(int argc, char *argv[]) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s <input_file.wav> <output_file.wav>\n", argv[0]);
        return 1;
    }
    const char *inputFile = argv[1];
    const char *outputFile = argv[2];

    SNDFILE *infile = NULL;
    SF_INFO sfinfo = {0};
    sf_count_t numSamples = 0;

    // Load the WAV file
    float *buffer = load_wav(inputFile, &infile, &sfinfo, &numSamples);
    if (buffer != NULL) {
        // Apply the lowpass filter
        // printf("%d", sfinfo.samplerate);
        apply_filter(buffer, numSamples, sfinfo.samplerate);

        // Write the filtered buffer to a new WAV file
        write_wav_file(outputFile, buffer, numSamples, sfinfo.samplerate, sfinfo.channels);

        free(buffer);
    }

    if (infile) {
        sf_close(infile);
    }

    return 0;
}
