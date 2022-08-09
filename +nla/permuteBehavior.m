function behavior = permuteBehavior(behavior_np, previous_result)
    import nla.*
    if previous_result ~= false
        % Permutation
        behavior = helpers.permuteVector(behavior_np);
    else
        behavior = behavior_np;
    end
end

