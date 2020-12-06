/*
 * Project1 Eva Kamionka
 * 
 * Developed by Dr. Carlo A. Beretta 
 * Math Clinic CellNetworks, University of Heidelberg
 * Email: carlo.beretta@bioquant.uni-heidelberg.de
 * Web: http://math-clinic.bioquant.uni-heidelberg.de
 * Tel.: +49 (0) 6221 54 51435
 * 
 * Comments: 
 * Use a customized filter to subtract the image background and identify the tumour cluster in the image.
 * INPUT: ilastik pixel classification probability map
 * 
 * Created: 2017/08/22
 * Last update: 2017/08/29
 */

// %%%%%%%%%%%%%%%%%%%%% Functions %%%%%%%%%%%%%%%%%%%%%
function CloseAllWindows() {
	while(nImages > 0) {
		selectImage(nImages);
		close();
	}
}

function LogHeader() {

	print( "%\t" + "% Image Processing Information\t" + "% Values\t");

}

// Open the ROI Manager
function OpenROIsManager() {
	if (!isOpen("ROI Manager")) {
		run("ROI Manager...");
		
	}
	
}

// Close the ROI Manager 
function CloseROIsManager() {
	if (isOpen("ROI Manager")) {
		selectWindow("ROI Manager");
     	run("Close");
     	
     } else {
     	print("ROI Manager window has not been found");
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

// Choose the input directory
function InputDirectory() {

	dirIn = getDirectory("Please choose the INPUT root directory (ilastik pixel classification PM) ");

	// The macro check that you choose a directory and output the input path
	if (lengthOf(dirIn) == 0) {
		print("Exit!");
		exit();
			
	} else {
		
		text = "Input path: \t" + dirIn;
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
		
		// print("parts["+i+"]="+splitString[i]);
		// Last element of the string
		lastString = splitString[i];
		
	} 

	// Remove the end part of the string
	indexLastSeparator = lastIndexOf(dirOut, lastString);
	dirOut = substring(dirOut, 0, indexLastSeparator);

	// Use the new string as a path to create the OUTPUT directory.
	dirOut = dirOut + "MacroResults_" + year + "-" + month + "-" + dayOfMonth + "_0" + second + File.separator;

	return dirOut;
	
}

// %%%%%%%%%%%%%%%%%%%%% Macro %%%%%%%%%%%%%%%%%%%%%
macro segTumourClusters {

	// 1. Close all the open images
	CloseAllWindows();

	// 2. Open ROI Manager
	OpenROIsManager();

	// 3.
	LogHeader();

	// Get the starting time for later
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);

	// 4. Function choose the input root directory
	dirIn = InputDirectory();

	// Get the list of file in the input directory
	fileList = getFileList(dirIn);

	// 5. Create the output directory in the input path
	dirOut = OutputDirectory(dirIn, year, month, dayOfMonth, second);

	if (!File.exists(dirOut)) {	
		File.makeDirectory(dirOut);
		text = "Output path:\t" + dirOut;
		print(text);
	
	} else {
		print("The output directory already exist")
		exit();
	}

	// Do not display the images
	setBatchMode(true);

	// Open the file located in the input directory
	for (i=0; i<fileList.length; i++) {

		// Check the input file format .tif / .tiff
		if (endsWith(fileList[i], '.tiff') || endsWith(fileList[i], 'tif' )) {

			// Update the user
			print("Processing file: " +(i+1));

			// Open the input image
			open(dirIn + fileList[i]);
			inputTitle = getTitle();
			print("Opening:\t" + inputTitle);
		
			// Remove file extension .tif
        	dotIndex = indexOf(inputTitle, ".");
        	title = substring(inputTitle, 0, dotIndex);

        	// Create a new directory inside the output directory where to save the red channel images
			dirOutAnalysis = dirOut + i + "_Results_" + title + File.separator;

			// Check if the output directory already exist
			if (!File.exists(dirOutAnalysis)) {	
				
				// Create a new directory inside the output directory
				File.makeDirectory(dirOutAnalysis);
				text = "Created output directory:\t" + dirOutAnalysis;
				print(text);

			}

			// Filter the data
			// Input size of the image
			wd = getWidth();
			hd = getHeight();
			nSlice = nSlices();

			// Check if the input image is a z-stack and in case process all the slices
			for (n=0; n<nSlices(); n++) {

				// Set slice
				setSlice(n+1);
				print("\\Update:Processing slice: " + n+1);
				print("\n");

				// Reset min and max value
				resetMinAndMax();

				// Image statistic
				getStatistics(area, mean, min, max, std, histogram);
				maxImage = max;
				stdImage = std;
				meanImage = mean;
			
				// Move ROI selection (x-row)
				for (j=0; j<wd; j++) {

					// (y-colum)
					for (k=0; k<hd; k++) {
					makeRectangle(j, k, 3, 3);
			
					// Get selected pixel statistic
					getStatistics(area, mean, min, max);
			
					// Intensity normalization using z score equation
					z = ((max - meanImage) /stdImage);  // 12 bits
			
					// Set the pixel value to the normalized value
					setPixel(j, k, z); 
			
					// Print intensity value
					// print("Normalized value", z);
			
					// Clear selection
					run("Select None");
					
					}
			
				// Output the next y position
				// print("\nColumn", i);
			
				// Clear selection
				run("Select None");
				
				// Show the propgress
				// It counts the number of colums left
				print("\\Update:Background Subtraction: " + wd-(j+1));
			
				}

			}

			// Reset min and max value
			print("\\Update:Done!");
			resetMinAndMax();

			// Save the background subtraction image
			selectImage(inputTitle);
			saveAs("Tiff", dirOutAnalysis + "0" + i + "_BackgroundSub_" + title);
			inputTitle = getTitle();
			
			// Blurred the background subtracted image 
			run("Gaussian Blur...", "sigma=5");
			setAutoThreshold("Default dark");
			setOption("BlackBackground", true);
			run("Convert to Mask");

			// Process the object of intrest and apply them on a new image
			run("Analyze Particles...", "size=4000-Infinity circularity=0.00-1.00 clear include add");
			newImage("BinaryMask", "8-bit black", wd, hd, nSlice);
			resultTitle = getTitle();
			roiManager("Show None");
			roiManager("Fill");

			// Save the results
			selectImage(resultTitle);
			saveAs("Tiff", dirOutAnalysis + "0" + i + "_Binary_" + title);
			resultTitle = getTitle();
			close(resultTitle);

			// Close the input image
			selectImage(inputTitle);
			close(inputTitle);

			// Save and clear the ROI manager
			roiManager("Save", dirOutAnalysis + "0" + i + "_Sub_" + title + "_ROI.zip");
			roiManager("reset");

		}
		
	}

	// Update the user when all the file have been processed
	print("\n%%% Congratulation your file have been successfully processed %%%");
	wait(3000);
	
	// Call the end functions
	CloseLogWindow(dirOut);
	CloseROIsManager();

	setBatchMode(false);

}