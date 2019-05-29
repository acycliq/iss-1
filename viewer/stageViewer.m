function out = stageViewer(o, stagingData)
img = '.\img\background_boundaries.tif'

cd = cleanData(o, stagingData);
uGenes = cd.uGenes;
PlotSpots = cd.PlotSpots;
GeneNo = cd.GeneNo;

stagingData.allSpots = collectSpots(o, uGenes, PlotSpots, GeneNo);

collectData(stagingData, o);

Roi = stagingData.Roi;
xRange = 1+Roi(2)-Roi(1);
yRange = 1+Roi(4)-Roi(3);
scaleFactor = 32768/max(xRange, yRange);

% cmdStr = ['.\vips\bin\vips.exe'  ' resize '  '.\img\DapiBoundaries_161220KI_3-1_left.tif out.tif ', num2str(scaleFactor, 6) ]
% first scale up the image
dim = 32768;
bigImg = [num2str(dim), 'px.tif'];
tilesFolder = [num2str(dim), 'px.dz'];
fprintf('%s: Upscaling the image \n', datestr(now));
cmdStr = ['.\vips\bin\vips.exe'  ' resize ' img ' ' bigImg ' ' num2str(scaleFactor, 9), ' --kernel nearest' ];
system(cmdStr);
fprintf('%s: Done! \n', datestr(now));

%now make the tiles
fprintf('%s: Started doing the pyramid of tiles \n', datestr(now));
cmdStr = ['.\vips\bin\vips.exe gravity ' bigImg ' ' tilesFolder '[layout=google,suffix=.png,skip_blanks=0] south-west ' num2str(dim) ' ' num2str(dim) ' --extend black'];
system(cmdStr);
fprintf('%s: Done! \n', datestr(now));

system ('start http://localhost:80')
system ('java -jar ./jar/SimpleWebServer.jar')

        

end


function out = cleanData(o, stagingData)

Roi = stagingData.Roi;
SpotGeneName = o.GeneNames(o.SpotCodeNo);
uGenes = unique(SpotGeneName);

% which ones pass quality threshold (combi first)
QualOK = o.quality_threshold;

% now show only those in Roi
if ~isempty(stagingData.Roi)
    InRoi = all(o.SpotGlobalYX>=stagingData.Roi([3 1]) & o.SpotGlobalYX<=stagingData.Roi([4 2]),2);
else
    InRoi = true;
end

PlotSpots = find(InRoi & QualOK);
[~, GeneNo] = ismember(SpotGeneName(PlotSpots), uGenes);

out.uGenes = uGenes;
out.PlotSpots = PlotSpots;
out.GeneNo = GeneNo;

end

