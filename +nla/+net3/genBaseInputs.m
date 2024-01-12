function inputs = genBaseInputs()
    %GENBASEINPUTS Generate struct of required network-level inputs with
    %   reasonable default values
    import nla.*
    inputs = struct('nonpermuted', true, 'full_conn', true, 'within_net_pair', true, 'prob_plot_method', gfx.ProbPlotMethod.DEFAULT, 'ranking_method', RankingMethod.P_VALUE, 'edge_chord_plot_method', gfx.EdgeChordPlotMethod.PROB, 'fdr_correction', net.mcc.Bonferroni(), 'd_thresh_chord_plot', true);
end

