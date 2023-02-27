function inputs = genBaseNetInputs()
    import nla.*
    inputs = struct('nonpermuted', true, 'full_conn', true, 'within_net_pair', true, 'prob_plot_method', gfx.ProbPlotMethod.DEFAULT, 'ranking_method', nla.RankingMethod.P_VALUE);
end

