
%If using snirf file pwd must contain Homer3 
%required inpaint_nans, homer2 scripts for non-snirf processing

function preprocessingfNIRS(dataprefix, hyperscan, multiscan, motionCorr, numaux)
% To run script without using command line function OR for more information  
% see 'runNIRSPreproc' script in the main folder

%inputs: 
%       dataprefix: string. Prefix of every folder name that should be considered a
%       data folder. E.g., 'ST' for ST_101, ST_102, etc.  
%       hyperscan: 0 or 1. 1 if hyperscanning, 0 if single subject.
%       multiscan: 0 or 1. 1 if multiple scans per person, 0 if single
%       scan.
%       motionCorr: 0 = no motion correction (not reccommended)
%                   1 = baseline volatility
%                   2 = PCFilter (requires mapping toolbox)
%                   3 = baseline volatility & CBSI
%                   4 = CBSI only
%       numaux: Number of aux inputs. Currently ONLY works for accelerometers.
%               Other auxiliary inputs: eeg, pulse, etc.
%
%outputs: three options of preprocessed files in a new folder in rawdir called
%           'PreProcessedFiles', sorted by subject. 

%Adding folders to directory if not already
addpath(genpath("0_designOptions/")); addpath(genpath("1_extractFuncs/")); 
addpath(genpath("3_removeNoisy/")); addpath(genpath("4_filtering/"));
addpath(genpath("5_qualityControl/")); addpath(genpath("6_compileData/"));

%What device was used, NIRScout, NIRSport, or if you have SNIRF file
supported_devices = {'NIRx-NirScout or NirSport1','NIRx-NirSport2 or .nirs file','.Snirf file (must have Homer3)'};
[device,~] = listdlg('PromptString', 'Select acquisition device:',...
    'SelectionMode', 'single', 'ListString', supported_devices);

%Directory selection
rawdir=uigetdir('','Choose Data Directory');
currdir=dir(strcat(rawdir,filesep,dataprefix,'*'));
if length(currdir)<1
    error(['ERROR: No data files found with ',dataprefix,' prefix']);
end

%If you want trim the data at all before preproc and if you want to use a csv to trim the data 
trimTypes = {'No trim','Beginning with 1st trigger','Beginning with last trigger', 'Beginning with .csv','Begin & end with .csv'};
[trim,~] = listdlg('PromptString', 'Do you want to trim scans?',...
    'SelectionMode', 'single', 'ListString', trimTypes);
if trim == 4 || trim == 5
    [trimTs, trimPath] = uigetfile('*.csv','Choose trim time CSV');
    trimTimes = readtable(strcat(trimPath,trimTs));
    clear trimPath trimTs trimTypes
else
    trimTimes=[];
end

%Will select correct script for study design (i.e., hyperscan? multiscan?)
if hyperscan
    if multiscan
        preprocessHyperMulti(dataprefix, currdir, rawdir, motionCorr, device, numaux, trim, trimTimes);
    else
        preprocessHyperSingle(dataprefix, currdir, rawdir, motionCorr, device, numaux, trim, trimTimes);
    end
else
    if multiscan
        preprocessSoloMulti(dataprefix, currdir, rawdir, motionCorr, device, numaux, trim, trimTimes);
    else
        preprocessSoloSingle(dataprefix, currdir, rawdir, motionCorr, device, numaux, trim, trimTimes);
    end
end

end
