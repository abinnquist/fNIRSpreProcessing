%% Set properties
dataprefix='HM';
IDlength=5;
ch_reject=2; %1=none, 2=noisy only, 3=noisy&uncertain
hyperscan=1; %0=no, 1=yes
numscans=3; %number of scans (i.e., 3) OR scans that you want to compile (i.e., [1,3])
zdim=0; %0=no z-score, 1=z-score
chanCheck=1; %0=no , 1=yes, extra variable(s) for lost channels by subject/scan

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
[deoxy3D,oxy3D] = compileNIRSdata(preprocdir,dataprefix,hyperscan,ch_reject,numscans,zdim,snames);

if chanCheck
    qualityRep;
end

save(strcat(preprocdir,filesep,dataprefix,'_compile.mat'),'oxy3D', 'deoxy3D');
