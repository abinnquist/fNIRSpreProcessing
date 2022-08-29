clc; clear
% INSTRUCTIONS: Run the script from the folder that contains the overarching 
% folder:'fNIRSpreProcessing' OR make sure all sub-folders are active 
% NOTE: If using snirf file pwd must contain Homer3 
%
% Before running make sure to change the INPUTS below. 
%
% The script will ask for three things in the following order:
% 1. Pop-up: What is the folder that contains all your NIRS data?
% 2. Pop-up: What machine collected the data (NIRScout, NIRSport or use a .snirf file
% 3. In the command window: Would you like to use a supplemental csv for trimming scans? 
% Enter: 0 for no CSV, 1 for CSV. 
% 4. Optional Pop-up: Select the location of the trim .csv.
% Structure of .csv below (up to 2 scans specified) 
    % Column1 = subject or dyad number
    % column2 = 1st scan where to start trim
    % column3 = 1st scan length
    % column4 = 2nd scan start trim
    % column5 = 2nd scan length
%
% OUTPUTS: three options of preprocessed files, based on quality in a new folder 
    % in rawdir called 'PreProcessedFiles', sorted by subject. 
% To compare different correction pipeline use 'preprocessingVisualize' in
% the 'imagingORcomparisons' folder

%% INPUTS: 
dataprefix='IPC'; % (character) Prefix of folders that contains data. E.g., 'ST' for ST_101, ST_102, etc. 
hyperscan=0;    % 0 or 1. 1 if hyperscanning, 0 if single subject.
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
