/*
 *========================================================================================================================
 * 		Dave's Attempt at a Batch Processor Macro for ThunderSTORM
 *========================================================================================================================
 *	
 *	Tested with:
 *	  - ImageJ 1.49s and 1.50g
 *    - Fiji (latest)
 *    - Fiji Life-Line version, 2013 July 15 (from http://fiji.sc/Downloads )
 *	  - ThunderSTORM dev-2015-10-03-b1
 *
 *	This version does: 			ND2 and TIF stack processing (possibly LIF as well, but not tested), post-processing file arrangement, saves tables and preview images for each step (allevents, filtered, filt+drift corrected, filt+drift+merging)
 *	This version does not do:	channel warping/alignment, reprocessing of existing tables, loading of existing drift files.
 * 
 *	Change settings in the sections headed 'General Variables' and 'ThunderSTORM Variables'
 * 
 */

// Initialise the variable arrays
var FilteringParams;
var DriftCorrParams;
var MergingParams;
var RenderingParams;
DriftCorrParams = newArray(6);
MergingParams = newArray(4);
RenderingParams = newArray(11);



/*========================================================================================================================
 * 		General settings
 *========================================================================================================================
 */

InputFileExt = 			".csv";				// File extension of the input data files
OutputFolderName = 		"ReProc";			// Name of folder that will be created to hold output data tables etc.
OutputFolderAppendUID = 	"datestamp";				// Will add a unique ID to the end of the folder name given above (e.g. to avoid overwriting existing data). Use either "random" or "datestamp".
OrganiseOutputFiles = 		false;					// Protocols, preview images, and drift plots will be stored their own folders



/*========================================================================================================================
 * 		Re Post Processing settings
 *========================================================================================================================
 */
 
// ORDER OF POST-PROCESSING
// Must be at least one of these phrases:
//	 Filter	DensityFilter	RemoveDuplicates	Merging	DriftCorrection	ZStageOffset
// If you don't want to do a particular type of post-processing simply don't include it!

PostProcOrder = 	newArray("Filter", "Merging", "DriftCorrection"); // !IMPORTANT! ==> When changing this, make sure you add/remove the matching true-false statements for saving tables and images (below, SavePostProcessedTables and SavePostProcessedPreviewImgs

// Remove Duplicates parameters
RemoveDuplicatesParams = 	"uncertainty_xy";

// Filtering parameters
FilteringParams = 		"intensity > 500 & intensity < 5000 & sigma > 50 & sigma < 250 & uncertainty_xy < 25";
			// options (common) :	 	uncertainty_xy , sigma , intensity 
			// options (less common): 	id , frame , x , y , offset , bkgstd
			// options (special):		detections (available after merging), chi2 (if doing least squares detection), uncertainty_z (if doing 3D)
			
// Drift Correction parameters
DriftCorrParams[0] = 		"5";					// magnification
DriftCorrParams[1] = 		"Cross correlation";		// type of correction
DriftCorrParams[2] = 		"false";				// save file to path
DriftCorrParams[3] = 		"5";					// steps/bins
DriftCorrParams[4] = 		"false";				// show correlation plot (this isn't the drift plot)

// Merging parameters
MergingParams[0] = 		"0.1";				// z-coordinate weight
MergingParams[1] = 		"25";					// off-frames (mergeable events can be separated by up to this much dark-time)
MergingParams[2] = 		"50";				// search radius (mergeable events can be this far away from initial event)
MergingParams[3] = 		"0";					// maximum number of consecutive frames such that a repeating event is still considered a single molecule.

// DATA TABLES & PREVIEW IMAGES
// set to true or false to save a table at each matching step in the PP chain given above.
// e.g. if you have three post-proc steps, you need three t/f statements. If you have two pp steps you need two tf statements!

SavePostProcessedTables  =		newArray(true, true, true);		// Save a data table for these steps? Matches to same position in PostProcOrder.
SavePostProcessedPreviewImgs = 	newArray(true, true, true);		// Save a preview image for these steps? Matches to same position in PostProcOrder.

// Other data table and preview options
SaveTable_Allevents = 		false;				// The table of all identified events (before post-processing is performed)
SavePreview_Allevents = 	false;				// Save an image of the initial detection, before any post-processing steps?
SaveTableForBayes = 		false;				// Save a table suitable for Bayesian Clustering Analysis (x,y,uncertainty cols only)
SaveDriftPlot = 			true;				// Save the drift-correction diagram?

// Naming of the output tables -- if the step is performed, these abbreviations will be appended in the file name.
// The order in the filename will reflect the order that you specified in the post-processing chain.
Suffix_AllEvents = 		"";
Suffix_Filtered = 		"Fil";
Suffix_RemoveDuplicates = 	"RemDup";
Suffix_Merging = 			"Mrg";
Suffix_DriftCorrection = 	"DriCor";
Suffix_ForBayes = 		"_Bayes";

