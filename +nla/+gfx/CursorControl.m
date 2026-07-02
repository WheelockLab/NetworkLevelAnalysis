classdef CursorControl < handle

    properties (Access = protected)
        fig_h
        brainIconMat = [];
    end

    methods
        function obj = CursorControl(parent_fig)
            obj.fig_h = parent_fig;
            try
                brainMatStruct = load(fullfile(nla.findRootPath(),'brainIconDat.mat'));
                obj.brainIconMat = brainMatStruct.brainMat;
            catch exep
            end
        end

        function changeToBrain(obj)
            obj.fig_h.Pointer = 'custom';
            obj.fig_h.PointerShapeCData = obj.brainIconMat;
        end

        function changeToArrow(obj)
            obj.fig_h.Pointer = 'arrow';
        end

        function changeToThinking(obj)
            try
                obj.changeToBrain();
            catch
                obj.fig_h.Pointer = 'watch';
            end
        end


    end


end