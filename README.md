# fNIRSpreProcessing
SCN Lab current preprocessing pipeline (09/25/2022). For an older/different version see: https://github.com/smburns47/preprocessingfNIRS -- much of the credit is due to Shannon Burns for this pipeline as most of what has been done here was built upon her work. 

# General
UCLA SCN lab preprocessing pipeline for fNIRS data, collected with NIRx: NIRScout or NIRSport2. Will preprocess Snirf files but only if you have Homer3 toolbox.

# Gui-based or function options
runNIRSpreproc.mat is a script you can run with Gui pop-ups OR use prepreprocessingfNIRS.mat as a function that automates the SCN lab's current preprocessing pipeline for fNIRS data (originally written by Shannon Burns, 2018, MIT License). 
See below for more details on each step of the pipeline, and how to use this code yourself. 

# Dependencies & Toolboxes
Included in repo: 
- Two publicly available Matlab packages - inpaint_nans and some Homer2 scripts
Not Included:
- MUST have MATLAB statistics and machine learning toolbox for nan based functions (will eventually fix this but for now you need the toolbox)
- If using Snirf file for preprocessing you MUST have Homer3 link below
	- Homer3 toolbox at https://github.com/BUNPC/Homer3 
- If using wavelet motion correction MUST have the MATLAB wavelet toolbox
- If using the PCfilter motion correction MUST have the MATLAB mapping toolbox

# Other Requirements 
NOTE: Hyperscan should work for 2+ subjects per group, so if you ran two hyperscans for a total of four subjects per group the script should still work as long as the folder structure is followed as shown below
- Data must be in the following structure: 
	- Hyper with multiple scans: MAIN_DIRECTORY/GROUP/SUBJECT/SCAN/raw files. 
	- Hyper w/ one scan: MAIN_DIRECTORY/GROUP/SUBJECT/raw files.  
	- Solo w/ multiple scans: MAIN_DIRECTORY/SUBJECT/SCAN/raw files. 
	- Solo w/ one scan: MAIN_DIRECTORY/SUBJECT/raw files. 
- All files must be together in each raw file folder 
- ALL dyads, subjects, and scan folders must start with a same prefix or they will be skipped. See 'helperScripts/folderRename' if you have not named your folders accordingly.
	- Additionally, if using compile avoid same name scans with a number (scan_1, scan_2) either different names or no underscore after the scan name (scan1, scan2)

# Contents
Preprocessing is structured as 6-step pipeline: extracting raw data & auxiliary variable from files; trimming dead time; removing bad channels; motion correction of the data with your choice of correction; quality check for remaining unreliable channels after motion correction; compilation of data into one .mat file (optional). 

Please see comments in runNIRSPreproc.m file to read about specific functionality. Folders are for the most part organized in this step-based structure to more easily navigate to specific scripts if there is a problem or you want to modify. 

- FOLDER STRUCTURE
	- 0_designOptions/
	- 1_extractFuncs/
	- 2_trimming/
	- 3_removeNoisy/
		- Inpaint_nans/
	- 4_filtering/
		- motionCorrs/
			- wavelet/
     		- raw_OD_concentration/
	- 5_qualityControl/
	- 6_compileData/
	- helperScripts/
		- In development/

- Currently there are five options asked for by the input motionCorr: 
	- Volatility correction=1, PCfilter=2, PCA=3, CBSI=4, Wavelet=5, or none=6. 
	- I'm leaning toward wavelet currently, but it is the longest and requires MATLAB wavelet toolbox.

- The "testQCoD.m" helper function. This tells you which channels are being marked as good and bad, and also visualizes the power spectral density of the raw signal in each 
fNIRS channel. Doing so is our current approach to finding bad channels (good channels have a preponderance of signal in slow frequencies, pure noise has random amounts of signal at every frequency). 
We're using a modified version of the quartile coefficient of dispersion (https://en.wikipedia.org/wiki/Quartile_coefficient_of_dispersion), abbreviated QCoD, to automatically decide which channels 
have good or bad signal. Essentially, it sums the frequency amplitudes in the first and fourth quartiles of the frequency range, and then compares them via (Q1-Q3)/(Q1+Q3). Larger QCoD is cleaner signal. 
Default threshold is set to 0.1 in preprocessingfNIRS. In testQCoD, change this to <0.1 to test allowing greater noise in the signal, or change to >0.1 for more stringency. Use this test function to 
check if the currently selected QCoD threshold for bad channel marking is what you want. Can be run on raw data, but does not do any other preprocessing. 

