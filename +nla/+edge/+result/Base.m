classdef Base < nla.TestResult
    %BASE Base class of results of edge-level analysis
    
    properties
        coeff % Fisher transformed r-value
        prob
        prob_sig
        avg_prob_sig = NaN
        prob_max = NaN
        behavior_name = ''
        coeff_range = [-0.3 0.3]
        coeff_name
        name
    end
    
    methods
        function obj = Base(size, prob_max)
            import nla.TriMatrix

            if nargin ~= 0
                obj.coeff = TriMatrix(size);
                obj.prob = TriMatrix(size);
                obj.prob_sig = TriMatrix(size, 'logical');
                obj.prob_max = prob_max;
            end
        end
        
        function output(obj, net_atlas, flags, prob_label)
            
            coeff_label = sprintf('Edge-level %s', obj.coeff_name);
            prob_label_appended = '';
            if ~strcmp(obj.behavior_name, '')
                coeff_label = [coeff_label, sprintf(' (%s)', obj.behavior_name)];
                prob_label_appended = sprintf(' (%s)', obj.behavior_name);
            end

            fig = nla.gfx.createFigure();
            matrix_plot = nla.gfx.plots.MatrixPlot(fig, coeff_label, obj.coeff, net_atlas.nets, nla.gfx.FigSize.LARGE, 'lower_limit', obj.coeff_range(1),...
                'upper_limit', obj.coeff_range(2));
            matrix_plot.displayImage();
            w = matrix_plot.image_dimensions("image_width");
            h = matrix_plot.image_dimensions("image_height");
            
            if ~isfield(flags, 'display_sig')
                flags.display_sig = true;
            end
            
            if flags.display_sig
                if ~exist('prob_label', 'var')
                    prob_label = [sprintf('Edge-level Significance (P < %g)', obj.prob_max), prob_label_appended];
                end
                matrix_plot2 = nla.gfx.plots.MatrixPlot(fig, prob_label, obj.prob_sig, net_atlas.nets, nla.gfx.FigSize.LARGE,...
                    'draw_legend', false, 'draw_colorbar', false, 'color_map', [[1,1,1];[0,0,0]], 'x_position', w, 'lower_limit', 0, 'upper_limit', 1);
                w2 = matrix_plot2.image_dimensions("image_width");
                h2 = matrix_plot2.image_dimensions("image_height");
                matrix_plot2.displayImage();
            else
                if ~exist('prob_label', 'var')
                    prob_label = ['Edge-level P-values (displayed on log scale)', prob_label_appended];
                end
                %prob_log = TriMatrix(net_atlas.numROIs());
                %prob_log.v = -1 * log10(obj.prob.v);
                cm_base = parula(1000);
                cm = flip(cm_base(ceil(logspace(-3, 0, 256) .* 1000), :));
                matrix_plot2 = nla.gfx.plots.MatrixPlot(fig, prob_label, obj.prob, net_atlas.nets, nla.gfx.FigSize.LARGE,...
                    'draw_legend', false, 'color_map', cm, 'x_position', w, 'lower_limit', 0, 'upper_limit', 1);
                w2 = matrix_plot2.image_dimensions("image_width");
                h2 = matrix_plot2.image_dimensions("image_height");
                matrix_plot2.displayImage();
            end
            w = w + w2;
            h = max(h, h2);
            fig.Position(3) = w;
            fig.Position(4) = h;
        end
    end
end
