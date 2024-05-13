string = "This program is intended to measure the length of the Purkinje cell layer in mouse brain tissue sections.\nPlease note that this program is computer-assisted, not completely automatic. You will be required to adjust the generated outlines.\nBefore running this program, put all NUCLEAR images in the same folder.\nCrop images to show only the cerebellum and convert to tiffs.\nEnsure that the pixel scaling is properly displayed in microns.\nPress OK to continue or cancel to quit."
Dialog.create("Before Running This Program");
Dialog.addMessage(string);
Dialog.show();

run("Set Measurements...", "perimeter redirect=None decimal=0");
setForegroundColor(0, 0, 0);
setBackgroundColor(255, 255, 255);

Dialog.create("Where Are Your (NUCLEAR ONLY) Images Located?");
Dialog.addDirectory("Image Folder:", File.getDefaultDir);
Dialog.show();
directory = Dialog.getString();

files = getFileList(directory);

//file management - if binaries exist, don't reevaluate, if not, make binary directory
if (File.exists(directory + "binaries/") == 1) {
	binaryfiles = getFileList(directory + "binaries/");
	if (binaryfiles.length > 0) {
		for (i = 0; i < binaryfiles.length; i++) {
			newname = split(binaryfiles[i], "_");
			binaryfiles[i] = newname[0] + "_c1.tif";
		}
		for (i = 0; i < binaryfiles.length; i++) {
			files = Array.deleteValue(files, binaryfiles[i]);
		}
	}
} else {
	File.makeDirectory(directory + "binaries/");
}

//Process files
for (i = 0; i < files.length; i++) {
	if (endsWith(files[i], ".tif")) {
		Processor(files[i]);
	}
}

print("Finished!");

//functions
function Processor(path) { 
// function description
	setBatchMode(true);
	
	//outline cerebellum villi
	open(directory + path);
	getPixelSize(unit, pixelWidth, pixelHeight);
	run("Duplicate...", "duplicate");
	run("Gaussian Blur...", "sigma=400 stack");
	run("Calculator Plus", "i1="+path+" i2="+File.getNameWithoutExtension(path)+"-1.tif operation=[Divide: i2 = (i1/i2) x k1 + k2] k1=3000 k2=0 create");
	selectImage("Result");
	close("\\Others");	
	run("Gaussian Blur...", "sigma=90");
	run("Find Edges");
	setAutoThreshold("Otsu dark");
	setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Analyze Particles...", "size=10000-Infinity add");
	
	//clear outside cerebellum villi
	roiManager("select", Array.getSequence(roiManager("count")));
	roiManager("Combine");
	run("Clear Outside");
	roiManager("reset");
	run("Select None");
	
	//save first shot at binary
	binary = File.getNameWithoutExtension(path) + "_binary.tif";
	saveAs("tiff", directory + "/binaries/" + binary);
	close("*");
	
	//Fix cerebellum villi
	setBatchMode("exit and display");
	FixVilli();         
}

function FixVilli() {
// function description
	open(directory + path);
	run("8-bit");
	rename("original");
	open(directory + "/binaries/" + binary);
	rename("binary");
	run("Merge Channels...", "c2=binary c4=original create");
	run("Enhance Contrast...", "saturated=0");
	
	setTool("multipoint");
	string = "Please use the drawing tools to fix the outline.\nAny small, unconnected pieces will be removed.\nONLY when the outline is completely correct, place a single point selection anywhere.\nDO NOT PRESS OK until finished.";
	Dialog.createNonBlocking("");
	Dialog.addMessage(string);
	Dialog.show();
	
	if (selectionType() < 0) {
		run("Split Channels");
		selectWindow("C1-Composite");
		close("\\Others");
		run("Convert to Mask");
		setForegroundColor(0, 0, 0);
		setBackgroundColor(255, 255, 255);
		run("Fill Holes");
		run("Analyze Particles...", "size=100000-Infinity add");
		roiManager("select", Array.getSequence(roiManager("count")));
		if (roiManager("count") > 1) {
			roiManager("Combine");
		}
		run("Clear Outside");
		roiManager("reset");
		run("Select None");
		saveAs("tiff", directory + "/binaries/" + binary);
		close("*");
		FixVilli();
	} else {
		setBatchMode(true);
		close("*");
	}
}
