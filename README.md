# fNIRSpreProcessing
SCN Lab current preprocessing pipeline (09/25/2022). For an older/different version see: https://github.com/smburns47/preprocessingfNIRS -- much of the credit is due to Shannon Burns for this pipeline as most of what has been done here was built upon her work. 

# General
UCLA SCN lab preprocessing pipeline for fNIRS data, collected with NIRx: NIRScout or NIRSport2. Will preprocess Snirf files but only if you have Homer3 toolbox.

# About: Gui-based or command line function
runNIRSpreproc.mat is a script you can run with Gui pop-ups OR use prepreprocessingfNIRS.mat as a function that automates the SCN lab's current preprocessing pipeline for fNIRS data (originally written by Shannon Burns, 2018, MIT License). 
See below for more details on each step of the pipeline, and how to use this code yourself. 

# Dependencies
The script depends on two publicly available Matlab packages - inpaint_nans and some Homer2 scripts. These are included with the preprocessingfNIRS repo. 
If you want to use a Snirf file you must downloaded the full Homer3 toolbox at https://github.com/BUNPC/Homer3. 

# Contents
preprocessingfNIRS is structured as 6-step pipeline: extracting raw data & auxiliary variable from files; trimming dead time; removing bad channels; motion correction of the data with your choice of correction; quality check for remaining unreliable channels after motion correction; compilation of data into one .mat file (optional). 
Please see comments in runNIRSPreproc.m file to read about specific functionality. Folders are for the most part organized in this step-based structure to more easily navigate to specific scripts if there is a problem or you want to modify.

- FOLDER STRUCTURE
	- 0_designOptions/
	- 1_extractFuncs/
     		- The inpain_nans dependency that interpolates missing values in a timecourse stored here. 
	- 2_trimming/
	- 3_removeNoisy/
     		- motionCorrs/
          			- wavelet/
     		- raw_OD_concentration/
	- 4_filtering/
	- 5_qualityControl/
	- 6_compileData/
	- helperScripts/
     		- In development

- Currently there are five options asked for by the input motionCorr: 
	- Volatility correction=1, PCfilter=2, PCA=3, CBSI=4, Wavelet=5, or none=6. I'm leaning toward wavelet currently.

- The "testQCoD.m" helper function. This tells you which channels are being marked as good and bad, and also visualizes the power spectral density of the raw signal in each 
fNIRS channel. Doing so is our current approach to finding bad channels (good channels have a preponderance of signal in slow frequencies, pure noise has random amounts of signal at every frequency). 
We're using a modified version of the quartile coefficient of dispersion (https://en.wikipedia.org/wiki/Quartile_coefficient_of_dispersion), abbreviated QCoD, to automatically decide which channels 
have good or bad signal. Essentially, it sums the frequency amplitudes in the first and fourth quartiles of the frequency range, and then compares them via (Q1-Q3)/(Q1+Q3). Larger QCoD is cleaner signal. 
Default threshold is set to 0.1 in preprocessingfNIRS. In testQCoD, change this to <0.1 to test allowing greater noise in the signal, or change to >0.1 for more stringency. Use this test function to 
check if the currently selected QCoD threshold for bad channel marking is what you want. Can be run on raw data, but does not do any other preprocessing. 

# How to Use
To download: clone or pull repo to your desired local directory. 

OPTION 1: With GUI pop-ups 
- Open runNIRSPreproc.m from main fNIRSPreProcessing folder 
- Hit Run (big green triangle) on runNIRSPreproc.m script, the script will add the paths for you. 

OPTION 2: as a function
- In the command window: addpath(genpath('fNIRSpreProcessing')) 
- Run the function preprocessingfNIRS from the command window
- takes 4 arguments: preprocessingfNIRS(dataprefix, hyperscan, multiscan, motionCorr, numaux)
     - Example: preprocessingfNIRS('IPC', 1, 1, 3, 2) <- for a dyadic study, with multiple scans, PCA selected as motion correction, and 2 accelerometers.

1. Dataprefix string; prefix of every folder name that should be considered a data folder (e.g., MIN for MIN_101, MIN_102, etc.) 
2. Hyperscanning marker, boolean (1 if hyperscanning, 0 if single subject) 
3. Multiscan marker (1 if multiple scans per participant, 0 if single scan)
4. Preferred Motion correction (1 = baseline volatility, 1 = baseline volatility, 2 = PCFilter, 3 = PCA by channel, 4=CBSI, 5=Wavelet, 6=None) 

- No output arguments, but saves a .mat file of z-scored and non z-scored oxy, deoxy, and totaloxy matrices into a new folder called PreProcessedFiles 
(timepoint x channel). Also saves variables that would go into the .nirs format like t and s. 

- Requirements: besides dependencies installed, data must be in the following structure: MAIN_DIRECTORY/GROUP/SUBJECT/SCAN/raw files. 
Omit Group or Scan level if the data is not hyperscanning or not multiscan, respectively. All files must be together in each raw file folder. 
***All subjects and scans must start with a study-specific prefix***

# Known Difficulties
1. Since this is still being worked on, here are some known issues that might pop up and how to fix them right now:
 	- UPDATE: The problem below should be fixed. Please let me know if this problem is still occuring.
 If you get an "Index exceeds matrix dimensions" error in hmrMotionArtifact for a subject that's not the first file: Check the SD Mask structure in the .hdr 
 of that subject to see if it matches the channel structure of the selected probeInfo file. If the wrong probeInfo file was chosen, this will throw the error. 
 also happens if the wrong montage was selected in recording, Simply copy-paste the correct SD Mask and ChannelDistance list into the .hdr file from a 
 subject's .hdr file that had the correct montage. 
 
 2. Delete all false start files from the data directory, or will cause script to error out. 
	- UPDATE: If the script errored out while preprocessing but what was processing was done correctly you should be able to start from that point. However, probably
best to start fresh.

3. The main folder should be 'fNIRSpreProcessing' NOT 'fNIRSpreProcessing-main' remove the '-main' if so.

# FAQ Not Covered Above
- In helperScripts/practiceProcess.m is to get a better understanding of how the script is running through preprocessing. Do not use this if you are batch processing. The script is there for learning our pipeline.
- COMING SOON: I will have a video(s) with a walkthrough on how to use the script for different types of data.
