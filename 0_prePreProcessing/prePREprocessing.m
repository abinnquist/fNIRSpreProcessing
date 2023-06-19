%% Data Organization check before pre-processing
clc;clear
% folderRename: Will add the dataprefix to any folder in the main data
% folder that does not have it. Leaves folders with the prefix untouched.
%   Note 1: if structure for hyperscanning is incorrect such that all scans
%   are in one folder (no seperate subject folders) then set hyperscan=0
%   when running this script or else it won't iterate through all folders.
%   Note 2: Run this with no other non-data folders, other files are fine

% reOrganize: ONLY use if you hyperscanned and the folder organization is incorrect.   
% Creates new data folder & reorganizes folder structure (options below) 
%   0 = off
%   1 = session>scan>subjects to session>subject>scans
%   2 = session>all scans to session>subject>scans

% countScans: Will count the scans for all subject/dyads to make sure you
% are not missing data. 
%   snames: list of scan names based on the first subject
%   scannames: Matrix of all dyad/subject scan names
%   scanCount: matrix of the number of scans per dyad/subject

% triggerCheck: Will create a trigInfo.mat in the rawdir. Includes all
% triggers for every dyad/subject/scan. This is especially important if you
% plan on trimming the data during pre-processing based on the triggers.
%   %ONLY run this if you have already run countScans and all subjects have the
%   same number of scan folders, even if you are missing data make sure you have
%   an EMPTY folder for that scan. 

% triggerChangeManual: Use if you only need to change a few triggers. For
% example you have multiple triggers and you want to remove all but the
% last one for a few scans.

% triggerDuplicate: Use if you only if you hyperscanned and the trigger is
% only in one subjects scan but you want it in both.
% Suggestion: Run trigCheck again to check if triggers duplicated as planned

%% Scripts to run
addPrefix=1; %0=no, 1=yes (ONLY run once with data)
reOrganize=0; %0=no, 1=yes & flip scans and subjects, 2=yes & seperate subjects
scanCheck=0; %0=no, 1=yes 
trigCheck=0; %0=no, 1=yes (will make new/overwrite trigInfo)
dupTrigs=0; %0=no, 1=yes (only for hyperscanning)

%% INPUTS:  
dataprefix='CC'; %Character prefix of folders that contains data. E.g., 'ST' for ST_101
hyperscan=1; %0=no, 1=yes
multiscan=1; %0=no, 1=yes
IDlength=5; % e.g. 'CC_103_rest' IDlength=3;
numscans=4; %number of scans per subject

%Below inputs only used if re-organizing folders, set to anything if not re-organizing
numHyper = 2;  % However many participants per session (2+)
newdir = 'C:\Users\Mike\Desktop\CC_data'; %Where you want the new organization to go
scanNames={'clip','conv','post','rest'}; %Name of scans (i.e., SD_001_bonding)

%% Make all folders active in your path
addpath(genpath('fNIRSpreProcessing'))

%% Select your data storage location
rawdir=uigetdir('','Choose Data Directory');
currdir=dir(strcat(rawdir,filesep,dataprefix,'*'));
if length(currdir)<1
    error(['ERROR: No data files found with ',dataprefix,' prefix']);
end

%% Pre-preprocessing OR Data organization
%Checks if all folders have the necessary dataprefix. Will add the prefix to
%the existing folder if not present. Leaves folders with the prefix untouched.
if addPrefix
    folderRename(rawdir,dataprefix,hyperscan,multiscan)
end

%ONLY for hyperscanning with multiple scans, creates new folder &  
%reorganizes folder structure from either: 
% 1 = session>scan>subjects to session>subject>scans
% 2 = session>all scans to session>subject>scans
if reOrganize
    pathName = rawdir; %where ever the original data is stored
    reOrganizeFolders(reOrganize,scanNames,dataprefix,numHyper,pathName,newdir); %uncomment ONLY if needed
    rawdir=newdir;
    currdir=dir(strcat(rawdir,filesep,dataprefix,'*'));
    if length(currdir)<1
        error(['ERROR: No data files found with ',dataprefix,' prefix']);
    end
end

%Check for the number of scans for each dyad/subject & get scan names.
if scanCheck
    [scanCount, scannames, snames] = countScans(currdir, dataprefix, hyperscan, numscans, IDlength);
end

%To run the check for only on or two scans use triggerCheckManual.m
if trigCheck
    trigInfo = triggerCheck(rawdir,dataprefix,IDlength,hyperscan,numscans);
end

if dupTrigs
    triggerDuplicate
end
