function dataOutput = sortDataSymFcn(dataInputRaw)
% sortDataSymFcn sorting data symbols alphabetically
dataInput = dataInputRaw;
nData = numel(dataInput);  % n price data only excluding volume
dataOutput = cell(1,nData);

for idx = 1:nData
    symbols = dataInput{idx}.Properties.VariableNames;
    symbols = string(symbols);
    symbols = sort(symbols,2,"ascend");
    dataOutput{idx} = dataInput{idx}(:,symbols);
end

end