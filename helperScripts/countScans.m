function [scanCount, scannames, snames] = countScans(currdir, rawdir, dataprefix, hyper, numscans, IDlength)

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

            if numscans==1
                scannames(g,1,p) = {subjname};
            else
                for k=1:length(subjdir)
                    scanname = subjdir(k).name;
                    scannames(g,k,p)={scanname};
                end
            end
        end
    end

    %for the names of scans based on first subject
    snames = cell(width(scannames),1,1);
    for s=1:width(scannames)
        sc=scannames{1,s};
        sc=sc(length(dataprefix)+IDlength+2:end);
        snames(s,1)={sc};
    end
else
    scanCount=zeros(length(currdir),1);
    scannames = cell(length(currdir),numscans);
    if numscans > 1
        for p=1:length(currdir)
            subjname = currdir(p).name;
            subjdir = dir(strcat(rawdir,filesep,subjname,filesep,dataprefix,'*'));
            scanCount(p,1)=length(subjdir);
    
            for k=1:length(subjdir)
                scanname = subjdir(k).name;
                scannames(p,k)={scanname};
            end
        end
    else
        for k=1:length(currdir)
            scanname = currdir(k).name;
            scannames(k,1)={scanname};
        end
    end

    %for the names of scans based on first subject
    snames=cell(width(scannames),1);
    for s=1:width(scannames)
        sc=scannames{1,s};
        sc=sc(length(dataprefix)+IDlength+2:end);
        snames(s,1)={sc};
    end
end

