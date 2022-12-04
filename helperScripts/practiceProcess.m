clc; clear
%% Practice script to better understand the full pipeline
% This script is for better understanding the pipeline and should not be
% used for batch processing. It will only process one scan at a time.
%% INPUTS: 
dataprefix='IPC'; % (character) Prefix of folders that contains data. E.g., 'ST' for ST_101, ST_102, etc. 
motionCorr=2;   % 0 = no motion correction (not reccommended unless comparing)
                % 1 = baseline volatility
                % 2 = wavelet, require homer2 (old: PCFilter-requires mapping toolbox)
                % 3 = baseline volatility & CBSI
                % 4 = CBSI only
numaux=2;       % Number of aux inputs. Currently ONLY works for accelerometers.
                % Other auxiliary inputs: eeg, pulse, etc.

i=1; % dyad, if not dyadic just enter 0
j=2; % subject, if you only have one subject enter 0
k=2; % scan
%% Make all folders active in your path
addpath(genpath('fNIRSpreProcessing'))

addpath(genpath("0_designOptions\")); addpath(genpath("1_extractFuncs\")); 
addpath(genpath("3_removeNoisy\")); addpath(genpath("4_filtering\"));
addpath(genpath("5_qualityControl\")); addpath(genpath("6_imagingORcomparisons\"));

%% Select your storage location
rawdir=uigetdir('','Choose Data Directory');

currdir=dir(strcat(rawdir,filesep,dataprefix,'*'));
if length(currdir)<1
    error(['ERROR: No data files found with ',dataprefix,' prefix']);
end

%% Select your device and trim choice
supported_devices = {'NIRx-NirScout or NirSport1','NIRx-NirSport2 or .nirs file','.Snirf file'};

[device,~] = listdlg('PromptString', 'Select acquisition device:',...
    'SelectionMode', 'single', 'ListString', supported_devices);

scannames = {};

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

    scannames = [scannames,scanname];
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

        scannames = [scannames,scanname];
        %This creates a new folder for my preprocessed data
        outpath = strcat(rawdir,filesep,'PreProcessedFiles',filesep,subjname,filesep,scanname);
    else
        %Here I select the scan 
        scanname = currdir(k).name;
        scanfolder = strcat(rawdir,filesep,scanname);

        scannames = [scannames,scanname];
        %This creates a new folder for my preprocessed data
        outpath = strcat(rawdir,filesep,'PreProcessedFiles',filesep,scanname);
    end
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
    onset = trigInfo.Onset;
    s(find(t==onset(1)),1) = 1;
end

%% 2) Trim scans
% Trim beginning of data based on first trigger
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
[dconverted, dnormed] = fNIRSFilterPipeline(d, SD, samprate, motionCorr, coords);

%% To visualize how your motion correction looks compared to no correction uncomment

% [dconverted2, ~] = fNIRSFilterPipeline(d, SD, samprate, 1, coords);
% dCon1=squeeze(dconverted(:,1,:));
% dCon2=squeeze(dconverted2(:,1,:));
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

%% 6) Output results for uncorrected, removal of noisy & removal of noisy/uncertain
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

%% This creates a csv that shows loss of 
preprocdir = strcat(rawdir,filesep,'PreProcessedFiles');
qualityReport(dataprefix,1,1,scannames,numchannels,preprocdir);

%% 6) Compile data into one .mat file
% Process at least two subjects/scans to get a better idea of what this
% script does.

%INPUTS TO CHANGE
numScans=2; %Number of scans per subject preprocessed
zdim=1; %1=Compile z-scored, 0=compile non-z-scored
ch_reject=2; %Which channel rejection to compile. 1=none, 2=noisy, 3=noisy&uncertain

%
preprocdir = strcat(rawdir,filesep,'PreProcessedFiles');
[deoxy3D,oxy3D]= compiledyadicNIRSdata(preprocdir,dataprefix,ch_reject,numScans,zdim);

% I have yet to find the best way to name the scans due to variation in how
% people name their scans. For now change the 'scannames' variable to include 
% the true scan names in the alphabetical order they appear in the folder. 
% Uncomment lines 258:262 to rename scans before saving.

% scannames={'ingroup','neutral'};
% for s=1:width(oxy3D)
%     oxy3D(s).name=scannames{s};
%     deoxy3D(s).name=scannames{s};
% end

save(strcat(preprocdir,filesep,dataprefix,'_compile.mat'),'oxy3D', 'deoxy3D');
