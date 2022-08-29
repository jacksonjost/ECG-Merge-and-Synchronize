% ASC / EDF Merge and Timesync
% Auerbach Lab 2022 | Jackson Jost & Justin Ryan
clear; clc;
%% Import Files and Gather Necessary Data

[ascfile,ascpath] = uigetfile('../*.asc', 'rt'); % Import ASC
ascpathlocation = fullfile(ascpath, ascfile); % " "
ascfid = fopen(ascpathlocation); % " "
ascheader = textscan(ascfid, '%{MM/dd/uuuu hh:mm:ss aa}D %f', 1, 'Delimiter', '	'); % Extract header data
ascdata = textscan(ascfid, '%f%f%f%f%f', 'Delimiter', '	', 'HeaderLines', 2); % Extract data'
ASCStart = ascheader(:,1);
originalFs = cell2mat(ascheader(1,2)); % Isolate/confirm original sample rate
ascecg = cell2mat(ascdata(:,2));
asctime = cell2mat(ascdata(:,1));

ASCStartTime = cell2mat(string(ASCStart{1,1}));
ASCStartString = ASCStartTime(1:end-2);
ASCTime = datetime(ASCStartTime, 'TimeZone','America/New_York', 'InputFormat', 'MM/dd/yyyy hh:mm:ss a');
ASCTimeInter = cell2mat(string(ASCTime));
ASCStartTimeConverted = ASCTimeInter(13:end);

[edffile,edfpath] = uigetfile('../*.edf', 'rt'); % Import EDF
edfpathlocation = fullfile(edfpath, edffile); % " "
edfdata = edfread(edfpathlocation); % Extract EDF data
startdate = edfinfor.StartDate; startime = edfinfor.StartTime;
EDFTime = cell2mat(string(datetime(startime, 'InputFormat', "HH.mm.ss")));
EDFTimeDT = datetime(startime, 'InputFormat', "HH.mm.ss");
EDFStartTimeConverted = EDFTime(13:end);
samplerates = edfinfor.NumSamples; % Extract number of samples per cluster
intervals = edfinfor.DataRecordDuration; % Extract time interval
EDFChannel5Fs = samplerates(5,1)/seconds(intervals); % Calculate sample rate for each channel
EDFChannel6Fs = samplerates(6,1)/seconds(intervals); % " "
EDFChannel7Fs = samplerates(7,1)/seconds(intervals); % " "
EDF = timetable2table(edfdata);
EDFChannel5 = cell2mat(EDF.C5);
EDFChannel6 = cell2mat(EDF.C6);
EDFChannel7 = cell2mat(EDF.C7);

Ex = datetime(EDFStartTimeConverted); %EDF Start Time
Ax = datetime(ASCStartTimeConverted); %ASC Start Time
DF = string(time(between(Ex, Ax, 'time'))); % Difference Between Them
[Y1, M1, D1, H1, MN1, S1] = datevec(DF); %Output Difference Split H/M/etc
TimeDiff = H1*3600+MN1*60+S1; % Seconds Difference
SampleDiffEDF = TimeDiff*EDFChannel5Fs; % Seconds Difference * Sample Rate
SampleDiffASC = TimeDiff*originalFs; % Seconds Difference * Sample Rate

DetrendASC = sgolayfilt(ascecg, 5, 51);
FixedASC = ascecg - DetrendASC;

ascresamp = resample(ascecg, EDFChannel5Fs,originalFs);
DetrendASCUp = sgolayfilt(ascresamp, 15, 601);
FixedASCUp = ascresamp - DetrendASCUp;
ASCUpForSync = FixedASCUp;

DetrendEDF = sgolayfilt(EDFChannel5, 15, 601);
FixedEDF = EDFChannel5 - DetrendEDF;

EDFForSync = FixedEDF(SampleDiffEDF:end);

EDFSync = EDFForSync(1:61440);
ASCUpSync = ASCUpForSync(1:61440); % One Minute of Recording
ASCSync = ASCUpForSync(1:6000); % One Minute of Recording

delayOut = finddelay(ASCUpSync, EDFSync);
%lowASCDelayOut = round((delayOut*originalFs)/EDFChannel5Fs);
delayOutLow = finddelay(ASCSync, EDFSync);

EDFSync = EDFForSync(delayOut:61440);% One Minute of Recording
ASCUpSync = ASCUpSync*3000;
ASCSync = ASCSync*3000;
timesASC = linspace(1, length(ASCSync)/originalFs, length(ASCSync));
timesASCUp = linspace(1, length(ASCUpSync)/EDFChannel5Fs, length(ASCUpSync));
timesEDF = linspace(1, length(EDFSync)/EDFChannel5Fs, length(EDFSync));
plot(timesASCUp, ASCUpSync, timesEDF, EDFSync)
ax = gca;
ax.XLim = [48,50.6];




