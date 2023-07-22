# fNIRSpreProcessing
SCN Lab current preprocessing pipeline (09/25/2022). For an older/different version see: https://github.com/smburns47/preprocessingfNIRS -- much of the credit is due to Shannon Burns for this pipeline as most of what has been done here was built upon her work. 

# General
UCLA SCN lab preprocessing pipeline for fNIRS data, collected with NIRx: NIRScout or NIRSport2 or you have a .nirs file. Will preprocess .Snirf files but only if you have Homer3 toolbox.

# Dependencies & Toolboxes
Included in repo: 
- Two publicly available Matlab packages - inpaint_nans and some Homer2 scripts
Not Included:
- MUST have MATLAB statistics and machine learning toolbox for nan based functions (will eventually fix this but for now you need the toolbox) & Signal Processing toolbox
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
- ALL dyads, subjects, and scan folders must start with a same prefix or they will be skipped. See '0_preProcessing/folderRename' if you have not named your folders accordingly.
	- Additionally, if using compile avoid same name scans with a number (scan_1, scan_2) either different names or no underscore after the scan name (scan1, scan2)

# Contents
Preprocessing is structured as 6-step pipeline: extracting raw data & auxiliary variable from files; trimming dead time; removing bad channels; motion correction of the data with your choice of correction; quality check for remaining unreliable channels after motion correction; compilation of data into one .mat file (optional). 
In addition, there is a prPreProcessing (folder 0) & postPreProcessing folder (folder 7). I highly reccomend using prePreProcessing to ensure your data is organized correctly and ready for preProcessing or else you will run into errors. 

Folders are for the most part organized in this step-based structure to more easily navigate to specific scripts if there is a problem or you want to modify. 

- FOLDER STRUCTURE
	- 0_prePreProcessing/
	- 1_design_extract/
		- functionBased/
	- 2_trimming/
	- 3_removeNoisy/
		- Inpaint_nans/
	- 4_filtering/
		- motionCorrs/
			- wavelet/
     		- raw_OD_concentration/
	- 5_qualityControl/
	- 6_compileData/
	- 7_postPreProcessing/
	- helperScripts/
		- In development/

- Currently there are six options for the input motionCorr: 
	- Volatility correction=1, PCfilter=2, PCA=3, CBSI=4, Wavelet=5, Short channel regression=6, or none=7. 
	- I'm leaning toward wavelet currently, but it is the longest and requires MATLAB wavelet toolbox.
	- Short channel regression is only possible if you collected data with short channels

# How to Use
To download: clone or pull repo to your desired local directory. After unzipping make sure to remove '-main' from the 'fNIRSpreProcessing' folder name. I also recommend having the pipeline in the same location as other toolboxes you may use like homer3. 

Once downloaded:
1. I recommend first using the pre-preProcessing to ensure you data is properly structured and ready for pre-processing.
2. Then run preprocessing with one of the 3 options described in the preprocessing section..
3. You can use post-preprocessing to compare motion correction or ensure you don't have wonky data.

# Pre-preprocessing: Data structure, triggers, and more
There is now a folder to check for the following before you start preprocessing. You can run these scripts seperately or use the prePREprocessing.m script to choose which functions you would like to run.

