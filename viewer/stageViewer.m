function out = stageViewer()

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

collectSpots(o, uGenes, PlotSpots, GeneNo);


end