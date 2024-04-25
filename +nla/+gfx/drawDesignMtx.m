function drawDesignMtx(design_mtx, labels)
    %DRAWDESIGNMTX Display design matrix in new figure
    %   design_mtx: NxN design matrix
    %   labels: Nx1 cell array, name labels of each variable
    
    % column-wise normalize the design matrix
    design_mtx_norm = (design_mtx - min(design_mtx)) ./ (max(design_mtx) - min(design_mtx));

    nla.gfx.createFigure(900, 450);
    
    ax = subplot('Position', [9/48, 4/12, 7/24, 7/12]);
    [num_scans, num_covariates] = size(design_mtx);
    imagesc(ax, design_mtx_norm');
    set(ax, 'XTick', [], 'XTickLabel', []);
    set(ax, 'YTick', 1:num_covariates, 'YTickLabel', labels);
    set(ax, 'TickDir', 'out');
    xlabel('subjects');
    colormap(ax, 'gray');
    set(ax, 'TickLabelInterpreter', 'none');
    
    num_cols = size(design_mtx, 2);
    for x = 1:num_cols
        for y = 1:num_cols
            [r, p] = corr(design_mtx(:, x), design_mtx(:, y));
            corr_mat(y,x) = r;
            p_mat(y,x) = p;
        end
    end
    
    ax = subplot('Position', [16/24, 4/12, 7/24, 7/12]);
    imagesc(ax, corr_mat);
    nla.gfx.setTitle(ax, "Colinearity (r-values)");
    xlabel(' ');
    set(ax, 'XTick', 1:num_covariates, 'XTickLabel', labels);
    set(ax, 'YTick', 1:num_covariates, 'YTickLabel', labels);
    xtickangle(90);
    colormap(ax, 'gray');
    caxis(ax, [-1, 1]);
    set(ax, 'TickLabelInterpreter', 'none');
    
    for x = 1:num_covariates
        for y = 1:num_covariates
            text(ax, x,y, num2str(corr_mat(y, x), '%.2f'), 'FontSize', 8, 'FontName', 'FixedWidth',...
                'HorizontalAlignment', 'center', 'Color', 'r');
        end
    end
end