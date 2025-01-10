run("Set Measurements...", "perimeter redirect=None decimal=0");

Dialog.create("Where Are Your Images Located?");
Dialog.addDirectory("Image Folder:", File.getDefaultDir);
Dialog.show();
directory = Dialog.getString();

//file management - get root names only
fileroots = getFileList(directory + "Nuclear/");
for (i = 0; i < fileroots.length; i++) {
	if (endsWith(fileroots[i], ".tif")) {
		newnames = split(fileroots[i], "_");
		fileroots[i] = newnames[0];
	} else {
		fileroots = Array.deleteValue(fileroots, fileroots[i]);
	}
}

Table.create("Distances");

for (i = 0; i < fileroots.length; i++) {
	distance = MeasurePerimeter(fileroots[i]);
	Table.set("Name", i, " " + fileroots[i], "Distances");
	Table.set("Purkinje Layer Length", i, distance, "Distances");
}

Table.save(directory + "Lengths.csv", "Distances");


function MeasurePerimeter(imageroot) { 
//Measure Purkinje Cell layer length
	setBatchMode(true);
	
	//get Pixel Width from calbindin image
	open(directory + "Calbindin/" + imageroot + "_c2.tif");
	rename("PCL");
	run("Enhance Contrast...", "saturated=0.35");
	run("8-bit");
	getPixelSize(unit, pixelWidth, pixelHeight);
	
	//measure full perimeter of binary image
	open(directory + "Nuclear/binaries/" + imageroot + "_c1_binary.tif");
	rename("Binary");
	run("Properties...", "unit=micron pixel_width=" + pixelWidth + " pixel_height=" + pixelHeight);
	run("Create Selection");
	run("Measure");
	overdistance = getResult("Perim.", 0);
	run("Clear Results");
	run("Select None");
	
	//get user input on unmeasured portions
	run("Merge Channels...", "c2=Binary c4=PCL create");
	
	setBatchMode("show");
	setTool("multipoint");
	string = "Set start/endpoints for unmeasured portions. DO NOT PRESS OK until finished.";
	Dialog.createNonBlocking("");
	Dialog.addMessage(string);
	Dialog.show();

	setBatchMode("hide");
	getSelectionCoordinates(x, y);
	
	//subtract unmeasured portions from total perimeter and return
	if (selectionType() == -1) {
		distance = round(overdistance/100)/10;
		return distance;
	} else {
		linedistances = newArray(0);
		arrayposition = 0;
		for (i = 0; i < x.length; i+=2) {
			linedistances[arrayposition] = pixelWidth*Math.sqrt(Math.sqr(x[i+1]-x[i])+Math.sqr(y[i+1]-y[i]));
			arrayposition = arrayposition + 1;
		}
		for (i = 0; i < linedistances.length; i++) {
			overdistance = overdistance - linedistances[i];
		}
		distance = round(overdistance/100)/10;
		return distance;
	}
	close("*");
}
