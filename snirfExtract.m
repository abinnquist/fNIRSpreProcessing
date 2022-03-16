function [d, samprate, t, SD, aux, trigInfo] = snirfExtract(subjfolder,numaux)
addpath(genpath('Homer3'))
% Load the snirf file and experimental info (triggers , sample rate, etc.)
snirfFile = dir(strcat(subjfolder,'/*.snirf'));
snirf = SnirfLoad(strcat(subjfolder,'/',snirfFile(1).name)); % Homer3 dependency
samprate = 1/mean(diff(snirf.data.time(:)));

d = snirf.data.dataTimeSeries; % raw data
t = snirf.data.time; % Time series in seconds per frame
if numaux>0
    auxS = snirf.aux;
    [auxData, auxTime, auxNames, auxSampRate] = formataux(auxS,numaux,t);
    aux.names=auxNames;
    aux.data=auxData;
    aux.time=auxTime;
    aux.samprate=auxSampRate;
else
    aux = snirf.aux;
end
SD = getSD(snirf);
trigInfo = snirfTrigInfo(snirf); % Trigger data sorted by time 

function [auxData, auxTime, auxNames, auxSampRate] = formataux(auxS,numaux,t)
numAccChans = length(auxS)/numaux;
lastAcc = numAccChans*numaux; 
auxSampRate = length(auxS(1).time)/auxS(1).time(end,1);
tacc = round(t(end,1)*auxSampRate); %sampling rate of accelerometers
auxData = zeros(tacc,numAccChans,2);
auxTime = zeros(tacc,numAccChans,2);
auxNames = {};
for aCh = 1:lastAcc
    if aCh <= numAccChans
        for auxCh = 1:numAccChans
            auxData(:,auxCh,1) = auxS(aCh).dataTimeSeries(1:tacc,:);
            auxTime(:,auxCh,1) = auxS(aCh).time(1:tacc,:);
        end
    else
        for auxCh = 1:numAccChans
            auxData(:,auxCh,2) = auxS(aCh).dataTimeSeries(1:tacc,:);
            auxTime(:,auxCh,2) = auxS(aCh).time(1:tacc,:);
        end
    end
    auxNames = [auxNames,{auxS(aCh).name}];
end

function SD = getSD(snirfFile)
MeasList = zeros(84,4);
[~, chans] = size(snirfFile.data.dataTimeSeries);
for ch=1:chans
    MeasList(ch,1) = snirfFile.data.measurementList(1,ch).sourceIndex;
    MeasList(ch,2) = snirfFile.data.measurementList(1,ch).detectorIndex;
    MeasList(ch,3) = snirfFile.data.measurementList(1,ch).dataTypeIndex;
    MeasList(ch,4) = snirfFile.data.measurementList(1,ch).wavelengthIndex;
end

SD.MeasList = MeasList;
SD.Lambda = snirfFile.probe.wavelengths;
SD.SrcPos = snirfFile.probe.sourcePos3D;
SD.DetPos = snirfFile.probe.detectorPos3D;
SD.nSrcs = length(SD.SrcPos);
SD.nDets = length(SD.DetPos);
SD.SpatialUnit = snirfFile.metaDataTags.tags.LengthUnit;

function trigInfo = snirfTrigInfo(snirfFile)
numTrigFiles = length(snirfFile.stim);
trigNames={};
triggerData=[];
for f=1:numTrigFiles
    tFolder=snirfFile.stim(f).data;
    triggerData=[triggerData;tFolder];
    
    [numTs, ~]=size(snirfFile.stim(f).data);
    tFolder=snirfFile.stim(f).name;
    for nt=1:numTs
        trigNames=[trigNames;{tFolder}];
    end
end
dataLabels = snirfFile.stim(1).dataLabels;
trigInfo = array2table(trigNames,'VariableNames',{'Condition'});
trigInfo = [trigInfo,array2table(triggerData,'VariableNames',dataLabels)];

trigInfo = sortrows(trigInfo,2);