function reOrganizeFolders(scanNames,numHyper,pathName,newdir)
% Make a new folder and subfolders to re-organize hyperscanned subjects w/ multiple scans
%Creates a new folder and moves the folders w/ NIRS data for correct structure 
%for preprocessing 2+ subjects (not needed for single scan hyper or single subject)

mkdir(newdir); %Create the folder
cd(newdir)

oldnirsDir = dir(pathName);
oldnirsDir = oldnirsDir(3:end); % this just removes non-NIRS directory stuff

newnirsDir= dir(newdir);
newnirsDir= newnirsDir(3:end);

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
            currName = scanName(1:end-(length(scanNames{sc})+1));
            subFolder = strcat(newdir,filesep,dyName,filesep,currName);
            if ~exist(subFolder)
                mkdir (subFolder)
            end

            newPath=strcat(newdir,filesep,dyName,filesep,currName);
            movefile(psPath, fullfile(newPath));

        end
    end
end


