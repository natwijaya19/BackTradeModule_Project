classdef MyClassTest
    %UNTITLED6 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Property1
        Property2 = 10
    end
    
    methods
%         function obj = untitled6(inputArg1,inputArg2)
%             %UNTITLED6 Construct an instance of this class
%             %   Detailed explanation goes here
%             obj.Property1 = inputArg1 + inputArg2;
%         end
        
        function obj = method1(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.Property1 = [obj.Property2, 2];
        end
    end
end

