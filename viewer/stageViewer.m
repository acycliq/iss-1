function out = stageViewer(o, myData, cellCallData)
img = '.\img\background_boundaries.tif'

% get the name of the folder where viewer lives in
viewerRoot = fileparts(which(mfilename));

% rename the subclasses PC.CA2 and PC.CA3 to PC.Other1 and PC.Other2 
isPC.CA2 = strcmp(myData.ClassNames, 'PC.CA2');
myData.ClassNames{isPC.CA2} = 'PC.Other1';

isPC.CA3 = strcmp(myData.ClassNames, 'PC.CA3');
myData.ClassNames{isPC.CA3} = 'PC.Other2';

clndt = cleanData(o, myData);
uGenes = clndt.uGenes;
PlotSpots = clndt.PlotSpots;
GeneNo = clndt.GeneNo;

myData.allSpots = collectSpots(o, uGenes, PlotSpots, GeneNo);

collectData(o, myData, cellCallData);

Roi = myData.Roi;
xRange = 1+Roi(2)-Roi(1);
yRange = 1+Roi(4)-Roi(3);
scaleFactor = 32768/max(xRange, yRange);

% cmdStr = ['.\vips\bin\vips.exe'  ' resize '  '.\img\DapiBoundaries_161220KI_3-1_left.tif out.tif ', num2str(scaleFactor, 6) ]
% first scale up the image
dim = 32768;
bigImg = [num2str(dim), 'px.tif'];
% tilesFolder = ['.\dashboard\data\img\', num2str(dim), 'px.dz'];

fprintf('%s: Upscaling the image \n', datestr(now));
vipsExe = fullfile(viewerRoot, 'vips', 'bin', 'vips.exe');
vipsExe = ['"', vipsExe '"'];
cmdStr = [vipsExe,  ' resize ' img ' ' bigImg ' ' num2str(scaleFactor, 9), ' --kernel nearest' ];
system(cmdStr);
fprintf('%s: Done! \n', datestr(now));

% read the dimensions of the scaled image
vipsheaderExe = fullfile(viewerRoot, 'vips', 'bin', 'vipsheader.exe');
vipsheaderExe = ['"', vipsheaderExe '"'];
cmdStr = [vipsheaderExe, ' -f height ', bigImg];
[status, h] = system(cmdStr);
cmdStr = [vipsheaderExe, ' -f width ', bigImg];
[status, w] = system(cmdStr);
imageStruct.height = str2double(h);
imageStruct.width =  str2double(w);
saveJSONfile(imageStruct, [viewerRoot, '\dashboard\data\json\imageSize.json'])

%now make the tiles
fprintf('%s: Started doing the pyramid of tiles \n', datestr(now));
tilesFolder = fullfile(fileparts(cd), 'viewer', 'dashboard', 'data', 'img', [num2str(dim),'px']);
if ~exist(tilesFolder, 'dir')
    fprintf('%s: Folder doesnt exist... \n', datestr(now));
    mkdir(tilesFolder);
    fprintf('%s: Created folder %s \n', datestr(now), tilesFolder);
end
% enclose the name is double quotes to avoid problems with spaces in the path
tilesFolder = ['"', tilesFolder, '"'];
cmdStr = [vipsExe, ' gravity ' bigImg ' ' [tilesFolder, '.dz'] '[layout=google,suffix=.png,skip_blanks=0] south-west ' num2str(dim) ' ' num2str(dim) ' --extend black'];
system(cmdStr);
fprintf('%s: Done! \n', datestr(now));

% save the roi as a json file
roiStruct.x0 = Roi(1);
roiStruct.x1 = Roi(2);
roiStruct.y0 = Roi(3);
roiStruct.y1 = Roi(4);
saveJSONfile(roiStruct, [viewerRoot, '\dashboard\data\json\roi.json'])

% launch now the viewer
% system ('start http://localhost:8080')
system ('start chrome http://localhost:8080')
% system ('java -jar ./jar/SimpleWebServer.jar')
system ('java -jar ./jar/nanoSimpleWWW.jar')


        

end


function out = cleanData(o, myData)

Roi = myData.Roi;
SpotGeneName = o.GeneNames(o.SpotCodeNo);
uGenes = unique(SpotGeneName);

% which ones pass quality threshold (combi first)
QualOK = o.quality_threshold;

% now show only those in Roi
if ~isempty(myData.Roi)
    InRoi = all(o.SpotGlobalYX>=myData.Roi([3 1]) & o.SpotGlobalYX<=myData.Roi([4 2]),2);
else
    InRoi = true;
end

PlotSpots = find(InRoi & QualOK);
[~, GeneNo] = ismember(SpotGeneName(PlotSpots), uGenes);

out.uGenes = uGenes;
out.PlotSpots = PlotSpots;
out.GeneNo = GeneNo;

end

