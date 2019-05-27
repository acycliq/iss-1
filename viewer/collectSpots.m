function out = collectSpots(o, uGenes, PlotSpots, GeneNo)
fprintf('%s: Function collectSpots was called. \n', datestr(now));


allSpots = [];
for i=1:length(uGenes)
    MySpots = PlotSpots(GeneNo==i);
    nn = length(o.SpotGlobalYX(MySpots));
    mat1 = [i*ones(nn,1), o.SpotGlobalYX(MySpots,1), o.SpotGlobalYX(MySpots,2)];
    mat2 = repmat(uGenes(i),nn,1);
    allSpots = [allSpots; [mat2, num2cell(mat1)]];
end
% save('allSpots.mat', 'allSpots')
% fprintf('%s: allSpots.mat saved \n', datestr(now))
% % T = cell2table(myarr);
% % T.Properties.VariableNames = {'Gene','Expt','y','x'};
% % save('mySpots.mat', 'T')
% % % writetable(T, 'Dapi_overlays.csv');

out = allSpots;