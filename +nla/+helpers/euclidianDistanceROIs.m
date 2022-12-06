function distances = euclidianDistanceROIs(network_atlas)
    import nla.* % required due to matlab package system quirks
    
    distances = nla.TriMatrix(network_atlas.numROIs());
    
    for col = 1:network_atlas.numROIs()
        for row = (col + 1):network_atlas.numROIs()
            pos1 = network_atlas.ROIs(row).pos;
            pos2 = network_atlas.ROIs(col).pos;
            distance = sqrt((pos1(1) - pos2(1))^2 + (pos1(2) - pos2(2))^2 + (pos1(3) - pos2(3))^2);
            distances.set(row, col, distance);
        end
    end
end

