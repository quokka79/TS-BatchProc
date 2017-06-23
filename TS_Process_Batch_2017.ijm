/*
 *========================================================================================================================
 * 		Dave's Attempt at a Batch Processor Macro for ThunderSTORM
 *========================================================================================================================
 *	
 *	Tested with:
 *    - Fiji (latest) ImageJ 1.51j
 *	  - ThunderSTORM dev-2015-10-03-b1
 *
 *	This version does: 			ND2 and TIF stack processing (possibly LIF as well, but not tested)
 * 								post-processing file arrangement
 * 								saves tables and preview images for each step (allevents, filtered, filt+drift corrected, filt+drift+merging)
 * 								reprocesses files from previous batch-processing.
 * 								
 *	This version does not do:	channel warping/alignment, loading of existing drift files.
 * 
 *	Change settings in the sections headed 'General Variables' and 'ThunderSTORM Variables'
 * 
 */

// Initialise the variable arrays
var AnalysisParams;
var FilteringParams;
var DriftCorrParams;
var MergingParams;
var RenderingParams;
var CameraParams;
AnalysisParams = newArray(29);
DriftCorrParams = newArray(6);
MergingParams = newArray(4);
RenderingParams = newArray(11);
CameraParams = newArray(6);
CameraPerf = newArray(12);


/*========================================================================================================================
 * 		General settings
 *========================================================================================================================
 */

ImportFileExt = 				".csv";		// File extension when importing data files, i.e. your raw image data file extension, e.g. .nd2 or .tif etc. For re-processing from a previous batch-proc, use the extension that you exported the data tables, e.g. .csv.

OutputFolderName = 			"Proc";			// Name of folder that will be created to hold output data tables etc.
OutputFolderAppendUID = 	"datestamp";	// Will add a unique ID to the end of the folder name given above (e.g. to avoid overwriting existing data). Use either "random" or "datestamp".
OrganiseOutputFiles = 		false;			// Protocols, preview images, and drift plots will be stored in their own folders. This can make the output a bit neater and easier to manage but see note below...
											// NOTE: If you want to do reprocessing then you will need to copy/move the protocol files into the same folder as the exported data files. Or set this to false when you do the initial procesing.

/*========================================================================================================================
 * 		Initial localization settings
 *========================================================================================================================
 */

// Image Filtering
AnalysisParams[0] = 		"Wavelet filter (B-Spline)";	// filter type
AnalysisParams[1] = 		"2.0";							// B-spline scale
AnalysisParams[2] = 		"3";							// B-spline order

// Approximate localisation of molecules
AnalysisParams[3] = 		"Non-maximum suppression";	// Approximate detection method: Non-maximum suppression, Local Maximum, Centroid of connected components
AnalysisParams[5] = 		"std(Wave.F1)";				// Intensity threshold
AnalysisParams[17] = 		"1";						// dilation radius (Non-maximum Suppression)	
AnalysisParams[4] = 		"8-neighbourhood";			// Connectivity (Local Maximum)
AnalysisParams[28] = 		"true";						// WatershedSegmentation true/false (Centroid of connected components)

// Sub-pixel localisation
AnalysisParams[6] = 		"PSF: Integrated Gaussian";	// Sub-pixel localisation estimator
AnalysisParams[9] = 		"3";						// Fitting radius
AnalysisParams[8] = 		"Maximum likelihood";		// Fitting method
AnalysisParams[7] = 		"1.6";						// Initial sigma (px)

// Multi-emitter fitting
AnalysisParams[10] = 		"false";				// multi-emitter fiting enabled?
AnalysisParams[18] = 		"false";				// full_image_fitting
AnalysisParams[21] = 		"3";					// nmax
AnalysisParams[22] = 		"1.0E-6";				// pvalue
AnalysisParams[23] = 		"false";				// keep_same_intensity
AnalysisParams[20] = 		"true";				// Limit intensity range
AnalysisParams[19] = 		"500:2500";				// Intensity range (photons) if above is true

// Image rendering - applied during processing only (see post-processing options below)
// Leave this off ("No Renderer" to disable preview rendering and speed things up
//  A preview of each image is saved at the end of the detection.
AnalysisParams[11] = 		"No Renderer";			// Change to a render type if you really want to see a progress image during the detection phase.
AnalysisParams[12] = 		"5.0";					// magnification
AnalysisParams[13] = 		"true";					// colorize z-values
AnalysisParams[14] = 		"2";					// histogram shifts
AnalysisParams[15] = 		"5000";					// update frequency (frames)
AnalysisParams[16] = 		"false";				// 3D rendering?
AnalysisParams[24] = 		"false";				// dxforce
AnalysisParams[25] = 		"20.0";					// dx
AnalysisParams[26] = 		"false";				// dzforce
AnalysisParams[27] = 		"100.0";				// dz

//EMCCD Camera information
//	NB: If you set anything to "auto" here you will need to check that the values applied below match those for your camera!
CameraParams[1] = 		"auto";				// (pixelSize=) input image pixel scale, 	auto = reads from metadata
CameraParams[2] = 		"auto";				// (gain=) EM Gain value, 					auto = reads from metadata
CameraParams[3] = 		"auto";				// (offset=) Base count offset (noise), 	auto = reads from metadata
CameraParams[4] = 		"auto";				// (photons2ADU=) Sensitivity, 				auto = reads from metadata
CameraParams[5] = 		"1.0";				// (quantumEfficiency=) Quantum efficiency. This is usually assumed to be 1.0 always (there's no 'auto' option).
CameraParams[0] = 		"true";				// (isEmGain=) Did you use camera gain? This is usually assumed to be true always (there's no 'auto' option).

