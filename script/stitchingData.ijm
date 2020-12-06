/*
 * Project3 Eva Kamionka
 * 
 * Developed by Dr. Carlo A. Beretta 
 * Math Clinic CellNetworks, University of Heidelberg
 * Email: carlo.beretta@bioquant.uni-heidelberg.de
 * Web: http://math-clinic.bioquant.uni-heidelberg.de
 * Tel.: +49 (0) 6221 54 51435
 * 
 * Comments: 
 * NB: Input file name as to be: something_that_make_sense_0000.tif
 * It supports the following index: 0000, 000, 00, 0
 * 
 * The input as to be a folder containg subfolders with the pre-renamed images.
 * If something do not work properly please contact the author (see above).
 * 
 * Created: 2017/08/24
 * Last update: 2017/09/07
 */

// ########################## Functions ##########################
// Close all the open images before to start the macro
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

// Save and close Log window
function CloseLogWindow(dirOutAnalysis) {
	if (isOpen("Log")) {
		selectWindow("Log");
		saveAs("Text", dirOutAnalysis + "Log.txt"); 
		run("Close");
		
	} else {

		print("Log window has not been found");
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

// ########################## Macro ##########################
macro MultipleFileStitching {

	// Output the starting
	print("\nMultiple File Stitching macro started!");

	// 1. Close all the open images
	CloseAllWindows();
		
	// 2. Function choose the input root directory
	dirIn = InputDirectory();

	// Get the folder path
	dirOutAnalysis = dirIn;

	// Get the list of subfolder in the input directory
	folderList = getFileList(dirIn);
	
	// Dialog box input stitching parametrs
	// Default parameters x Eva Kamionka project
	// Image properties dialog box
	title = "Set Properties & Enter the Grid Parameters";
  	unit = "pixel";
	pixel_width = 1.0000;
	pixel_height = 1.0000;
	voxel_depth = 1.0000;
	gridSizeX = 4; gridSizeY = 3; tileOverlapping = 20; firstFileIndex = 0; regression = 0.50; maxAvg = 2.50; absDisplacment = 3.50;
  	Dialog.create("Grid Stitching Paramters - CellNetworks - Math-Clinic");
  	Dialog.addString("Unit: ", unit);
  	Dialog.addNumber("Width: ", pixel_width, 3, 10, "");
  	Dialog.addNumber("Height: ", pixel_height, 3, 10, "");
  	Dialog.addNumber("Voxel depth: ", voxel_depth, 3, 10, "");
  	Dialog.addNumber("Grid size (x):", 4);
  	Dialog.addNumber("Grid size (y):", 3);
  	Dialog.addNumber("Tile overlapping (%):", 20);
  	Dialog.addNumber("Index of the first file:", 0);
  	Dialog.addChoice("Grid type:", newArray("Grid: row-by-row", "Grid: column-by-column"));
  	Dialog.addChoice("Order:", newArray("Right & Down                ", "Down & Right                "));
  	Dialog.addChoice("Method:", newArray("Linear Blending", "Average", "Median", "Max. Intensity", "Min. Intensity"));
	Dialog.addNumber("Regression threshold:", 0.50);
	Dialog.addNumber("Max/Avg displacement threshold:", 2.50);
	Dialog.addNumber("Absolute displacement threshold:", 3.50);
  	Dialog.addCheckbox("Compute overlap", false);
  	Dialog.addCheckbox("Subpixel accuracy", true);
  	Dialog.show();

  	// Dialog box variables
  	unit = Dialog.getString();
  	pixel_width = Dialog.getNumber();
  	pixel_height = Dialog.getNumber();
  	voxel_depth = Dialog.getNumber();
  	gridSizeX = Dialog.getNumber();
  	gridSizeY = Dialog.getNumber();
  	tileOverlapping = Dialog.getNumber();
  	firstFileIndex = Dialog.getNumber();
  	type = Dialog.getChoice();
  	order = Dialog.getChoice();
  	method = Dialog.getChoice();
  	regression = Dialog.getNumber();
  	maxAvg = Dialog.getNumber();
  	absDisplacment = Dialog.getNumber();
  	compute = Dialog.getCheckbox();
  	subpixel = Dialog.getCheckbox();

  	// Output the choosen parameters
  	print("Choosen setting:");
  	print("1. Grid size (XY): "+ gridSizeX + " x " + gridSizeY);
  	print("2. Tile overlapping: " + tileOverlapping + " %");
  	print("3. Index of first file: " + firstFileIndex);
  	print("4. " + type);
  	print("5. Order: " + order);
  	print("6. Method: " + method);

  	if (compute == 0) {

  		print("7. Compute overlapping: false");

  	} else if (compute == 1) {

  		print("7. Compute overlapping: true");
  	}
  	
  	if (subpixel == 0) {

  		print("8. Subpixel accuracy: false");

  	} else if (subpixel == 1) {

  		print("8. Subpixel accuracy: true");
  	}
  	
	// Display memory usage and don't display the images
	doCommand("Monitor Memory...");
	setBatchMode(true);
	
	// Get the starting time for later
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);

	// Check the number of subfolder in the input directory
	for (i=0; i<folderList.length; i++) {
	
		// List of subfolders
		path = dirIn + folderList[i];
		print("\n");
		print("################################################################################################################");
		print((i+1) + ". Processing Subfolder: "+ path);

		// Look in the subfolders and output the list of file
		fileList = getFileList(dirIn + folderList[i]);

		if (endsWith(path, "/")) {

			// Create the output directory inside the subfolder to store the results
			// Use the new string as a path to create the OUTPUT directory.
			dirOut = dirIn + folderList[i] + "StitchedFile_" + "0" + second + File.separator;	
			dirOutTextFile = folderList[i] + "StitchedFile_" + "0" + second + File.separator;
			if (!File.exists(dirOut)) {	
				File.makeDirectory(dirOut);
				text = "Output path: " + dirOut;
				print(text);
				print("\n");
	
			}
			
			// Get the file name of the first file in the input directory
			fileName = folderList[i] + fileList[1];

			// Check the input file format
			if (endsWith(fileName, '.tiff') || endsWith(fileName, '.tif')) {

				// Keep the original file name for saving
				saveName = fileList[1];
	
				// Get the input image file name and make it general
				// It is used as file name to save the stitched file
				PMTseparator = indexOf(saveName, "_PMT_");
				saveName = substring(saveName, 0, PMTseparator);
				// print(saveName);
		
				// Remove the last directory file separator to work with the stitching plugin
				separatorIndex = lastIndexOf(path, File.separator);
				stringDirectory = substring(path, 0, separatorIndex);
	
				// Remove .tif from the file name
				firstPart = fileName;
				dotSeparator = lastIndexOf(firstPart, ".");
				firstPart = substring(firstPart, 0, dotSeparator);
		
				// Split the string by file separtor
				splitString = split(firstPart, "_PMT_"); 
				for(j=0; j<splitString.length; j++) {
		
					// OutPut file name parts
					// print("parts["+j+"]="+splitString[j]);
					
					// Last element of the string
					countIndex = splitString[j];
					// print(countIndex);
			
				} 
	
				// First part of file name
				indexLastSeparator = lastIndexOf(firstPart, countIndex);
				firstPart = substring(firstPart, 0, indexLastSeparator);
				// print(firstPart);
	
				// Index the value extention in the file name [0000]
				secondPart = countIndex;
				// print(secondPart);
				lengthSecondPart = lengthOf(secondPart);
				// print(lengthSecondPart);
	
				// Choose the right index using the file name information
				if (lengthSecondPart == 4) {
	
					index = "iiii";
					// print("{" + index + "}");
			
				} else if (lengthSecondPart == 3) {
			
					index = "iii";
					// print("{" + index + "}");
	
	 			}  else if (lengthSecondPart == 2) {
			
					index = "ii";
					// print("{" + index + "}");
	
	 			} else if (lengthSecondPart == 1) {
	
					index = "i";
					// print("{" + index + "}");
	 		
				} else {
				
					print("Error: The input file index is not supported");
					print("Please Contact: carlo.beretta@bioqunat.uni-heidelberg.de at CellNetworks Math-Clinic");
					CloseAllWindows();
					exit();
			
				}
	
				// Stitching Grid Collection setting conditions
				if (compute == false && subpixel == false) {
			
					run("Grid/Collection stitching", "type=["+type+"] order=["+order+"] grid_size_x=["+gridSizeX+"] grid_size_y=["+gridSizeY+"] tile_overlap=["+tileOverlapping+"] first_file_index_i=["+firstFileIndex+"] directory=["+stringDirectory+"] file_names=["+firstPart+"{"+index+"}.tif] output_textfile_name=["+dirOutTextFile+" TileConfiguration.txt] fusion_method=["+method+"] regression_threshold=["+regression+"] max/avg_displacement_threshold=["+maxAvg+"] absolute_displacement_threshold=["+absDisplacment+"] add_tiles_as_rois computation_parameters=[Save computation time (but use more RAM)] image_output=[Fuse and display]");
			
				} else if (compute == true && subpixel == false) {
	
					run("Grid/Collection stitching", "type=["+type+"] order=["+order+"] grid_size_x=["+gridSizeX+"] grid_size_y=["+gridSizeY+"] tile_overlap=["+tileOverlapping+"] first_file_index_i=["+firstFileIndex+"] directory=["+stringDirectory+"] file_names=["+firstPart+"{"+index+"}.tif] output_textfile_name=["+dirOutTextFile+" TileConfiguration.txt] fusion_method=["+method+"] regression_threshold=["+regression+"] max/avg_displacement_threshold=["+maxAvg+"] absolute_displacement_threshold=["+absDisplacment+"] add_tiles_as_rois compute_overlap computation_parameters=[Save computation time (but use more RAM)] image_output=[Fuse and display]");
		
				} else if (compute == true && subpixel == true) {
	
					run("Grid/Collection stitching", "type=["+type+"] order=["+order+"] grid_size_x=["+gridSizeX+"] grid_size_y=["+gridSizeY+"] tile_overlap=["+tileOverlapping+"] first_file_index_i=["+firstFileIndex+"] directory=["+stringDirectory+"] file_names=["+firstPart+"{"+index+"}.tif] output_textfile_name=["+dirOutTextFile+" TileConfiguration.txt] fusion_method=["+method+"] regression_threshold=["+regression+"] max/avg_displacement_threshold=["+maxAvg+"] absolute_displacement_threshold=["+absDisplacment+"] add_tiles_as_rois compute_overlap subpixel_accuracy computation_parameters=[Save computation time (but use more RAM)] image_output=[Fuse and display]");
			
				} else if (compute == false && subpixel == true) {
			
					run("Grid/Collection stitching", "type=["+type+"] order=["+order+"] grid_size_x=["+gridSizeX+"] grid_size_y=["+gridSizeY+"] tile_overlap=["+tileOverlapping+"] first_file_index_i=["+firstFileIndex+"] directory=["+stringDirectory+"] file_names=["+firstPart+"{"+index+"}.tif] output_textfile_name=["+dirOutTextFile+" TileConfiguration.txt] fusion_method=["+method+"] regression_threshold=["+regression+"] max/avg_displacement_threshold=["+maxAvg+"] absolute_displacement_threshold=["+absDisplacment+"] add_tiles_as_rois subpixel_accuracy computation_parameters=[Save computation time (but use more RAM)] image_output=[Fuse and display]");
			
				}
		
				// Get output image title
				stitchingTitle = getTitle();
				run("Remove Overlay");
	
				// Calibrate the output images
				properties = "unit=["+unit+"] pixel_width=["+pixel_width+"] pixel_height=["+pixel_height+"] voxel_depth=["+voxel_depth+"]";
				run("Properties...", properties);
	
				// Save the stitched results in the output directory
				saveAs("Tiff", dirOut + "Stitched_" + saveName);
				stitchingTitle = getTitle();
	
				// Compute the MIP and save the results in the output folder directory
				run("Z Project...", "projection=[Max Intensity]");
				getMinAndMax(min, max);
				maxTitle = getTitle();
				saveAs("Tiff", dirOut + "Max_Stitched_" + saveName);
				maxTitle = getTitle();
				close(maxTitle);
	
				// Replace stripes with background
				selectImage(stitchingTitle);
	
				// Duplicate the stitched z-stack
				run("Duplicate...", "duplicate");
				setAutoThreshold("Triangle dark stack");
				run("Convert to Mask", "method=Triangle background=Dark calculate black");
				run("Median...", "radius=2");
				stitchingTitleBinary = getTitle();
	
				// Correct threshold by background selection
				for (j=0; j<nSlices; j++) {
	
					n = j+1;
					print("\\Update:Processing slice (Background correction...): " +n);
					selectImage(stitchingTitleBinary);
					setSlice(j+1);
					List.setMeasurements(n);
					imageMode = List.getValue("Mode");
	
					if (imageMode == 255) {
						run("Set...", "value=0 slice");
					
					}
					
					List.clear;
					
				}
	
				// Convert the input stitched stack to 8 bit for subtraction
				selectImage(stitchingTitle);
				setMinAndMax(min, max);
				run("8-bit");
	
				// Image subtraction 
				imageCalculator("Subtract create stack", stitchingTitle, stitchingTitleBinary);
				stitchingTitleSubtraction = getTitle();
				run("Grays");
	
				// Compute the mode value on the average intesnity projection
				run("Z Project...", "projection=[Average Intensity]");
				averageTitle = getTitle();
				List.setMeasurements();
				averageModeValue = List.getValue("Mode");
				close(averageTitle);
	
				// Replace the 0 value with the mode value
				selectImage(stitchingTitleSubtraction);
				run("Replace value", "pattern=0 replacement=["+averageModeValue+"]");
				List.clear();
				
				// Compute the Sum, subtract the background and save the results in the output folder directory
				run("Z Project...", "projection=[Sum Slices]");
				run("Subtract Background...", "rolling=50");
				sumTitle = getTitle();
				saveAs("Tiff", dirOut + "Sum_Stitched_Corrected_" + saveName);
				sumTitle = getTitle();
				close(sumTitle);
	
				// Save the stitched results in the output directory and close it
				selectImage(stitchingTitleSubtraction);
				saveAs("Tiff", dirOut + "Stitched_Corrected_" + saveName);
				stitchingTitleSubtraction = getTitle();
				close(stitchingTitleSubtraction);
	
				// Close all the open image one by one
				selectImage(stitchingTitle);
				close(stitchingTitle);
				selectImage(stitchingTitleBinary);
				close(stitchingTitleBinary);
	
				// Reclaim memory 
				call("java.lang.System.gc");


			} else {

				print("File format is not supported: " + fileName);
				
			}

		} else {

			// Quit the macro if NaN subdirectory are found
			print("Error: The input directroy must contain at least one subdirectory with the input images save as .tiff!");
			
			// Check which file cause the error
			indexFormat = lastIndexOf(path, File.separator);
			outPutFormat = substring(path, indexFormat+1); // +1 to delete the file separator from the printed output
			print("Invalid input: " + outPutFormat);

			// End functions
			CloseMemoryWindow();
			CloseAllWindows();

			// Quit the macro
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

	// End function
	CloseLogWindow(dirOutAnalysis);
	
	// Display the images
	setBatchMode(false);
	showStatus("Completed");
	
}
