function [d,s,t,aux] = trimData(trim, d, s, t, subj, scanNum, numScans, trimTimes, samprate, device, aux, numaux)

% 2) Trim scans: no=0, trim beginning=1, trim begin & end=2
% 2a) Trim beginning based on first trigger (trim=2) or the last (trim==3)
if trim==2 || trim==3
    ssum = sum(s,2);
    stimmarks = find(ssum);
    if length(stimmarks)>=1
        if trim==2
            begintime = stimmarks(1);
        else
            begintime = stimmarks(end);
        end
    else
        begintime=0;
        %error('ERROR: There are no triggers for this scan');
    end
    if begintime>0
        d = d(begintime:end,:);
        s = s(begintime:end,:);
        t = t(begintime:end); %Trim our frames to the same length as data
        t = t-t(1,1); %Reset the first frame to be zero
        if device==2 && numaux > 0
            aux=aux(begintime:end,:,:);
        elseif device==3 && numaux > 0
            auxbegin = round(aux.samprate*begintime/samprate);
            aux.data = aux.data(auxbegin:end,:,:);
            aux.time = aux.time(auxbegin:end,:,:);
        end
        stimmarks = stimmarks-begintime;
    end
elseif trim==4 || trim==5
    % 2b) Trim nirs scan according to a specified begin time
    begintime=round(table2array(trimTimes(subj,scanNum))*samprate);

    if trim==5
        endScan=begintime + round(table2array(trimTimes(subj,scanNum+numScans))*samprate);
    else
        endScan=length(d);
    end

    d = d(begintime:endScan,:);
    s = s(begintime:endScan,:);
    t = t(begintime:end); %Trim our frames to the same length as data
    t = t-t(1,1); %Reset the first frame to be zero

    if begintime>0
        if device==2 && numaux > 0
            aux=aux(begintime:end,:,:);
        elseif device==3 && numaux > 0
            auxbegin = round(aux.samprate*begintime/samprate);
            auxend = round(aux.samprate*endScan/samprate);
            aux.data = aux.data(auxbegin:auxend,:,:);
            aux.time = aux.time(auxbegin:auxend,:,:);
        end
    end
end