// EMCCD Camera Performance
// Metadata keywords - Explore the metadata by opening an image and pressing 'i' for Image Info. Scroll until you find the values you need.
// Generally these phrases are stable unless your provider does some major software restructuring.
MetaDataWord_Gain = 		"GainMultiplier";		// The phrase used to identify camera gain (200 to 300 usually)
MetaDataWord_PixelSize = 	"dCalibration";			// Pixel size, in um per pixel (usually around 160 nm per pixel or 100 nm per pixel)
MetaDataWord_Readout = 		"Readout Speed";		// Should be 17 MHz
MetaDataWord_PreAmp = 		"Conversion Gain";		// Internal conversion gain setting (1, 2, or 3)

// 17 Mhz Readout Rate
CameraPerf[0] =			"99.74";			// PreAmp Gain 3 Noise
CameraPerf[1] =			"5.32";				// PreAmp Gain 3 Sensitivity
CameraPerf[2] =			"162.88";			// PreAmp Gain 2 Noise
CameraPerf[3] =			"9.12";				// PreAmp Gain 2 Sensitivity
CameraPerf[4] =			"249.62";			// PreAmp Gain 1 Noise
CameraPerf[5] =			"15.62";			// PreAmp Gain 1 Sensitivity

// 10 Mhz Readout Rate
CameraPerf[6] =			"65.86";			// PreAmp Gain 3 Noise
CameraPerf[7] =			"4.84";				// PreAmp Gain 3 Sensitivity
CameraPerf[8] =			"93.03";			// PreAmp Gain 2 Noise
CameraPerf[9] =			"7.87";				// PreAmp Gain 2 Sensitivity
CameraPerf[10] =		"163.65";			// PreAmp Gain 1 Noise
CameraPerf[11] =		"15.06";			// PreAmp Gain 1 Sensitivity


/*========================================================================================================================
 * 		Post Processing settings
 *========================================================================================================================
 */
 
// ORDER OF POST-PROCESSING
// Must be at least one of these phrases:
//	 	Filter		DensityFilter		RemoveDuplicates		Merging		DriftCorrection		ZStageOffset
// If you don't want to do a particular type of post-processing simply don't include it!

PostProcOrder = 	newArray("Filter", "DriftCorrection", "Merging"); 	
// !IMPORTANT! When changing this, make sure you add/remove a matching true/false statements for
// saving tables (SavePostProcessedTables) and preview-images (SavePostProcessedPreviewImgs), lines below.
// e.g. if you have three post-proc steps, then you need three true/false statements. If you have two pp steps you need two such statements

// DATA TABLES & PREVIEW IMAGES
SavePostProcessedTables  =		newArray(false, true, true);		// Save a data table for these steps? Matches to same position in PostProcOrder, above.
SavePostProcessedPreviewImgs = 	newArray(false, true, true);		// Save a preview image for these steps? Matches to same position in PostProcOrder, above.


// Remove Duplicates parameters
RemoveDuplicatesParams = 	"uncertainty_xy";

// Filtering parameters
FilteringParams = 		"intensity > 150 & intensity < 10000 & sigma > 50 & sigma < 250 & uncertainty_xy < 30";
			// options (common) :	 	uncertainty_xy , sigma , intensity 
			// options (less common): 	id , frame , x , y , offset , bkgstd
			// options (special):		detections (available after merging), chi2 (if doing least squares detection), uncertainty_z (if doing 3D)
			
// Drift Correction parameters
DriftCorrParams[0] = 		"5";					// magnification
DriftCorrParams[1] = 		"Cross correlation";	// type of correction
DriftCorrParams[2] = 		"false";				// save file to path
DriftCorrParams[3] = 		"5";					// steps/bins
DriftCorrParams[4] = 		"false";				// show correlation plot (this isn't the drift plot)
SaveDriftPlot = 			true;					// Save the drift-correction diagram?

// Merging parameters
MergingParams[0] = 		"0.1";				// z-coordinate weight
MergingParams[1] = 		"25";					// off-frames (mergeable events can be separated by up to this much dark-time)
MergingParams[2] = 		"50";				// search radius (mergeable events can be this far away from initial event)
MergingParams[3] = 		"0";					// maximum number of consecutive frames such that a repeating event is still considered a single molecule.

// Other data table and preview options
SaveTable_Allevents = 		true;				// The table of all identified events (before any post-processing is performed) It's a good idea to save this if you plan to do any re-processing of the data later!
SavePreview_Allevents = 	true;				// Save an image of the initial detection, before any post-processing steps?
SaveTableForBayes = 		false;				// Save a table suitable for Bayesian Clustering Analysis (x,y,uncertainty cols only)

// Naming of the output tables -- if the post-processing step is performed, its matching suffix will be appended in the file name.
// The order in the filename will reflect the order that you specified in the post-processing chain, given earlier.
Suffix_AllEvents = 			"";
Suffix_Filtered = 			"Fil";
Suffix_RemoveDuplicates = 	"RemDup";
Suffix_Merging = 			"Mrg";
Suffix_DriftCorrection = 	"DriCor";
Suffix_ForBayes = 			"_Bayes";

