/*
 * Project2A Eva Kamionka
 * 
 * Developed by Dr. Carlo A. Beretta 
 * Math Clinic CellNetworks, University of Heidelberg
 * Email: carlo.beretta@bioquant.uni-heidelberg.de
 * Web: http://math-clinic.bioquant.uni-heidelberg.de
 * Tel.: +49 (0) 6221 54 51435
 * 
 * 
 * Created: 2017/08/23
 * Last update: 2017/08/23
 */


// %%%%%%%%%%%%%%%%%%%%% Functions %%%%%%%%%%%%%%%%%%%%%
function CloseAllWindows() {
	while(nImages > 0) {
		selectImage(nImages);
		close();
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
	dirOut = dirOut + "Renamed_" + year + "-" + month + "-" + dayOfMonth + "_0" + second + File.separator;

	return dirOut;
	
}

// %%%%%%%%%%%%%%%%%%%%% Macro %%%%%%%%%%%%%%%%%%%%%
macro RenameFile {

	// 1. Close all the open images
	CloseAllWindows();

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
	
	} 
	
	// Do not display the images
	setBatchMode(true);

	// Open the file located in the input directory
	for (i=0; i<fileList.length; i++) {

		// Check the input file format .tif / .tiff
		if (endsWith(fileList[i], '.tiff') || endsWith(fileList[i], 'tif' )) {

			// Open the input image
			open(dirIn + fileList[i]);

			// Input file name 
			inputTitle = getTitle();
			print((i+1) + ". Image title: " + inputTitle);
			
			// Remove from _PMT...
			firstIndex = indexOf(inputTitle, " - ");
			firstString = substring(inputTitle, 0, firstIndex);

			// Save the renamed file
			if (i < 10) {
				saveAs("Tiff", dirOut + firstString + "_000" + i );
				inputTitle = getTitle();
				print(">. New file name: " + inputTitle);
				close(inputTitle);

				
			} else if (i >= 10 && i < 100) { 

				saveAs("Tiff", dirOut + firstString + "_00" + i );
				inputTitle = getTitle();
				print(">. New file name: " + inputTitle);
				close(inputTitle);
				
			} else {

				saveAs("Tiff", dirOut + firstString + "_0" + i );
				inputTitle = getTitle();
				print(">. New file name: " + inputTitle);
				close(inputTitle);
			}
		}
	}

	// Display the images
	setBatchMode(false);

	// Update the user
	print("\n%%% Congratulation your file have been successfully renamed %%%");
	
}

			
