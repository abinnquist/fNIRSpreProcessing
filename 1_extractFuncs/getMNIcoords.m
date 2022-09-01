function mni_ch_table = getMNIcoords(digfile, SD)

%MNI coordinates of 10-20 reference points
mni_refs = [2.32,62.34,-21.85,1;          %Nz
            0.882,-13.4729,74.1371,1;     %Cz
            -60.6623,-15.935,-34.9223,1;  %LPA
            -4.77,-100.26,-14.39,1];      %Iz

numchannels = size(SD.MeasList,1)/2;
nSrc = SD.nSrcs;
nDet = SD.nDets;
src_det_pair = SD.MeasList(1:numchannels,1:2);
digptsInfo = readtable(digfile);
dgLabels = table2array(digptsInfo(:,1));
digpts = [table2array(digptsInfo(:,2:4)),ones(length(dgLabels),1)];
digpts_refs(1,1:4) = digpts(find(strcmpi(dgLabels,'nz:')),:);
digpts_refs(2,1:4) = digpts(find(strcmpi(dgLabels,'cz:')),:);
digpts_refs(3,1:4) = digpts(find(contains(dgLabels,'l','IgnoreCase',true)),:); %LPA or al
digpts_refs(4,1:4) = digpts(find(strcmpi(dgLabels,'iz:')),:);
digpts = digpts(find(strcmpi(dgLabels,'s1:')):find(strcmpi(dgLabels,'s1:'))+nSrc+nDet-1,:);

trsfm = mni_refs' * pinv(digpts_refs)';
mni_pts = trsfm * digpts';
mni_pts = mni_pts';
mni_pts = mni_pts(:,1:3);

mni_srcPos = mni_pts(1:nSrc,:);
mni_detPos = mni_pts(nSrc+1:end,:);

mni_ch = nan(numchannels,3);
for i=1:numchannels
    x = (mni_srcPos(src_det_pair(i,1),1) + mni_detPos(src_det_pair(i,2),1))/2;
    y = (mni_srcPos(src_det_pair(i,1),2) + mni_detPos(src_det_pair(i,2),2))/2;
    z = (mni_srcPos(src_det_pair(i,1),3) + mni_detPos(src_det_pair(i,2),3))/2;
    mni_ch(i,:) = [x y z];
end

mni_ch_table = array2table(mni_ch);
mni_ch_table.Properties.VariableNames = {'x','y','z'};

end

