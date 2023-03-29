function trigInfo = triggerCheck(rawdir,dataprefix,IDlength,hyperscan,numscans)

% Will collect the trigger data for the current study so you can check if there
% are any problems, inconsistencies, etc before runnning the preprocessing.
% I often use the first trigger to trim the data so I always want to make sure it
% is present or in the correct location before preprocessing.
% If run it without the output it will still save to the rawdir as trigInfo

% Scan numbers and names
addpath(genpath("fNIRSpreProcessing/1_extractFuncs/")); 

supported_devices = {'NIRx-NirScout or NirSport1','NIRx-NirSport2 or .nirs file','.Snirf file'};
[device,~] = listdlg('PromptString', 'Select acquisition device:',...
    'SelectionMode', 'single', 'ListString', supported_devices);

currdir=dir(strcat(rawdir,filesep,dataprefix,'*'));

%Check how many scans per participant
[scanCount, ~, snames] = countScans(currdir, dataprefix, hyperscan, numscans, IDlength);

% Collect trigger info and save
if hyperscan==1
    fprintf('\n\t Checking triggers ...\n')
    reverseStr = '';
    Elapsedtime = tic;

    trigInfo=struct;

    for k=1:numscans
        dyadNums=cell(length(currdir),1);
        subjectNames=cell(length(currdir),width(scanCount));
        scanLength=nan(length(currdir),width(scanCount));
        triggers=zeros(length(currdir),1,2);

        for g=1:length(currdir)
            group=currdir(g).name;  
            groupdir=dir(strcat(rawdir,filesep,group,filesep,dataprefix,'*'));
        
            for p=1:length(groupdir)
                subjname = groupdir(p).name;
                subjdir = dir(strcat(rawdir,filesep,group,filesep,subjname,filesep,dataprefix,'*'));

                msg = sprintf('\n\t scan %d/%d, group %d/%d, subj %d/%d ...', k,numscans,g,length(currdir),p,length(groupdir));
                fprintf([reverseStr,msg]);
                reverseStr = repmat(sprintf('\b'),1,length(msg)); 

                scanname = subjdir(k).name;
                scandir=dir(strcat(rawdir,filesep,group,filesep,subjname,filesep,subjdir(k).name,filesep));
                subjectNames(g,p)={subjname};
                dyadNums(g,p)={group};

                if length(scandir) > 2
                    scanfolder = strcat(rawdir,filesep,group,filesep,subjname,filesep,scanname);
                    if device==1
                        [d, sd_ind, samprate, wavelengths, s] = extractNIRxData(scanfolder);
                    else
                        [d, samprate, s, ~, ~, ~] = extractTechEnData(scanfolder);
                    end
                    lenScan=length(d);
                    scanLength(g,p)=lenScan;
    
                    ssum = sum(s,2);
                    stimmarks = find(ssum);
    
                    if isempty(stimmarks)
                        triggers(g,1,p)=0;
                    else
                        nt=length(stimmarks);
                        triggers(g,1:nt,p)=stimmarks;
                    end
                end
            end
        end  
        trigInfo(k).scanname=snames{k};
        trigInfo(k).dyad=dyadNums;
        trigInfo(k).subNum=subjectNames;
        trigInfo(k).trigs=triggers;   
        trigInfo(k).scanLen=scanLength;
    end
    Elapsedtime = toc(Elapsedtime);
    fprintf('\n\t Elapsed time: %g seconds\n', Elapsedtime);
else
    fprintf('\n\t Checking triggers ...\n')
    reverseStr = '';
    Elapsedtime = tic;

    for k=1:numscans
        subjectNames=cell(length(currdir),1);
        scanLength=nan(length(currdir),1);
        triggers=nan(length(currdir),numscans);

        for p=1:length(currdir)
            subjname = currdir(p).name;
            subjectNames(p,1)={subjname};
            subjdir = dir(strcat(rawdir,filesep,subjname,filesep,dataprefix,'*'));

            msg = sprintf('\n\t scan %d/%d, subj %d/%d ...',k,numscans,p,length(currdir));
            fprintf([reverseStr,msg]);
            reverseStr = repmat(sprintf('\b'),1,length(msg)); 

            scanname = subjdir(k).name;
            scandir=dir(strcat(rawdir,filesep,subjname,filesep,subjdir(k).name,filesep));

            if length(scandir) > 2
                scanfolder = strcat(rawdir,filesep,subjname,filesep,scanname);

                if device==1
                    [d, sd_ind, samprate, wavelengths, s] = extractNIRxData(scanfolder);
                else
                    [d, samprate, s, SD, aux, t] = extractTechEnData(scanfolder);
                end  
                lenScan=length(d);
                scanLength(p,1)=lenScan;

                ssum = sum(s,2);
                stimmarks = find(ssum);
    
                if isempty(stimmarks)
                    triggers(p,k)=0;
                else
                    nt=length(stimmarks);
                    triggers(p,1:nt)=stimmarks;
                end
            end
        end
        trigInfo(k).scanname=snames{k};
        trigInfo(k).subNum=subjectNames;
        trigInfo(k).trigs=triggers;   
        trigInfo(k).scanLen=scanLength; 
    end
    Elapsedtime = toc(Elapsedtime);
    fprintf('\n\t Elapsed time: %g seconds\n', Elapsedtime);
end

save(strcat(rawdir,filesep,'trigInfo.mat'),'trigInfo')
