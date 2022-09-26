% [dout, dlocal] = hmrSSR(din, SD, s, t, blen, offset, task, thres)
%
%
% UI NAME:
% SSR_Homer2
%
%
% DESCRIPTION:
% This applies short-separation regression as described in:
% (1) Saager and Berger 2005 https://www.ncbi.nlm.nih.gov/pubmed/16211814
% (2) Scholkmann et al 2014 https://www.ncbi.nlm.nih.gov/pubmed/24622337
%
% Please note that the input provided should be OPTICAL DENSITY (OD).
%
%
% INPUT:
% din: optical density data (#data points x #channels)
% SD: SD structure (provided within the *.nirs file)
% s: stimulation vector (#data points x #conditions)=1 at onset otherwise=0
% t: time vector corresponding with y and s
% blen: baseline in seconds prior to stimulus onset (e.g. 5)
% offset: time to consider following stimulus onset (e.g. 30)
% task: whether to apply only to response blocks (1) or whole series (0)
% thres: threshold of inter-optode distance 'mm' to automatically identify
% short-channels (e.g. 10)
%
%
% OUTPUT:
% dout: optical density data after applying SSR correction
% dlocal: optical density data with superficial contribution
%

function [dout, dlocal] = hmrSSR(din, SD, s, t, blen, offset, task, thres)

% Jan 2019: check that t and din have both "# of samples" as their first dimension
if size(t, 1)~= size(din, 1)
    t=t';
end

% baseline in seconds prior stimulus onset
if nargin < 5
    blen = 5;
end

% duration of task window following stimulus onset
if nargin < 6
    offset = 30;
end

% flag to run regression only on response period
% if set to '0', consider whole time series instead
if nargin < 7
    task = 1;
end

% inter-optode distance threshold
% to define a short-distance channel
if nargin < 8
    thres = 10; % set to 10 mm
end

% adjust threshold according to spatial unit
if isfield(SD,'SpatialUnit') && strcmpi(SD.SpatialUnit,'cm')
    thres = thres / 10; %convert to 'cm'
end

% initialize output variables
dout = din;
dlocal = din;

wls = max(SD.MeasList(:,4));

% retrieve source-detector pairs
link = SD.MeasList(SD.MeasList(:,4)==1,1:2);
% get number of conditions
conds = size(s,2);
% get sampling frequency
Fs = 1/(t(2)-t(1));

% find short-distance channels based on inter-optode distance
idxS = []; idxL = [];
longpos = []; shortpos = [];
for i=1:length(link)
    srcpos = SD.SrcPos(link(i,1),:);
    detpos = SD.DetPos(link(i,2),:);
    dist = norm(srcpos-detpos);
    chnpos = (srcpos+detpos)/2;
    if dist < thres
        % store index of short-channel
        idxS = [idxS i];
        % store its 3D position as well
        shortpos = [shortpos; chnpos];
    else
        idxL = [idxL i];
        longpos = [longpos; chnpos];
    end
end

% iterate over long-channels
for j=1:length(idxL)
    
    % find the index of the closest short-channel
    [~,i] = min(vecnorm(longpos(j,:) - shortpos,2,2));
    
    % iterate over wavelengths
    for wl=1:wls
        
        longchn = find(SD.MeasList(:,1) == link(idxL(j),1) & ...
                       SD.MeasList(:,2) == link(idxL(j),2) & ...
                       SD.MeasList(:,4) == wl);
                   
        shortchn = find(SD.MeasList(:,1) == link(idxS(i),1) & ...
                        SD.MeasList(:,2) == link(idxS(i),2) & ...
                        SD.MeasList(:,4) == wl);
         
        if task && conds > 0
            
            % iterate over conditions
            for c=1:conds
                
                % find onsets of condition 'c'
                onsets = find(s(:,c)~=0);
                
                for o=1:length(onsets)
                    
                    % get window limits
                    wmin = onsets(o) - round(Fs*blen);
                    wmax = onsets(o) + round(Fs*offset);
                    
                    % check upper and lower limits
                    wmin = max(wmin,1); %adjust for the case wmin < 1
                    wmax = min(wmax, size(t,1)); %for wmax > length(data) 
                    
                    % get long-channel data for this window
                    AL = din(wmin:wmax,longchn);
                    % and corresponding short-channel data
                    AS = din(wmin:wmax,shortchn);
                    
                    alfa = dot(AS,AL)/dot(AS,AS);
                    
                    % corrected data
                    AC = AL - alfa.*AS;
                    
                    % store corrected channel in dout
                    dout(wmin:wmax,longchn) = AC;
                    % and the superficial portion in dlocal
                    dlocal(wmin:wmax,longchn) = alfa.*AS;
                    
                end
                
            end
            
            % this rather applies the correction
            % for the whole time series at once
        else
            
            wmin = 1; wmax = size(t,1);
            
            AL = din(wmin:wmax,longchn);
            AS = din(wmin:wmax,shortchn);
            
            alfa = dot(AS,AL)/dot(AS,AS);
            
            AC = AL - alfa.*AS;
            
            dout(wmin:wmax,longchn) = AC;
            dlocal(wmin:wmax,longchn) = alfa.*AS;
            
        end
        
    end
            
end 

end