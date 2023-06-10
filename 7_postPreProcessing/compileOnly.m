%% Set properties
dataprefix='SD';
IDlength=4;
ch_reject=2; %1=none, 2=noisy only, 3=noisy&uncertain
hyperscan=1; %0=no, 1=yes
numscans=3; %number of scans per subject
zdim=0; %0=no z-score, 1=z-score

%% Select your data storage location
rawdir=uigetdir('','Choose Data Directory');

currdir=dir(strcat(rawdir,filesep,dataprefix,'*'));
if length(currdir)<1
    error(['ERROR: No data files found with ',dataprefix,' prefix']);
end

%% Make all folders active in your path
addpath(genpath('fNIRSpreProcessing'))

addpath(genpath("0_designOptions\")); addpath(genpath("1_extractFuncs\")); 
addpath(genpath("3_removeNoisy\")); addpath(genpath("4_filtering\"));
addpath(genpath("5_qualityControl\")); addpath(genpath("6_imagingORcomparisons\"));
addpath(genpath("helperScripts\"));

%% Get scan names
preprocdir = strcat(rawdir,filesep,'PreProcessedFiles');
[~, ~,snames] = countScans(currdir, dataprefix, hyperscan, numscans, IDlength);  

%% Compile Data & Save
[deoxy3D,oxy3D] = compileNIRSdata(preprocdir,dataprefix,hyperscan,ch_reject,numScans,zdim,snames);

save(strcat(preprocdir,filesep,dataprefix,'_compile.mat'),'oxy3D', 'deoxy3D');
