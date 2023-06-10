%Script to duplicate triggers for hyperscanned subjects

for i=1:length(currdir)
    group=currdir(i).name;  
    groupdir=dir(strcat(rawdir,filesep,group,filesep,dataprefix,'*'));

    for sc=1:numscans
        nsubs=1:length(groupdir);

        subname1 = groupdir(1).name;
        subdir1 = dir(strcat(rawdir,filesep,group,filesep,subname1,filesep,dataprefix,'*'));
        subname2 = groupdir(2).name;
        subdir2 = dir(strcat(rawdir,filesep,group,filesep,subname2,filesep,dataprefix,'*'));
            
        scanname1 = subdir1(sc).name;
        nirsfile1 = dir(strcat(rawdir,filesep,group,filesep,subname1,filesep,scanname1,filesep,'/*.nirs'));
        if ~isempty(nirsfile1)
            nirsname1 = nirsfile1.name;
            load(strcat(rawdir,filesep,group,filesep,subname1,filesep,scanname1,filesep,nirsname1),'-mat');
            s1=s;
        else
            s1=0;
        end

        scanname2 = subdir2(sc).name;
        nirsfile2 = dir(strcat(rawdir,filesep,group,filesep,subname2,filesep,scanname2,filesep,'/*.nirs'));
        if ~isempty(nirsfile2)
            nirsname2 = nirsfile2.name;
            load(strcat(rawdir,filesep,group,filesep,subname2,filesep,scanname2,filesep,nirsname2),'-mat');
            s2=s;
        else
            s2=0;
        end

        if sum(s1(:,1)) > sum(s2(:,1))
            s=s1;
            if ~isempty(nirsfile2)
                save(strcat(rawdir,filesep,group,filesep,subname2,filesep,scanname2,filesep,nirsname2),'s','-append');
            end
        elseif sum(s1(:,1)) < sum(s2(:,1))
            s=s2;
            if ~isempty(nirsfile1)
                save(strcat(rawdir,filesep,group,filesep,subname1,filesep,scanname1,filesep,nirsname1),'s','-append');
            end
        end
    end
end