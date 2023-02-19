function [outputArg1,outputArg2] = setTitle(ax, txt, is_subtitle)
    if ~exist('is_subtitle', 'var'), is_subtitle = false; end
    
    if is_subtitle
        subtitle(ax, txt);
    else
        title(ax, txt);
    end
    set(ax,'fontsize', 9.5)
end

