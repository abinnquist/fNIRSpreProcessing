% NIRx Medical Technologies
% For any questions/more information, contact: support@nirx.net

function [dout, dlocal] = ntbxSSR(din, blen, offset, task, thres)
% DESCRIPTION:
% This applies short-separation regression as described in:
% (1) Saager and Berger 2005 https://www.ncbi.nlm.nih.gov/pubmed/16211814
% (2) Scholkmann et al 2014 https://www.ncbi.nlm.nih.gov/pubmed/24622337
%
% Please note that the input provided should be OPTICAL DENSITY (OD).
%
%
% INPUT:
% din: analyzir Data class with optical density (#data points x #channels)
% blen: baseline in seconds prior to stimulus onset (e.g. 5)
% offset: time to consider following stimulus onset (e.g. 30)
% task: whether to apply only to response blocks (1) or whole series (0)
% thres: threshold of inter-optode distance 'mm' to automatically identify
% short-channels (e.g. 10)
%
%
% OUTPUT:
% dout: Data class with optical density after applying SSR correction
% dlocal: Data class with optical density data of superficial contribution

% baseline in seconds prior stimulus onset
if nargin < 2
    blen = 5;
end

% rest period after response duration and prior next trial
if nargin < 3
    offset = 10;
end

% flag to run regression only on response period
% if set to '0', consider whole time series instead
if nargin < 4
    task = 1;
end

% inter-optode distance threshold
% to define a short-distance channel
if nargin < 5
    thres = 10; % set to 10 mm
end

% get number of subjects
subjs = length(din);

% initialize output variables
dout = din;
dlocal = din;

% iterate over all subjects
for n=1:subjs

    % get channels info
    link = din(n).probe.link;
    % number of conditions
    conds = length(din(n).stimulus.keys);
    % retrieve sampling frequency
    Fs = din(n).Fs;
    
    % check if short separation info is available in link table
    if ismember('ShortSeperation', link.Properties.VariableNames)
        idxS = find(link.ShortSeperation==1);
        idxL = find(link.ShortSeperation==0);
    % otherwise, use inter-optode distance information
    else
        idxS = find(din(n).probe.distances<=thres);
        idxL = find(din(n).probe.distances>thres);
        
        % store short-distance information in 'dout'
        dout(n).probe.link.ShortSeperation(idxS) = 1;
        dout(n).probe.link.ShortSeperation(idxL) = 0;
    end
    
    pos = [];
    % calculate 3D location of each channel
    for chn=1:size(link,1)
        src = link.source(chn);
        det = link.detector(chn);
        chnpos = (din(n).probe.srcPos(src,:) + din(n).probe.detPos(det,:))/2;
        pos = [pos; chnpos];
    end
    % retrieve positions of short- and long-channels
    shortpos = pos(idxS,:);
    longpos = pos(idxL,:);
    
    % iterate over long-channels
    for j=1:length(idxL)
    
        % get subset of shortpos related to current wavelength
        sub_wl = find(link.type(idxS)==link.type(idxL(j)));
        
        % find the index of the closest short-channel
        [~,i] = min(vecnorm(longpos(j,:) - shortpos(sub_wl,:),2,2));
        
        % correct short-channel index (due to wavelength subset)
        i = sub_wl(i);

        % if apply for each trial and trigger markers available
        if task && conds > 0
            
            % iterate over conditions (markers)
            for c=1:conds
                
                % get number of trials for current condition
                trials = length(din(n).stimulus.values{c}.onset);
                
                % iterate over trials
                for t=1:trials
                    
                    % find window limits
                    ini = din(n).stimulus.values{c}.onset(t)- din(n).time(1);
                    fim = ini + din(n).stimulus.values{c}.dur(t) + offset;
                    
                    % adjust window begin with baseline
                    % and convert from 's' to data point
                    wmin = round(Fs*(ini-blen));
                    wmin = max(wmin,1); %adjust for the case wmin < 1
                    
                    % convert from 's' to data point
                    % compare with end of time series
                    wmax = round(Fs*fim);
                    wmax = min(wmax, length(din(n).data)); %for wmax > length(data)
                    
                    % retrieve long- and short-channel data
                    AL = din(n).data(wmin:wmax,idxL(j));
                    AS = din(n).data(wmin:wmax,idxS(i));
                    
                    % calculate ratio for short-data
                    alfa = dot(AS,AL)/dot(AS,AS);
                    
                    % corrected data
                    AC = AL - alfa.*AS;
                    
                    % store corrected data
                    dout(n).data(wmin:wmax,idxL(j)) = AC;
                    % store superficial data
                    dlocal(n).data(wmin:wmax,idxL(j)) = alfa.*AS;
                    
                end
                
            end
         
        % this rather applies the correction
        % for the whole time series at once    
        else
            
            wmin = 1; wmax = length(din(n).data);
            
            AL = din(n).data(wmin:wmax,idxL(j));
            AS = din(n).data(wmin:wmax,idxS(i));
            
            alfa = dot(AS,AL)/dot(AS,AS);
            
            AC = AL - alfa.*AS;
            
            dout(n).data(wmin:wmax,idxL(j)) = AC;
            dlocal(n).data(wmin:wmax,idxL(j)) = alfa.*AS;
            
        end
        
    end

end
            
end 