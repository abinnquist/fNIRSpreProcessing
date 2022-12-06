clc; clear
% INSTRUCTIONS: Run the script from the folder that contains the overarching 
% folder:'fNIRSpreProcessing' OR make sure all sub-folders are active 
% NOTE 1: If using snirf file pwd must contain Homer3 
% NOTE 2: Wavelet correct will take the longest
%
% If you prefer to manually input study Information uncomment the first four 
% lines under INPUT or else the script will use a GUI pop-up to ask. 
%
% The script has 3 pop-ups before processing and 1 after in the below order:
% 1. Pop-up (4 inputs): dataprefix for all folders of interest, if hyperscans, if
% multiple scans per subject/dyad, how many if any auxiliaries
% 2. Pop-up (select one): What type of motion correction do you want to use?
% 3. Pop-up: Where is the folder that contains all your NIRS data?
% 4. Pop-up: What machine collected the data: NIRScout, NIRSport or a .snirf file
% 5. Pop-up: What type of trimming of the data you want to do, if any? 
% Structure of .csv below, handles 1-n scans per subject: 
    % Column_1 = subject or dyad number
    % column_2 = 1st scan where to start trim
    % column_3 = 1st scan length
    % column_4 = 2nd scan start trim
    % column_5 = 2nd scan length
    % column_n*2 = nth scan start trim
    % column_n*2+1 = nth scan length
% 6. Pop-up: If you want to compile the data into one .mat file. 
% Note: You MUST have the same number of scans for every subject.
    % Compile data: 0=No, 1=Yes
    % Number of scans: any number 1 to n. n=number of scans per subject
    % Z-scored: 0=oxy/deoxy, 1=z_oxy/z_deoxy
    % Channel rejection: 1=none, 2=noisy only, 3=noisy and uncertain (reccommended)

% OUTPUTS: 
% In 'PreProcessedFiles' created by the script:
    % 4 .csv's (2 for each removal) with # of subjects and # of channels
    % 3 .mat files of the data for choice  of channel removal, exp. below
        % '_preprocessed'= no removal
        % '_preprocessed_nonoisy'= oversaturated channels removed
        % '_preprocessed_nouncertain'= Unreliable channels removed (step 5)
    % A 'channel_mnicoords.csv' if applicable
    % Compile chosen: a 'dataprefix_compile.mat' will be created with
    % all subjects & scan compiled into one .mat structure
  
% To compare different correction pipeline use 'preprocessingVisualize' in
% the 'helperScripts' folder

%% INPUTS: 
% dataprefix='IPC'; % (character) Prefix of folders for all data. E.g., 'ST' for ST_101, ST_102, etc. 
% hyperscan=1;      % 0 or 1. 1 if hyperscanning, 0 if single subject.
% multiscan=1;      % 0 or 1. 1 if multiple scans per person, 0 if single scan
% numaux=2;         % Number of aux inputs. Currently ONLY works for accelerometers.
%                   % Other auxiliary inputs: eeg, pulse, etc.

definput = {' ','0','0','0'};
studyInfo = inputdlg({'Dataprefix  for all study folders','Hyperscan? (0=no, 1=yes)','Multiscan? (0=no, 1=yes)','Number of auxiliary? (0-n)'},...
              'Study Info', [1 35], definput,'on');     
dataprefix=char(studyInfo(1));
hyperscan=str2num(cell2mat(studyInfo(2)));
multiscan=str2num(cell2mat(studyInfo(3)));
numaux=str2num(cell2mat(studyInfo(4)));

mcorrTypes = {'Baseline volatility','PCFilter (MUST have mapping toolbox)',...
    'PCA by channel','CBSI','Wavelet (uses db2)','Short channel regression','None'};
[motionCorr,~] = listdlg('PromptString', 'What kind of motion correction do you want to do?',...
'SelectionMode', 'single', 'ListSize',[250,150], 'ListString', mcorrTypes);

%% To make all folders active in your path
addpath(genpath('fNIRSpreProcessing'))
preprocessingfNIRS(dataprefix, hyperscan, multiscan, motionCorr, numaux)

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
