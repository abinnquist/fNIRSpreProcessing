% function dodWavelet = hmrMotionCorrectWavelet(dod,SD,iqr)
%
% UI NAME:
% Wavelet_Motion_Correction
%
% Perform a wavelet transformation of the dod data and computes the
% distribution of the wavelet coefficients. It sets the coefficient
% exceeding iqr times the interquartile range to zero, because these are probably due
% to motion artifacts. set iqr<0 to skip this function.
% 
% The algorithm follows in part the procedure described by
% Molavi et al.,Physiol Meas, 33, 259-270 (2012).
%
% INPUTS:
% dod -  delta_OD 
% SD -   SD structure
% iqr -  parameter used to compute the statistics (iqr = 1.5 is 1.5 times the
%        interquartile range and is usually used to detect outliers). 
%        Increasing it, it will delete fewer coefficients.
%        If iqr<0 then this function is skipped. 
% 
%
% OUTPUTS:
% dodWavelet - dod after wavelet motion correction, same
%              size as dod (Channels that are not in the active ml remain unchanged)
%
% LOG:
% Script by Behnam Molavi bmolavi@ece.ubc.ca adapted for Homer2 by RJC
% modified 10/17/2012 by S. Brigadoi
%


function [dodWavelet] = hmrMotionCorrectWavelet(dod,SD,iqr,turnon)

if exist('turnon')
   if turnon==0
       dodWavelet = dod;
   return;
   end
end


if iqr<0
    dodWavelet = dod;
    return;
end

mlAct = SD.MeasListAct; % prune bad channels

lstAct = find(mlAct==1);
dodWavelet = dod;

SignalLength = size(dod,1); % #time points of original signal
N = ceil(log2(SignalLength)); % #of levels for the wavelet decomposition
DataPadded = zeros (2^N,1); % data length should be power of 2  

p = ffpath2('db2.mat');
if p>1
    %fprintf('Loading %s\n', [p, '/db2.mat']);
    load([p, '/db2.mat']);  % Load a wavelet (db2 in this case)
else
    error(['You do not have a db2.mat found on your computer.  Check if db2.mat' ...
        ' is in the fNIRSpreProcessing path (stored in motionCorrs/Wavelet folder)'])
end
qmfilter = qmf(db2,4); % Quadrature mirror filter used for analysis
L = 4;  % Lowest wavelet scale used in the analysis

for ii = 1:length(lstAct)
    
    idx_ch = lstAct(ii);

    DataPadded(1:SignalLength) = dod(:,idx_ch);  % zeros pad data to have length of power of 2   
    DataPadded(SignalLength+1:end) = 0;  
    
    DCVal = mean(DataPadded);         
    DataPadded = DataPadded-DCVal;    % removing mean value
    DataLength = size(DataPadded,1);  
   
    [yn NormCoef]=NormalizationNoise(DataPadded',qmfilter);
    
    StatWT = WT_inv(yn,L,N,'db2'); % discrete wavelet transform shift invariant

    [ARSignal wcTI] = WaveletAnalysis(StatWT,L,'db2',iqr,SignalLength);  % Apply artifact removal
       
    ARSignal = ARSignal/NormCoef+DCVal;           

    dodWavelet(:,idx_ch) = ARSignal(1:length(dod));

end




% ---------------------------------------------------------------------

function pth = ffpath2(fname)
%   FFPATH    Find file path
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The function browses very fast current directory and directories known in 
% 'matlabpath' and the system variable 'path'. It searches for the file,
% name of which is in the input argument 'fname'. If a directory is found, 
% the output argument pth is filled by path to the file name from the input
% argument, otherwise pth is empty.
% File names should have their extensions, but MATLAB m-files.
% 
% Arguments:
%   fname   file name 
%   pth     path to the fname
%
% Examples:
%   pth = ffpath('gswin32c.exe')
%   pth =
%   c:\Program Files\gs\gs8.60\bin\
%
%   pth = ffpath('hgrc')
%   pth =
%   C:\PROGRA~1\MATLAB\R2006b\toolbox\local

% Miroslav Balda
% miroslav AT balda DOT cz
% 2008-12-15    v 0.1   only for system variable 'path'
% 2008-12-20    v 1.0   for both 'path' and 'matlabpath'

% Brought here by Jay Dubb. In order to keep hmrMotionCorrectWavelet
% self-contained, copied ffpath to here. 

if nargin<1
    error('The function requires one input argument (file name)')
end
pth = pwd;
if exist([pth '/' fname],'file')
    return
end % fname found in current dir

tp = matlabpath;
t  = 0;
if isunix() | ismac()
    I = [t, findstr(tp,':'), length(tp)+1];
elseif ispc()
    I = [t, findstr(tp,';'), length(tp)+1];
end    
for k = 1:length(I)-1               %   search in path's directories
    pth = tp(I(k)+1:I(k+1)-1);
    % fprintf('%s\n', [pth '/' fname]);
    if exist([pth '/' fname],'file')
        return;
    end
end
t = 5;
pth = '';

