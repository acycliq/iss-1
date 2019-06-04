function collectData(varargin)

o = varargin{1}; 
myData = varargin{2};

if nargin == 2
    helper_1ite(myData)
elseif nargin == 3
    cellCallData = varargin{3};
    helper(o, myData, cellCallData)
else
    disp('Hello')
end

end


function helper_1ite(myData)

[m,~] = size(myData.CellYX);
for i=1:m
    df{i,1} = i;
    df{i,2} = myData.CellYX(i,1);
    df{i,3} = myData.CellYX(i,2);

    df{i,4} = {};
    df{i,5} = {};
    
    df{i,6} = {};
    df{i,7} = {};
    
end

nAs = size(myData.allSpots, 1);
arr = [myData.allSpots, num2cell(nan(nAs,1))];

saveJson(df)
saveCsv(arr)

end




function helper(o, myData, cellCallData)

allSpots = myData.allSpots;
GeneNames = cellCallData.GeneNames;
ClassNames = cellCallData.ClassNames; 
pCellClass = cellCallData.pCellClass; 
CellGeneCount = cellCallData.CellGeneCount;
CellYX = myData.CellYX;
IncludeSpot = cellCallData.IncludeSpot;
Neighbors = cellCallData.Neighbors;
pSpotNeighb = cellCallData.pSpotNeighb;


% rename PC.CA2 to PC.Other1
isPC.CA2 = strcmp(ClassNames, 'PC.CA2');
ClassNames{isPC.CA2} = 'PC.Other1';

% rename PC.CA3 to PC.Other2
isPC.CA3 = strcmp(ClassNames, 'PC.CA3');
ClassNames{isPC.CA3} = 'PC.Other2';


% 1. Collect the cells and their locations
collectCells(GeneNames, ClassNames, pCellClass, CellGeneCount, CellYX)

% 2. Find the best neighbour
[~, BestNeighb] = max(pSpotNeighb,[],2);
nS = size(Neighbors, 1);
SpotBestNeighb = bi(Neighbors,(1:nS)',BestNeighb(:));

mySpots = [o.SpotGlobalYX(IncludeSpot,:), SpotBestNeighb];

keyAllSpots = cellfun(@(y, x) sprintf('%.10f_%.10f', y,x), allSpots(:,3), allSpots(:,4), 'Uniform',0);
keyMySpots = cellfun(@(y, x) sprintf('%.10f_%.10f', y,x), num2cell(mySpots(:,1)), num2cell(mySpots(:,2)), 'Uniform',0);

[~, ia, ib] = intersect(keyAllSpots, keyMySpots);
res = nan(size(allSpots,1),1);
res(ia) = mySpots(ib, 3);

arr = [allSpots, num2cell(res)];
% out(out(:,end)==0) = -1;

saveCsv(arr)

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


saveJson(df)

end


function saveJson(df)

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


% out(out(:,end)==0) = -1;
function saveCsv(arr)

T = cell2table(arr);
T.Properties.VariableNames = {'Gene','Expt','y','x','neighbour' };
str = ['.\dashboard\data\json\Dapi_overlays.csv']; 
writetable(T, str);

fprintf('%s: %s saved. \n', datestr(now), str);


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