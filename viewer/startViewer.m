function startViewer(o, img, cellCallData)

dim = 32768;

if ~exist('cellCallData', 'var')
    % parameter does not exist, so default it to something
    cellCallData = NaN;
    
end

if isstruct(cellCallData)
    fn = fieldnames(cellCallData);
    target = {'GeneNames', 'ClassNames', 'IncludeSpot', 'pCellClass', 'CellGeneCount', 'Neighbors', 'pSpotNeighb'};
    if ~isempty(setdiff(fn, target))
        msg = sprintf('%s: cellCallData should be a structure with fields: \n', datestr(now));
        msg = sprintf('%s \n %s \n ', msg, target{:});
        error(msg);
    end
end
    
myData.Roi = getRoi(o);
[myData.CellYX, status1] = getCellYX(o, myData);

% get the name of the folder where viewer lives in
viewerRoot = fileparts(which(mfilename));

if ~startsWith(viewerRoot, pwd)
    error('%s: The viewer folder should in the same folder as or below the %s', datestr(now), pwd)
end

% clear the folder from any old flatfiles.
clearDir(['"', fullfile(viewerRoot, 'dashboard', 'data', 'json'),'"'])

[uGenes, PlotSpots, GeneNo] = cleanData(o, myData.Roi);
myData.allSpots = collectSpots(o, uGenes, PlotSpots, GeneNo);

collectData(o, myData, cellCallData, viewerRoot);

if ~exist('img', 'var')
    fprintf('%s: No image passed-in. Black backround will be shown \n', datestr(now));
    
    % clear the folder from old files.
    myHandler(dim)
    
    % save the roi as a json file
    roiStruct.x0 = myData.Roi(1);
    roiStruct.x1 = myData.Roi(2);
    roiStruct.y0 = myData.Roi(3);
    roiStruct.y1 = myData.Roi(4);
    saveJSONfile(roiStruct, fullfile(viewerRoot, 'dashboard', 'data', 'json', 'roi.json'));
    
    % save the image size as a json file
    [scaleFactor, xRange, yRange] = getScaleFactor(myData.Roi);
    imageStruct.width = xRange * scaleFactor;
    imageStruct.height = yRange * scaleFactor;
    saveJSONfile(imageStruct,  fullfile(viewerRoot, 'dashboard', 'data', 'json', 'imageSize.json'));
    
    
else
    
    % calc how much you have to scale-up the image
    [scaleFactor, ~, ~] = getScaleFactor(myData.Roi);

    % get the full path the the Vips executables
    [vipsExe, vipsheaderExe] = vips(viewerRoot);

    % first scale up the image
    bigImg = [num2str(dim), 'px.tif'];
    bigImg = fullfile(viewerRoot, bigImg);

    % do a santity check before start upscaling the image 
    status2 = sanityCheck(img, myData.Roi);


    if all([status1, status2])
        % Upscale the image
        try
            flag1 = rescale(vipsExe, ['"', bigImg, '"'], img, scaleFactor);
            
            % check the output
            sanityCheck3(['"', bigImg, '"'], vipsheaderExe, dim)
        catch ME
            rethrow(ME)
        end

        % now make the tiles
        try
            flag2 = tileMaker(vipsExe, bigImg, dim, viewerRoot);
        catch ME
            warning('Failed during tile making...Black background image will be shown');
            getReport(ME)
            myHandler(dim);
        end
    else
        myHandler(dim);
    end

    
    % save the image dimensions and the ROI to json files
    write2file(vipsheaderExe, ['"', bigImg, '"'], myData.Roi, viewerRoot)
    
    % ImgPath = fullfile(viewerRoot, bigImg);
    if exist(bigImg, 'file') == 2
      delete(bigImg);
    end

end



subFolder = erase(viewerRoot, pwd);

% launch now the viewer
% fprintf('%s: Launching viewer. Copy-paste this link <a href="http://localhost:8080">http://localhost:8080</a> to the browser if it doesnt load automatically.\n', datestr(now))
fprintf('%s: Press ENTER to stop serving the dir and return to the Matlab prompt. \n', datestr(now));
% system ('start chrome http://localhost:8080');

nanoHttpd = fullfile(viewerRoot, 'jar', 'nanohttpd-webserver-2.1.1-jar-with-dependencies.jar');
system (['start chrome http://localhost:8080', subFolder, ' & java -jar ', ['"', nanoHttpd, '"'], ' > log.txt ']);


end


function [scaleFactor, xRange, yRange] = getScaleFactor(Roi)

xRange = 1+Roi(2)-Roi(1);
yRange = 1+Roi(4)-Roi(3);
scaleFactor = 32768/xRange;
if xRange <= yRange
    scaleFactor = scaleFactor * xRange/yRange;
end 

end


function myHandler(dim)
    % delete the contents from the folder 
    tilesFolder = mkTilesFolder(dim);
    
    % enclose the name is double quotes to avoid problems with spaces in the path
    tilesFolder = ['"', tilesFolder, '"'];
    clearDir(tilesFolder)
end


function out = rescale(vipsExe, bigImg, img, scaleFactor)

fprintf('%s: Upscaling the image \n', datestr(now));
cmdStr = [vipsExe,  ' resize ' img ' ' bigImg ' ' num2str(scaleFactor, 9), ' --kernel nearest' ];
status = system(cmdStr);

if status == 0
    fprintf('%s: Done! \n', datestr(now));
