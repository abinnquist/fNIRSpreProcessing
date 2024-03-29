function reOrganizeFolders(reOrganize,snames,dataprefix,numHyper,pathName,newdir)
% Make a new folder and subfolders to re-organize hyperscanned subjects w/ multiple scans
%Creates a new folder and moves the folders w/ NIRS data for correct structure 
%for preprocessing 2+ subjects (not needed for single scan hyper or single subject)

mkdir(newdir); %Create the folder
cd(newdir)

oldnirsDir=dir(strcat(pathName,filesep,dataprefix,'*'));
%oldnirsDir = oldnirsDir(3:end); % this just removes non-NIRS directory stuff

newnirsDir= dir(newdir);
newnirsDir= newnirsDir(3:end);

if reOrganize==1
    for d = 1:length(oldnirsDir)
        dyName=oldnirsDir(d).name;
        dyDir = dir(strcat(pathName,filesep,dyName));
        dyDir = dyDir(3:end);
        dyFolder = strcat(newdir,filesep,dyName);
        mkdir (dyFolder)
    
        for sc = 1:length(dyDir)
            scName = dyDir(sc).name;
            scDir = dir(strcat(pathName,filesep,dyName,filesep,scName));
            scDir=scDir(3:end);
            pName={scDir.name};
    
            for p=1:numHyper
                psPath = fullfile(pathName,dyName,scName,pName{p});
                scanName = pName{p};
                currName = scanName(1:end-(length(snames{sc})+1));
                subFolder = strcat(newdir,filesep,dyName,filesep,currName);
                if ~exist(subFolder)
                    mkdir (subFolder)
                end
    
                newPath=strcat(newdir,filesep,dyName,filesep,currName);
                movefile(psPath, fullfile(newPath));
            end
        end
    end
elseif reOrganize==2
    nscans=length(snames);
    for d = 1:length(oldnirsDir)
        dyName=oldnirsDir(d).name;
        dyDir = dir(strcat(pathName,filesep,dyName,filesep,dataprefix,'*'));
        pName={dyDir.name};
        dyFolder = strcat(newdir,filesep,dyName);
        mkdir (dyFolder)

        strtScan=1;
        for p=1:numHyper
            %Create folders to seperate scans based on subjects
            subName=dyDir(strtScan).name; subName=subName(1:end-length(snames{1,1}));
            subFolder = strcat(newdir,filesep,dyName,filesep,subName);
            mkdir (subFolder)
            
            for sc=1:nscans
                psPath = fullfile(pathName,dyName,pName{strtScan});

                newPath=strcat(newdir,filesep,dyName,filesep,subName);
                movefile(psPath, fullfile(newPath));

                strtScan=strtScan+1;
            end
        end
    end
end


