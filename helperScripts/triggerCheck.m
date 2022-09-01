%This will collect the trigger data for the current study to check if there
%are any problems, inconsistencies, etc before runnning the preprocessing

dataprefix='SS'; %Change this for the study
hyper=1; %If hyperscanning
numscans=5; %Number of scans per subject

rawdir=uigetdir('','Choose data directory');
currdir=dir(strcat(rawdir,filesep,dataprefix,'*'));
if hyper==1
    triggers=nan(length(currdir),numscans,2);
    for g=1:length(currdir)
        group=currdir(g).name;  
        groupdir=dir(strcat(rawdir,filesep,group,filesep,dataprefix,'*'));
    
        for p=1:length(groupdir)
            subjname = groupdir(p).name;
            subjdir = dir(strcat(rawdir,filesep,group,filesep,subjname,filesep,dataprefix,'*'));
    
            for k=1:length(subjdir)
                scanname = subjdir(k).name;
                scanfolder = strcat(rawdir,filesep,group,filesep,subjname,filesep,scanname);
                [d, sd_ind, samprate, wavelengths, s] = extractNIRxData(scanfolder);
                
                ssum = sum(s,2);
                stimmarks = find(ssum);
    
                if isempty(stimmarks)
                    triggers(g,k,p)=0;
                else
                    triggers(g,k,p)=stimmarks;
                end
            end
        end
    end
else

    triggers=nan(length(currdir),numscans);
    for p=1:length(groupdir)
        subjname = currdir(p).name;
        subjdir = dir(strcat(rawdir,filesep,subjname,filesep,dataprefix,'*'));
    
        for k=1:length(subjdir)
            scanname = subjdir(k).name;
            scanfolder = strcat(rawdir,filesep,subjname,filesep,scanname);
            [d, sd_ind, samprate, wavelengths, s] = extractNIRxData(scanfolder);
            
            ssum = sum(s,2);
            stimmarks = find(ssum);

            if isempty(stimmarks)
                triggers(p,k)=0;
            else
                triggers(p,k)=stimmarks;
            end
        end
    end
end

