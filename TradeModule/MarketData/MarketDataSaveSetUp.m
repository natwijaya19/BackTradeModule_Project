classdef MarketDataSaveSetUp
    %MarketDataSaveSetUp is class data holder to hold input required to
    % save data
    %   
    % Input arguments
    %   filename: file name of spreadsheet
    %   openPriceSheetname: sheet name where openPriceSheetname will be stored
    %   highPriceSheetname: sheet name where highPriceSheetname will be stored
    %   lowPriceSheetname: sheet name where lowPriceSheetname will be stored
    %   closePriceSheetname: sheet name where closePriceSheetname will be stored
    %   volumeSheetname: sheet name where volumeSheetname will be stored
    %======================================================================
    
    properties
        filename {mustBeText, mustBeFile, mustBeTextScalar} = "filename"
        openPriceSheetname {mustBeText, mustBeTextScalar} = "openPriceSheetname"
        lowPriceSheetname {mustBeText, mustBeTextScalar} = "lowPriceSheetname"
        highPriceSheetname {mustBeText, mustBeTextScalar} = "highPriceSheetname"
        closePriceSheetname {mustBeText, mustBeTextScalar} = "lowPriceSheetname"
        volumeSheetname {mustBeText, mustBeTextScalar} = "closePriceSheetname"        
    end

    methods
        function obj = MarketDataSaveSetUp(filename, openPriceSheetname,...
                lowPriceSheetname, highPriceSheetname, closePriceSheetname,...
                volumeSheetname)
            %MarketDataSaveSetUp Construct an instance of this class

            obj.filename = filename;
            obj.openPriceSheetname = openPriceSheetname;
            obj.highPriceSheetname = highPriceSheetname;
            obj.lowPriceSheetname = lowPriceSheetname;
            obj.closePriceSheetname = closePriceSheetname;
            obj.volumeSheetname = volumeSheetname;
        end
    end
end