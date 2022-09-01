clc; clear
% INSTRUCTIONS: Run the script from the folder that contains the overarching 
% folder:'fNIRSpreProcessing' OR make sure all sub-folders are active 
% NOTE: If using snirf file pwd must contain Homer3 
%
% Before running make sure to change the INPUTS below. 
%
% The script has 3 pop-ups before processing and 1 after in the below order:
% 1. Pop-up: What is the folder that contains all your NIRS data?
% 2. Pop-up: What machine collected the data (NIRScout, NIRSport or use a .snirf file
% 3. Pop-up: Would you like to use a supplemental csv for trimming scans? 
% Structure of .csv below (up to 2 scans specified) 
    % Column1 = subject or dyad number
    % column2 = 1st scan where to start trim
    % column3 = 1st scan length
    % column4 = 2nd scan start trim
    % column5 = 2nd scan length

% 4. Pop-up: If you want to compile the data into one .mat file. 
% Note: You MUST have the same number of scans for every subject.
    % Compile data: 0=No, 1=Yes
    % Number of scans: any number 1 to n. Number of scan per subject=n
    % Z-scored: 0=oxy/deoxy, 1=z_oxy/z_deoxy
    % Channel rejection: 1=none, 2=noisy only, 3=noisy and uncertain (reccommended)

% OUTPUTS: 
    % In 'PreProcessedFiles' 4 .csv's (2 for each removal) with # of subjects 
    % and # of channels were of good quality.
    % In 'PreProcessedFiles' each scan will have 3 options of preprocessed 
    % files, based on quality. The MNI coordinates as a csv (if applicable): 
        % '_preprocessed'=no removal
        % '_preprocessed_nonoisy'= oversaturated channels removed
        % '_preprocessed_nouncertain'= Unreliable channels removed (step 5)
        % 'channel_mnicoords.csv' if applicable
    % If compile was chosen a 'dataprefix_compile.mat' will be created with
    % all subjects & scan compiled into one .mat structure
% To compare different correction pipeline use 'preprocessingVisualize' in
% the 'helperScripts' folder

%% INPUTS: 
dataprefix='IPC'; % (character) Prefix of folders that contains data. E.g., 'ST' for ST_101, ST_102, etc. 
hyperscan=1;    % 0 or 1. 1 if hyperscanning, 0 if single subject.
multiscan=1;    % 0 or 1. 1 if multiple scans per person, 0 if single scan
motionCorr=3;   % 0 = no motion correction (not reccommended unless comparing)
                % 1 = baseline volatility
                % 2 = PCFilter (requires mapping toolbox)
                % 3 = baseline volatility & CBSI
                % 4 = CBSI only
numaux=2;       % Number of aux inputs. Currently ONLY works for accelerometers.
                % Other auxiliary inputs: eeg, pulse, etc.

%% To make all folders active in your path
addpath(genpath('fNIRSpreProcessing'))
preprocessingfNIRS(dataprefix, hyperscan, multiscan, motionCorr, numaux)

%% DEBUGGING TIPS:
%Note that this function is, funcitonal, but not 100% optimized for
%everything that could go wrong. 
% 1. I would check is if you are in the correct location too
% add all folders from 'fnirsPreprocessing' to you path (i.e., wherever the
% folder is located on your computer).
% 2. If you get an "Index exceeds matrix dimensions" error in
%   hmrMotionArtifact for a subject that's not the first file:
%       Check the SD Mask structure in the .hdr of that subject to see if 
%       it matches the channel structure of the selected probeInfo file. If
%       the wrong probeInfo file was chosen, this will throw the error.
%       also happens if the wrong montage was selected in recording, Simply copy-paste
%       the correct SD Mask and ChannelDistance list into the .hdr file from a
%       subject's .hdr file that had the correct montage.+
