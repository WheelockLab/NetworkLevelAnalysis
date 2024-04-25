% Taken from fileexchange and Matlab 2024a
function hex = rgb2hex(rgb_color)
    assert(nargin==1,'This function requires an RGB input.') 
    assert(isnumeric(rgb_color)==1,'Function input must be numeric.') 
    sizergb = size(rgb_color); 
    assert(sizergb(2)==3,'rgb value must have three components in the form [r g b].')
    assert(max(rgb_color(:)) <= 255 & min(rgb_color(:)) >= 0,'rgb values must be on a scale of 0 to 1 or 0 to 255')
    %% If no value in RGB exceeds unity, scale from 0 to 255: 
    if max(rgb_color(:))<=1
        rgb_color = round(rgb_color * 255); 
    else
        rgb_color = round(rgb_color); 
    end
    
    hex(:,2:7) = reshape(sprintf('%02X',rgb_color.'),6,[]).'; 
    hex(:,1) = '#';
end