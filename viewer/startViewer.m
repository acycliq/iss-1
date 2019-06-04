function out = startViewer(varargin)
img = '.\img\background_boundaries.tif'
o = varargin{1};
% img = '\\basket.cortexlab.net\data\kenneth\iss\170315_161220KI_4-3\Output\background_image.tif'

myData.Roi = getRoi(o);
myData.CellYX = getCellYX(o, myData);

% get the name of the folder where viewer lives in
viewerRoot = fileparts(which(mfilename));

clndt = cleanData(o, myData.Roi);
uGenes = clndt.uGenes;
PlotSpots = clndt.PlotSpots;
GeneNo = clndt.GeneNo;

myData.allSpots = collectSpots(o, uGenes, PlotSpots, GeneNo);


if nargin == 2
    collectData(o, myData, varargin{2});
elseif nargin == 1
    collectData(o, myData);
else 
    error('I shouldnt be here..')
end

Roi = myData.Roi;
xRange = 1+Roi(2)-Roi(1);
yRange = 1+Roi(4)-Roi(3);
scaleFactor = 32768/max(xRange, yRange);

% cmdStr = ['.\vips\bin\vips.exe'  ' resize '  '.\img\DapiBoundaries_161220KI_3-1_left.tif out.tif ', num2str(scaleFactor, 6) ]
% first scale up the image
dim = 32768;
bigImg = [num2str(dim), 'px.tif'];
% tilesFolder = ['.\dashboard\data\img\', num2str(dim), 'px.dz'];


% do a santity check before start upscaling the image 
sanityCheck(img, Roi)

% get the full path the the Vips executables
myVips = vips(viewerRoot);
vipsExe = myVips.exe;
vipsheaderExe = myVips.headerExe;

fprintf('%s: Upscaling the image \n', datestr(now));
cmdStr = [vipsExe,  ' resize ' img ' ' bigImg ' ' num2str(scaleFactor, 9), ' --kernel nearest' ];
system(cmdStr);
fprintf('%s: Done! \n', datestr(now));


% save the image dimensions and the ROI to json files
write2file(vipsheaderExe, bigImg, Roi, viewerRoot)

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


% launch now the viewer
system ('start chrome http://localhost:8080')
system ('java -jar ./jar/nanoSimpleWWW.jar > log.txt')


end


function write2file(vipsheaderExe, bigImg, Roi, viewerRoot)

% read the dimensions of the scaled image
cmdStr = [vipsheaderExe, ' -f height ', bigImg];
[status, h] = system(cmdStr);
cmdStr = [vipsheaderExe, ' -f width ', bigImg];
[status, w] = system(cmdStr);
imageStruct.height = str2double(h);
imageStruct.width =  str2double(w);
saveJSONfile(imageStruct, [viewerRoot, '\dashboard\data\json\imageSize.json'])


% save the roi as a json file
roiStruct.x0 = Roi(1);
roiStruct.x1 = Roi(2);
roiStruct.y0 = Roi(3);
roiStruct.y1 = Roi(4);
saveJSONfile(roiStruct, [viewerRoot, '\dashboard\data\json\roi.json'])

end

function out = vips(viewerRoot)

vipsExe = fullfile(viewerRoot, 'vips', 'bin', 'vips.exe');
vipsExe = ['"', vipsExe '"'];

vipsheaderExe = fullfile(viewerRoot, 'vips', 'bin', 'vipsheader.exe');
vipsheaderExe = ['"', vipsheaderExe '"'];

vips.exe = vipsExe;
vips.headerExe = vipsheaderExe;

out = vips;
end


function out = getRoi(o)

y0 = min(o.CellCallRegionYX(:,1));
x0 = min(o.CellCallRegionYX(:,2));
y1 = max(o.CellCallRegionYX(:,1));
x1 = max(o.CellCallRegionYX(:,2));

% myData.Roi = [x0, x1, y0, y1];
fprintf('%s: The Roi is BottomLeft: [%d, %d] and topRight: [%d, %d] \n', datestr(now), x0, y0, x1, y1);
out = [x0, x1, y0, y1];

end


function out = getCellYX(o, myData)

fprintf('%s: loading CellMap from %s ...', datestr(now), o.CellMapFile);
load(o.CellMapFile)
fprintf('Done! \n');

sanityCheck2(CellMap, myData.Roi)


x0 = myData.Roi(1);
y0 = myData.Roi(3);
rp = regionprops(CellMap);
CellYX = fliplr(vertcat(rp.Centroid)) + [y0 x0]; % convert XY to YX

out = CellYX;
end



function out = cleanData(o, Roi)

SpotGeneName = o.GeneNames(o.SpotCodeNo);
uGenes = unique(SpotGeneName);

% which ones pass quality threshold (combi first)
QualOK = o.quality_threshold;

% now show only those in Roi
if ~isempty(Roi)
    InRoi = all(o.SpotGlobalYX>=Roi([3 1]) & o.SpotGlobalYX<=Roi([4 2]),2);
else
    InRoi = true;
end

PlotSpots = find(InRoi & QualOK);
[~, GeneNo] = ismember(SpotGeneName(PlotSpots), uGenes);

out.uGenes = uGenes;
out.PlotSpots = PlotSpots;
out.GeneNo = GeneNo;

end


function sanityCheck(img, roi)
viewerRoot = fileparts(which(mfilename));
vipsheaderExe = fullfile(viewerRoot, 'vips', 'bin', 'vipsheader.exe');
vipsheaderExe = ['"', vipsheaderExe '"'];

% get the image dimensions from the tif
cmdStr = [vipsheaderExe, ' -f height ', img];
[~, hImg] = system(cmdStr);
hImg = str2double(hImg);

cmdStr = [vipsheaderExe, ' -f width ', img];
[~, wImg] = system(cmdStr);
wImg = str2double(wImg);

% get the image dimensions as infered by the roi
dimRoi = diff(roi) + 1;
hRoi = dimRoi(3);
wRoi = dimRoi(1);

if (hRoi ~= hImg) || (wRoi ~= wImg)
    error('The ROI implies an image of dimension %d by %d whereas the image is %d by %d pixels', wRoi, hRoi, wImg, hImg)
end

end


function sanityCheck2(CellMap, roi)

[h, w] = size(CellMap);

% get the image dimensions as infered by the roi
dimRoi = diff(roi) + 1;
hRoi = dimRoi(3);
wRoi = dimRoi(1);

if (hRoi ~= h) || (wRoi ~= w)
    error('The ROI implies an image of dimension %d by %d whereas the CellMap is %d by %d pixels', wRoi, hRoi, w, h)
end

end


