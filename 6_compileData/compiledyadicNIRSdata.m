%Compiles the dyadic data for n scans.
%NOTE: Even if you don't have the scan make sure you have an empty folder
%so the script does not error out.
%Compiles your choice of channel rejection from preprocessing (i.e. ch_reject) 

function [deoxy3D,oxy3D]= compiledyadicNIRSdata(preprocess_dir,dataprefix,ch_reject,numScans,zdim)

%find all of the preprocessed folders
currdir=dir(strcat(preprocess_dir,filesep,dataprefix,'*'));

if zdim %will compile zscored data (i.e., z_oxy/z_deoxy)
    for sc=1:numScans
        z_oxy1=nan(1,1,2);
        z_deoxy1=nan(1,1,2);
        z_oxy2=nan(1,1,2);
        z_deoxy2=nan(1,1,2);

        for i=1:length(currdir)
            dyad=currdir(i).name; %define dyad
            dyaddir=dir(strcat(preprocess_dir,filesep,dyad,filesep,dataprefix,'*'));
        
            for sj=1:length(dyaddir)
                subject=dyaddir(sj).name;
                subfolder=dir(strcat(currdir(1).folder,filesep,dyad,filesep,subject,filesep,dataprefix,'*')); 
        
                if ~isempty(subfolder) && sj==1
                    subfiles=dir(strcat(subfolder(1).folder,filesep,subfolder(sc).name,filesep,'*.mat'));
                    if ~isempty(subfiles)
                        load(strcat(subfiles(1).folder,filesep,subfiles(ch_reject).name),'z_oxy','z_deoxy') 
                        [length_convo, numchans]=size(z_oxy);
                        z_deoxy1(1:length_convo,1:numchans,i)=z_deoxy(1:length_convo,:);
                        z_oxy1(1:length_convo,1:numchans,i)=z_oxy(1:length_convo,:);
                    end
        
                elseif ~isempty(subfolder) && sj==2
                    subfiles=dir(strcat(subfolder(1).folder,filesep,subfolder(sc).name,filesep,'*.mat'));
                    if ~isempty(subfiles)
                        load(strcat(subfiles(1).folder,filesep,subfiles(ch_reject).name),'z_oxy','z_deoxy')
                        length_convo=length(z_oxy);
                        z_deoxy2(1:length_convo,1:numchans,i)=z_deoxy(1:length_convo,:);
                        z_oxy2(1:length_convo,1:numchans,i)=z_oxy(1:length_convo,:);
                    end
                end
            end
        end
        deoxy3D(sc).name=strcat('Scan',num2str(sc));
        deoxy3D(sc).sub1=z_deoxy1;
        deoxy3D(sc).sub2=z_deoxy2;
      
        oxy3D(sc).name=strcat('Scan',num2str(sc));
        oxy3D(sc).sub1=z_oxy1;
        oxy3D(sc).sub2=z_oxy2;
    end
else %will compile non-zscored data (i.e., oxy/deoxy)
    for sc=1:numScans
        oxy1=nan(1,1,2);
        deoxy1=nan(1,1,2);
        oxy2=nan(1,1,2);
        deoxy2=nan(1,1,2);

        for i=1:length(currdir)
            dyad=currdir(i).name; %define dyad
            dyaddir=dir(strcat(preprocess_dir,filesep,dyad,filesep,dataprefix,'*'));       
    
            for sj=1:length(dyaddir)
                subject=dyaddir(sj).name;
                subfolder=dir(strcat(currdir(1).folder,filesep,dyad,filesep,subject,filesep,dataprefix,'*')); 
       
                if ~isempty(subfolder) && sj==1
                    subfiles=dir(strcat(subfolder(sc).folder,filesep,subfolder(sc).name,filesep,'*.mat'));
                    if ~isempty(subfiles)
                        load(strcat(subfiles(1).folder,filesep,subfiles(ch_reject).name),'oxy','deoxy') 
                        [length_convo, numchans]=size(oxy);
                        deoxy1(1:length_convo,1:numchans,i)=deoxy(1:length_convo,:);
                        oxy1(1:length_convo,1:numchans,i)=oxy(1:length_convo,:);
                    end
        
                elseif ~isempty(subfolder) && sj==2
                    subfiles=dir(strcat(subfolder(sc).folder,filesep,subfolder(sc).name,filesep,'*.mat'));
                    if ~isempty(subfiles)
                        load(strcat(subfiles(1).folder,filesep,subfiles(ch_reject).name),'oxy','deoxy')
                        [length_convo, numchans]=size(oxy);
                        deoxy2(1:length_convo,1:numchans,i)=deoxy(1:length_convo,:);
                        oxy2(1:length_convo,1:numchans,i)=oxy(1:length_convo,:);
                    end
                end
            end
        end
        deoxy3D(sc).name=strcat('Scan',num2str(sc));
        deoxy3D(sc).sub1=deoxy1;
        deoxy3D(sc).sub2=deoxy2;
        
        oxy3D(sc).name=strcat('Scan',num2str(sc));
        oxy3D(sc).sub1=oxy1;
        oxy3D(sc).sub2=oxy2;
    end
end

