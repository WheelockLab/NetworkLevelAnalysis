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
            import nla.* % required due to matlab package system quirks
            if nargin ~= 0
                obj.coeff = TriMatrix(size);
                obj.prob = TriMatrix(size);
                obj.prob_sig = TriMatrix(size, 'logical');
                obj.prob_max = prob_max;
            end
        end
        
        function output(obj, net_atlas, flags, prob_label)
            import nla.* % required due to matlab package system quirks
            
            coeff_label = sprintf('Edge-level %s', obj.coeff_name);
            prob_label_appended = '';
            if ~strcmp(obj.behavior_name, '')
                coeff_label = [coeff_label, sprintf(' (%s)', obj.behavior_name)];
                prob_label_appended = sprintf(' (%s)', obj.behavior_name);
            end

            fig = gfx.createFigure();
            [w, h] = gfx.drawMatrixOrg(fig, 0, 0, coeff_label, obj.coeff, obj.coeff_range(1), obj.coeff_range(2), net_atlas.nets, gfx.FigSize.LARGE, gfx.FigMargins.WHITESPACE, true, true);

            if flags.display_sig
                if ~exist('prob_label', 'var')
                    prob_label = [sprintf('Edge-level Significance (P < %g)', obj.prob_max), prob_label_appended];
                end
                [w2, h2] = gfx.drawMatrixOrg(fig, w, 0, prob_label, obj.prob_sig, 0, 1, net_atlas.nets, gfx.FigSize.LARGE, gfx.FigMargins.WHITESPACE, false, false, [[1,1,1];[0,0,0]]);
                w = w + w2;
                h = max(h, h2);
            else
                if ~exist('prob_label', 'var')
                    prob_label = ['Edge-level P-values (displayed on log scale)', prob_label_appended];
                end
                %prob_log = TriMatrix(net_atlas.numROIs());
                %prob_log.v = -1 * log10(obj.prob.v);
                cm_base = parula(1000);
                cm = flip(cm_base(ceil(logspace(-3, 0, 256) .* 1000), :));
                [w2, h2] = gfx.drawMatrixOrg(fig, w, 0, prob_label, obj.prob, 0, 1, net_atlas.nets, gfx.FigSize.LARGE, gfx.FigMargins.WHITESPACE, false, true, cm);
                w = w + w2;
                h = max(h, h2);
            end

            fig.Position(3) = w;
            fig.Position(4) = h;
        end
        
    end
end