// Exported data table format
SaveTable_Format = 			"CSV (comma separated)"		// Other options must be given as: "XLS (tab separated)" , "XML" , "JSON" , "YAML" , "Google Protocol Buffer" , "Tagged spot file"
OutputFileExt = 			".csv";						// File extension of the output data tables

// Columns to include when exporting a data table (excluding the final Bayes table)
// For excellent and sensible reasons, these true/false values need to be in quotes ("")...
Save_Protocol =			"true";
Save_Col_ID =			"true";
Save_Col_Frame =		"true"; 
Save_Col_x_Coord =		"true";
Save_Col_y_Coord =		"true";
Save_Col_Sigma =		"true";
Save_Col_Intensity =	"true"; 
Save_Col_Offset =		"true";
Save_Col_Bkgstd =		"true";
Save_Col_Uncertainty =	"true";
Save_Col_Detections =	"true";				// available if doing merging
Save_Col_Chi2 =			"false";			// available if doing least squares fitting

//Image rendering - applied to post-processing preview images only
RenderingParams[0] = 		"0.0"; 					//imleft
RenderingParams[1] = 		"0.0"; 					//imtop
RenderingParams[2] = 		"256.0"; 				//imwidth, size in pixels of raw input images
RenderingParams[3] = 		"256.0"; 				//imheight
RenderingParams[4] = 		"Normalized Gaussian";	//Render style
RenderingParams[5] = 		"10.0"; 				//Magnification
RenderingParams[6] = 		"false"; 				//dxforce
RenderingParams[7] = 		"20.0"; 				//dx
RenderingParams[8] = 		"false"; 				//colorizez
RenderingParams[9] = 		"false"; 				//threed (3D)
RenderingParams[10] = 		"false"; 				//dzforce

// HistogramStats - To come

/*========================================================================================================================
 * 		Begin Processing
 (Do no edit below this line. All useful variables are above this line)
 *========================================================================================================================
 */
current_version_script = "1.04";
ReprocessingExistingData = false; // This will change when the script finds processed data.

if ((PostProcOrder.length ! = SavePostProcessedTables.length) || (PostProcOrder.length ! = SavePostProcessedPreviewImgs.length) || (SavePostProcessedTables.length ! = SavePostProcessedPreviewImgs.length)) {
	ProcErrorMessage= "--------------------------------------------------------------------------------------------\n" + 
		      "   Error! \n" + 
		      "--------------------------------------------------------------------------------------------\n\n" + 
		      "   Please check your macro settings: \n" + 
		      "   These variables need to ALL have the same number of values: \n\n" + 
		      "       " + PostProcOrder.length + " values for PostProcOrder\n" + 
		      "       " + SavePostProcessedTables.length + " values for SavePostProcessedTables\n" + 
		      "       " + SavePostProcessedPreviewImgs.length + " values for SavePostProcessedPreviewImgs\n" + 
		      "--------------------------------------------------------------------------------------------\n\n";
	Dialog.create("Batch Processing Error");
	Dialog.addMessage(ProcErrorMessage);
	Dialog.show();
	exit();
}

 
//===== Gather info, set up folder ======

InputFolder = getDirectory("Choose directory where your input files are stored");

var AllFilesInDir;
AllFilesInDir= getFileList(InputFolder);

var numberOfInputFiles = 0;
numberOfInputFiles = countInputFiles(ImportFileExt);

if (numberOfInputFiles > 0) {

	var ListInputFiles;
	ListInputFiles = getImagesContaining(ImportFileExt);
	numberOfInputFiles = ListInputFiles.length; // update the number of files now that we've (possibly) excluded some from consideration

	var SaveFileNames;
	SaveFileNames = cleanFileNames(ImportFileExt);
	
	if(ImportFileExt == ".csv" || ImportFileExt == ".xls" || ImportFileExt == ".xml" || ImportFileExt == ".yaml" || ImportFileExt == ".json" || ImportFileExt == ".tsf" ) {
		ReprocessingExistingData = true;
	}

	// Housekeeping - create the output folder
	OutputFolderUID = "";	
	if (OutputFolderAppendUID == "random") {
		OutputFolderUID = genUID("random");
	}
	if (OutputFolderAppendUID == "datestamp") {
		OutputFolderUID = genUID("datestamp");
	}
	OutputFolder = InputFolder + OutputFolderName + OutputFolderUID + File.separator;
	File.makeDirectory(OutputFolder);
	
	DriftCorrParams[5] = OutputFolder;			//we can now set this variable 'path' for saving drift files;

	// clear out any unused memory before we load the big files
	CollectTheTrash();

	StopWatchTotal = getTime(); // Start the overall processing timer
	
} else {
	// No useable files! Push a dialog box and hope they click Cancel...
	ProcMessage = "----------------------------------------------------\n" +
				  "   Folder contains no " + ImportFileExt + " files! \n" +
				  "   Click *CANCEL* to exit the macro now. \n" + 
				  "----------------------------------------------------\n\n";
	Dialog.create("Batch Processing Problem...");
	Dialog.addMessage(ProcMessage);
	Dialog.show();
}


//===== Show variables and accept any changes ======

// Set up the log window
f1 = "[ThunderSTORM Batch Processor Log]";

if (isOpen("ThunderSTORM Batch Processor Log")) { 
	selectWindow("ThunderSTORM Batch Processor Log");
	print(f1,"\n\n\n");
} else {
	run("Text Window...", "name="+f1+" width=80 height=40");
}
	
