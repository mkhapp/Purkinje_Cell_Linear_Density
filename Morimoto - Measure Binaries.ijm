
	//Measure Purkinje Cell layer length
	run("Select None");
	setBatchMode("show");
	setTool("multipoint");
	string = "Set start and endpoint for cell layer. DO NOT PRESS OK until finished.";
	Dialog.createNonBlocking("");
	Dialog.addMessage(string);
	Dialog.show();

	setBatchMode("hide");
	getSelectionCoordinates(x, y);
	setLineWidth(50);
	drawLine(x[0], y[0], x[1], y[1]);
	run("Fill Holes");
	run("Create Selection");
	run("Measure");
	overdistance = getResult("Perim.", 0);
	run("Clear Results");
	linedistance = pixelWidth*Math.sqrt(Math.sqr(x[1]-x[0])+Math.sqr(y[1]-y[0]));
	distance = round((overdistance - linedistance)/100)/10;
	binary = File.getNameWithoutExtension(path) + "_binary.tif";
	saveAs("tiff", directory + binary);
	close("*");
	return distance;
}

function FixVilli() { 
// function description
	setBatchMode("show");
	setTool("multipoint");
	string = "Please connect any missing pieces. DO NOT PRESS OK until finished.";
	Dialog.createNonBlocking("");
	Dialog.addMessage(string);
	Dialog.show();
	
	setBatchMode("hide");
	if (selectionType() >= 0) {
		getSelectionCoordinates(x, y);
		setLineWidth(50);
		for (i = 0; i < x.length; i+=2) {
			drawLine(x[i], y[i], x[i+1], y[i+1]);
		}
		run("Fill Holes");
		run("Select None");
		FixVilli();
	}
}