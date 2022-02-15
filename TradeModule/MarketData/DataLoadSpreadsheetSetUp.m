classdef DataLoadSpreadsheetSetUp
    %DataLoadSpreadsheetSetUp is class data holder to hold input required to
    % save data
    %   
    % Input arguments
    %   filename: file name of spreadsheet
    %   openPriceSheetname: sheet name where openPriceSheetname is stored
    %   highPriceSheetname: sheet name where highPriceSheetname is stored
    %   lowPriceSheetname: sheet name where lowPriceSheetname is stored
    %   closePriceSheetname: sheet name where closePriceSheetname is stored
    %   volumeSheetname: sheet name where volumeSheetname is stored
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
        function obj = DataLoadSpreadsheetSetUp(filename, openPriceSheetname,...
                lowPriceSheetname, highPriceSheetname, closePriceSheetname,...
                volumeSheetname)
            %DataLoadSpreadsheetSetUp Construct an instance of this class

            obj.filename = filename;
            obj.openPriceSheetname = openPriceSheetname;
            obj.highPriceSheetname = highPriceSheetname;
            obj.lowPriceSheetname = lowPriceSheetname;
            obj.closePriceSheetname = closePriceSheetname;
            obj.volumeSheetname = volumeSheetname;
        end
    end
end