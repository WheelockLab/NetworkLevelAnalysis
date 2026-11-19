function outGroupIds = combineSingletonGroups(inGroupIds)
    unqGroupIds = unique(inGroupIds);
    singletonGroupIds = [];

    %identify singleton groups
    for i = 1:length(unqGroupIds)
        thisGroupId = unqGroupIds(i);
        numSubjThisGroup = sum(inGroupIds==thisGroupId);
        if numSubjThisGroup == 1
            singletonGroupIds(end+1) = thisGroupId;
        end
    end

    %assign new group ID for all singletons to be assigned to
    newSingletonGroupId = max(unqGroupIds) + 1;            
    outGroupIds = inGroupIds;
    for i = 1:length(singletonGroupIds)
        subjThisSingletonGroup = (inGroupIds == singletonGroupIds(i));
        outGroupIds(subjThisSingletonGroup) = newSingletonGroupId;
    end


end