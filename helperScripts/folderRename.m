function folderRename(rawdir,dataprefix,hyperscan)
% Script will only add a prefix to any folders missing your chosen prefix,
% will change nothing else. Adds the prefix to whatever the folder is
% currently named. 
% Make sure you only have the data folders in the rawdir or else it will 
% rename other folders in the directory.

%Directory selection
currpath=pwd;

cd(rawdir)
currdir=dir(strcat(rawdir,filesep,'*'));
currdir = currdir(~startsWith({currdir.name},'.'));
lenPre=length(dataprefix);

if hyperscan
    for i=1:length(currdir)
        group = currdir(i).name;  
        groupdir = dir(strcat(rawdir,filesep,group,filesep));
        groupdir = groupdir(~startsWith({groupdir.name},'.'));

        if ~strcmp(group(1:lenPre),dataprefix)
            newgp=strcat(dataprefix,'_',group);
            movefile(subjname, newgp)
        else
            newgp=group;
        end
        cd(group)

        for j=1:length(groupdir)
            subjname = groupdir(j).name;
            subjdir = dir(strcat(rawdir,filesep,group,filesep,subjname,filesep));
            subjdir = subjdir(~startsWith({subjdir.name},'.'));

            if ~strcmp(subjname(1:lenPre),dataprefix)
                newsb=strcat(dataprefix,'_',subjname);
                movefile(subjname, newsb)
            else
                newsb=subjname;
            end
            cd(subjname)

            for k=1:length(subjdir)
                scanname = subjdir(k).name;

                if ~strcmp(scanname(1:lenPre),dataprefix)
                    newsc=strcat(dataprefix,'_',scanname);
                    movefile(scanname, newsc)
                end
            end
            cd ..
        end
        cd ..
    end
else
    for j=1:length(currdir)
        subjname = currdir(j).name;
        subjdir = dir(strcat(rawdir,filesep,subjname,filesep));
        subjdir = subjdir(~startsWith({subjdir.name},'.'));

        if ~strcmp(subjname(1:lenPre),dataprefix)
            newsb=strcat(dataprefix,'_',subjname);
            movefile(subjname, newsb)
        else
            newsb=subjname;
        end
        cd(subjname)

        for k=1:length(subjdir)
            scanname = subjdir(k).name;

            if ~strcmp(scanname(1:lenPre),dataprefix)
                newsc=strcat(dataprefix,'_',scanname);
                movefile(scanname, newsc)
            end
        end
        cd ..
    end
end
cd(currpath)
