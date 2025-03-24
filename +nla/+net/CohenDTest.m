classdef CohenDTest < handle
    %COHENDTEST Cohen's D Test for network tests
    % This Cohen's D test is run for all of the tests
    % Input:
    %   edge_test_results: Results from the edge tests
    %   network_atlas: Network Atlas
    %   result_object: This is a NetworkTestResult object. This needs to be passed in, and then it will be returned.

    properties (Constant)
        name = "Cohen's D Test"
    end

    methods
        function obj = CohenDTest
        end

        function result_object = run(obj, edge_test_results, network_atlas, result_object)
            
            
            %DETERMINED THAT CURRENT COHEN'S D CALC IS INVALID
            %RETURN WITHOUT MODIFYING EXISTING D PLACEHOLDER VALUE FROM 0            
            %RECOMMEND THAT, WHEN REENABLED, THIS FN BE CHANGED TO ACCEPT
            %VECTOR OF INPUT AND RETURN VECTOR OF OUTPUT RATHER THAN
            %RESULTS CLASS
            %ADE 2025MAR24
            return;
            
            
            
            
            %LEAVING COMMENTED CODE BELOW THAT WOULD MODIFY FIELDS AS DONE
            %PREVIOUSLY FOR REFERENCE.
%             number_of_networks = network_atlas.numNets();
% 
%             for row = 1:number_of_networks
%                 for column = 1:row
%                     
%                     if isprop(result_object, "no_permutations") && ~isequal(result_object.no_permutations, false)
%                         %this_netpair_nonperm_d = COMPUTE NONPERMUTED D HERE;
%                         result_object.no_permutations.d.set(row, column, this_netpair_nonperm_d);
%                     end
%                     if isprop(result_object, "full_connectome") && ~isequal(result_object.full_connectome, false)
%                         %this_netpair_fullconn_d = COMPUTE FULLCONN D HERE;
%                         result_object.full_connectome.d.set(row, column, this_netpair_fullconn_d);
%                     end
%                     if isprop(result_object, "within_network_pair") && ~isequal(result_object.within_network_pair, false)
%                         %this_netpair_withinNP_d = COMPUTE WITHIN NET PAIR D HERE
%                         result_object.within_network_pair.d.set(row, column, this_netpair_withinNP_d);
%                     end
%                 end
%             end
        end
    end
end