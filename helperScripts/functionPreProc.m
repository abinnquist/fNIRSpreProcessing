
%If using snirf file pwd must contain Homer3 
%required inpaint_nans, homer2 scripts for non-snirf processing

function functionPreProc(dataprefix, hyperscan, multiscan, motionCorr, device, numaux)
% To run script without using command line function OR for more information  
% see 'runNIRSPreproc' script in the main folder

%inputs: 
%       dataprefix: string. Prefix of every folder name that should be considered a
%       data folder. E.g., 'ST' for ST_101, ST_102, etc.  
%       hyperscan: 0 or 1. 1 if hyperscanning, 0 if single subject.
%       multiscan: 0 or 1. 1 if multiple scans per person, 0 if single
%       scan.
%       motionCorr: 1 = baseline volatility
%                   2 = PCFilter (requires mapping toolbox)
%                   3 = PCA by channel
%                   4 = CBSI only
%                   5 = Wavelet
%                   6 = Short channel regression
%                   7 = no motion correction (not reccommended)                
%       numaux: Number of aux inputs. Currently ONLY works for accelerometers.
%               Other auxiliary inputs: eeg, pulse, etc.
%
%outputs: three options of preprocessed files in a new folder in rawdir called
%           'PreProcessedFiles', sorted by subject. 

%Adding folders to directory if not already
addpath(genpath("fNIRSpreProcessing/")); %OR
addpath(genpath("0_prePreProcessing/"));addpath(genpath("1_design_extract/")); 
addpath(genpath("2_trimming/"));addpath(genpath("3_removeNoisy/"));
addpath(genpath("4_filtering/"));addpath(genpath("5_qualityControl/"));
addpath(genpath("6_compileData/"));addpath(genpath("7_postPreProcessing/"));
addpath(genpath("helperScripts/"));

%Directory selection
rawdir=uigetdir('','Choose Data Directory');
currdir=dir(strcat(rawdir,filesep,dataprefix,'*'));
if length(currdir)<1
    error(['ERROR: No data files found with ',dataprefix,' prefix']);
end

%Compile data info
compInfo = inputdlg({'Run Channel loss Check? (0=no, 1=yes)','ID length in scan name (e.g., IPC_103_rest=5; CF005_rest=4; SNV_rest=1)?',...
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

end
