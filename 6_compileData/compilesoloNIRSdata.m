%Compiles the solo data for n scans
%Compiles your choice of channel rejection from preprocessing (i.e. ch_reject) 

function [deoxy3D,oxy3D]= compilesoloNIRSdata(preprocess_dir,dataprefix,ch_reject,numScans,zdim)

%find all of the preprocessed folders
currdir=dir(strcat(preprocess_dir,filesep,dataprefix,'*'));

if zdim %will compile zscored data (i.e., z_oxy/z_deoxy)
    for sc=1:numScans
        z_oxy1=nan(1,1,2);
        z_deoxy1=nan(1,1,2);

        for i=1:length(currdir)
            subject=currdir(i).name; %define dyad
            subfolder=dir(strcat(preprocess_dir,filesep,subject,filesep,dataprefix,'*'));

            if ~isempty(subfolder)
                subfiles=dir(strcat(subfolder(1).folder,filesep,subfolder(sc).name,filesep,'*.mat'));
                if ~isempty(subfiles)
                    load(strcat(subfiles(1).folder,filesep,subfiles(ch_reject).name),'z_oxy','z_deoxy') 
                    [length_convo, numchans]=size(z_oxy);
                    z_deoxy1(1:length_convo,1:numchans,i)=z_deoxy(1:length_convo,:);
                    z_oxy1(1:length_convo,1:numchans,i)=z_oxy(1:length_convo,:);
                end
            end
        end
        deoxy3D(sc).name=strcat('Scan',num2str(sc));
        deoxy3D(sc).subdata=z_deoxy1;
      
        oxy3D(sc).name=strcat('Scan',num2str(sc));
        oxy3D(sc).subdata=z_oxy1;
    end  
else %will compile non-zscored data (i.e., oxy/deoxy)
    for sc=1:numScans
        oxy1=nan(1,1,2);
        deoxy1=nan(1,1,2);

        for i=1:length(currdir)
            subject=currdir(i).name; %define dyad
            subfolder=dir(strcat(preprocess_dir,filesep,subject,filesep,dataprefix,'*'));       
    
            if ~isempty(subfolder)
                subfiles=dir(strcat(subfolder(sc).folder,filesep,subfolder(sc).name,filesep,'*.mat'));
                if ~isempty(subfiles)
                    load(strcat(subfiles(1).folder,filesep,subfiles(ch_reject).name),'oxy','deoxy') 
                    [length_convo, numchans]=size(oxy);
                    deoxy1(1:length_convo,1:numchans,i)=deoxy(1:length_convo,:);
                    oxy1(1:length_convo,1:numchans,i)=oxy(1:length_convo,:);
                end
            end
        end
        deoxy3D(sc).name=strcat('Scan',num2str(sc));
        deoxy3D(sc).subdata=deoxy1;
        
        oxy3D(sc).name=strcat('Scan',num2str(sc));
        oxy3D(sc).subdata=oxy1;
    end
end

