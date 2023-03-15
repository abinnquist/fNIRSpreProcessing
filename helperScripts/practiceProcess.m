clc; clear
%% Practice script to better understand the full pipeline
% This script is for better understanding the pipeline and should not be
% used for batch processing. It will only process one scan at a time.

%Step 6 has it's own unique inputs and should only be run once a couple of
%scans/subjects have been preprocessed.

%You may also want to run some pre-preprocessing scripts such as
%countScans.m and triggerCheck.m

%% INPUTS: 
dataprefix='IPC'; % (character) Prefix of folders that contains data. E.g., 'ST' for ST_101, ST_102, etc. 
motionCorr=5;   % 1 = Baseline volatility
                % 2 = PCFilter-requires mapping toolbox
                % 3 = PCA x channel
                % 4 = CBSI
                % 5 = Wavelet, requires homer2 
                % 6 = Short channel regression (Must have short chans)
                % 7 = No correction
numaux=2;       % Number of aux inputs. Currently ONLY works for accelerometers.
                % Other auxiliary inputs: eeg, pulse, etc.

i=6; % dyad, if not dyadic just enter 0
j=1; % subject, if you only have one subject enter 0
k=2; % scan

%For pre-preproc OR step 6
hyperscan=1;
multiscan=1;

numscans=5; %Max number of scan per subject
IDlength=4; %If the subject ID is in the scan name (i.e., IPC_301_rest=4)
zdim=0; %1=Compile z-scored, 0=compile non-z-scored
ch_reject=2; %Which channel rejection to compile. 1=none, 2=noisy, 3=noisy&uncertain

%% Make all folders active in your path
addpath(genpath('fNIRSpreProcessing'))

