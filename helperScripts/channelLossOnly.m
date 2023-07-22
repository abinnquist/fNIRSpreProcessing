%% Set properties
dataprefix='HM';
hyperscan=1; %0=no, 1=yes
multiscan=1; %0=no, 1=yes
IDlength=5;
numscans=3;
channelnum=42;

%% Select your data storage location
preprocdir=uigetdir('','Choose Preprocessed Data Directory');
currdir=dir(strcat(preprocdir,filesep,dataprefix,'*'));
if length(currdir)<1
    error(['ERROR: No data files found with ',dataprefix,' prefix']);
end

%% Make all folders active in your path
addpath(genpath('fNIRSpreProcessing'))

addpath(genpath("0_designOptions\")); addpath(genpath("1_extractFuncs\")); 
addpath(genpath("3_removeNoisy\")); addpath(genpath("4_filtering\"));
addpath(genpath("5_qualityControl\")); addpath(genpath("6_imagingORcomparisons\"));
addpath(genpath("helperScripts\"));

%% Get scan names
[~, ~,snames] = countScans(currdir, dataprefix, hyperscan, numscans, IDlength);  

%% Check for compile file and mask
dn=struct2cell(currdir(:,1));
nams=dn(1,:);
compExist=~strcmp(nams,strcat(dataprefix,'_compile.mat'));
numSubs=sum(compExist);

%% Run channnel loss check
if hyperscan
    qatable1a = array2table(cell(1,2));
    qatable1a.Properties.VariableNames={'Dyad','subjname'};
else
    qatable1a = array2table(cell(1,1));
    qatable1a.Properties.VariableNames={'subjname'};
end
qatable1b = array2table(zeros(1,length(snames)));
qatable1b.Properties.VariableNames=snames;
qatable1 = [qatable1a qatable1b];
qatable2 = qatable1;
qatable_copy = qatable1;

chtable1a = array2table((1:channelnum)');
chtable1a.Properties.VariableNames={'channelnum'};
chtable1b = array2table(zeros(channelnum,length(snames)));
chtable1b.Properties.VariableNames=snames;
chtable1 = [chtable1a chtable1b];
chtable2 = chtable1;    
    
fprintf('\n\t Generating data quality reports ...\n')
    reverseStr = '';
if hyperscan
    for i=1:numSubs
        msg = sprintf('\n\t group number %d/%d ...',i,length(currdir));
        fprintf([reverseStr,msg]);
        reverseStr = repmat(sprintf('\b'),1,length(msg));

        group=currdir(i).name;
        groupdir=dir(strcat(preprocdir,filesep,group,filesep,dataprefix,'*'));
        
        for j=1:length(groupdir)
            subjname = groupdir(j).name;
            subjnamelength = length(subjname);
            qatable_copy.subjname{1} = subjname;
            qatable_copy.Dyad{1} = group;
            qatable1 = [qatable1; qatable_copy];
            qatable2 = [qatable2; qatable_copy];
            subjdir = dir(strcat(preprocdir,filesep,group,filesep,subjname,filesep,dataprefix,'*'));
            
            if multiscan
                for k=1:length(subjdir)
                    scanname = subjdir(k).name;
                    currscan = snames(k);
                    scandir = dir(strcat(preprocdir,filesep,group,filesep,subjname,filesep,scanname,filesep,'*_nonoisych.mat'));
                    if ~isempty(scandir)
                        load(strcat(preprocdir,filesep,group,filesep,subjname,filesep,scanname,filesep,scandir(1).name))
                        goodchannels = ~isnan(z_oxy(1,:));
                        sumgoodchannels = sum(goodchannels);
                        qatable1.(currscan{1})(end) = sumgoodchannels;
                        chtable1.(currscan{1})(:) = chtable1.(currscan{1})(:) + goodchannels';
                    end
                    scandir = dir(strcat(preprocdir,filesep,group,filesep,subjname,filesep,scanname,filesep,'*_nouncertainch.mat'));
                    if ~isempty(scandir)
                        load(strcat(preprocdir,filesep,group,filesep,subjname,filesep,scanname,filesep,scandir(1).name))
                        goodchannels = ~isnan(z_oxy(1,:));
                        sumgoodchannels = sum(goodchannels);
                        qatable2.(currscan{1})(end) = sumgoodchannels;
                        chtable2.(currscan{1})(:) = chtable2.(currscan{1})(:) + goodchannels';
                    end
                end
                       
            else  
                scandir = dir(strcat(preprocdir,filesep,group,filesep,subjname,filesep,'*_nonoisych.mat'));
                currscan = snames(1);
                if ~isempty(scandir)
                    load(strcat(preprocdir,filesep,group,filesep,subjname,filesep,scandir(1).name)) 
                    goodchannels = ~isnan(z_oxy(1,:));
                    sumgoodchannels = sum(goodchannels);
                    qatable1.(currscan{1})(end) = sumgoodchannels;
                    chtable1.(currscan{1})(:) = chtable1.(currscan{1})(:) + goodchannels';
                end
                scandir = dir(strcat(preprocdir,filesep,group,filesep,subjname,filesep,'*_nouncertainch.mat'));
                if ~isempty(scandir)
                    load(strcat(preprocdir,filesep,group,filesep,subjname,filesep,scandir(1).name)) 
                    goodchannels = ~isnan(z_oxy(1,:));
                    sumgoodchannels = sum(goodchannels);
                    qatable2.(currscan{1})(end) = sumgoodchannels;
                    chtable2.(currscan{1})(:) = chtable2.(currscan{1})(:) + goodchannels';
                end
            end
        end
    end
else
    for i=1:numSubs
        msg = sprintf('\n\t subject number %d/%d ...',i,length(currdir));
        fprintf([reverseStr,msg]);
        reverseStr = repmat(sprintf('\b'),1,length(msg));
        subjname = currdir(i).name;
        subjnamelength = length(subjname);
        qatable_copy.subjname{1} = subjname;
        qatable1 = [qatable1; qatable_copy];
        qatable2 = [qatable2; qatable_copy];
        subjdir = dir(strcat(preprocdir,filesep,subjname,filesep,dataprefix,'*'));

        if multiscan
            for k=1:length(subjdir)
                scanname = subjdir(k).name;
                currscan = snames(k);
                scandir = dir(strcat(preprocdir,filesep,subjname,filesep,scanname,filesep,'*_nonoisych.mat'));
                if ~isempty(scandir)
                    load(strcat(preprocdir,filesep,subjname,filesep,scanname,filesep,scandir(1).name))
                    goodchannels = ~isnan(z_oxy(1,:));
                    sumgoodchannels = sum(goodchannels);
                    qatable1.(currscan{1})(end) = sumgoodchannels;
                    chtable1.(currscan{1})(:) = chtable1.(currscan{1})(:) + goodchannels';
                end
                scandir = dir(strcat(preprocdir,filesep,subjname,filesep,scanname,filesep,'*_nouncertainch.mat'));
                if ~isempty(scandir)
                    load(strcat(preprocdir,filesep,subjname,filesep,scanname,filesep,scandir(1).name))
                    goodchannels = ~isnan(z_oxy(1,:));
                    sumgoodchannels = sum(goodchannels);
                    qatable2.(currscan{1})(end) = sumgoodchannels;
                    chtable2.(currscan{1})(:) = chtable2.(currscan{1})(:) + goodchannels';
                end
            end
                       
        else  
            scandir = dir(strcat(preprocdir,filesep,subjname,filesep,'*_nonoisych.mat'));
            currscan = snames(1);
            if ~isempty(scandir)
                load(strcat(preprocdir,filesep,subjname,filesep,scandir(1).name)) 
                goodchannels = ~isnan(z_oxy(1,:));
                sumgoodchannels = sum(goodchannels);
                qatable1.(currscan{1})(end) = sumgoodchannels;
                chtable1.(currscan{1})(:) = chtable1.(currscan{1})(:) + goodchannels';
            end
            scandir = dir(strcat(preprocdir,filesep,subjname,filesep,'*_nouncertainch.mat'));
            if ~isempty(scandir)
                load(strcat(preprocdir,filesep,subjname,filesep,scandir(1).name)) 
                goodchannels = ~isnan(z_oxy(1,:));
                sumgoodchannels = sum(goodchannels);
                qatable2.(currscan{1})(end) = sumgoodchannels;
                chtable2.(currscan{1})(:) = chtable2.(currscan{1})(:) + goodchannels';
            end
        end
    end
end

qaoutpath_noisy=strcat(preprocdir,filesep,'QAreport_allsubj_cleanchannels.csv');
qaoutpath_uncertain=strcat(preprocdir,filesep,'QAreport_allsubj_cleanandcertainchannels.csv');
writetable(qatable1,qaoutpath_noisy,'Delimiter',',');
writetable(qatable2,qaoutpath_uncertain,'Delimiter',',');

choutpath_noisy=strcat(preprocdir,filesep,'QAreport_allch_cleanchannels.csv');
choutpath_uncertain=strcat(preprocdir,filesep,'QAreport_allch_cleanandcertainchannels.csv');
writetable(chtable1,choutpath_noisy,'Delimiter',',');
writetable(chtable1,choutpath_uncertain,'Delimiter',',');

clear
