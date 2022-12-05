function qualityReport(dataprefix,hyperscan,multiscan,channelnum,preprocdir,snames)

%inputs: 
%       dataprefix: string. Prefix of every folder name that should be considered a
%           data folder. E.g., ST for ST_101, ST_102, etc.  
%       hyperscan: 0 or 1. 1 if hyperscanning, 0 if single subject.
%       multiscan: 0 or 1. If the experiment has multiple scans per person
%       channelnum: integer. Number of channels in the montage
%       samprate: double. Sampling rate in experiment
%       thresh: double, multiple of 0.05. Max amount you want to allow a 
%          synchrony estimate to vary by (measurement error allowance).
%           Default is 0.1 
%       preprocdir: string. Path to PreProcessedFiles directory
%
%outputs: csv data quality reports, per subject and whole dataset, reporting
%           which channels had poor data quality.

if ~exist('preprocdir','var')
    preprocdir=uigetdir('','Choose Preprocessed Data Directory');
    currdir=dir(strcat(preprocdir,filesep,dataprefix,'*'));
else
    currdir=dir(strcat(preprocdir,filesep,dataprefix,'*'));
end
if length(currdir)<1
    error(['ERROR: No data files found with ',dataprefix,' prefix']);
end

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

chtable1a = array2table([1:channelnum]');
chtable1a.Properties.VariableNames={'channelnum'};
chtable1b = array2table(zeros(channelnum,length(snames)));
chtable1b.Properties.VariableNames=snames;
chtable1 = [chtable1a chtable1b];
chtable2 = chtable1;    
    
fprintf('\n\t Generating data quality reports ...\n')
    reverseStr = '';
if hyperscan
    for i=1:length(currdir)
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
                    if exist(strcat(preprocdir,filesep,group,filesep,subjname,filesep,scanname,filesep,scandir(1).name),'file')
                        load(strcat(preprocdir,filesep,group,filesep,subjname,filesep,scanname,filesep,scandir(1).name))
                        goodchannels = ~isnan(z_oxy(1,:));
                        sumgoodchannels = sum(goodchannels);
                        qatable1.(currscan{1})(end) = sumgoodchannels;
                        chtable1.(currscan{1})(:) = chtable1.(currscan{1})(:) + goodchannels';
                    end
                    scandir = dir(strcat(preprocdir,filesep,group,filesep,subjname,filesep,scanname,filesep,'*_nouncertainch.mat'));
                    if exist(strcat(preprocdir,filesep,group,filesep,subjname,filesep,scanname,filesep,scandir(1).name),'file')
                        load(strcat(preprocdir,filesep,group,filesep,subjname,filesep,scanname,filesep,scandir(1).name))
                        goodchannels = ~isnan(z_oxy(1,:));
                        sumgoodchannels = sum(goodchannels);
                        qatable2.(currscan{1})(end) = sumgoodchannels;
                        chtable2.(currscan{1})(:) = chtable2.(currscan{1})(:) + goodchannels';
                    end
                end
                       
            else  
                scandir = dir(strcat(preprocdir,filesep,group,filesep,subjname,filesep,'*_nonoisych.mat'));
                if exist(strcat(preprocdir,filesep,group,filesep,subjname,filesep,scandir(1).name),'file')
                    load(strcat(preprocdir,filesep,group,filesep,subjname,filesep,scandir(1).name)) 
                    goodchannels = ~isnan(z_oxy(1,:));
                    sumgoodchannels = sum(goodchannels);
                    qatable1.scan(end) = sumgoodchannels;
                    chtable1.scan(:) = chtable1.scan(:) + goodchannels';
                end
                scandir = dir(strcat(preprocdir,filesep,group,filesep,subjname,filesep,'*_nouncertainch.mat'));
                if exist(strcat(preprocdir,filesep,group,filesep,subjname,filesep,scandir(1).name),'file')
                    load(strcat(preprocdir,filesep,group,filesep,subjname,filesep,scandir(1).name)) 
                    goodchannels = ~isnan(z_oxy(1,:));
                    sumgoodchannels = sum(goodchannels);
                    qatable2.scan(end) = sumgoodchannels;
                    chtable2.scan(:) = chtable2.scan(:) + goodchannels';
                end
            end
        end
    end
else
    for i=1:length(currdir)
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
                if exist(strcat(preprocdir,filesep,subjname,filesep,scanname,filesep,scandir(1).name),'file')
                    load(strcat(preprocdir,filesep,subjname,filesep,scanname,filesep,scandir(1).name))
                    goodchannels = ~isnan(z_oxy(1,:));
                    sumgoodchannels = sum(goodchannels);
                    qatable1.(currscan{1})(end) = sumgoodchannels;
                    chtable1.(currscan{1})(:) = chtable1.(currscan{1})(:) + goodchannels';
                end
                scandir = dir(strcat(preprocdir,filesep,subjname,filesep,scanname,filesep,'*_nouncertainch.mat'));
                if exist(strcat(preprocdir,filesep,subjname,filesep,scanname,filesep,scandir(1).name),'file')
                    load(strcat(preprocdir,filesep,subjname,filesep,scanname,filesep,scandir(1).name))
                    goodchannels = ~isnan(z_oxy(1,:));
                    sumgoodchannels = sum(goodchannels);
                    qatable2.(currscan{1})(end) = sumgoodchannels;
                    chtable2.(currscan{1})(:) = chtable2.(currscan{1})(:) + goodchannels';
                end
            end
                       
        else  
            scandir = dir(strcat(preprocdir,filesep,subjname,filesep,'*_nonoisych.mat'));
            if exist(strcat(preprocdir,filesep,subjname,filesep,scandir(1).name),'file')
                load(strcat(preprocdir,filesep,subjname,filesep,scandir(1).name)) 
                goodchannels = ~isnan(z_oxy(1,:));
                sumgoodchannels = sum(goodchannels);
                qatable1.scan(end) = sumgoodchannels;
                chtable1.scan(:) = chtable1.scan(:) + goodchannels';
            end
            scandir = dir(strcat(preprocdir,filesep,subjname,filesep,'*_nouncertainch.mat'));
            if exist(strcat(preprocdir,filesep,subjname,filesep,scandir(1).name),'file')
                load(strcat(preprocdir,filesep,subjname,filesep,scandir(1).name)) 
                goodchannels = ~isnan(z_oxy(1,:));
                sumgoodchannels = sum(goodchannels);
                qatable2.scan(end) = sumgoodchannels;
                chtable2.scan(:) = chtable2.scan(:) + goodchannels';
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

end
