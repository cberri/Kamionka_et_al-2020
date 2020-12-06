/*
 * Project Eva Kamionka
 * 
 * Developed by Dr. Carlo A. Beretta 
 * Math Clinic CellNetworks, University of Heidelberg
 * Email: carlo.beretta@bioquant.uni-heidelberg.de
 * Web: http://math-clinic.bioquant.uni-heidelberg.de
 * Tel.: +49 (0) 6221 54 51435
 * 
 * Comments: The input image has to be a z-stack.
 * 
 * Copy the following code in the ImageJ macro folder, startup macro .ijm file and restart imageJ/Fiji
 * Then you can use the 'a' shortcut to add 255 values to a ROI
 * // Key short cut
 *	macro "SetBinaryValue [a]" {
 *		run("Set...", "value=255");
 * }
 * 
 * Created: 2018/07/23
 * Last update: 2018/07/23
 */

// %%%%%%%%%%%%%%%%%%%%% Functions %%%%%%%%%%%%%%%%%%%%%
// # 1
function CloseAllWindows() {
	while(nImages > 0) {
		selectImage(nImages);
		close();
	}
}

// # 2
// Choose the input directories
function InputDirectory() {

	dirInRaw = getDirectory("Please choose the RAW input root directory");
	dirInSeg = getDirectory("Please choose the ILASTIK input root directory");

	// The macro check that you choose a directory and output the input path
	if (lengthOf(dirInRaw) == 0 || lengthOf(dirInSeg) == 0) {
		print("Exit!");
		exit();
			
	} else {

		// Output the path
		text = "Input row path:\t" + dirInRaw;
		print(text);
		text = "Input ilastik path:\t" + dirInSeg;
		print(text);

		dirIn = newArray(dirInRaw, dirInSeg);
		return dirIn;
			
	}
	
}

//  # 3
// Output directory
function OutputDirectory(outputPath, year, month, dayOfMonth, second) {

	// Use the dirIn path to create the output path directory
	dirOut = outputPath;

	// Change the path 
	lastSeparator = lastIndexOf(dirOut, File.separator);
	dirOut = substring(dirOut, 0, lastSeparator);
	
	// Split the string by file separtor
	splitString = split(dirOut, File.separator); 
	for(i=0; i<splitString.length; i++) {

		lastString = splitString[i];
		
	} 

	// Remove the end part of the string
	indexLastSeparator = lastIndexOf(dirOut, lastString);
	dirOut = substring(dirOut, 0, indexLastSeparator);

	// Use the new string as a path to create the OUTPUT directory.
	dirOut = dirOut + "MacroResults_" + year + "-" + month + "-" + dayOfMonth + "_0" + second + File.separator;
	return dirOut;
	
}

// # 4
// Open the ROI Manager
function OpenROIsManager() {
	if (!isOpen("ROI Manager")) {
		run("ROI Manager...");
		
	}
	
}

// # 5
// Close the ROI Manager 
function CloseROIsManager() {
	if (isOpen("ROI Manager")) {
		selectWindow("ROI Manager");
     	run("Close");
     	
     } else {
     	print("ROI Manager window has not been found");
     }	
     
}

// # 6
// Save and close Log window
function CloseLogWindow(dirOut) {
	if (isOpen("Log")) {
		selectWindow("Log");
		saveAs("Text", dirOut + "Log.txt"); 
		run("Close");
		
	} else {

		print("Log window has not been found");
	}
	
}

// # 7
// User can edit the ROIs and correct potential mistakes
function ManualCorrection(maxInputTitleRaw, binaryTitle) {

	// Select the max raw input image
	selectImage(maxInputTitleRaw);
	width = getWidth();
	height = getHeight();

	// Convert the raw image to 8 bit
	run("8-bit");
	run("Add Slice"); // Add a slide solve the problem with the combine function
	run("Duplicate...", "duplicate");
	rename("invertedRaw");
	invertedRawTitle = getTitle();
	
	// Binary image
	selectImage(binaryTitle);
	run("Add Slice"); // Add a slide solve the problem with the combine function
	run("Duplicate...", "duplicate");
	rename("invertedBinary");
	invertedBinaryTitle = getTitle();
	
	// Stack 1 -> Support only z-stacks
	selectImage(maxInputTitleRaw);
	run("Combine...", "stack1=["+binaryTitle+"] stack2=["+maxInputTitleRaw+"]");
	rename("combineBinaryRaw");
	combineBinaryRaw = getTitle();

	// Stack 2 -> Support only z-stacks
	run("Combine...", "stack1=["+invertedRawTitle+"] stack2=["+invertedBinaryTitle+"]");
	rename("combineRawBinary");
	combineRawBinary = getTitle();
	
	// Concatenate the stacks
	run("Concatenate...", "  title=[Concatenated Stacks] image1=["+combineBinaryRaw+"] image2=["+combineRawBinary+"]");
	concatenateRedStack = getTitle();

	// Add informatin for the user
	for (q=1; q<=nSlices(); q++) {

		// Select slides
		setSlice(q);

		// Delete the black slices
		getRawStatistics(nPixels, mean, min, max, std, histogram);

		if (max == 0) {
			run("Delete Slice");
			
		} else {

			// Add a line as overlay
			setColor(125);
			makeLine(width+1, 0, width+1, height);
			run("Add Selection...");
	
			// Add text as overlay
			setFont("Arial" , 60);
			drawString("<- Edit the left image", width+40, 60);
	
			if (q == 1) {
				drawString("Binary Image", width+40, 110);	
			} else if (q == 2) {
				drawString("Raw Image", width+40, 110);		
			}
		}
	}
	
	// Remove selection and set the first slice
	run("Select None");
	setSlice(1);
	
	// Display the input image before correction
	setBatchMode("show");
	
	// Set free hand tool
	setTool("freehand");

	// Update the user
	showStatus("Binary Image Correction...");

	// Create a dialog window
	title = "Wait for user...";
	msg = "Click OK when you have done with the corrections!";
	waitForUser(title, msg);

	// Hide the input image after correction
	setBatchMode("hide");

	// Rebuild the binary image (from stack to binary)
	while (nSlices() > 1) {
		setSlice(2);
		run("Delete Slice");
		
	}

	// Get the output binary mask (crop)
	makeRectangle(0, 0, width, height);
	run("Crop");
	run("Select None");
	
}