addpath(genpath("0_designOptions\")); addpath(genpath("1_extractFuncs\")); 
addpath(genpath("3_removeNoisy\")); addpath(genpath("4_filtering\"));
addpath(genpath("5_qualityControl\")); addpath(genpath("6_imagingORcomparisons\"));
addpath(genpath("helperScripts\"));

%% Select your data storage location
rawdir=uigetdir('','Choose Data Directory');

currdir=dir(strcat(rawdir,filesep,dataprefix,'*'));
if length(currdir)<1
    error(['ERROR: No data files found with ',dataprefix,' prefix']);
end

%% Pre-preprocessing
%Checks if all folders have the necessary dataprefix. Will add the prefix to
%the existing folder if not present. Leaves folders with the prefix untouched.
folderRename(rawdir,dataprefix,hyperscan)

%Checks for the number of scan for each dyad/subject. Will also give you
%the scan names based on the first subject.
[scanCount, scannames, snames] = countScans(currdir, dataprefix, hyperscan, numscans, IDlength);

%Only run this if you have already run countScans and all subjects have the
%same number of scan folders, even if the folder is empty. 
%To run the check for only on or two scans use triggerCheckManual.m
trigInfo = triggerCheck(rawdir,dataprefix,IDlength,hyperscan,numscans);

%% Select your device, compile options, and trim choice
supported_devices = {'NIRx-NirScout or NirSport1','NIRx-NirSport2 or .nirs file','.Snirf file'};
[device,~] = listdlg('PromptString', 'Select acquisition device:',...
    'SelectionMode', 'single', 'ListString', supported_devices);

%Quality assesment & Compile options
compInfo = inputdlg({'Run Quality Check? (0=no, 1=yes)','ID length in scan name (e.g., IPC_103_rest=4; CF005_rest=3; SNV_rest=0)?',...
    'Compile  data? (0=no, 1=yes)','Number of Scans (1-n)','Compile Z-score? (0=no, 1=yes)',...
    'Channel rejection? (1=none, 2=noisy, or 3=noisy & uncertain)'},...
              'Compile data info', [1 75]); 

%Type of data trim, if wanted
trimTypes = {'No trim','Beginning with 1st trigger','Beginning with last trigger',...
    'Beginning with .mat','Beginning with a spreadsheet'};
[trim,~] = listdlg('PromptString', 'Do you want to trim scans?',...
    'SelectionMode', 'single', 'ListString', trimTypes);
if trim == 4 
    [trimTs, trimPath] = uigetfile('*.mat','Choose trim time .mat');
    load(strcat(trimPath,trimTs))
elseif trim == 5
    numscans=str2num(compInfo{4});
    [trimTs, trimPath] = uigetfile('*.*','Choose trim times spreadsheet');
    trimTimes =  trimConvert(trimTs, trimPath, numscans);
else
    trimTimes=[];
end
clear trimPath trimTs trimTypes

%% Selecting what data to process
% This example is for hyper & multi scan data
if i>0 
    %Here I select the dyad and create a directory
    group=currdir(i).name;  
    groupdir=dir(strcat(rawdir,filesep,group,filesep,dataprefix,'*'));

    %Here I select the subject and create a directory
    subjname = groupdir(j).name;
    subjdir = dir(strcat(rawdir,filesep,group,filesep,subjname,filesep,dataprefix,'*'));
    
    %Here I select the scan 
    scanname = subjdir(k).name;
    scanfolder = strcat(rawdir,filesep,group,filesep,subjname,filesep,scanname);

    %This creates a new folder for my preprocessed data
    outpath = strcat(rawdir,filesep,'PreProcessedFiles',filesep,group,filesep,subjname,filesep,scanname);
else
    if j>0
        %Here I select the subject and create a directory
        subjname = currdir(j).name;
        subjdir = dir(strcat(rawdir,filesep,subjname,filesep,dataprefix,'*'));
        
        %Here I select the scan 
        scanname = subjdir(k).name;
        scanfolder = strcat(rawdir,filesep,subjname,filesep,scanname);

        %This creates a new folder for my preprocessed data
        outpath = strcat(rawdir,filesep,'PreProcessedFiles',filesep,subjname,filesep,scanname);
    else
        %Here I select the scan 
        scanname = currdir(k).name;
        scanfolder = strcat(rawdir,filesep,scanname);

        %This creates a new folder for my preprocessed data
        outpath = strcat(rawdir,filesep,'PreProcessedFiles',filesep,scanname);
    end
end

%Checks to see if there is data. If not true don't run preproc just make
%empty folder. This allows the compile code to work correctly.
scdir=dir(scanfolder);
scdir=scdir(~startsWith({scdir.name},'.'));
if isempty(scdir)
    mkdir(outpath)
end

%% 1) extract data values
pp=dir(strcat(scanfolder,filesep,'*_probeInfo.mat'));
if isempty(pp) && device==1
    error('ERROR: Scan  does not contain a probeInfo object');
elseif isempty(pp) && device~=1
    coords=[];
elseif ~isempty(pp) 
    load(fullfile(pp.folder,filesep,pp.name));
    coords=probeInfo.probes.coords_c3;
end

%This loop will extract data based on the device you chose
if device==1 %NIRScout
    [d, sd_ind, samprate, wavelengths, s] = extractNIRxData(scanfolder);
    probenumchannels = probeInfo.probes.nChannel0;
    datanumchannels = size(d,2)/2;
    if probenumchannels~=datanumchannels
        error('ERROR: number of data channels in hdr file does not match number of channels in probeInfo file.');
    end
    [SD, aux, t] = getMiscNirsVars(d, sd_ind, samprate, wavelengths, probeInfo);
elseif device==2 %NIRSport
    [d, samprate, s, SD, aux, t] = extractTechEnData(scanfolder);
elseif device==3 %NIRSport & other brands
    [d, samprate, t, SD, aux, trigInfo] = snirfExtract(scanfolder,numaux);
    s = zeros(length(d),1);
    if ~isempty(trigInfo)
        onset = trigInfo.Onset;
        s(find(t==onset(1)),1) = 1;
    end
end

%% 2) Trim scans
% Trim beginning of data based on first trigger

%Below is the actual code for trimming
% sInfo(1,1)=i; sInfo(2,1)=j; sInfo(3,1)=k; sInfo(4,1)=length(subjdir);
% [d,s,t,aux] = trimData(trim, d, s, t, trimTimes, samprate, device, aux, numaux, sInfo);

ssum = sum(s,2);
stimmarks = find(ssum); %Will collect all triggers

%Will trim based on first trigger
if length(stimmarks)>=1
    begintime = stimmarks(end);
    if begintime>0
        d = d(begintime:end,:);
        s = s(begintime:end,:);
        if device==3 && numaux > 0
            auxbegin = round(aux.samprate*begintime/samprate);
            aux.data = aux.data(auxbegin:end,:,:);
            aux.time = aux.time(auxbegin:end,:,:);
        elseif numaux > 0
            aux=aux(begintime:end,:);
        end
        stimmarks = stimmarks-begintime;
        t = t(begintime:end); %This trims our frames to the same length as data
        t = t-t(1,1); %Now we reset the first frame to be zero
    end
else %No data trim if no trigger
    begintime=1;
end

%% 3) identify noisy channels (SNR channel rejection)
satlength = 2; %in seconds
QCoDthresh = 0.6 - 0.03*samprate; % >0.6 more stringency
[d, channelmask] = removeBadChannels(d, samprate, satlength, QCoDthresh);

SD.MeasListAct = [channelmask'; channelmask'];
SD.MeasListVis = SD.MeasListAct;

% This loop will create the correct MNI based on probe/digipts
if SD.SrcPos==0
    load(strcat(rawdir,filesep,'SD_fix.mat'))
    digfile = strcat(rawdir,filesep,'digpts.txt');
    mni_ch_table = getMNIcoords(digfile, SD);
else
    digfile = strcat(scanfolder,filesep,'digpts.txt');
    if device>=2 && exist(digfile,'file')
        mni_ch_table = getMNIcoords(digfile, SD);
    end
end

%% 4) motion filter, convert to hemodynamic changes
[dconverted, dnormed] = fNIRSFilterPipeline(d, SD, samprate, motionCorr, coords,t);

%% To visualize how your motion correction looks compared to no correction uncomment

% [dconverted2, ~] = fNIRSFilterPipeline(d, SD, samprate, 4, coords, t);
% dCon1=squeeze(dconverted(:,1,:));
% dCon2=squeeze(dconverted2(:,1,:));
% 
% tiledlayout(2,1)
% nexttile
% plot(dCon1)
% nexttile
% plot(dCon2)

%% 5) final data quality assessment, remove uncertain channels
% default is to use Pearson's correlation to check how impactful remaining
%  spikes are - can change to "ps" as well if you're using phase synchrony
% in your analyses instead default QA threshold is 0.1 - amount of measurement
% error to be allowed in data (out of 1). Quality assessment only run on the oxy 
qamethod = 'corr';
thresh = 0.1;
qamask = qualityAssessment(squeeze(dconverted(:,1,:)),samprate,qamethod,thresh);
z_qamask = qualityAssessment(squeeze(dnormed(:,1,:)),samprate,qamethod,thresh);

%% Output results for uncorrected, removal of noisy & removal of noisy/uncertain
mkdir(outpath)

if i==0
    i=1;
end

totalmask = channelmask;
totalmask(~qamask) = 0;
z_totalmask = channelmask;
z_totalmask(~z_qamask) = 0;

% Uncorrected 
numchannels = size(dconverted,3);
oxy = zeros(size(dconverted,1), numchannels);
deoxy = zeros(size(dconverted,1), numchannels);
totaloxy = zeros(size(dconverted,1), numchannels);
z_oxy = zeros(size(dnormed,1), numchannels);
z_deoxy = zeros(size(dnormed,1), numchannels);
z_totaloxy = zeros(size(dnormed,1), numchannels);
new_d = zeros(size(dconverted,1), numchannels*2);
for c = 1:numchannels
    oxy(:,c) = dconverted(:,1,c);
    deoxy(:,c) = dconverted(:,2,c);
    totaloxy(:,c) = dconverted(:,3,c);
    z_oxy(:,c) = dnormed(:,1,c);
    z_deoxy(:,c) = dnormed(:,2,c);
    z_totaloxy(:,c) = dnormed(:,3,c);
    new_d(:,(c*2)-1) = oxy(:,c);
    new_d(:,c*2) = deoxy(:,c);
end
save(strcat(outpath,filesep,group,'_',scanname,'_preprocessed.mat'),'oxy', 'deoxy', 'totaloxy','z_oxy', 'z_deoxy', 'z_totaloxy','s','samprate','t','SD','aux');

% Data with noisy channels removed 
oxy(:,~channelmask) = NaN;
deoxy(:,~channelmask) = NaN;
totaloxy(:,~channelmask) = NaN;
z_oxy(:,~channelmask) = NaN;
z_deoxy(:,~channelmask) = NaN;
z_totaloxy(:,~channelmask) = NaN;
save(strcat(outpath,filesep,group,'_',scanname,'_preprocessed_nonoisych.mat'),'oxy', 'deoxy', 'totaloxy','z_oxy', 'z_deoxy', 'z_totaloxy','s','samprate','t','SD','aux');

% Data with noisy channels removed & uncertain based QA mask
oxy(:,~totalmask) = NaN;
deoxy(:,~totalmask) = NaN;
totaloxy(:,~totalmask) = NaN;
z_oxy(:,~z_totalmask) = NaN;
z_deoxy(:,~z_totalmask) = NaN;
z_totaloxy(:,~z_totalmask) = NaN;
save(strcat(outpath,filesep,group,'_',scanname,'_preprocessed_nouncertainch.mat'),'oxy', 'deoxy', 'totaloxy','z_oxy', 'z_deoxy', 'z_totaloxy','s','samprate','t','SD','aux');

%Will create an MNI csv if it exists
if exist('mni_ch_table','var')
    writetable(mni_ch_table,strcat(outpath,filesep,'channel_mnicoords.csv'),'Delimiter',',');
end

%% 6) Compile lost channels & data
%Get scan names
preprocdir = strcat(rawdir,filesep,'PreProcessedFiles');
[~, ~,snames] = countScans(currdir, preprocdir, dataprefix, hyperscan, numscans, IDlength);  

%6.1) Compile number of lost channels
qualityReport(dataprefix,hyperscan,multiscan,numchannels,preprocdir,snames);

%6.2) Compile data into one .mat file
[deoxy3D,oxy3D]= compileNIRSdata(preprocdir,dataprefix,hyperscan,ch_reject,numscans,zdim,snames);

save(strcat(preprocdir,filesep,dataprefix,'_compile.mat'),'oxy3D', 'deoxy3D');
