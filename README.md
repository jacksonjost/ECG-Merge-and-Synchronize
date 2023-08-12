# ECG-Merge-and-Synchronize
A Matlab Script that imports and ECG recording from two different devices and synchronizes the signal using R peaks.
Created by Jackson Jost and Justin Ryan, PhD in the Auerbach Lab, SUNY Upstate Medical University.

This program imports data from two distinct systems using distinct electrodes. From there, the program then processes and sorts the data, filters the signals, and synchronizes the signals with both system time and ECG R peaks (to account for milisecond differences in computer times).

The program utilizes specific file structres from a GE monitor (recorded with iCollect) and a Natus Neuroworks recording system. 
