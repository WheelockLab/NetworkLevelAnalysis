classdef CortexAnatomy
    %CORTEXANATOMY Anatomical model of the cortex
    
    properties
        hemi_l
        hemi_r
        space
    end
    
    methods
        function obj = CortexAnatomy(fname)
            anat_struct = load(fname);
            obj.hemi_l = anat_struct.ctx_l;
            obj.hemi_r = anat_struct.ctx_r;
            obj.space = anat_struct.space;
        end
    end
end

