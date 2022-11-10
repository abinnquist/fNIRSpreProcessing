clear
%This will collect the trigger data for the current study to check if there
%are any problems, inconsistencies, etc before runnning the preprocessing.
%I often use the first trigger to trim the data so I always want to make sure it
%is present or in the correct location before preprocessing

% INPUTS
dataprefix='0'; %Data prefix for the study
hyper=1; %If hyperscanning
numscans=5; %Number of scans per subject

supported_devices = {'NIRx-NirScout or NirSport1','NIRx-NirSport2 or .nirs file','.Snirf file'};
[device,~] = listdlg('PromptString', 'Select acquisition device:',...
    'SelectionMode', 'single', 'ListString', supported_devices);

rawdir=uigetdir('','Choose data directory');
currdir=dir(strcat(rawdir,filesep,dataprefix,'*'));

subjectNames={};
scannames=cell(1,numscans);
if hyper==1
    dyadNums={};
    triggers=nan(length(currdir),numscans,2);
    scanLength=nan(length(currdir),numscans,2);
    for g=1:length(currdir)
        group=currdir(g).name;  
        groupdir=dir(strcat(rawdir,filesep,group,filesep,dataprefix,'*'));
    
        for p=1:length(groupdir)
            subjname = groupdir(p).name;
            subjectNames=[subjectNames,subjname];
            dyadNums=[dyadNums,group];
            subjdir = dir(strcat(rawdir,filesep,group,filesep,subjname,filesep,dataprefix,'*'));
    
            for k=1:length(subjdir)
                scanname = subjdir(k).name;
                scannames(1,k)={scanname};
                scanfolder = strcat(rawdir,filesep,group,filesep,subjname,filesep,scanname);
                if device==1
                    [d, sd_ind, samprate, wavelengths, s] = extractNIRxData(scanfolder);
                else
                    [d, samprate, s, ~, ~, ~] = extractTechEnData(scanfolder);
                end
                lenScan=length(d);
                scanLength(g,k,p)=lenScan;

                ssum = sum(s,2);
                stimmarks = find(ssum);
    
                if isempty(stimmarks)
                    triggers(g,k,p)=0;
                else
                    triggers(g,k,p)=stimmarks(1);
                end
            end
        end
    end
else
    triggers=nan(length(currdir),numscans);
    for p=1:length(groupdir)
        subjname = currdir(p).name;
        subjectNames=[subjectNames,subjname];
        subjdir = dir(strcat(rawdir,filesep,subjname,filesep,dataprefix,'*'));
    
        for k=1:length(subjdir)
            scanname = subjdir(k).name;
            scannames(1,k)={scanname};
            scanfolder = strcat(rawdir,filesep,subjname,filesep,scanname);
            if device==1
                [d, sd_ind, samprate, wavelengths, s] = extractNIRxData(scanfolder);
            else
                [d, samprate, s, SD, aux, t] = extractTechEnData(scanfolder);
            end  
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

if hyper
    studyInfo=array2table(cell(length(subjectNames),2));
    studyInfo.Properties.VariableNames={'Dyad','Subject'};
    dnames = extract(string(dyadNums),digitsPattern);
    sjnames = extract(string(subjectNames),digitsPattern);
    studyInfo.Dyad=dnames';
    studyInfo.Subject=sjnames'; %If your subjects have letters, change this
   
    triggers=reshape(triggers,g*p,numscans); %dyads * subjects per dyad
    scanlen=reshape(scanLength,g*p,numscans); %dyads * subjects per dyad
else
    studyInfo=array2table(cell(length(subjectNames),1));
    studyInfo.Properties.VariableNames={'Subject'};
    sjnames = extract(string(subjectNames),digitsPattern);
    studyInfo.Subject=sjnames'; 
end

snames = extract(string(scannames),lettersPattern);
[~, ~, thirdD]=size(snames);
if strcmp(dataprefix,snames(1,1,1)) || thirdD > 1
    sname=snames(1,:,2);
end
lenInterest=scanlen-triggers;

sLenName=sname(1,:)+'_length'; %length of entire scan
sTrigName=sname(1,:)+'_trig'; %first trigger
sIName=sname(1,:)+'_active'; %time after first trigger
scanlen=array2table(scanlen,"VariableNames",sLenName);
triggers=array2table(triggers,"VariableNames",sTrigName);
lenInterest=array2table(lenInterest,"VariableNames",sIName);

triggerC=[];
for c=1:numscans
    triggerC=[triggerC,triggers(:,c),lenInterest(:,c),scanlen(:,c)];
end
triggerC=[studyInfo,triggerC];

save(strcat(rawdir,filesep,'triggerCheck'),'triggerC')
clear


