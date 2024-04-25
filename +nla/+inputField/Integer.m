classdef Integer < nla.inputField.Number
    methods
        function [w, h] = draw(obj, x, y, parent, fig)
            [w, h] = draw@nla.inputField.Number(obj, x, y, parent, fig);
            obj.field.RoundFractionalValues = 'on';
        end
    end
end