print(f1,"--------------------------------------------------------------------------------------\n");
print(f1,"     ThunderSTORM Batch Processor \t (DW ver-" + current_version_script + ")\n");
print(f1,"--------------------------------------------------------------------------------------\n");
print(f1,"\n");
if (numberOfInputFiles==1) {
	print(f1,"\t" + TimeStamp() + "\tProcessing "+ numberOfInputFiles + " image.\n");
} else {
	print(f1,"\t" + TimeStamp() + "\tProcessing "+ numberOfInputFiles + " images.\n");
}
print(f1,"\n");
print(f1," Source:\t" + InputFolder  + "\n");
print(f1," Output:\t" + OutputFolder + "\n");
print(f1,"\n");

setBatchMode(true);


//===== Set the camera info ======

if (((CameraParams[4] == "auto") & (CameraParams[3] != "auto")) | ((CameraParams[3] == "auto") & (CameraParams[4] != "auto"))) {
	exit("Uh-oh! Problem with EMCCD Camera Properties\nYou must set both Noise and Sensitivity to 'auto' or specify a number for both.\nOne can't be auto and the other not...");
}

// Apply camera settings that are not set to 'auto'

CameraParamsStringUser = "quantumEfficiency="+CameraParams[5];

if (CameraParams[1] != "auto") {
	// Apply camera settings using the user-supplied gain
	CameraParamsStringUser = CameraParamsStringUser + " pixelsize="+CameraParams[1]);
}

if (CameraParams[2] != "auto") {
	// Apply camera settings using the user-supplied gain
	CameraParamsStringUser = CameraParamsStringUser + " isemgain=true gainem="+CameraParams[2]);
}

if (CameraParams[3] != "auto") {
	// Apply camera settings using the user-supplied offset (noise)
	CameraParamsStringUser = CameraParamsStringUser + " offset="+CameraParams[3]);
}

if (CameraParams[4] != "auto") {
	// Apply camera settings using the user-supplied sensitivity
	CameraParamsStringUser = CameraParamsStringUser + " photons2adu="+CameraParams[4]);
}

//===== Start of processing loop ======

