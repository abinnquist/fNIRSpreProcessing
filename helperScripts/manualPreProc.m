%% Manual input for preProcessing
% INPUTS 
dataprefix='SIM'; % (character) Prefix of folders for all data. E.g., 'ST' for ST_101, ST_102, etc. 
hyperscan=0;      % 0 or 1. 1 if hyperscanning, 0 if single subject.
multiscan=1;      % 0 or 1. 1 if multiple scans per person, 0 if single scan
numaux=2;         % Number of aux inputs. Currently ONLY works for accelerometers.
motionCorr=1;     % 1 = baseline volatility
                  % 2 = PCFilter (requires mapping toolbox)
                  % 3 = PCA by channel
                  % 4 = CBSI only
                  % 5 = Wavelet
                  % 6 = Short channel regression
                  % 7 = no motion correction (not reccommended)
device=2;         % 1 = NIRScout, 2 = NIRSport2 or .nirs,  3 = .snirf
trim=1;           % 1 = no trim, 2 = w/ 1st trigger, 3 = w/ last trigger,
                  % 4 = w/ .mat file, 5 = w/ spreadsheet
chanCheck=1;      % 0 or 1. Number of channels lost per subject & channel
IDlength=5;       % ID length in scan name (e.g., IPC_103_rest=5; CF005_rest=4; SNV_rest=1)
compile=1;        % 0 or 1. To compile all data into one .mat
numscans=5;       % Number of Scans (1-n)
zdim=0;           % 0 or 1. Compile Z-score 0=no, 1=yes
ch_reject=2;      % Channel rejection: 1=none, 2=noisy, or 3=noisy & uncertain
rawdir='C:\Users\Mike\Desktop\SIM_nirs';        % Folder path with all the data to be processed

%% Select location of trim times (if applicable)
% Change nothing below here
compInfo={num2str(chanCheck);num2str(IDlength);num2str(compile);num2str(numscans);...
    num2str(zdim);num2str(ch_reject)}; %DO NOT CHANGE

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

%Check if there is data in the rawdir
currdir=dir(strcat(rawdir,filesep,dataprefix,'*'));
if length(currdir)<1
    error(['ERROR: No data files found with ',dataprefix,' prefix']);
end

%Adding folders to directory if not already
addpath(genpath("fNIRSpreProcessing/")); %OR
addpath(genpath("0_prePreProcessing/"));addpath(genpath("1_design_extract/")); 
addpath(genpath("2_trimming/"));addpath(genpath("3_removeNoisy/"));
addpath(genpath("4_filtering/"));addpath(genpath("5_qualityControl/"));
addpath(genpath("6_compileData/"));addpath(genpath("7_postPreProcessing/"));
addpath(genpath("helperScripts/"));

%Will select correct script for study design (i.e., hyperscan? multiscan?)
if hyperscan
    if multiscan
        preprocessHyperMulti;
    else
        preprocessHyperSingle;
    end
else
    if multiscan
        preprocessSoloMulti;
    else
        preprocessSoloSingle;
    end
end

clear