% ASC / EDF Merge and Timesync
% Auerbach Lab 2022 | Jackson Jost
clear; clc;
%% Import Files and Gather Necessary Data
%[ascfile,ascpath] = uigetfile('../*.asc', 'rt'); % Import ASC
%ascpathlocation = fullfile(ascpath, ascfile); % " "
%ascfid = fopen(ascpathlocation); % " "
% OG ascfid = fopen('2_7_rb14466_BASELINE_waves.asc');
ascfid = fopen('RB14472_PTZ_2-9-2022_waves.asc');
ascheader = textscan(ascfid, '%{MM/dd/uuuu hh:mm:ss aa}D %f', 1, 'Delimiter', '	'); % Extract header data
ascdata = textscan(ascfid, '%f%f%f%f%f', 'Delimiter', '	', 'HeaderLines', 2); % Extract data'
ASCStart = ascheader(:,1);
originalFs = cell2mat(ascheader(1,2)); % Isolate/confirm original sample rate
ascecg = cell2mat(ascdata(:,2));
ascpleth = cell2mat(ascdata(:,3));
ascCO2 = cell2mat(ascdata(:,4));
ascO2 = cell2mat(ascdata(:,5));
asctime = cell2mat(ascdata(:,1));
ASCStartTime = cell2mat(string(ASCStart{1,1}));
ASCStartString = ASCStartTime(1:end-2);
ASCTime = datetime(ASCStartTime, 'TimeZone','America/New_York', 'InputFormat', 'MM/dd/yyyy hh:mm:ss a');
ASCTimeInter = cell2mat(string(ASCTime));
ASCStartTimeConverted = ASCTimeInter(13:end);
%[edffile,edfpath] = uigetfile('../*.edf', 'rt'); % Import EDF
%edfpathlocation = fullfile(edfpath, edffile); % " "
%edfdata = edfread(edfpathlocation); % Extract EDF data
% OG edfdata = edfread('1446614472_ 7b_a187b711-1931-4351-afe0-bc894b66631f._A.edf');
edfdata = edfread('1446614472_ 7B_f417e844-5ac2-47fc-89ac-629efd588c69._B.edf');
%OG edfinfor = edfinfo('1446614472_ 7b_a187b711-1931-4351-afe0-bc894b66631f._A.edf');
edfinfor = edfinfo('1446614472_ 7B_f417e844-5ac2-47fc-89ac-629efd588c69._B.edf');
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
EDFChannel5 = cell2mat(EDF.(7)); %make C5
EDFChannel6 = cell2mat(EDF.(8));
EDFChannel7 = cell2mat(EDF.(9));
%% Calculate Sample (Clock Time) Difference
Ex = datetime(EDFStartTimeConverted); %EDF Start Time
Ax = datetime(ASCStartTimeConverted); %ASC Start Time
DF = string(time(between(Ex, Ax, 'time'))); % Difference Between Them
[Y1, M1, D1, H1, MN1, S1] = datevec(DF); % Seperate Output Difference Hour/Min/etc
TimeDiff = H1*3600+MN1*60+S1; % Seconds Difference
SampleDiffEDF = TimeDiff*EDFChannel5Fs; % Seconds Difference * Sample Rate
SampleDiffASC = TimeDiff*originalFs; % Seconds Difference * Sample Rate
%% Resample ASC
ascECGresamp = resample(ascecg, EDFChannel5Fs,originalFs); % Self-Explanatory
plethresamp = resample(ascpleth, EDFChannel5Fs,originalFs);
O2resamp = resample(ascO2, EDFChannel5Fs,originalFs);
CO2resamp = resample(ascCO2, EDFChannel5Fs,originalFs);
%% Prepare ECGs
DetrendASC = sgolayfilt(ascecg, 5, 51);
FixedASC = ascecg - DetrendASC;
DetrendASCUp = sgolayfilt(ascECGresamp, 15, 601);
FixedASCUp = ascECGresamp - DetrendASCUp;
ASCUpForSync = FixedASCUp;
DetrendEDF = sgolayfilt(EDFChannel5, 15, 601);
FixedEDF = EDFChannel5 - DetrendEDF;
%% Calculate QRS Offset (Difference/Delay)
EDFForSync = FixedEDF(SampleDiffEDF:end);
EDFSync = EDFForSync(1:61440);
ASCUpSync = ASCUpForSync(1:61440); % One Minute of Recording
ASCSync = ascecg(1:6000); % One Minute of Recording
delayOut = finddelay(ASCUpSync, EDFSync);
lowASCDelayOut = fix((delayOut*originalFs)/EDFChannel5Fs);
%% Syncronize Signals
Gap = zeros(1,SampleDiffEDF+delayOut)';
GapASCOg = zeros(1,SampleDiffASC+lowASCDelayOut)';
ASCecgLowComb = cat(1, GapASCOg, ascecg);
ASCecgLowComb = ASCecgLowComb*3000;
ASCecgComb = cat(1, Gap, ascECGresamp);
Channel = zeros(1, fix(length(ASCecgComb)/128))+128;
ChannelX = (fix(length(ASCecgComb)/128))*128;
ChannelDiff = length(ASCecgComb) - ChannelX;
ChannelCat = [Channel ChannelDiff];
%ASCECGOut = mat2cell(ASCecgComb, ChannelCat, [1]);
ASCplethComb = cat(1, Gap, plethresamp);
%ASCPlethOut = mat2cell(ASCplethComb, ChannelCat, [1]);
ASCcO2Comb = cat(1, Gap, CO2resamp);
%ASCcO2Out = mat2cell(ASCcO2Comb, ChannelCat, [1]);
ASCO2Comb = cat(1, Gap, O2resamp);
%ASCO2Out = mat2cell(ASCO2Comb, ChannelCat, [1]);
ASCDataMain = [ASCecgComb, ASCplethComb, ASCcO2Comb, ASCO2Comb];
%% Error Testing
intervalsize = 5000;
errorpercent = [1];
ASCecgComb_Scaled = ASCecgComb*2000;
if length(EDFChannel5) > length(ASCecgComb_Scaled)
    endsize = length(ASCecgComb_Scaled);