for(i = 0; i < ListInputFiles.length; i++) {

	StopWatchA = getTime(); // Start the processing timer

	print(f1, " [" + i+1 + "/" + numberOfInputFiles + "]\t" + SaveFileNames[i] + "\n");

	if (ReprocessingExistingData) {

		print(f1,"\tLoading data table for reprocessing... ");
		run("Import results", "filepath=[" + InputFolder+ListInputFiles[i] + "] fileformat=[CSV (comma separated)] append=false startingframe=1 rawimagestack= livepreview=false");	
		print(f1," done. \n");
		
	} else {
	
		print(f1,"\tLoading raw image data for localisation processing... ");
		run("Bio-Formats Importer", "open='" + InputFolder+ListInputFiles[i] + "' color_mode=Default view=[Standard ImageJ] stack_order=Default virtual");
		print(f1," done. \n");
		
		if ((CameraParams[1] == "auto") | (CameraParams[2] == "auto") | (CameraParams[3] == "auto") | (CameraParams[4] == "auto") ){
			print(f1,"\tUsing metadata to set remaining camera parameters:\n");

			CameraParamsStringAuto = CameraParamsStringUser;

			if (CameraParams[1] == "auto") {
				// Reapply camera settings using the pixel size from metadata
				MyCameraPixelSize = floor(1000000 * GetMetaDataValue(MetaDataWord_PixelSize))/1000;	// ND2 stores this as um/px but ThunderSTORM needs nm/px :)
				CameraParamsStringAuto = CameraParamsStringAuto + " pixelsize="+MyCameraPixelSize;
				print(f1,"\tPixel Size = "+MyCameraPixelSize+" nm/px");
			}
	
			if (CameraParams[2] == "auto") {
				// Reapply camera settings using the image gain from metadata
				MyCameraGain = GetMetaDataValue(MetaDataWord_Gain);	
				CameraParamsStringAuto = CameraParamsStringAuto + " isemgain=true gainem="+MyCameraGain;
				print(f1,"\tGain = "+MyCameraGain);
			}
	
			if ((CameraParams[4] == "auto") & (CameraParams[3] == "auto")) {
			
				// Get metadata
				ReadoutSpeed = GetMetaDataValue(MetaDataWord_Readout);
				PreAmpConvGain = GetMetaDataValue(MetaDataWord_PreAmp);
					
				if (ReadoutSpeed == 17) {
					if (PreAmpConvGain == " Gain 3") {			// Readout = 17 Mhz, Preamp = Gain 3
						MyCameraOffset = CameraPerf[0];		//Noise
						MyCameraSensitivity  = CameraPerf[1];	//Sensitivity
					}
					if (PreAmpConvGain == " Gain 2") {			// Readout = 17 Mhz, Preamp = Gain 2
						MyCameraOffset = CameraPerf[2];		//Noise
						MyCameraSensitivity = CameraPerf[3];	//Sensitivity
					}
					if (PreAmpConvGain == " Gain 1") {			// Readout = 17 Mhz, Preamp = Gain 1
						MyCameraOffset = CameraPerf[4];		//Noise
						MyCameraSensitivity = CameraPerf[5];	//Sensitivity
					}
				}
				if (ReadoutSpeed == 10) {
					if (PreAmpConvGain == " Gain 3") {			// Readout = 17 Mhz, Preamp = Gain 3
						MyCameraOffset = CameraPerf[6];		//Noise
						MyCameraSensitivity  = CameraPerf[7];	//Sensitivity
					}
					if (PreAmpConvGain == " Gain 2") {			// Readout = 17 Mhz, Preamp = Gain 2
						MyCameraOffset = CameraPerf[8];		//Noise
						MyCameraSensitivity = CameraPerf[9];	//Sensitivity
					}
					if (PreAmpConvGain == " Gain 1") {			// Readout = 17 Mhz, Preamp = Gain 1
						MyCameraOffset = CameraPerf[10];		//Noise
						MyCameraSensitivity = CameraPerf[11];	//Sensitivity
					}
				}
				CameraParamsStringAuto = CameraParamsStringAuto + " offset="+MyCameraOffset +" photons2adu="+MyCameraSensitivity;	
				print(f1,"\tNoise = "+MyCameraOffset +"\tSensitivity = "+MyCameraSensitivity);
			}
			print(f1,".\n");
			run("Camera setup", CameraParamsStringAuto);
			// print(f1,"\tCamera Settings: "+CameraParamsStringAuto+"\n");
		}

		// Initial detection
		print(f1,"\tIdentifying events... ");
		DoMainProcessing();
		if (SaveTable_Allevents) {
			filenameOut = OutputFolder+SaveFileNames[i]+Suffix_AllEvents+OutputFileExt;
			SaveProcessedTable(filenameOut);
		}
		if (SavePreview_Allevents) {
			filenameOutPreview = OutputFolder+SaveFileNames[i]+Suffix_AllEvents;
			SavePreviewImage(filenameOutPreview);
		}
		print(f1," done.\n");
		// end initial detection block

		// wait(2000);  // this might be necessary if your detection finishes too soon (e.g. on test images with only a few frames)
		
	}

// ==== Post Processing ====
	
	filenameOutPostProcessing = OutputFolder+SaveFileNames[i];
	
	for(pp = 0; pp < PostProcOrder.length; pp++) {

	// Filter event list
		if (PostProcOrder[pp]=="Filter") {
		
			print(f1,"\tFiltering...");
			filenameOutPostProcessing = filenameOutPostProcessing+Suffix_Filtered;
			
			DoFiltering();
			if (SavePostProcessedTables[pp]) {
				filenameOutFiltered = filenameOutPostProcessing+OutputFileExt;
				SaveProcessedTable(filenameOutFiltered);
			}
			if (SavePostProcessedPreviewImgs[pp]) {
				SavePreviewImage(filenameOutPostProcessing);
			}
			print(f1," done.\n");
			
		}
	// end filtering block
	
// Check size of table here. If zero events then give an error!
	
	// Density filter - not yet used
		if (PostProcOrder[pp]=="DensityFilter") {
			print(f1,"\tDensity Filtering: skipped! This is not yet implemented in the batch processor!\n");
		}
	// end density filtering block

	
	// Remove Duplicates
		if (PostProcOrder[pp]=="RemoveDuplicates") {
		
			print(f1,"\tRemove Duplicates...");
			filenameOutPostProcessing = filenameOutPostProcessing+Suffix_RemoveDuplicates;
			
			DoRemoveDuplicates();
			if (SavePostProcessedTables[pp]) {
				filenameOutDuplicatesRemoved = filenameOutPostProcessing+OutputFileExt;
				SaveProcessedTable(filenameOutDuplicatesRemoved);
			}
			if (SavePostProcessedPreviewImgs[pp]) {
				SavePreviewImage(filenameOutPostProcessing);
			}
			print(f1," done.\n");
			
		}
	// end remove duplicates block

	
	// Merge re-blinkers
		if (PostProcOrder[pp]=="Merging") {
		
			print(f1,"\tMerging...");
			filenameOutPostProcessing = filenameOutPostProcessing+Suffix_Merging;
			
			DoMerging();
			if (SavePostProcessedTables[pp]) {
				filenameOutMerged = filenameOutPostProcessing+OutputFileExt;
				SaveProcessedTable(filenameOutMerged);
			}
			if (SavePostProcessedPreviewImgs[pp]) {
				SavePreviewImage(filenameOutPostProcessing);
			}
			print(f1," done.\n");
		}
	//end merging block
	
		
	// Correct for sample drift
		if (PostProcOrder[pp]=="DriftCorrection") {
		
			print(f1,"\tDrift Correction...");
			filenameOutPostProcessing = filenameOutPostProcessing+Suffix_DriftCorrection;
			
			DoDriftCorrection();
			if (SaveDriftPlot) {
				selectWindow("Drift");
				saveAs("PNG", OutputFolder+SaveFileNames[i]+"_DriftDiag.png");
				close();
				selectWindow("ThunderSTORM: results");
			}
			if (SavePostProcessedTables[pp]) {
				filenameOutDriftCorr = filenameOutPostProcessing+OutputFileExt;
				SaveProcessedTable(filenameOutDriftCorr);
			}
			if (SavePostProcessedPreviewImgs[pp]) {
				SavePreviewImage(filenameOutPostProcessing);
			}
			print(f1," done.\n");
			
		}
	// end drift correction block

	
	
	// Z-stage offset - Not yet used
		if (PostProcOrder[pp]=="ZStageOffset") {
			print(f1,"\tZ-Stage Offset.: skipped! This is not yet implemented in the batch processor!\n");
		}
	// end z-stage offset block

	}
	
	
	if (SaveTableForBayes) {
		filenameOutForBayes = OutputFolder+SaveFileNames[i]+Suffix_ForBayes+OutputFileExt;
		run("Export results", 
		"filepath=["+ filenameOutForBayes + "]" +  
		" file=[CSV (comma separated)]" +
		" saveprotocol=true" +
		" id=false" +
		" frame=false" +
		" x=true" +
		" y=true" +
		" sigma=false" + 
		" intensity=false" +
		" offset=false" +
		" bkgstd=false" +
		" uncertainty_xy=true" + 
		" detections=false" + 
		" chi2=false");
	}
	

	// Report processing time for this image
	StopWatchB = getTime();
	TimeElapsedStr = TimeElapsed(StopWatchA,StopWatchB);
	print(f1,TimeStamp() + "\tProcessed this image in " + TimeElapsedStr + ".\n");
	print(f1,"\n");

	// Wait for things to calm down, close any open images and run garbage collection
	wait(2000); 
	run("Close All");
	wait(2000); 
	CollectTheTrash();
	wait(2000);
}
//===== End of processing loop ======

