function [d,s,t,aux] = trimData(trim, d, s, t, subj, scanNum, numScans, trimTimes, samprate, device, aux)
scanNum=scanNum+1;

% 2) Trim scans: no=0, trim beginnin=1, trim begin & end=2
% 2a) Trim beginning of data based on first trigger
if trim==2 
    ssum = sum(s,2);
    stimmarks = find(ssum);
    if length(stimmarks)>=1
        begintime = stimmarks(1);
        if begintime>0
            d = d(begintime:end,:);
            s = s(begintime:end,:);
            if device==2 && sum(aux(:,1,1)) ~= 0
                aux=aux(begintime:end,:,:);
            elseif device==2 && sum(aux2.data(:,1,1)) ~= 0
                auxbegin = round(aux.samprate*begintime/samprate);
                aux.data = aux.data(auxbegin:end,:,:);
                aux.time = aux.time(auxbegin:end,:,:);
            end

            stimmarks = stimmarks-begintime;
        end
    else %No data trim if no trigger
        error('ERROR: There are no triggers for this scan');
    end
elseif trim==3 || trim==4
    % 2b) Trim nirs scan according to a specified begin time
    begintime=round(table2array(trimTimes(subj,scanNum))*samprate);

    if trim==4
        endScan=begintime + round(table2array(trimTimes(subj,scanNum+numScans))*samprate);
    else
        endScan=length(d);
    end

    d = d(begintime:endScan,:);
    s = s(begintime:endScan,:);
    t = t(begintime:end);

    if begintime>0
        if device==2 && sum(aux(:,1,1)) ~= 0
            aux=aux(begintime:end,:,:);
        elseif device==3 && sum(aux2.data(:,1,1)) ~= 0
            auxbegin = round(aux.samprate*begintime/samprate);
            auxend = round(aux.samprate*endScan/samprate);
            aux.data = aux.data(auxbegin:auxend,:,:);
            aux.time = aux.time(auxbegin:auxend,:,:);
        end
    end
end