# How to Use
To download: clone or pull repo to your desired local directory. After unzipping make sure to remove '-main' from the 'fNIRSpreProcessing' folder name. I also recommend having hte pipeline in the same location as other toolboxes you may use like homer3. 

Pre-preprocessing: There are scripts in 'helperScripts' in case you have named your folders incorrectly (i.e., folderRename'), want to make sure you triggers are as they should be before running preprocessing (i.e., triggerCheck), or want to better understand the pipeline without having to run the entire function (i.e., practiceProcess).

OPTION 1: With GUI pop-ups 
- Open runNIRSPreproc.m from main fNIRSPreProcessing folder 
- Hit Run (big green triangle) on runNIRSPreproc.m script, the script will add the paths for you. 
- You will get a series of pop-ups described below
	1. Pop-up (4 inputs): 
		- Dataprefix for all folders of interest: Letters or numbers (e.g., IPC, SS, 0)
		- Hyperscan: 0=no, 1=yes 
		- Multiple scans per subject/dyad: 0=no, 1=yes
		- Number of auxiliaries: 0-n (n=however many you have)
	2. Pop-up (select one): What type of motion correction do you want to use?
	3. Pop-up (select one): What machine collected the data? 
		- NIRScout 
		- NIRSport 
		- Snirf file (MUST have Homer3)
	4. Pop-up: Select location of where the data folder that contains all your NIRS data is
	5. Pop-up (select one): Do you want to trim the data before preproc, if so how? 
		- No trim
		- Trim from first trigger
		- Trim begginning with supplemental .csv
		- Trim begginning & end with supplemental .csv
			- Structure of .csv below, handles 1-n scans per subject: 
				- column_1 = subject or dyad number
    				- column_2 = 1st scan where to start trim
    				- column_3 = 1st scan length
    				- column_4 = 2nd scan start trim
    				- column_5 = 2nd scan length
    				- column_n*2 = nth scan start trim
    				- column_n*2+1 = nth scan length
	6. Pop-up: If you want to compile the data into one .mat file. 
		- Note: You MUST have the same number of scans for every subject.
		- Compile data: 0=No, 1=Yes
		- Number of scans: any number 1 to n. n=number of scans per subject
    		- Z-scored: 0=oxy/deoxy, 1=z_oxy/z_deoxy
    		- Channel rejection: 1=none, 2=noisy only, 3=noisy and uncertain 

OPTION 2: as a function
- In the command window: addpath(genpath('fNIRSpreProcessing')) 
- Run the function preprocessingfNIRS from the command window
- takes 5 arguments: preprocessingfNIRS(dataprefix, hyperscan, multiscan, motionCorr, numaux)
     - Example: preprocessingfNIRS('IPC', 1, 1, 3, 2) <- for a dyadic study, with multiple scans, PCA selected as motion correction, and 2 accelerometers.

1. Dataprefix string: prefix of every folder name that should be considered a data folder (e.g., MIN for MIN_101, MIN_102, etc.) 
2. Hyperscanning marker: 1=hyperscanning, 0=single subject 
3. Multiscan marker: 1=multiple scans per participant, 0=single scan
4. Preferred Motion correction: 1=baseline volatility, 1=baseline volatility, 2=PCFilter, 3=PCA by channel, 4=CBSI, 5=Wavelet, 6=None 
5. Number of Auxiliary: If you have 2 acceleromters or 1 pulse oximeter

- No output arguments, but saves a .mat file of z-scored and non z-scored oxy, deoxy, and totaloxy matrices into a new folder called PreProcessedFiles 
(timepoint x channel). Also saves variables that would go into the .nirs format like t and s. 

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
4. If you are having problems with the compile script this may be due to how you named your scans. I have yet to find a perfect fix if your naming system has something like: 
	- IP_scan_1, IP_scan_2, with IP being the prefix. This naming system will cause an error because of a duplicate scan name (i.e., scan). To fix this remove the second underscore to look like below.
		- IP_scan1, IP_scan2

# FAQ Not Covered Above
- In helperScripts/practiceProcess.m is to get a better understanding of how the script is running through preprocessing. Do not use this if you are batch processing. The script is there for learning our pipeline.
- COMING SOON: I will have a video(s) with a walkthrough on how to use the script for different types of data.
