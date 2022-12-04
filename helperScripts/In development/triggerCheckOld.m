clear
%This will collect the trigger data for the current study to check if there
%are any problems, inconsistencies, etc before runnning the preprocessing.
%I often use the first trigger to trim the data so I always want to make sure it
%is present or in the correct location before preprocessing

% INPUTS
dataprefix='IPC'; %Data prefix for the study
hyper=1; %If hyperscanning
numscans=5; %Number of scans per subject

supported_devices = {'NIRx-NirScout or NirSport1','NIRx-NirSport2 or .nirs file','.Snirf file'};
[device,~] = listdlg('PromptString', 'Select acquisition device:',...
    'SelectionMode', 'single', 'ListString', supported_devices);

rawdir=uigetdir('','Choose data directory');
currdir=dir(strcat(rawdir,filesep,dataprefix,'*'));

%Check how many scans per participant
scanCount = countScans(currdir, rawdir, dataprefix, hyper);

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
                scannames(g,k,p)={scanname};
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

%Again if uneven number of scans
scanMask=scanCount~=numscans;
exscloc=find(scanMask(:,1)==0);
exSN=scannames(exscloc(1),:,1);
snames = extract(string(exSN),lettersPattern);
[~, ~, thirdD]=size(snames);
if strcmp(dataprefix,snames(1,1,1)) || thirdD > 1
    sname=snames(1,:,2);
end

neworder = norder(scanCount,numscans,scanMask,scannames,dataprefix,sname);
for g=1:length(scanCount)
    for p=1:width(scanCount)
        triggers(g,:,p)=triggers(g,neworder(g,:,p),p);
        scanLength(g,:,p)=scanLength(g,neworder(g,:,p),p);
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

%% Step 4: To remove all but the last trigger
% load(strcat(rawdir,filesep,'trigInfo.mat'))
% scanLengths = [620;587;638;632;...
%     646;628;614;677;506;636;931;584;709];
% 
% 
% for t=1:length(trigInfo)
%     trigs=trigInfo(t).trigs;
%     [dyNum,maxTrig,nSubs]=size(trigs);
%     for s=1:nSubs
%         trigMask(:,s,t)=trigs(:,2,s)>0;
%     end
% end
% 
% %This loop will remove all but the last trigger
% for sc=1:length(trigInfo)
%     [dy,sb]=find(trigMask(:,:,sc));
% 
%     for tr=1:length(dy)
%         dyName=currdir(dy(tr)).name;
%         dydir=dir(strcat(rawdir,filesep,dyName,filesep,dataprefix,'*'));
%         subName=dydir(sb(tr)).name;
%         subjdir=dir(strcat(rawdir,filesep,dyName,filesep,subName,filesep,dataprefix,'*'));
%         scanfolder=subjdir(sc).name;
% 
%         nirsfile = dir(strcat(rawdir,filesep,dyName,filesep,subName,filesep,scanfolder,'/*.nirs'));
%         filename=nirsfile(1).name;
%         load(strcat(nirsfile.folder,'/',filename),'-mat');
%         ssum = sum(s,2);
%         stimmarks = find(ssum);
%         nStims=length(stimmarks);
% 
%         if nStims > 1
%             for st=1:nStims-1
%                 s(stimmarks(st),1)=0;
%             end
%             save(strcat(nirsfile.folder,filesep,filename),'aux','d','s','SD','t')
%         end
%     end
% end
% 
% fs=5.0863;
% inLen=round(10*60*fs);
% oNLen=round(15*60*fs);
% restLen=round(5*60*fs);
% vidLen=round(9*60*fs);
% 
% inT=trigInfo(1).scanLen;
% neuT=trigInfo(2).scanLen;
% outT=trigInfo(3).scanLen;
% restT=trigInfo(4).scanLen;
% vidT=trigInfo(5).scanLen;
% 
% %Find scans shorter than intended convo
% [r,c]=find(inT<inLen);
% [r,c]=find(outT<oNLen);
% [r,c]=find(neuT<oNLen);
% [r,c]=find(restT<restLen);
% [r,c]=find(vidT<vidLen);
% 

