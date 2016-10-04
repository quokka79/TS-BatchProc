# TS-BatchProc

========================================================================================================================
 		Dave's Attempt at a Batch Processor Macro for ThunderSTORM
========================================================================================================================

Tested with:
- ImageJ 1.49s and 1.50g
- Fiji (latest)
- Fiji Life-Line version, 2013 July 15 (from http://fiji.sc/Downloads )
- ThunderSTORM dev-2015-10-03-b1

========================================================================================================================
TS_Process_Batch.ijm
========================================================================================================================

This version does: 			
	- ND2, TIF, LIF, CZS localisation and post-processing -- if you can open it with BioFormats then you can use it with
	  this script.
	- Flexible post-processing. You can specify which steps you want done and the order you want them done. All files are
	  then treated in the same manner after the initial detection.
	- (optional) post-processing file arrangement, which saves tables and preview images for each step.
	- reprocessing of existing tables (set the input file extension to match the existing exported data files.
	
This version does not do:
    - Channel warping/alignment.
	- loading of existing drift files.

Usage:

Open the file in a text editor (if you only have Notepad, then be sure to check out Notepad++)
Edit the various settings to match what you want to do. They are split up in separate sections, which are explained in the 
comments section of the script.
