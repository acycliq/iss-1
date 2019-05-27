function out = stageViewer(o, stagingData)
img = '.\img\DapiBoundaries_161220KI_3-1_left.tif'
Roi = stagingData.Roi;
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

stagingData.allSpots = collectSpots(o, uGenes, PlotSpots, GeneNo);

collectData(stagingData, o);

xRange = Roi(2)-Roi(1);
yRange = Roi(4)-Roi(3);
scaleFactor = 32768/max(xRange, yRange)

% cmdStr = ['.\vips\bin\vips.exe'  ' resize '  '.\img\DapiBoundaries_161220KI_3-1_left.tif out.tif ', num2str(scaleFactor, 6) ]
% first scale up the image
dim = 32768;
bigImg = [num2str(dim), 'px.tif'];
tilesFolder = [num2str(dim), 'px.dz'];
cmdStr = ['.\vips\bin\vips.exe'  ' resize ' img ' ' bigImg ' ' num2str(scaleFactor, 6) ];
system(cmdStr)

%now make the tiles
cmdStr = ['.\vips\bin\vips.exe gravity ' bigImg ' ' tilesFolder '[layout=google,suffix=.png,skip_blanks=0] south-west ' num2str(dim) ' ' num2str(dim) ' --extend black']
system(cmdStr)

system ('java -jar ./jar/SimpleWebServer.jar')
dos('start http://localhost:80/');

        

end