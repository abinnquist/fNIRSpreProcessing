function [scanCount, scannames] = countScans(currdir, rawdir, dataprefix, hyper, numscans)

if hyper
    scanCount=zeros(length(currdir),2); %If more than two it will adjust
    scannames = cell(length(currdir),numscans,2);
    for g=1:length(currdir)
        group=currdir(g).name;  
        groupdir=dir(strcat(rawdir,filesep,group,filesep,dataprefix,'*'));
    
        for p=1:length(groupdir)
            subjname = groupdir(p).name;
            subjdir = dir(strcat(rawdir,filesep,group,filesep,subjname,filesep,dataprefix,'*'));     
            scanCount(g,p)=length(subjdir);

            for k=1:length(subjdir)
                scanname = subjdir(k).name;
                scannames(g,k,p)={scanname};
            end
        end
    end
else
    scanCount=zeros(length(currdir),1);
    scannames = cell(length(currdir),numscans);
    for p=1:length(currdir)
        subjname = currdir(p).name;
        subjdir = dir(strcat(rawdir,filesep,subjname,filesep,dataprefix,'*'));
        scanCount(p,1)=length(subjdir);

        for k=1:length(subjdir)
            scanname = subjdir(k).name;
            scannames(p,k)={scanname};
        end
    end
end

