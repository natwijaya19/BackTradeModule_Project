classdef MyClassTest
    properties
        prop1  = 100
        prop2  = "Hi"
        prop3 
        prop4 

    end

    methods 
        function obj = MyClassTest(prop1, prop2, varargin)
            if nargin <3
                obj.prop1 = 100;
                obj.prop2 = "Hello";
            end
            obj.prop1 = prop1;
            obj.prop2 = prop2;

            ip = inputParser;
            ip.addParameter('prop3',10);
            ip.addParameter('prop4','abcd')
            
            ip.parse(varargin{:});
            result = ip.Results;

            obj.prop3 = result.prop3;
            obj.prop4 = result.prop4;

        end
    end
end