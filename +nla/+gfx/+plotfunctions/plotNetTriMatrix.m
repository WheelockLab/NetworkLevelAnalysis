function plotNetTriMatrix(fig_h, net_atlas, plot_data, sig_matrix, plot_settings)

%                color_map: [1001×3 double]
%     statistic_plot_matrix: [1×1 nla.TriMatrix]
%          p_value_plot_max: 0.0500
%                name_label: "Welch's T-test Full Connectome Method↵Network vs. Connectome Significance↵Uncorrected data↵P < 0.05"
%         significance_plot: [1×1 nla.TriMatrix]
%                  callback: @NetworkResultPlotParameter.plotProbabilityParameters/brainFigureButtonCallback
%         significance_type: "nla.gfx.SigType.DECREASING"
%                plot_scale: 'nla.gfx.ProbPlotMethod.DEFAULT'
%                  plot_max: 0.0500

    %load('probability_parameters_example.mat');
    %load('net_atlas_example.mat');
    
    probability_parameters = plot_settings;
    probability_parameters.statistic_plot_matrix = nla.TriMatrix(plot_data, nla.TriMatrixDiag.KEEP_DIAGONAL);
    
    if isempty(sig_matrix)
        sig_matrix = zeros(size(plot_data));
    end
    
    probability_parameters.significance_plot = nla.TriMatrix(sig_matrix, nla.TriMatrixDiag.KEEP_DIAGONAL);
    
    plotter = nla.net.result.plot.PermutationTestPlotter(net_atlas);
    
    plotter.plotProbability(fig_h, probability_parameters,...
        nla.inputField.LABEL_GAP, -50);


end