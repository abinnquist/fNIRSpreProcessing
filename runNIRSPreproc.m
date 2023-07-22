clc; clear
% INSTRUCTIONS: Run the script from the folder that contains the overarching 
% folder 'fNIRSpreProcessing' OR make sure all sub-folders are active. 
%
% NOTE 1: If using snirf file pwd must contain Homer3 
% NOTE 2: Wavelet correct will take the longest
% NOTE 3: If you prefer to manually input study info uncomment below the section
%         labelled "Start manual input here (OPTIONAL)" or else the script 
%         will use a GUI pop-up to ask for inputs.
%
% INPUTS:
% The script has 6 pop-ups or 8 inputs before pre processing in the below order:
% 1. Pop-up (4 inputs): dataprefix for all folders of interest, if hyperscanned, if
% multiple scans per subject/dyad/triad/quad, if/how many auxiliaries
% 2. Pop-up (select one): What type of motion correction do you want to use?
% 3. Pop-up: Where is the folder that contains all your NIRS data?
% 4. Pop-up: What machine collected the data: NIRScout, NIRSport or a .snirf file
% 5. Pop-up: If you want to compile the preprocessed data into one .mat file. 
% Note: You MUST have the same number of scan folders for every subject.
    % Quality check: 0=No, 1=Yes
    % ID length: Number of charaters after the dataprefix & before the scan name (e.g. IPC_101_rest = 5 or IPC101rest = 3)
    % Compile data: 0=No, 1=Yes
    % Number of scans: any number 1 to n. n=number of scans per subject
    % Z-scored: 0=oxy/deoxy, 1=z_oxy/z_deoxy
    % Channel rejection: 1=none, 2=noisy only, 3=noisy and uncertain (reccommended)
% 6. Pop-up: What type of data trimming do you want to do, if any? 
    % If hyperscan
        % If .mat: should be in 3D format (i.e., dyad x scan x sub)
        % If spreadsheet: should be in 2D format (i.e., dyad x scanSub1,scanSub2,...scanSubn)
        % the script will convert it to a .mat for you
    % If single subject
        % If .mat or spreadsheet: should be in 2D format (i.e., sub x scan)

% OUTPUTS: 
% In 'PreProcessedFiles' created by the script:
    % Three .mat files of the data for choice  of channel removal, exp. below
        % '_preprocessed'= no removal
        % '_preprocessed_nonoisy'= oversaturated channels removed
        % '_preprocessed_nouncertain'= Unreliable channels removed (step 5)
    % A 'channel_mnicoords.csv' if applicable
    % Compile chosen: a 'dataprefix_compile.mat' will be created with
    % all subjects & scan compiled into one .mat structure and lost
    % channels (if quality check was chosen)
    % If quality check: 2 .csv's with # of subjects and # of channels
  
% To compare different correction pipeline use 'preprocessingVisualize' in
% the 'helperScripts' folder

%% INPUTS: 
% To make all folders active in your path
%Adding folders to directory if not already
addpath(genpath("fNIRSpreProcessing/")); %OR depending on you cd
addpath(genpath("0_prePreProcessing/"));addpath(genpath("1_design_extract/")); 
addpath(genpath("2_trimming/"));addpath(genpath("3_removeNoisy/"));
addpath(genpath("4_filtering/"));addpath(genpath("5_qualityControl/"));
addpath(genpath("6_compileData/"));addpath(genpath("7_postPreProcessing/"));
addpath(genpath("helperScripts/"));

%Study specifics: dataprefix, hyper, multi, etc.
definput = {' ','0','0','0'};
studyInfo = inputdlg({'Dataprefix for all study folders','Hyperscan? (0=no, 1=yes)','Multiscan? (0=no, 1=yes)','Number of auxiliary? (0-n)'},...
              'Study Info', [1 35], definput,'on');     
dataprefix=char(studyInfo(1));
hyperscan=str2num(cell2mat(studyInfo(2)));
multiscan=str2num(cell2mat(studyInfo(3)));
numaux=str2num(cell2mat(studyInfo(4)));

%Type of motion correction
mcorrTypes = {'Baseline volatility','PCFilter (MUST have mapping toolbox)',...
    'PCA by channel','CBSI','Wavelet (uses db2)','Short channel regression','None'};
[motionCorr,~] = listdlg('PromptString', 'What kind of motion correction do you want to do?',...
'SelectionMode', 'single', 'ListSize',[250,150], 'ListString', mcorrTypes);

%What device was used, NIRScout, NIRSport, or if you have SNIRF file
supported_devices = {'NIRx-NirScout or NirSport1','NIRx-NirSport2 or .nirs file','.Snirf file (must have Homer3)'};
[device,~] = listdlg('PromptString', 'Select acquisition device:',...
    'SelectionMode', 'single', 'ListString', supported_devices);

%Compile data info
compInfo = inputdlg({'Run Quality Check? (0=no, 1=yes)','ID length in scan name (e.g., IPC_103_rest=5; CF005_rest=4; SNV_rest=1)?',...
    'Compile  data? (0=no, 1=yes)','Number of Scans (1-n)','Compile Z-score? (0=no, 1=yes)',...
    'Channel rejection? (1=none, 2=noisy, or 3=noisy & uncertain)'},...
              'Compile data info', [1 75]); 

%Type of data trim, if wanted
trimTypes = {'No trim','Beginning with 1st trigger','Beginning with last trigger',...
    'Beginning with .mat','Beginning with a spreadsheet'};
[trim,~] = listdlg('PromptString', 'Do you want to trim scans?',...
    'SelectionMode', 'single', 'ListString', trimTypes);

%Directory selection
rawdir=uigetdir('','Choose Data Directory');

%select location of trim times (if applicable)
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
%% DEBUGGING TIPS:
%Note that this function is, funcitonal, but not 100% optimized  
% 1. I would check is if you are in the correct location too
% add all folders from 'fnirsprePreprocessing' to you path (i.e., wherever the
% folder is located on your computer).
% 2. If you get an error specific to one subject (i.e., if ran a couple
% than errored out) check to see if something is missing for the
% subject/scan. Often a scan is missing or the probe montage is incorrect.
% 3. If you can't figure it out and you are going absolutely mad, email me
% at abinnquist@ucla.edu with a screenshot of the error or a descritption
% of what is not working and I'll do my best to help ya out.
