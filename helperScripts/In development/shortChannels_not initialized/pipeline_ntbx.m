% NIRx Medical Technologies
% For any questions/more information, contact: support@nirx.net

%% Prompt to select path and file
[filename, pathname] = uigetfile({'*.hdr'; '*.nirs'}, 'Please select the .nirs or .hdr file of your experiment.');
data_path = [pathname, filename];

%% Load Data (individual dataset)
[~,~,ext] = fileparts(data_path);
if strcmp(ext,'.nirs')
    raw = nirs.io.loadDotNirs(data_path);
elseif strcmp(ext, '.hdr')
    raw = nirs.io.loadNIRx(data_path, false);
else
    display(['Unexpected file extension: ' ext])
end

%% Edit stimulus duration
stim_dur = [12 12]; %array with duration of each condition
raw_edit = nirs.design.change_stimulus_duration(raw, [], stim_dur);

%% Rename stimulus
job = nirs.modules.RenameStims();
job.listOfChanges = {
    'stim_channel1', 'left_tap';
    'stim_channel2', 'right_tap';
    };
raw_edit = job.run(raw_edit);

%% Compute Optical Density
job = nirs.modules.OpticalDensity(); 
OD = job.run(raw_edit);

%% Short-channels correction
blen = 5; % baseline (pre onset)
offset = 5; % offset (post duration)
task = 0; % flag for separate blocks
OD_edit = nirs.modules.ntbxSSR(OD, blen, offset, task);

%% Compute Concentration Changes
job = nirs.modules.BeerLambertLaw(); % it uses PPF = 0.1
hb = job.run(OD_edit); % unit: uM (i.e. 10^-6 mmol/L)

%% Individual Stats: AR-IRLS
job = nirs.modules.AR_IRLS();
job.verbose = true;
job.basis = Dictionary();
job.basis('default') = nirs.design.basis.Canonical();
SubjStats=job.run(hb);

%% Visualize Results
c = [-1 1]; % contrast: right - left
ContrastSubj = SubjStats.ttest(c); % compute t-test
ContrastSubj.draw('tstat', [-10 10], 'q < 0.05') % apply threshold