print(f1," Tidying up... ");
if (OrganiseOutputFiles) {
	OutputFileOrganizer(OutputFolder);
}
run("Close All");
print(f1,"done!\n");

setBatchMode(false);
StopWatchFinal = getTime();
TimeElapsedStr = TimeElapsed(StopWatchTotal,StopWatchFinal);
print(f1,"\n");

print(f1,"--------------------------------------------------------------------------------------\n");
print(f1,"     Batch Processing Complete in " + TimeElapsedStr + ".\n");
print(f1,"--------------------------------------------------------------------------------------\n");
print(f1,"\n");

ProcMessage = "----------------------------------------------------\n" + 
	      "   Batch Processing Complete! \n" + 
	      "----------------------------------------------------\n\n" + 
	      "   Please check your output folder: \n" + 
	      "     " + OutputFolder + "\n" + 
	      "   for the data tables and preview images.\n\n" + 
	      "----------------------------------------------------\n\n";
Dialog.create("Batch Processing Complete");
Dialog.addMessage(ProcMessage);
Dialog.show();
//===== End of batch processing ======



/*========================================================================================================================
 * 		Supporting functions
 *========================================================================================================================
 */



// countInputFiles - Count the number of files in a folder containing 'text'
function countInputFiles(text) {
	count = 0;
	for(i=0; i<AllFilesInDir.length; i++) {
		if (endsWith(AllFilesInDir[i], text ) == 1 )
		count++;
	}
	return count;
}


// getImagesContaining - List the file names containing 'text', initialised by counting (above)
// Filename also can't contain the existing 'extension phrases' to avoid loading already-processed files.
function getImagesContaining(text) {
	result = newArray(numberOfInputFiles);
	badnames = newArray(Suffix_Filtered, Suffix_RemoveDuplicates, Suffix_Merging, Suffix_DriftCorrection, Suffix_ForBayes);
	index = 0;
	for (i=0; i<AllFilesInDir.length; i++) {
	
		// First test -- does it have the right file extension?
		if (endsWith(AllFilesInDir[i], text) ==1) {

			// Second test -- does it contain any of the words that might indicate this file is an already-processed file?
			badvibes=0;
			for (z=0; z<badnames.length; z++) {
				if (indexOf(AllFilesInDir[i], badnames[z]) >= 0) {
					badvibes++;
				}
			}
			
			// 
			if (badvibes == 0) {
				result[index] = AllFilesInDir[i];
				index++;
			}
			
		}
	}
	//trim the zeros
	finalresult = Array.slice(result,0,index);
	return finalresult;
}


// cleanFileNames - Strip baggage from file names
function cleanFileNames(text) {
	result = newArray(ListInputFiles.length);
	for(i=0; i<result.length; i++) {
		result[i] = replace(ListInputFiles[i], text, "");	 	// delete occurances of the main file extension
		result[i] = replace(result[i], ".nd2", ""); 			// scrub Nikon file extensions from the name
		result[i] = replace(result[i], ".lif", "");				// scrub Leica file extensions from the name
	}
	return result;
}


// CollectTheTrash - force run garbage collection to free up memory
function CollectTheTrash() {
	call("java.lang.System.gc");
}