else
    error('%s: Failed! \n', datestr(now));
end

out = status;
end


function out = tileMaker(vipsExe, bigImg, dim, viewerRoot)

% first check if file exists
status = exist(bigImg, 'file') == 2;

if status
    fprintf('%s: Started doing the pyramid of tiles. It will take around 2mins and 1.5GB of diskspace. \n', datestr(now));
    tilesFolder = mkTilesFolder(dim, viewerRoot);
    
    % enclose the name is double quotes to avoid problems with spaces in the path
    tilesFolder = ['"', tilesFolder, '"'];
    bigImg = ['"', bigImg, '"'];
    clearDir(tilesFolder)

    cmdStr = [vipsExe, ' gravity ' bigImg ' ' [tilesFolder, '.dz'] '[layout=google,suffix=.png,skip_blanks=0] south-west ' num2str(dim) ' ' num2str(dim) ' --extend black'];
    status = system(cmdStr);

    if status == 0
        fprintf('%s: Done! \n', datestr(now));
    else
        error('%s: Failed! \n', datestr(now));
    end
    
else
     fprintf('%s: Image doesnt exist, showing a black backbground instead \n', datestr(now));
end

out = status;
end


function out = mkTilesFolder(dim, viewerRoot)

    tilesFolder = fullfile(viewerRoot, 'dashboard', 'data', 'img', [num2str(dim),'px']);
    if ~exist(tilesFolder, 'dir')
        fprintf('%s: Folder doesnt exist... \n', datestr(now));
        mkdir(tilesFolder);
        fprintf('%s: Created folder %s \n', datestr(now), tilesFolder);
    end
   
    out = tilesFolder;
end


function clearDir(tilesFolder)

% fprintf('%s: Deleting files \n', datestr(now));
cmdStr = ['del /S /Q ', tilesFolder, ' > NUL ']; 
[status, out] = system(cmdStr);
% fprintf('%s: Done \n', datestr(now));

end


function write2file(vipsheaderExe, bigImg, Roi, viewerRoot)

% read the dimensions of the scaled image
cmdStr = [vipsheaderExe, ' -f height ', bigImg];
[status, h] = system(cmdStr);
if status ~=0; error('Failed. \n%s', h); end

cmdStr = [vipsheaderExe, ' -f width ', bigImg];
[status, w] = system(cmdStr);
if status ~=0; error('Failed. \n%s', h); end

imageStruct.height = str2double(h);
imageStruct.width =  str2double(w);
saveJSONfile(imageStruct,  fullfile(viewerRoot, 'dashboard', 'data', 'json', 'imageSize.json'));

% save the roi as a json file
roiStruct.x0 = Roi(1);
roiStruct.x1 = Roi(2);
roiStruct.y0 = Roi(3);
roiStruct.y1 = Roi(4);
saveJSONfile(roiStruct, fullfile(viewerRoot, 'dashboard', 'data', 'json', 'roi.json'));

end

function [vipsExe, vipsheaderExe] = vips(viewerRoot)

vipsExe = fullfile(viewerRoot, 'vips', 'bin', 'vips.exe');
vipsExe = ['"', vipsExe '"'];

vipsheaderExe = fullfile(viewerRoot, 'vips', 'bin', 'vipsheader.exe');
vipsheaderExe = ['"', vipsheaderExe '"'];

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


function [CellYX, status] = getCellYX(o, myData)

fprintf('%s: loading CellMap from %s ...', datestr(now), o.CellMapFile);
load(o.CellMapFile)
fprintf('Done! \n');

status = sanityCheck2(CellMap, myData.Roi);

x0 = myData.Roi(1);
y0 = myData.Roi(3);
rp = regionprops(CellMap);
CellYX = fliplr(vertcat(rp.Centroid)) + [y0 x0]; % convert XY to YX

end



function [uGenes, PlotSpots, GeneNo] = cleanData(o, Roi)

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

end


function status = sanityCheck(img, roi)

if ~isfile(img) % Note: looks better than the old way of "if exist(filename, 'file') == 2"
     error('%s: %s does not exist.', datestr(now), img)
end
    
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

status = checkHelper(wRoi, hRoi, wImg, hImg, 'image');
end


function status = sanityCheck2(CellMap, roi)

[h, w] = size(CellMap);

% get the image dimensions as infered by the roi
dimRoi = diff(roi) + 1;
hRoi = dimRoi(3);
wRoi = dimRoi(1);

status = checkHelper(wRoi, hRoi, w, h, 'CellMap');
end

function sanityCheck3(bigImg, vipsheaderExe, dim)

% get the image dimensions from the tif
cmdStr = [vipsheaderExe, ' -f height ', bigImg];
[~, h] = system(cmdStr);
h = str2double(h);

cmdStr = [vipsheaderExe, ' -f width ', bigImg];
[~, w] = system(cmdStr);
w = str2double(w);

if max(h, w) ~= dim
    error('%s: The longest side of %s  should be %d pixels but it is %d \n', datestr(now), bigImg, dim, max(h, w))
else
    fprintf('%s: Check passed! \n', datestr(now))
end

end


function status = checkHelper(wRoi, hRoi, w, h, label)

if (hRoi ~= h) || (wRoi ~= w)

    warning('The ROI implies an image of dimension %d by %d whereas the %s is %d by %d pixels', wRoi, hRoi, label, w, h)
    status = false;
else
    status = true;
    fprintf('%s: Check....OK! \n', datestr(now))
end

end


