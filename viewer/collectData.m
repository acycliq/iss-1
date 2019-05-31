function collectData(o, myData, cellCallData)

allSpots = myData.allSpots;
GeneNames = myData.GeneNames;
ClassNames = myData.ClassNames; 
pCellClass = cellCallData.pCellClass; 
CellGeneCount = cellCallData.CellGeneCount;
CellYX = myData.CellYX;
IncludeSpot = myData.IncludeSpot;
Neighbors = cellCallData.Neighbors;
pSpotNeighb = cellCallData.pSpotNeighb;

% 1. Collect the cells and their locations
collectCells(GeneNames, ClassNames, pCellClass, CellGeneCount, CellYX)

% 2. Collect all spots and their locations, and for a specific subset, get
% the cell they have been asigned to.
% load('allSpots.mat')
% fprintf('%s: allSpots.mat loaded\n', datestr(now))
% % allSpots = allSpots(ismember(allSpots(:,1), GeneNames), :);

% for each spot, concatenate all its Neighbors into a single column
nb = mat2cell(Neighbors, ones(size(Neighbors,1),1), size(Neighbors,2));

% and do the same for the corresponding probabilities
nbPror = mat2cell(pSpotNeighb, ones(size(pSpotNeighb,1),1), size(pSpotNeighb,2));


[~, BestNeighb] = max(pSpotNeighb,[],2);
nS = size(pSpotNeighb,1);
SpotBestNeighb = bi(Neighbors,(1:nS)',BestNeighb(:));

mySpots = [num2cell(o.SpotGlobalYX(IncludeSpot,:)), num2cell(SpotBestNeighb), nb, nbPror];

keyAllSpots = cellfun(@(y, x) sprintf('%.10f_%.10f', y,x), allSpots(:,3), allSpots(:,4), 'Uniform',0);
keyMySpots = cellfun(@(y, x) sprintf('%.10f_%.10f', y,x), mySpots(:,1), mySpots(:,2), 'Uniform',0);

[~, ia, ib] = intersect(keyAllSpots, keyMySpots);
res = num2cell(nan(size(allSpots,1),3));
res(ia, :) = mySpots(ib, 3:end);

out = [allSpots, res];
% out(out(:,end)==0) = -1;

T = cell2table(out);
% % T.Properties.VariableNames = {'Gene','Expt','y','x','neighbour' };
T.Properties.VariableNames = {'Gene','Expt','y','x','neighbour','neighbour_array','neighbour_prob'};
% str = [fName, '_sims_Dapi_overlays.csv']; 
% writetable(T, str);

jsonStr = jsonencode(T);
str = ['.\dashboard\data\json\Dapi_overlays.json'];
fid = fopen(str, 'w');
if fid == -1, error('Cannot create JSON file'); end
fwrite(fid, jsonStr, 'char');
fclose(fid);

fprintf('%s: %s saved. \n', datestr(now), str);

end

function collectCells(GeneNames, ClassNames, pCellClass, CellGeneCount, CellYX)
% DN wrote this to get data for the viewer

[m,~] = size(CellYX);
for i=1:m
    df{i,1} = i;
    df{i,2} = CellYX(i,1);
    df{i,3} = CellYX(i,2);
    
    idx = CellGeneCount(i,:) > 0.001;
    df{i,4} = GeneNames(idx);
    df{i,5} = num2cell(CellGeneCount(i, idx));
    
    idx2 = pCellClass(i,:) > 0.001;
    df{i,6} = ClassNames(idx2);
    df{i,7} = pCellClass(i, idx2);
    
end


VariableNames = {'Cell_Num','Y','X','Genenames','CellGeneCount','ClassName','Prob'};
T = cell2table(df, 'VariableNames',VariableNames);

jsonStr = jsonencode(T);
str = ['.\dashboard\data\json\iss.json']; 
fid = fopen(str, 'w');
if fid == -1, error('Cannot create JSON file'); end
fwrite(fid, jsonStr, 'char');
fclose(fid);

fprintf('%s: %s saved \n', datestr(now), str);

end

function cell2csv(filename,cellArray,delimiter)
% Writes cell array content into a *.csv file.
% 
% CELL2CSV(filename,cellArray,delimiter)
%
% filename      = Name of the file to save. [ i.e. 'text.csv' ]
% cellarray    = Name of the Cell Array where the data is in
% delimiter = seperating sign, normally:',' (default)
%
% by Sylvain Fiedler, KA, 2004
% modified by Rob Kohr, Rutgers, 2005 - changed to english and fixed delimiter
if nargin<3
    delimiter = ',';
end

datei = fopen(filename,'w');
for z=1:size(cellArray,1)
    for s=1:size(cellArray,2)

        var = eval(['cellArray{z,s}']);

        if size(var,1) == 0
            var = '';
        end

        if isnumeric(var) == 1
            var = num2str(var);
        end

        fprintf(datei,var);

        if s ~= size(cellArray,2)
            fprintf(datei,[delimiter]);
        end
    end
    fprintf(datei,'\n');
end
fclose(datei);

end