%Scan-by-scan version of triggerCheck. Make sure to change the inputs
%before running
clear; clc
%% INPUTS
dataprefix='IPC'; %Data prefix for the study
IDlength=4; % Length of ID+1 (i.e. IPC_103_rest=4); 0=ID not in scan name
hyperscan=1; %If hyperscanning
numscans=5; %Number of scans per subject
rawdir=uigetdir('','Choose data directory');

g=1; % dyad, if not dyadic just enter 0
p=2; % subject, if you only have one subject enter 0
k=5; % scan

%% Step 1: Scan numbers and names
addpath(genpath("fNIRSpreProcessing/1_extractFuncs/")); 

supported_devices = {'NIRx-NirScout or NirSport1','NIRx-NirSport2 or .nirs file','.Snirf file'};
[device,~] = listdlg('PromptString', 'Select acquisition device:',...
    'SelectionMode', 'single', 'ListString', supported_devices);

currdir=dir(strcat(rawdir,filesep,dataprefix,'*'));

%Check how many scans per participant
[scanCount, ~, snames] = countScans(currdir, rawdir, dataprefix, hyperscan, numscans, IDlength);

if g>0 
    %Here I select the dyad and create a directory
    group=currdir(g).name;  
    groupdir=dir(strcat(rawdir,filesep,group,filesep,dataprefix,'*'));

    %Here I select the subject and create a directory
    subjname = groupdir(p).name;
    subjdir = dir(strcat(rawdir,filesep,group,filesep,subjname,filesep,dataprefix,'*'));
    
    %Here I select the scan 
    scanname = subjdir(k).name;
    scanfolder = strcat(rawdir,filesep,group,filesep,subjname,filesep,scanname);

    %This creates a new folder for my preprocessed data
    outpath = strcat(rawdir,filesep,'PreProcessedFiles',filesep,group,filesep,subjname,filesep,scanname);
else
    if p>0
        %Here I select the subject and create a directory
        subjname = currdir(p).name;
        subjdir = dir(strcat(rawdir,filesep,subjname,filesep,dataprefix,'*'));
        
        %Here I select the scan 
        scanname = subjdir(k).name;
        scanfolder = strcat(rawdir,filesep,subjname,filesep,scanname);
    else
        %Here I select the scan 
        scanname = currdir(k).name;
        scanfolder = strcat(rawdir,filesep,scanname);
    end
end

%% Collect trigger info for specific scan
if hyperscan
    scandir=dir(strcat(rawdir,filesep,group,filesep,subjname,filesep,subjdir(k).name,filesep));

    if length(scandir) > 2
        scanfolder = strcat(rawdir,filesep,group,filesep,subjname,filesep,scanname);
    else
        disp('There is no data in this folder')
        return
    end
else
    scandir=dir(strcat(rawdir,filesep,subjname,filesep,subjdir(k).name,filesep));

    if length(scandir) > 2
        scanfolder = strcat(rawdir,filesep,subjname,filesep,scanname);
    else
        disp('There is no data in this folder')
        return
    end
end

% Find triggers and length of scan based on first trigger
if device==1
    [d, sd_ind, samprate, wavelengths, s] = extractNIRxData(scanfolder);
else
    [d, samprate, s, ~, ~, ~] = extractTechEnData(scanfolder);
end
lenScan=length(d);

ssum = sum(s,2);
stimmarks = find(ssum);

if isempty(stimmarks)
    triggers=0;
else
    nt=length(stimmarks);
    triggers=stimmarks;
end
 
fprintf('Number of triggers found: %d \nLength of scan based on first trigger: %f frames\n',length(triggers),lenScan);