// %%%%%%%%%%%%%%%%%%%%% Macro %%%%%%%%%%%%%%%%%%%%%
macro ManualClusterCorrection {

	// Start functions
	// 1.
	CloseAllWindows();

	// 2.
	OpenROIsManager();

	// Display memory usage
	doCommand("Monitor Memory...");

	// Get the starting time
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);

	// 3. Function choose the input root directory
	dirIn = InputDirectory();
	outputPath = dirIn[0];

	// Get the list of file in the input directory
	fileListRaw = getFileList(dirIn[0]);
	fileListSeg = getFileList(dirIn[1]);

	// Check the numebr of file in the input directories
	if (fileListRaw.length != fileListSeg.length) {

		// Quit the macro
		print("Unequal number of file!");
		exit();

	} else {

		fileList = fileListRaw;
		
	}

	// 4. Create the output directory in the input path
	dirOut = OutputDirectory(outputPath, year, month, dayOfMonth, second);

	if (!File.exists(dirOut)) {	
		File.makeDirectory(dirOut);
		text = "Output path:\t" + dirOut;
		print(text);
	
	} 

	// Do not display the images
	setBatchMode(true);

	// Open the file located in the input directory
	for (i=0; i<fileList.length; i++) {

		// Check the input file format .tif / .tiff
		if (endsWith(fileList[i], '.tiff') || endsWith(fileList[i], '.tif' )) {

			// Update the user
			print("Processing file:\t\t" +(i+1));

			// Open the input Raw image
			open(dirIn[0] + fileListRaw[i]);
			inputTitleRaw = getTitle();
			print("Opening:\t" + inputTitleRaw);

			// Check if the input file is a z-stack
			if (nSlices <=1) {
				print("The input file is not a z-stack");
				exit();
				
			}

			// Remove file extension .tif
            dotIndex = indexOf(inputTitleRaw, ".");
            title = substring(inputTitleRaw, 0, dotIndex);

            // MIP
			run("Z Project...", "projection=[Max Intensity]");
			rename("MaxRaw");
			maxInputTitleRaw = getTitle();

			// Enhance contrast
			run("Enhance Contrast", "saturated=0.35");

			// Open the ilastik input image
			open(dirIn[1] + fileListSeg[i]);
			inputTitleSeg = getTitle();
			print("Opening:\t" + inputTitleSeg);

			// Check if the input file is a z-stack
			if (nSlices <=1) {
				print("The input file is not a z-stack");
				exit();
				
			}

			// ######### PROCESS #########
			// Process the ilastik input image
			selectImage(inputTitleSeg);

			// MIP
			run("Z Project...", "projection=[Average Intensity]");
			rename("AverageSeg");
			maxInputTitleSeg = getTitle();

			// Get image dimentions
			imageWidth = getWidth();
			imageHeight = getHeight();
			nSlice = nSlices;

			// Threshold
			setOption("BlackBackground", true);
			setAutoThreshold("RenyiEntropy dark");
			run("Convert to Mask");

			// Median filter
			// run("Median...", "radius=2");

			// Analyse partcles
			run("Analyze Particles...", "size=25-Infinity clear include add");					// <------------------------------ Here is the size fileter! Now I set it on 30

			// Set to white fill ROIs color
			setForegroundColor(255, 255, 255);

			// Create a new image and fill the ROIs
			newImage("binary", "8-bit black", imageWidth, imageHeight, nSlice);
			roiManager("Show All");
			roiManager("Fill");
			roiManager("Delete");
			binaryTitle = getTitle();

			// Close all the unused images
			selectImage(inputTitleRaw);
			close(inputTitleRaw);
			selectImage(inputTitleSeg);
			close (inputTitleSeg);
			selectImage(maxInputTitleSeg);
			close(maxInputTitleSeg);

			// Manual correction function
			ManualCorrection(maxInputTitleRaw, binaryTitle);

			// Get the output image title and save the results
			processedBinaryTitle = getTitle();
			saveAs("Tiff", dirOut + "0" + i + "_" + title + "_Edit");
			processedBinaryTitle = getTitle();
			close(processedBinaryTitle);
			
		}

	}

	// Update the user 
	text = "\nNumber of file processed:\t\t" + fileList.length;
	print(text);
	text = "\n%%% Congratulation your file have been successfully processed %%%";
	print(text);
	
	// End functions
	CloseROIsManager();
	CloseLogWindow(dirOut);
	
	// Display the images
	setBatchMode(false);
	showStatus("Completed");
	
}