// Exported data table format
SaveTable_Format = 		"CSV (comma separated)"		// Other options: "XLS (tab separated)" , "XML" , "JSON" , "YAML" , "Google Protocol Buffer" , "Tagged spot file"
OutputFileExt = 			".csv";				// File extension of the output data tables

// Columns to include when exporting a data table (excluding the final Bayes table)
// For excellent and sensible reasons, these true/false values need to be in quotes ("")...
Save_Protocol =			"true";
Save_Col_ID =			"true";
Save_Col_Frame =			"true"; 
Save_Col_x_Coord =		"true";
Save_Col_y_Coord =		"true";
Save_Col_Sigma =			"true";
Save_Col_Intensity =		"true"; 
Save_Col_Offset =			"true";
Save_Col_Bkgstd =			"true";
Save_Col_Uncertainty =		"true";
Save_Col_Detections =		"true";				// available if doing merging
Save_Col_Chi2 =			"false";				// available if doing least squares fitting

//Image rendering - applied to post-processing preview images only
RenderingParams[0] = 		"0.0"; 				//imleft
RenderingParams[1] = 		"0.0"; 				//imtop
RenderingParams[2] = 		"256.0"; 				//imwidth, size in pixels of raw input images
RenderingParams[3] = 		"256.0"; 				//imheight
RenderingParams[4] = 		"Normalized Gaussian";		// Render style
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
current_version_script = "1.0";

if ((PostProcOrder.length ! = SavePostProcessedTables.length) || (PostProcOrder.length ! = SavePostProcessedPreviewImgs.length) || (SavePostProcessedTables.length ! = SavePostProcessedPreviewImgs.length)) {
	ProcErrorMessage= "--------------------------------------------------------------------------------------------\n" + 
		      "   Error! \n" + 
		      "--------------------------------------------------------------------------------------------\n\n" + 
		      "   Please check your macro settings: \n" + 
		      "   These variables need to have the same number of values: \n\n" + 
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

InputFolder = getDirectory("Choose directory where your already processed data tables are stored");

var AllFilesInDir;
AllFilesInDir= getFileList(InputFolder);

var numberOfImages = 0;
numberOfImages = countImages(InputFileExt);

if (numberOfImages > 0) {

	var ListInputImages;
	ListInputImages = getImagesContaining(InputFileExt);
	numberOfImages = ListInputImages.length; // update the number of files now that we've (possibly) excluded some from consideration

	var SaveFileNames;
	SaveFileNames = cleanFileNames(InputFileExt);

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
				  "   Folder contains no " + InputFileExt + " files! \n" +
				  "   Click *CANCEL* to exit the macro now. \n" + 
				  "----------------------------------------------------\n\n";
	Dialog.create("Batch Processing Problem...");
	Dialog.addMessage(ProcMessage);
	Dialog.show();
}







//===== Show variables and accept any changes ======

// Set up the log window
f1 = "[ThunderSTORM Batch Reprocessor Log]";

if (isOpen("ThunderSTORM Batch Reprocessor Log")) { 
	selectWindow("ThunderSTORM Batch Reprocessor Log");
	print(f1,"\n\n\n");
} else {
	run("Text Window...", "name="+f1+" width=80 height=40");
}
	
print(f1,"--------------------------------------------------------------------------------------\n");
print(f1,"     ThunderSTORM Batch Re-Processor \t (DW ver-" + current_version_script + ")\n");
print(f1,"--------------------------------------------------------------------------------------\n");
print(f1,"\n");
if (numberOfImages==1) {
	print(f1,"\t" + TimeStamp() + "\tReprocessing "+ numberOfImages + " data table.\n");
} else {
	print(f1,"\t" + TimeStamp() + "\tReprocessing "+ numberOfImages + " data tables.\n");
}
print(f1,"\n");
print(f1," Source:\t" + InputFolder  + "\n");
print(f1," Output:\t" + OutputFolder + "\n");
print(f1,"\n");

setBatchMode(true);



//===== Start of processing loop ======

for(i = 0; i < ListInputImages.length; i++) {

	StopWatchA = getTime(); // Start the processing timer

	print(f1, " [" + i+1 + "/" + numberOfImages + "]\t" + SaveFileNames[i] + "\n");
	print(f1,"\tLoading... ");
	run("Import results", "filepath=[" + InputFolder+ListInputImages[i] + "] fileformat=[CSV (comma separated)] append=false startingframe=1 rawimagestack= livepreview=false");	
	print(f1," done. \n");


// ==== Re Post Processing ====
	

	
	
	
	
	
	
	
	
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



// countImages - Count the number of files in a folder containing 'text'
function countImages(text) {
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
	result = newArray(numberOfImages);
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
	result = newArray(ListInputImages.length);
	for(i=0; i<result.length; i++) {
		result[i] = replace(ListInputImages[i], text, "");	 	// delete occurances of the main file extension
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

// EOF
