marketData = MarketData;
marketData.matFileSetUp.fileName = "DataInput\PriceVolumeInput2010to22Raw.mat";

marketData = marketData.loadSymbolMCapRef;

marketData = marketData.loadDataFromMatFile;

marketData = marketData.classifyMktCap;

marketCapCategory = marketData.marketCapCategory;
marketCapCategoryVar = marketCapCategory.Variables;
uniqueMCap = unique(string(marketCapCategoryVar(end,:)));
mCap = uniqueMCap;
mCap(ismissing(mCap)) = [];

volume = marketData.volume;
volume.Variables = double(string(marketData.volume.Variables));
volumeVar = volume.Variables;
volumeVar(isnan(volumeVar)) = 0;
volume.Variables = volumeVar;

closePrice = marketData.closePrice;
closePrice.Variables = double(string(marketData.closePrice.Variables));
closePriceVar = closePrice.Variables;
closePriceVar(isnan(closePriceVar)) = 0;
closePrice.Variables = closePriceVar;

value = closePrice;
value.Properties.VariableNames = strrep(string(value.Properties.VariableNames), "_close","_value");
value.Variables = closePrice.Variables .* volume.Variables;

valueAvg = mean(value.Variables,2)';
minValue = min(valueAvg(valueAvg~=0));


valueThreshold = 100*10^6;
valueVar = value.Variables;
valuegtThreshold = value;
valuegtThreshold.Variables = valueVar >= valueThreshold;
nSymValue = valuegtThreshold(:,1);
nSymValue.Properties.VariableNames = strrep(nSymValue.Properties.VariableNames,"AALI_value", "nSymValue");
nSymValue.Variables = sum(valuegtThreshold.Variables, 2);

figure
plot(nSymValue.Time,nSymValue.Variables)
title(nSymValue.Properties.VariableNames)

%%
mCapValueNSym = closePrice(:,1:6); 
mCapValueNSymVar = mCapValueNSym.Variables;
mCapValueNSymVar(:,:) = 0;
mCapValueNSym.Properties.VariableNames = mCap;
for mCapIdx = 1:numel(mCap)
    
    mCapValid = marketCapCategoryVar==mCap(mCapIdx);
    mCapValue = mCapValid .* valuegtThreshold.Variables;
    mCapValueNSymVar(:,mCapIdx) = sum(mCapValue,2);

    f1 = figure;
    plot(mCapValueNSym.Time, mCapValueNSymVar(:,mCapIdx));
    title(mCap(mCapIdx));
    
end
mCapValueNSym.Variables = mCapValueNSymVar;

