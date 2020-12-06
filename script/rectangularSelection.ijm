/*
 * Project Eva Kamionka
 * 
 * Developed by Dr. Carlo A. Beretta 
 * Math Clinic CellNetworks, University of Heidelberg
 * Email: carlo.beretta@bioquant.uni-heidelberg.de
 * Web: http://math-clinic.bioquant.uni-heidelberg.de
 * Tel.: +49 (0) 6221 54 51435
 * 
 * Created: 2017/09/27
 * Last update: 2017/09/27
 */

// %%%%%%%%%%%%%%%%%%%%% Functions %%%%%%%%%%%%%%%%%%%%%
function CloseAllWindows() {
	while(nImages > 0) {
		selectImage(nImages);
		close();
	}
}

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

// Close Memory window
function CloseMemoryWindow() {
	if (isOpen("Memory")) {
		selectWindow("Memory");
		run("Close", "Memory");
		
	} else {
		print("Memory window has not been found!");
	}
	
}

// Choose the input directory
function InputDirectory() {

	dirIn = getDirectory("Please choose the INPUT root directory");

	// The macro check that you choose a directory and output the input path
	if (lengthOf(dirIn) == 0) {
		print("Exit!");
		exit();
			
	} else {
		
		text = "Input path: " + dirIn;
		print(text);
		return dirIn;
			
	}
	
}

// Main output directory
function OutputDirectory(dirIn, year, month, dayOfMonth, second) {

	// Use the dirIn path to create the output path directory
	dirOut = dirIn;

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
	dirOut = dirOut + "Cropped_MacroResults_" + year + "-" + month + "-" + dayOfMonth + "_0" + second + File.separator;
	return dirOut;
	
}

// Dialog box
function ReginSelection() {
	title = "Input Rectangular Parameters";
  	x = 0;
  	y = 0;
  	width = 0;
  	heigth = 0;
  	Dialog.create("Enter Rectangle Properties");
  	Dialog.addNumber("x: ", x, 5, 6, "pixel");
  	Dialog.addNumber("y: ", y, 5, 6, "pixel");
  	Dialog.addNumber("width: ", width, 5, 6, "pixel");
  	Dialog.addNumber("heigth: ", heigth, 5, 6, "pixel");
  	Dialog.show();
  	x = Dialog.getNumber();
  	y = Dialog.getNumber();
  	width = Dialog.getNumber();
  	height = Dialog.getNumber();

  	// Return variables
  	regionProperties = newArray(x, y, width, height);
  	return regionProperties;
	
}

// %%%%%%%%%%%%%%%%%%%%% Macro %%%%%%%%%%%%%%%%%%%%%
macro RectangularRegionSelection {

	// Start functions
	// 1.
	CloseAllWindows();

	// Display memory usage
	doCommand("Monitor Memory...");

	// Get the starting time for later
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);

	// 2. Function choose the input root directory
	dirIn = InputDirectory();

	// Get the list of file in the input directory
	fileList = getFileList(dirIn);

	// 3. Create the output directory in the input path
	dirOut = OutputDirectory(dirIn, year, month, dayOfMonth, second);

	if (!File.exists(dirOut)) {	
		File.makeDirectory(dirOut);
		text = "Output path: " + dirOut;
		print(text);
	
	} 

	// Open the file located in the input directory
	for (i=0; i<fileList.length; i++) {

		// Check the input file format .tif / .tiff
		if (endsWith(fileList[i], '.tiff') || endsWith(fileList[i], '.tif' )) {

			// Update the user
			print("Processing file: " +(i+1));

			// Open the input image
			open(dirIn + fileList[i]);
			
			inputTitle = getTitle();
			print("Opening: " + inputTitle);

			// Remove file extension .tif
        	dotIndex = indexOf(inputTitle, ".");
        	title = substring(inputTitle, 0, dotIndex);

        	// Create a new directory inside the output directory
			dirOutAnalysis = dirOut + i + "_Results_" + title + File.separator;

			// Check if the output directory already exist
			if (!File.exists(dirOutAnalysis)) {	
				
				// Create a new directory inside the output directory
				File.makeDirectory(dirOutAnalysis);
				print("Created output directory: " + dirOutAnalysis);

			}

			// Rectangle selection 
			regionProperties = ReginSelection();
			makeRectangle(regionProperties[0], regionProperties[1], regionProperties[2], regionProperties[3]);

			// Crop the image only if the selection exist
			selectionExist = selectionType();
			if (selectionExist != -1) {
				run("Crop");
					
			}
			
			// Save the ROI
			saveAs("Tiff", dirOutAnalysis + "0" + i + "_Cropped_" + title);
			croppedTitle = getTitle();
			close(croppedTitle);
			
		} else {

			// Warning message
			print("Warning: The input file is not .tiff or an image: " + fileList[i]);
		}

	}

	// Update the user 
	text = "\nNumber of file processed: " + fileList.length;
	print(text);
	text = "\n%%% Congratulation your file have been successfully processed %%%";
	print(text);
	
	// End functions
	CloseLogWindow(dirOut);
	CloseMemoryWindow();
	
}
