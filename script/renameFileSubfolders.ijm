/*
 * Project2 Eva Kamionka
 * 
 * Developed by Dr. Carlo A. Beretta 
 * Math Clinic CellNetworks, University of Heidelberg
 * Email: carlo.beretta@bioquant.uni-heidelberg.de
 * Web: http://math-clinic.bioquant.uni-heidelberg.de
 * Tel.: +49 (0) 6221 54 51435
 * 
 * Added: check the file format. Only tiff file are processed.
 * Otherwise a warning message is created in the Log file.
 * 
 * Created: 2017/08/23
 * Last update: 2020/10/30
 */

// %%%%%%%%%%%%%%%%%%%%% Functions %%%%%%%%%%%%%%%%%%%%%
function CloseAllWindows() {
	while(nImages > 0) {
		selectImage(nImages);
		close();
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

// ########################## Macro ##########################
macro RenameFileFromSubfolders {

	// 1. Close all the open images
	CloseAllWindows();
	
	// Display memory usage and don't display the images
	doCommand("Monitor Memory...");
	setBatchMode(true);
	
	// Get the starting time for later
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	
	// 2. Function choose the input root directory
	dirIn = InputDirectory();
	
	// Get the list of subfolder in the input directory
	folderList = getFileList(dirIn);
	print("Number of subfolder to process:", folderList.length);
	
	// 3. Create the output directory in the input path
	dirOut = OutputDirectory(dirIn, year, month, dayOfMonth, second);
	
	if (!File.exists(dirOut)) {	
		File.makeDirectory(dirOut);
		text = "Output path: " + dirOut;
		print(text);
		
	} 
	
	// Loop over the folders
	for (i=0; i<folderList.length; i++) {
		
		// List of subfolders
		path = dirIn + folderList[i];
		print("\n");
		print((i+1) + ". Processing Subfolder: "+ path);
	
		fileList = getFileList(path);
		indexCh0 = 0;
		indexCh1 = 0;
	
		if (endsWith(path, "/")) {
	
			for (k=0; k<fileList.length; k++) {

				// Check the input file format .tiff / .tif
				if (endsWith(fileList[k], '.tiff') || endsWith(fileList[k], '.tif' )) {

					// Open one file after the otherone
					open(dirIn + folderList[i] + fileList[k]);
	
					// Input file name 
					inputTitle = getTitle();
					print((k+1) + ". Image title: " + inputTitle);

					// Remove file extension .tif / tiff
            		dotIndex = indexOf(inputTitle, ".");
            		title = substring(inputTitle, 0, dotIndex);
				
					// Eva images: Remove from ] [...
					firstIndex = indexOf(title, "] [");
					if (firstIndex != -1)  {
					
						firstString = substring(title, 0, firstIndex);

					}

					// Varun images: Remove in bewteen [...]
					firstIndex = indexOf(title, "[");
					lastIndex = indexOf(title, "]");
					if (firstIndex != -1 && lastIndex != -1)  {
					
						firstString = substring(title, 0, firstIndex);
						lastString = substring(title, lastIndex+1, lengthOf(title)); 
						renameTitle = firstString + lastString;
						firstString = renameTitle;

					}
	
					// Create an output directory in the output directory path
					dirOutFolder = dirOut + "0" + i + "_Renamed_" + firstString + File.separator;
					if (!File.exists(dirOutFolder)) {	
						
						File.makeDirectory(dirOutFolder);
		
					}

					// Count file x channel
					channelFirstIndex = indexOf(title, "C00");
					channelSecondIndex = indexOf(title, "C01");

					if (channelFirstIndex != -1) {

						indexCh0 += 1;
						
							// Save the renamed file
						if (k < 10) {
							
							saveAs("Tiff", dirOutFolder + firstString + "_PMT_000" + indexCh0 );
							inputTitle = getTitle();
							print(">. New file name: " + inputTitle);
							close(inputTitle);
	
					
						} else if (k >= 10 && k < 100) { 
	
							saveAs("Tiff", dirOutFolder + firstString + "_PMT_00" + indexCh0 );
							inputTitle = getTitle();
							print(">. New file name: " + inputTitle);
							close(inputTitle);
					
						} else {
	
							saveAs("Tiff", dirOutFolder + firstString + "_PMT_0" + indexCh0 );
							inputTitle = getTitle();
							print(">. New file name: " + inputTitle);
							close(inputTitle);
						}
						
					} else if (channelSecondIndex != -1) {

						indexCh1 += 1;
						
						// Save the renamed file
						if (k < 10) {
							
							saveAs("Tiff", dirOutFolder + firstString + "_PMT_000" + indexCh1 );
							inputTitle = getTitle();
							print(">. New file name: " + inputTitle);
							close(inputTitle);
	
					
						} else if (k >= 10 && k < 100) { 
	
							saveAs("Tiff", dirOutFolder + firstString + "_PMT_00" + indexCh1 );
							inputTitle = getTitle();
							print(">. New file name: " + inputTitle);
							close(inputTitle);
					
						} else {
	
							saveAs("Tiff", dirOutFolder + firstString + "_PMT_0" + indexCh1 );
							inputTitle = getTitle();
							print(">. New file name: " + inputTitle);
							close(inputTitle);
						}

					}

				} else {

					// Warning if the directory do not contain file .tiff/tif
					print(">>>>> Warning - File not supported: " + fileList[k] + " <<<<<");
				}
	
			}
			
		} else {
			
				// Quit the macro if NaN subdirectory are found
				print("Error: The input directroy must contain at least one subdirectory with the input images!");
				exit();
			
		}
		
	}
	
	// End function 
	CloseMemoryWindow();
		
	// Update the user 
	text = "\nNumber of subdirectory processed: " + folderList.length;
	print(text);
	text = "\n%%% Congratulation your file have been successfully stitched %%%";
	print(text);
		
	// Display the images
	setBatchMode(false);

}
