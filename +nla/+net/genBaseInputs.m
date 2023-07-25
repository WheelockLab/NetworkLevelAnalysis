function inputs = genBaseInputs()
    %GENBASEINPUTS Generate struct of required network-level inputs with
    %   reasonable default values
    import nla.*
    inputs = struct('nonpermuted', true, 'full_conn', true, 'within_net_pair', true, 'prob_plot_method', gfx.ProbPlotMethod.DEFAULT, 'ranking_method', nla.RankingMethod.P_VALUE);
end

