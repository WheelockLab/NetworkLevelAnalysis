function checkNormalityWithKS(fig, input_struct, test_pool)

    prog = uiprogressdlg(...
        fig, 'Title', 'Checking Normaility', 'Message', 'Running Kolmogorov-Smirnov Test'...
    );
    prog.Value = 0.02;
    
    prog.Value = 0.25;
    edge_test_result = test_pool.runEdgeTest(input_struct);

    prog.Value = 0.5;
    ks_result = runKolmogorovSmirnovTest(input_struct, edge_test_result);

    prog.Value = 0.75;
    qcKSOutput(ks_result, struct(), input_struct)

end

function ks_result = runKolmogorovSmirnovTest(input_struct, edge_result)
    import nla.TriMatrix nla.TriMatrixDiag

    ks_result = struct();
    number_of_networks = input_struct.net_atlas.numNets();
    ks_result.p = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);
    ks_result.ks = TriMatrix(number_of_networks, TriMatrixDiag.KEEP_DIAGONAL);

    for network1 = 1:number_of_networks
        for network2 = 1:network1
            network_rho = edge_result.coeff.get(input_struct.net_atlas.nets(network1).indexes,...
                input_struct.net_atlas.nets(network2).indexes);
            [~, p, ks] = kstest(network_rho);
            ks_result.p.set(network1, network2, p);
            ks_result.ks.set(network1, network2, ks);
        end
    end
end

function qcKSOutput(ks_result, flags, edge_test_options)
    
    network_test_options = nla.net.genBaseInputs();
    network_test_options.full_connectome = false;
    network_test_options.within_network_pair = false;
    network_test_options.fdr_correction = nla.net.mcc.None();
    edge_test_options.prob_max = 0.05;

    p_value_max = network_test_options.fdr_correction.correct(edge_test_options.net_atlas,...
        edge_test_options, '');


    fig = nla.gfx.createFigure();
    matrix_plot = nla.gfx.plots.MatrixPlot(fig, '', ks_result.p, edge_test_options.net_atlas.nets, nla.gfx.FigSize.LARGE,...
        'lower_limit', -0.03, 'upper_limit', p_value_max);
    matrix_plot.displayImage();
    width = matrix_plot.image_dimensions('image_width');
    height = matrix_plot.image_dimensions('image_height');

    if ~isfield(flags, 'display_sig')
        flags.display_sig = true;
    end

    matrix_plot2 = nla.gfx.plots.MatrixPlot(fig, '', ks_result.ks, edge_test_options.net_atlas.nets, nla.gfx.FigSize.LARGE,...
        'draw_legend', false, 'x_position', width, 'lower_limit', min(ks_result.ks.v), 'upper_limit', max(ks_result.ks.v));
    width2 = matrix_plot2.image_dimensions('image_width');
    height2 = matrix_plot2.image_dimensions('image_height');
    matrix_plot2.displayImage();

    width = width + width2;
    height = max(height, height2);
    fig.Position(3) = width;
    fig.Position(4) = height;
end