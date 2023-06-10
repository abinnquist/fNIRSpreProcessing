%Scan-by-scan version of triggerCheck. Make sure to change the inputs
%before running
clear; clc
%% INPUTS
dataprefix='CC'; %Data prefix for the study
IDlength=5; % Length of ID+1 (i.e. IPC_103_rest=4); 0=ID not in scan name
hyperscan=1; %If hyperscanning
numscans=4; %Number of scans per subject
rawdir=uigetdir('','Choose data directory');

g=2; % dyad, if not dyadic just enter 0
p=2; % subject, if you only have one subject enter 0
k=2; % scan

%% Step 1: Scan numbers and names
addpath(genpath("fNIRSpreProcessing/1_design_extract/")); 

supported_devices = {'NIRx-NirScout or NirSport1','NIRx-NirSport2 or .nirs file','.Snirf file'};
[device,~] = listdlg('PromptString', 'Select acquisition device:',...
    'SelectionMode', 'single', 'ListString', supported_devices);

currdir=dir(strcat(rawdir,filesep,dataprefix,'*'));

%Check how many scans per participant
[scanCount, ~, snames] = countScans(currdir, dataprefix, hyperscan, numscans, IDlength);

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
    disp('You will not be able to save changes for NIRScout')
else
    [d, samprate, s, SD, aux, t] = extractTechEnData(scanfolder);
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
display(strcat("Frame location for each trigger: ",num2str(stimmarks')))

% Change triggers
changeInfo = inputdlg({'Delete triggers? (0=no, 1=yes)','Add triggers? (0=no, 1=yes)',...
    'Change trigger time? (0=no, 1=yes)'},...
              'Triggers to change', [1 50]); 

if strcmp(changeInfo{1},'1')
    trigDelete = inputdlg({['Which trigger(s) do you want to delete?...' ...
        ' If it is more than one put it in list format (i.e., 1,3).']},...
              'Trigger Number', [1 75]); 
    s(stimmarks(str2num(trigDelete{1})))=0;

    ssum = sum(s,2);
    stimmarks = find(ssum);
end

if strcmp(changeInfo{2},'1')
    trigAdd = inputdlg({['Where do want to add trigger(s)?...' ...
        ' Make sure you are entering the correct frame number and if it is more than one put it in list format (i.e., 509,512).']},...
              'Trigger Number', [1 75]); 
    s(str2num(trigAdd{1}))=1;

    ssum = sum(s,2);
    stimmarks = find(ssum);
end

if strcmp(changeInfo{3},'1')
    trigChange = inputdlg({'Which trigger(s) do you want to change? If it is more than one put it in list format (i.e., 1,3).',
        'Where do you want to move the triggers? Make sure you are entering the correct frame number and if it is more than one put it in list format (i.e., 509,512).'},...
              'Trigger Number', [1 75]); 

    s(stimmarks(str2num(trigChange{1})))=0;
    s(str2num(trigChange{2}))=1;

    ssum = sum(s,2);
    stimmarks = find(ssum);
end

newTrigs=strcat("You have ",num2str(length(stimmarks))," trigger(s) at the following frame(s): ",num2str(stimmarks'),". Do you want to save the new trigger(s)? 1=yes, 0=no");
saveTrigs=inputdlg({newTrigs},'Save Trigger',[1 65]);

if strcmp(saveTrigs{1},'1')
    nirsfile = dir(strcat(scanfolder,'/*.nirs'));
    nirsFileName=strcat(nirsfile.folder,filesep,nirsfile.name);
    if device==1
        disp('Currently this script does not save changes for the NIRScout')
    else
        save(nirsFileName,'d','samprate','s','SD','aux','t')
    end
end