else
    endsize = length(EDFChannel5);
end
ii = length(Gap):intervalsize:endsize;
for xxy = 1:length(ii)
    if xxy+1 > length(ii)
        break
    else
ASCecgComb_Scaled = ASCecgComb*2000;
timesASComb = linspace(1, length(ASCecgComb_Scaled)/EDFChannel5Fs, length(ASCecgComb_Scaled));
timesEDFMain = linspace(1, length(EDFChannel5)/EDFChannel5Fs, length(EDFChannel5));
LowBo = ii(xxy);
UpBo = ii(xxy+1);
ASCUpVer = ASCecgComb_Scaled(LowBo:UpBo);
ASCUpVer2 = sgolayfilt(ASCUpVer, 16, 501);
ASCUpVer = ASCUpVer - ASCUpVer2;
EDFVer = EDFChannel5(LowBo:UpBo);
EDFVer2 = sgolayfilt(EDFVer, 16, 501);
EDFVer = EDFVer - EDFVer2;
EDFTime1 = timesEDFMain(LowBo:UpBo);
AscTime1 = timesASComb(LowBo:UpBo);
[EDFpks1,EDFlocs1, EDFw1, EDFp1] = findpeaks(EDFVer, EDFTime1,  "MinPeakProminence", 600);
[ASCRpks,ASCRlocs, ASCRw, ASCRp] = findpeaks(ASCUpVer, AscTime1, "MinPeakProminence", 300);
RRA = diff(ASCRlocs);
BBARate = 60./RRA;
RateASC = mean(BBARate);
ASCRate(xxy) = RateASC;
RRE = diff(EDFlocs1);
BBERate = 60./RRE;
RateEDF = mean(BBERate);
EDFRate(xxy) = RateEDF;
if length(RRE) > length(RRA)
    RRE = RRE(1:length(RRA));
else
    RRA = RRA(1:length(RRE));
end
error(xxy) = mean(abs(RRE-RRA))*10000;
if error(xxy)<300
errorpercent(xxy) = (error(xxy)/EDFChannel5Fs)*100;
elseif xxy-1 == 0
    errorpercent(xxy) = 0;
else
    errorpercent(xxy) = errorpercent(xxy-1);
end
    end
end
samples = EDFChannel5Fs*(max(errorpercent)/100);
timeoffsec = samples/EDFChannel5Fs;
miliseconds = timeoffsec*1000;
samples2 = EDFChannel5Fs*(median(errorpercent)/100);
timeoffsec2 = samples2/EDFChannel5Fs;
miliseconds2 = timeoffsec2*1000;
fprintf("The Sync is off by a max of %.3f milliseconds.\n", miliseconds)
fprintf("The median sync error is %.3f milliseconds.\n", miliseconds2)
RateCompare = median(abs(rmmissing(EDFRate(1:length(rmmissing(ASCRate)))) - rmmissing(ASCRate)));
fprintf("The median difference in heart rate is over %.0f 4.8sec intervals is %.3f beats/minute.\n", length(ii), RateCompare)
%plot(AscTime1, ASCUpVer, EDFTime1, EDFVer)
%% EDF OUTPUT
for i = 2:width(EDF)
sigdata(:,i) = EDF.(i);
end
sigdataout = cell2mat(sigdata);
if length(ASCDataMain) > length(sigdataout)
    ASCData = 3000*ASCDataMain(1:length(sigdataout),:);
else
    lengthdiff = abs(length(ASCDataMain) - length(sigdataout));
    extratoadd = zeros(lengthdiff, width(ASCDataMain));
    ASCData = 3000*vertcat(ASCDataMain, extratoadd);
end
sigdataMAIN = [sigdataout ASCData];
hdr = edfheader("EDF");
hdr.Patient = edfinfor.Patient;
hdr.Recording = edfinfor.Recording;
hdr.StartDate = edfinfor.StartDate;
hdr.StartTime = edfinfor.StartTime;
hdr.NumSignals = edfinfor.NumSignals + 4;
hdr.NumDataRecords = edfinfor.NumDataRecords;
hdr.DigitalMax = [ 8711; 8711; 8711; 8711; 8711; 8711; 8711; 8711; 8711; 8711; 8711; 8711; 8711;];
hdr.DigitalMin = [ -8711; -8711; -8711; -8711; -8711; -8711; -8711; -8711; -8711; -8711; -8711; -8711; -8711;];
hdr.PhysicalMax = [ 8711; 8711; 8711; 8711; 8711; 8711; 8711; 8711; 8711; 8711; 8711; 8711; 8711;];
hdr.PhysicalMin = [ -8711; -8711; -8711; -8711; -8711; -8711; -8711; -8711; -8711; -8711; -8711; -8711; -8711;];
edfOutput = edfwrite("outputEDFtest.edf",hdr,sigdataMAIN);
