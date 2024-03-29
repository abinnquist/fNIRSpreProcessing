function [scanCount, scannames, snames] = countScans(currdir, dataprefix, hyper, numscans, IDlength)
rdir=currdir(1).folder;

if length(numscans) < 2
    numscans=1:numscans;
end

if hyper
    scanCount=zeros(length(currdir),2); %If more than two it will adjust
    scannames = cell(length(currdir),length(numscans),2);
    for g=1:length(currdir)
        group=currdir(g).name;  
        groupdir=dir(strcat(rdir,filesep,group,filesep,dataprefix,'*'));
    
        for p=1:length(groupdir)
            subjname = groupdir(p).name;
            subjdir = dir(strcat(rdir,filesep,group,filesep,subjname,filesep,dataprefix,'*'));     
            scanCount(g,p)=length(subjdir);

            if length(numscans)==1
                scannames(g,1,p) = {subjname};
            else
                sk=1;
                for k=numscans
                    scanname = subjdir(k).name;
                    scannames(g,sk,p)={scanname};
                    sk=sk+1;
                end
            end
        end
    end

    %for the names of scans based on first subject
    snames = cell(width(scannames),1,1);
    for s=1:width(scannames)
        sc=scannames{1,s};
        sc=sc(length(dataprefix)+IDlength+1:end);
        snames(s,1)={sc};
    end
else
    scanCount=zeros(length(currdir),1);
    scannames = cell(length(currdir),length(numscans));
    if length(numscans)==1
        for k=1:length(currdir)
            scanname = currdir(k).name;
            scannames(k,1)={scanname};
            datadir=strcat(currdir(k).folder,filesep,currdir(k).name);
            if ~isempty(datadir)
                scanCount(k,1)=1;
            end
        end
    else
        for p=1:length(currdir)
            subjname = currdir(p).name;
            subjdir = dir(strcat(rdir,filesep,subjname,filesep,dataprefix,'*'));
            scanCount(p,1)=length(subjdir);
    
            for k=1:length(subjdir)
                scanname = subjdir(k).name;
                scannames(p,k)={scanname};
            end
        end
    end

    %for the names of scans based on first subject
    snames=cell(width(scannames),1);
    for s=1:width(scannames)
        sc=scannames{1,s};
        sc=sc(length(dataprefix)+IDlength+1:end);
        snames(s,1)={sc};
    end
end