0. prePREprocessing.m: Turn on/off the below functions to ensure good data organization before running preprocessing.
1. folderRename.m: Your folders are missing the study prefix. This can be for some of the or all of them. It will only add the study prefix for the ones that are missing.
2. reOrganizeFolders.m: This will reorder the scans for a study so it is in the correct structure for preprocessing. Only use if the structure of you folders is wrong. This is most common for hyperscanning. The folders should be in the below structure.
	- studyPrefix_DyadNumber > studyPrefix_subjectNumber > studyPrefix_subjectNumber_scan
		- Example: ![image](https://user-images.githubusercontent.com/57020313/231604166-959df19a-429b-413c-89b3-456c9357d2a8.png)
3. countScans.m: Counts how many scans per subject and collects the names of the scan based on the first dyad/subject. 
4. triggerCheck.m: makes a new .mat of all the triggers in every scan so you can ensure you have the correct amount of triggers in the correct place. Won't change anything, this function is for reviewing triggers ONLY.
5. triggerChangeManual.m: You can delete, add, or modify triggers scan by scan with this script. Best used if you only have a few that need to be changed. See below section for how-to video.
6. triggerDuplicate.m: For hyperscanning ONLY. If your trigger is only in one of the subject's scan this will find it and then duplicate that trigger in the other subject's scan. Not needed if using the NIRScout ot single subjects scanning.

want to make sure you triggers are as they should be before running preprocessing (i.e., triggerCheck), or want to better understand the pipeline without having to run the entire function (i.e., practiceProcess).

# Preprocessing: from raw data to Hb change
For the main preprocesing I have created three options for how you prefer to run. If you are running into a lot of errors the second option may be best so you don't have to continually deal with pop-ups. 
1. runNIRSpreproc.mat is a script you can run with Gui pop-ups
2. manualPreProc.m is input only with no pop-ups
3. functionPreProc.mat as a function

For all three options of preprocessing the output will be the same, no outputs in the command window or workspace except elapsed time. 
A new folder will be created in the data directory called PreProcessedFiles that includes:
- Three .mat files for every individual scan (no channel rejection, noisy channel rejection, noisy & uncertain channels rejected)
	- z-scored and non z-scored 
		- oxy, deoxy, and totaloxy (timepoint x channel) 
		- t (time in seconds)
		- s (triggers) matrices 
	- mni coordinates as a .csv
- If you chose to compile the data it will also create a compile .mat of all the data named dataprefix_compile.mat (e.g., IPC_compile.mat). This compile will include the following:
	- Two 3D structures, oxy3D and deoxy3D, which include
		- Scan names, subject's NIRS data, t (time in seconds), triggers, aux, samprate, lost channels by subject (and scan if applicable)
			- If hyperscan, same structure but subject specific variables are doubled.
	- See below photo for examples of each type of 3D structure.
 ![compileStructure](https://github.com/abinnquist/fNIRSpreProcessing/assets/57020313/f44af584-f70b-43a2-a808-7013d9f48700)

OPTION 1: With GUI 6 pop-ups (no inputs)
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
		- NIRSport2 or .nirs file 
		- Snirf file (MUST have Homer3)
	4. Pop-up: Select location of where the data folder that contains all your NIRS data is
	5. Pop-up: If you want to compile the data into one .mat file. 
		- Note: You MUST have the same number of scans for every subject.
		- Run a quality check: 0=No, 1=Yes
		- ID length: Number of charaters after the dataprefix and before the scan names (e.g. IPC_101_rest = 5 or IPC101rest = 3)
		- Compile data: 0=No, 1=Yes
		- Number of scans: any number 1 to n. n=number of scans per subject
    		- Z-scored: 0=oxy/deoxy, 1=z_oxy/z_deoxy
    		- Channel rejection: 1=none, 2=noisy only, 3=noisy and uncertain 
	6. Pop-up (select one): Do you want to trim the data before preproc, if so how? 
		- No trim
		- Trim beginning of data from first trigger
		- Trim beginning of data from last trigger
		- Trim beginning of data with supplemental .mat
		- Trim beginning of data with supplemental spreadsheet (.csv, .xls, .xlsx)

	- NOTE: if using supplemental .mat or spreadsheet trim time MUST be in frames and in correct format
		- If using a .mat: 
			- Single subjects: 2D matrix (i.e., sub x scan) 
			- Hyperscan: 3D matrix (i.e., dyad x scan x sub)
		- If spreadsheet 2D regardless (i.e., one sheet):
			- Single subjects: sub x scan1, ... scanN
			- Hyperscan: dyad x scan1_sub1, ... scanNsubN
				
OPTION 2: Manual inputs (No pop-ups)
- Open manualPreProc.m from fNIRSPreProcessing/helperScripts folder 
- Change all the inputs that are specific to the data and what type of preprocessing you want to run. 
- Hit Run (big green triangle) on manualPreProc.m script, the script will add the paths for you. 

OPTION 3: As a function (3 pop-ups)
- In the command window: addpath(genpath('fNIRSpreProcessing')) 
- In the command window run the functionPreProc(dataprefix, hyperscan, multiscan, motionCorr, device, numaux)
- The function is in the fNIRSPreProcessing/helperScripts folder but no need to open it.
- The function takes 5 arguments and will also have 3 pop-ups: data directory, compile info, and trim info.
     - Example: preprocessingfNIRS('IPC', 1, 1, 3, 2, 2) <- for a dyadic study, with multiple scans, PCA selected as motion correction, collected with NIRSport2 (or .nirs file), and 2 accelerometers.

1. Dataprefix: prefix of every folder name that should be considered a data folder.Must be string or character format, even if it's a number ('0' or "0"; 'IPC' or "IPC"). 
2. Hyperscan: 1=hyperscanning, 0=single subject 
3. Multiscan: 1=multiple scans per participant, 0=single scan
4. Preferred Motion correction: 1=baseline volatility, 1=baseline volatility, 2=PCFilter, 3=PCA by channel, 4=CBSI, 5=Wavelet, 6=Short channel regression, 7=none 
5. Device: 1=NIRScout, 2=NIRSport2 or .nirs file, 3=.Snirf file (must have Homer3)
6. Number of Auxiliary: If you have 2 acceleromters or 1 pulse oximeter

# Post-preprocessing: compare motion correction, check data quality visually
This folder includes some scripts for checking the data or compiling the data if you chose not to do so during preprocessing.
1. plotCheck.m: Can visualize all subject data from a scan or selected subjects. You can also use this to compare different types of motion correction or no motion coreection.
2. reduceMagChans.m: This script is if you have channels that for some reason have very high magnitude change compared to the rest. It will reduce the change to the the average baseline of all the data (I am not 100% on this so  don't use if you don't have to).
3. postReduction.m: To compare pre- and post-high magnitude reduction. Will run some basic correlations to show how the magnitude can change subsequent analysis of the data.

# Helper Scripts: learning, preproc options, and post-stand alone 
This folder contains the second two options for preprocessing, a stand alone compile sript, and a stand alone script to create the mni coordinates
1. functionPreProc.m: function based version of the preprocessing script, will still have three pop-ups.
2. manualPreProc.m: input only version of the preprocessing script.
3. mniTableMaker.m: creates a .csv of the probe coordinates in MNI space (done in preprocessing but here for any reason you may need to make this at another time).
4. practiceProcess.m: to get a better understanding of how the script is running through preprocessing. Do not use this if you are batch processing. The script is there for learning our pipeline.
   
# Known Difficulties
1. Since this is still being worked on, here are some known issues that might pop up and how to fix them right now:
 	- UPDATE: The problem below should be fixed. Please let me know if this problem is still occuring.
 If you get an "Index exceeds matrix dimensions" error in hmrMotionArtifact for a subject that's not the first file: Check the SD Mask structure in the .hdr 
 of that subject to see if it matches the channel structure of the selected probeInfo file. If the wrong probeInfo file was chosen, this will throw the error. 
 also happens if the wrong montage was selected in recording, Simply copy-paste the correct SD Mask and ChannelDistance list into the .hdr file from a 
 subject's .hdr file that had the correct montage. 
 
 2. Delete all false start files from the data directory, or will cause script to error out. 
	- UPDATE: If the script errored out while preprocessing but what was processing was done correctly you should be able to start from that point. 

3. The main folder should be 'fNIRSpreProcessing' NOT 'fNIRSpreProcessing-main' remove the '-main' if so.
4. If you are having problems with the compile script this may be due to how you named your scans. I have yet to find a perfect fix if your naming system has something like: 
	- IP_scan_1, IP_scan_2, with IP being the prefix. This naming system will cause an error because of a duplicate scan name (i.e., scan). To fix this remove the second underscore to look like below.
		- IP_scan1, IP_scan2

# How-to Videos
I will have more video(s) soon but for trigger and visualization: https://www.youtube.com/@AshleyBinnquist

# FAQ Not Covered Above
- The "testQCoD.m" helper function. This tells you which channels are being marked as good and bad, and also visualizes the power spectral density of the raw signal in each 
fNIRS channel. Doing so is our current approach to finding bad channels (good channels have a preponderance of signal in slow frequencies, pure noise has random amounts of signal at every frequency). 
We're using a modified version of the quartile coefficient of dispersion (https://en.wikipedia.org/wiki/Quartile_coefficient_of_dispersion), abbreviated QCoD, to automatically decide which channels 
have good or bad signal. Essentially, it sums the frequency amplitudes in the first and fourth quartiles of the frequency range, and then compares them via (Q1-Q3)/(Q1+Q3). Larger QCoD is cleaner signal. 
Default threshold is set to 0.1 in preprocessingfNIRS. In testQCoD, change this to <0.1 to test allowing greater noise in the signal, or change to >0.1 for more stringency. Use this test function to 
check if the currently selected QCoD threshold for bad channel marking is what you want. Can be run on raw data, but does not do any other preprocessing. 
