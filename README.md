# ECG-Merge-and-Synchronize
A Matlab Script that imports and ECG recording from two different devices and synchronizes the signal using R peaks.
Created by Jackson Jost and Justin Ryan, PhD in the Auerbach Lab, SUNY Upstate Medical University.

This program imports data from two distinct systems using distinct electrodes. From there, the program then processes and sorts the data, filters the signals, and synchronizes the signals with both system time and ECG R peaks (to account for milisecond differences in computer times).

The program utilizes specific file structures from a GE monitor (recorded with iCollect - ASC) and a Natus Neuroworks recording system (EDF). 

1. **Import Files and Gather Necessary Data**: 
   - Reads ASC file and extracts header information (time, sample rate) and data (ECG, plethysmogram, CO2, and O2 levels).
   - Reads EDF file and extracts start date, start time, sample rates, number of samples, and channels.

2. **Calculate Sample (Clock Time) Difference**: 
   - Calculates the time difference between the ASC and EDF recordings and converts this into sample differences for synchronization.

3. **Resample ASC**: 
   - Resamples the ASC data to match the EDF sample rates.

4. **Prepare ECGs**: 
   - Detrends and filters the ECG signals using a Savitzky-Golay filter.

5. **Calculate QRS Offset (Difference/Delay)**:
   - Computes the delay between the two ECG signals to align them.

6. **Synchronize Signals**: 
   - Creates synchronization gaps and concatenates the data to align the ASC and EDF signals.

7. **Error Testing**: 
   - Tests the synchronization using specific intervals and calculates the error percentage, providing the difference in milliseconds and bpm.

8. **EDF Output**: 
   - Combines the synchronized data and constructs an EDF header for output.

The end result is a merged and synchronized dataset that combines the information from both the ASC and EDF files. This script takes care to adjust the sampling rates and align the signals for consistent synchronization.
