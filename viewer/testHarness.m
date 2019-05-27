%%%%% 
%%%%% Code to test run the cell calling algorith and display the findings on the viewer
%%%%%


load("..\viewer\cachedData\oSegment_dapi_left_170315_161220KI_4_3.mat")
load('..\viewer\cachedData\CellMap.mat')
load('..\viewer\cachedData\gSetCA1all.mat')


% Manual overrides
[m, ~, n] = size(o.cSpotColors);
o.cAnchorIntensities = (o.DetectionThresh+1) * ones(m,n);
o.GeneNames(strcmp(o.GeneNames, 'Lphn2')) = {'Adgrl2'};
o.CellMapFile = '..\viewer\cachedData\CellMap.mat';

o = o.call_cells(gSet, DapiBoundaries);