// TimeStamp - creates a readable time stamp for the log window
function TimeStamp() {
	MonthNames = newArray("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
	DayNames = newArray("Sun", "Mon","Tue","Wed","Thu","Fri","Sat");
     
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);

	TimeString = "";
     
	if (hour<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+hour+":";
     
	if (minute<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+minute+":";
     
	if (second<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+second;

/*   TimeString =TimeString + " - " + DayNames[dayOfWeek]+" ";  
     if (dayOfMonth<10) {TimeString = TimeString+"0";}
     TimeString = TimeString+dayOfMonth+" "+MonthNames[month]+" "+year;
*/    
     return TimeString;
}


// TimeElapsed - Calculate the processing times for the log window
function TimeElapsed(StartTime,StopTime){	
	TimeDiff_ms = StopTime - StartTime;
	TimeDiff_h = floor(TimeDiff_ms/3600000);
	TimeRemain = TimeDiff_ms - (TimeDiff_h*3600000);
	TimeDiff_m = floor(TimeRemain/60000);
	TimeRemain = TimeRemain - (TimeDiff_m*60000);
	TimeDiff_s = floor(TimeRemain/1000);
	TimeDiff_ms = TimeRemain - (TimeDiff_s*1000);
	
	TimeElapseStr = "";
	if (TimeDiff_s == 0 && TimeDiff_m == 0 && TimeDiff_h == 0){
		TimeElapseStr = "" + TimeDiff_ms + " milliseconds";
	}
	if (TimeDiff_s > 0) {
		if (TimeDiff_s != 1) {
			TimeElapseStr = "" + TimeDiff_s + " seconds" + TimeElapseStr;
		} else {
			TimeElapseStr = "" + TimeDiff_s + " second" + TimeElapseStr;
		}
	}
	if (TimeDiff_m > 0) {
		if (TimeDiff_m != 1) {
			TimeElapseStr = "" + TimeDiff_m + " minutes " + TimeElapseStr;
		} else {
			TimeElapseStr = "" + TimeDiff_m + " minute " + TimeElapseStr;
		}
	}
	if (TimeDiff_h > 0) {
		if (TimeDiff_h != 1) {
			TimeElapseStr = "" + TimeDiff_h + " hours " + TimeElapseStr;
		} else {
			TimeElapseStr = "" + TimeDiff_h + " hour " + TimeElapseStr;
		}
	}
	return TimeElapseStr;
}


function GetMetaDataValue(FindThisMetadataValue) {

	final_output = NaN;

	info = getImageInfo();
	arr_metadata = split(info, "\n");
		
	for (j=0; j<arr_metadata.length; j++) { 
		if (matches(arr_metadata[j],"\.?"+FindThisMetadataValue+"\.*")) {
			metadata_str= split(arr_metadata[j],"[\:,=]");
			metadata_value = parseFloat(metadata_str[1]);
			// print("Value found on line: "+j);

			if (isNaN(metadata_value)) {
				final_output = metadata_str[1];
				return final_output;
			} else {
				final_output = metadata_value;
				return final_output;
			}
		} 
	}
	return final_output;
}

// Make a random set of 5 chars or a datestamp (for output folders)
function genUID(type) {
	OutputUID = "-";

	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);

	if (type == "random") {
		uid_seed = year+month+dayOfWeek+dayOfMonth+hour+minute+second+msec;
		random("seed", uid_seed)
		alphanums = newArray("A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","0","1","2","3","4","5","6","7","8","9");

		for (k=0;k<5;k++) {
			arraypos = round(random() * alphanums.length);
			OutputUID = OutputUID + alphanums[arraypos];
		}
		return OutputUID;
	}

	if (type == "datestamp") {
		year =substring(toString(year),2,4);
		month = toString(1+month);
		day = toString(dayOfMonth);
		hour = toString(hour);
		minute = toString(minute);

		if (lengthOf(month) < 2) {
		 month = "0"+month;
		}

		if (lengthOf(day) < 2) {
		 day= "0"+day;
		}

		if (lengthOf(hour) < 2) {
		 hour= "0"+hour;
		}

		if (lengthOf(minute) < 2) {
		 minute= "0"+minute;
		}

		OutputUID  = year+month+day+"-"+hour+minute;
		return OutputUID;
	}
}

//===== Processing Functions ======

// Do the main Thunderstorm processing using paramters in AnalysisParams
function DoMainProcessing() {
 run("Run analysis", 
 		"filter=[" + AnalysisParams[0] +"]" + 
 		" scale=" + AnalysisParams[1] +
 		" order=" + AnalysisParams[2] + 
  		" detector=[" + AnalysisParams[3] + "]" +
 		" connectivity=" + AnalysisParams[4] +  
 		" threshold=" + AnalysisParams[5] + 
		" radius=" + AnalysisParams[17] + 
 		" estimator=[" + AnalysisParams[6] + "]" +
 		" sigma=" + AnalysisParams[7] +  
 		" method=[" + AnalysisParams[8] + "]" +
 		" full_image_fitting=" + AnalysisParams[18] +  
 		" fitradius=" + AnalysisParams[9] +  
 		" fixed_intensity=" + AnalysisParams[20] +  
 		" expected_intensity=" + AnalysisParams[19] +   
 		" nmax=" + AnalysisParams[21] +   
 		" pvalue=" + AnalysisParams[22] +  
 		" mfaenabled=" + AnalysisParams[10] +  
 		" keep_same_intensity=" + AnalysisParams[23] +  
 		" renderer=[" + AnalysisParams[11] + "]" +
 		" magnification=" + AnalysisParams[12] +  
		" shifts=" + AnalysisParams[14] +
 		" dxforce=" + AnalysisParams[24] +  
 		" dx=" + AnalysisParams[25] +  
 		" repaint=" + AnalysisParams[15] +  
 		" colorize=" + AnalysisParams[13] +  
 		" threed=" + AnalysisParams[16] +  
 		" dzforce=" + AnalysisParams[26] );
}


// Filter events based on criteria in filter string paramter in FilteringParams
function DoFiltering() {
	run("Show results table", "action=filter formula=[" + FilteringParams + "]");
}


// DoRemoveDuplicates - Apply event merging on data table using paramters in RemoveDuplicatesParams
function DoRemoveDuplicates() {
	run("Show results table", "action=duplicates distformula=[" + RemoveDuplicatesParams + "]");
}


// DoDriftCorrection - Correct data table for lateral drift during acquisition using paramters in DriftCorrParams
function DoDriftCorrection() {
	run("Show results table", "action=drift magnification=" + DriftCorrParams[0] + " method=[" + DriftCorrParams[1] + "]" + " save=" + DriftCorrParams[2] + " path=" + DriftCorrParams[5] + " steps=" + DriftCorrParams[3] + " showcorrelations=" + DriftCorrParams[4] );
}


// DoMerging - Apply event merging on data table using paramters in MergingParams
function DoMerging() {
	run("Show results table", "action=merge zcoordweight=" + MergingParams[0] + " offframes=" + MergingParams[1] + " dist=" + MergingParams[2] + " framespermolecule=" + MergingParams[3] );
}


// Save the data table as CSV using the given filename
function SaveProcessedTable(filenameOut) {
	run("Export results", 
		"filepath=[" + filenameOut + "]" +
		" file=" + SaveTable_Format + 
		" saveprotocol=" + Save_Protocol +
		" id=" + Save_Col_ID +
		" frame=" + Save_Col_Frame +
		" x=" + Save_Col_x_Coord +
		" y=" + Save_Col_y_Coord +
		" sigma=" + Save_Col_Sigma +
		" intensity=" + Save_Col_Intensity +
		" offset=" + Save_Col_Offset +
		" bkgstd=" + Save_Col_Bkgstd +
		" uncertainty_xy=" + Save_Col_Uncertainty +
		" detections=" + Save_Col_Detections +
		" chi2=" + Save_Col_Chi2 );
}
	

// SavePreviewImage - Saves PNG files of the xy event data
function SavePreviewImage(filenameOut) {
setBatchMode(false); //setBatchMode("show")
//	run("Visualization", "imleft=0.0 imtop=0.0 imwidth=256.0 imheight=256.0 renderer=[Normalized Gaussian] dxforce=false magnification=10.0 dx=20.0 colorizez=false threed=false dzforce=false");
	run("Visualization", "imleft=" + RenderingParams[0] + " imtop=" + RenderingParams[1] + " imwidth=" + RenderingParams[2] + " imheight=" + RenderingParams[3] + " renderer=[" + RenderingParams[4] + "] magnification=" + RenderingParams[5] + " dxforce=" + RenderingParams[6] + " dx=" + RenderingParams[7] + " colorizez=" + RenderingParams[8] + " threed=" + RenderingParams[9] + " dzforce=" + RenderingParams[10]);
	run("16-bit");
	run("Enhance Contrast...", "saturated=0.5");
	saveAs("PNG", ""+filenameOut+"_Preview.png");
	run("Close All");
setBatchMode(true);
}


// OutputFileOrganizer - Moves accessory files to separate folders after processing
function OutputFileOrganizer(FolderToClean) {

	list = getFileList(FolderToClean);

	//Make the tidy folders
	ProtocolsDestFolder = FolderToClean+File.separator+"Protocols"+File.separator;
	DriftPlotDestFolder = FolderToClean+File.separator+"Drift Plots"+File.separator;
	PreviewsDestFolder = FolderToClean+File.separator+"Previews"+File.separator;

	File.makeDirectory(ProtocolsDestFolder);
	File.makeDirectory(DriftPlotDestFolder);
	File.makeDirectory(PreviewsDestFolder);
        
	//Look throug the list - move the files to appropriate dirs
	for (i=0; i<list.length; i++) {
		

		if (endsWith(list[i], "protocol.txt")) {
			File.rename(FolderToClean + list[i], ProtocolsDestFolder + list[i]); 	
		}

		if (endsWith(list[i], "DriftDiag.png")) {
			File.rename(FolderToClean + list[i], DriftPlotDestFolder + list[i]); 	
		}

		if (endsWith(list[i], "Preview.png") || endsWith(list[i], "Preview.tif")) {
			File.rename(FolderToClean + list[i], PreviewsDestFolder + list[i]);
		}
	}
	
	if (isOpen("Log")) {
		selectWindow("Log");
		run("Close");
	}

}

// OutputFileOrganizer_v2 - Moves accessory files to separate folders after processing
function OutputFileOrganizer_v2(FolderToClean) {

	list = getFileList(FolderToClean);
	SearchPhrase = "";

	//Make the tidy folders based on the post-processing string.
	
	for (j=0; j<PostProcOrder.length; j++) {
	
		// Get element of the filtering steps and make a folder for it.
		OrganizerDestFolderName = PostProcOrder[j];
		OrganizerDestFolder = FolderToClean + File.separator + OrganizerDestFolderName + File.separator;
		File.makeDirectory(OrganizerDestFolder);
			
		// get the unique identifier for these types of files
		if (OrganizerDestFolderName == Filter)
			SearchPhrase = SearchPhrase + Suffix_Filtered;
		
		if (OrganizerDestFolderName == DensityFilter)
			SearchPhrase = SearchPhrase + Suffix_RemoveDuplicates;
		
		if (OrganizerDestFolderName == RemoveDuplicates)
			SearchPhrase = SearchPhrase + Suffix_Merging;
			
		if (OrganizerDestFolderName == Merging)
			SearchPhrase = SearchPhrase + Suffix_DriftCorrection;
			
		if (OrganizerDestFolderName == DriftCorrection)
			SearchPhrase = SearchPhrase + Suffix_ForBayes;

		//Look throug the list - move the files to appropriate dirs
		for (i=0; i<list.length; i++) {
			
			if (matches(list[i],"\.?"+SearchPhrase+"\.*")) {
				File.rename(FolderToClean + list[i], OrganizerDestFolder + list[i]); 	
			}

		}
	
	}
	
	if (isOpen("Log")) {
		selectWindow("Log");
		run("Close");
	}

}

// EOF
