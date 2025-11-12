# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a MATLAB implementation of real-time heart rate detection using remote photoplethysmography (rPPG). The system analyzes the green channel of video frames from a person's forehead region to detect subtle color changes caused by blood flow, then uses FFT analysis to estimate heart rate in beats per minute (BPM).

## Running the Code

```matlab
heartbeat('video.mp4')
```

The function takes a video file path as input and opens a real-time visualization window showing:
- Video feed with face and ROI overlays
- rPPG signal (green channel intensity over time)
- Frequency spectrum with detected heart rate peak

## Required MATLAB Toolboxes

- Computer Vision Toolbox (for `vision.CascadeObjectDetector` and `VideoReader`)
- Signal Processing Toolbox (for `detrend`, `cheby2`, `filtfilt`, `hamming`, `fft`)

## Core Architecture

The system operates in a continuous processing loop:

1. **Face Detection** (`heartbeat.m:29`): Uses Haar cascade classifier (`FrontalFaceCART`) to locate the face in each frame
2. **ROI Extraction** (`heartbeat.m:36-40`): Defines forehead region as 30-70% horizontally and 10-25% vertically from top of detected face
3. **Signal Acquisition** (`heartbeat.m:44`): Extracts mean green channel value from ROI (rPPG is strongest in green spectrum)
4. **Signal Buffering** (`heartbeat.m:45-50`): Maintains sliding window of last `WINDOW_SIZE` (150) frames
5. **Heart Rate Estimation** (`estimateHeartRate` function): Processes signal when buffer is full
6. **BPM Smoothing** (`heartbeat.m:67-73`): Uses median filter over last 10 BPM estimates for stable display

## Heart Rate Estimation Algorithm

The `estimateHeartRate` function implements a standard rPPG pipeline:

1. **Detrending** (`heartbeat.m:129`): Removes slow-moving artifacts and baseline drift
2. **Normalization** (`heartbeat.m:132`): Standardizes signal to zero mean, unit variance
3. **Bandpass Filtering** (`heartbeat.m:135-138`): Chebyshev Type II filter isolates physiological heart rate range (50-180 BPM = 0.83-3 Hz)
4. **Windowing** (`heartbeat.m:141-142`): Hamming window reduces spectral leakage
5. **FFT with Zero-Padding** (`heartbeat.m:145-146`): 4x zero-padding improves frequency resolution
6. **Peak Detection** (`heartbeat.m:159-172`): Finds maximum power within valid BPM range

## Key Parameters

- `LOW_BPM = 50`: Minimum physiological heart rate (corresponds to 0.83 Hz)
- `HIGH_BPM = 180`: Maximum expected heart rate (corresponds to 3 Hz)
- `WINDOW_SIZE = 150`: Number of frames for FFT analysis (at 30 fps = 5 seconds of data)
- ROI placement: Forehead region chosen for minimal motion artifacts and strong perfusion
- Filter: Chebyshev Type II with 4th order, 40 dB stopband attenuation

## Display System

The `displayResults` function manages a 3-panel figure:
- **Top panel**: Live video with bounding boxes and BPM overlay
- **Middle panel**: Time-domain rPPG signal plot
- **Bottom panel**: Frequency-domain spectrum with detected peak marker

## Potential Modifications

When modifying this code:
- Changing `WINDOW_SIZE` affects both frequency resolution and latency (longer window = better resolution, higher latency)
- ROI position can be adjusted for different facial orientations or different measurement sites (cheeks, nose)
- Filter design (currently Chebyshev) could be changed to Butterworth for different passband characteristics
- BPM smoothing (currently median of last 10) affects display stability vs. responsiveness
