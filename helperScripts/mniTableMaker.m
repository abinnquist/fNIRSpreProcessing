%% This script will make an MNI table based on any probe you make in NIRSite
% You will need the script getMNIcoords.m which is in the fNIRSpreprocessing
% under folder 1_extractFuncs. 

%Select the folder where the probe info file is that you want
%Location: NIRx > Configurations > Montages > 'Montage you want'
probedir=uigetdir('','Choose Data Directory');
probeloc=load(strcat(probedir,filesep,'Standard_probeInfo.mat'));
probeInfo=probeloc.probeInfo;
digfile = strcat(probedir,filesep,'digpts.txt');

%Grab info from probe file for SD
nSrcs = probeInfo.probes.nSource0;
nDets = probeInfo.probes.nDetector0;
numchannels = probeInfo.probes.nChannel0;
MeasList = [probeInfo.probes.index_c ones(numchannels,1)];
WavelengthColumn = ones(numchannels,1);
MeasList1 = [MeasList WavelengthColumn];
WavelengthColumn(:)=2;
MeasList2 = [MeasList WavelengthColumn];

%Make the SD structure
SD.MeasList = [MeasList1; MeasList2];
SD.SrcPos = probeInfo.probes.coords_s3;
SD.nSrcs = nSrcs;
SD.SrcAmp = ones(nSrcs,1);
SD.DetPos = probeInfo.probes.coords_d3;
SD.nDets = nDets;
SD.DetAmp = ones(nDets,1);
SD.SpatialUnit = 'cm';

mni_ch_table = getMNIcoords(digfile, SD);

%Write the MNI coordinates as a csv
writetable(mni_ch_table,strcat(probedir,filesep,'channel_mnicoords.csv'),'Delimiter',',');
