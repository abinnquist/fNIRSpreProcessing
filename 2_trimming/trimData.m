function [d,s,t,aux] = trimData(trim, d, s, t, trimTimes, samprate, device, aux, numaux, sInfo)
%Trim times MUST be in frames
% 2a) Trim beginning based on first trigger (trim=2) or the last (trim==3)
if trim==2 || trim==3
    ssum = sum(s,2);
    stimmarks = find(ssum);
    if length(stimmarks)>=1
        if trim==2 
            begintime = stimmarks(1); %To trim based on first trigger
        else 
            begintime = stimmarks(end); %To trim based on last trigger
        end
    else
        begintime=0; %If no trigger, no trim
    end
    if begintime>0
        d = d(begintime:end,:);
        s = s(begintime:end,:);
        t = t(begintime:end); %Trim frames to the same length as data
        t = t-t(1,1); %Reset the first frame to be zero
        if device==2 && numaux > 0
            aux=aux(begintime:end,:);
        elseif device==3 && numaux > 0
            auxbegin = round(aux.samprate*begintime/samprate);
            aux.data = aux.data(auxbegin:end,:,:);
            aux.time = aux.time(auxbegin:end,:,:);
        end
        stimmarks = stimmarks-begintime;
    end
elseif trim==4 || trim==5 % 2b) Trim nirs scan according to a specified begin time
    begintime=trimTimes(sInfo(1),sInfo(3),sInfo(2)); %dyad,scan,sub or sub,scan,1

    d = d(begintime:end,:);
    s = s(begintime:end,:);
    t = t(begintime:end); %Trim our frames to the same length as data
    t = t-t(1,1); %Reset the first frame to be zero

    if begintime>0
        if device==2 && numaux > 0
            aux=aux(begintime:end,:);
        elseif device==3 && numaux > 0
            auxbegin = round(aux.samprate*begintime/samprate);
            aux.data = aux.data(auxbegin:end,:,:);
            aux.time = aux.time(auxbegin:end,:,:);
        end
    end
end