import nla.TriMatrix nla.TriMatrixDiag
obj.number_of_networks = 15;

networks_connected = false(obj.number_of_networks, obj.number_of_networks + 1);

% These set up arrays of net numbers and indexes the networks are located at. 
% When we go to connect networks, we can easily index the various networks and locations
% to connect them. It's a lot of setup, but it does make some sense.
network_array = TriMatrix(obj.number_of_networks, 'double', TriMatrixDiag.KEEP_DIAGONAL);
network2_array = TriMatrix(obj.number_of_networks, 'double', TriMatrixDiag.KEEP_DIAGONAL);
network_indexes = TriMatrix(obj.number_of_networks, 'double', TriMatrixDiag.KEEP_DIAGONAL);
network2_indexes = TriMatrix(obj.number_of_networks, 'double', TriMatrixDiag.KEEP_DIAGONAL);
for network = 1:obj.number_of_networks
    for network2 = network:obj.number_of_networks
        network_index = find(networks_connected(network, :) == 0, 1, 'last');
        networks_connected(network, network_index) = true;

        network2_index = find(networks_connected(network2, :) == 0, 1, 'last');
        networks_connected(network2, network2_index) = true;

        network_array.set(network2, network, network);
        network2_array.set(network2, network, network2);
        network_indexes.set(network2, network, network_index);
        network2_indexes.set(network2, network, network2_index);
    end
end