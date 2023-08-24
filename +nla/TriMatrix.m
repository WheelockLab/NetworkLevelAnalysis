classdef TriMatrix < handle & matlab.mixin.Copyable
    %TRIMATRIX Lower triangle matrix
    %   Elements of a TriMatrix can be anything from doubles
    %   to multidimensional arrays of strings. However, there
    %   may only be one type of element overall per TriMatrix
    %   TriMatrix inherits from handle because otherwise the set() function
    %   just doesn't work. I would love to implement normal parenthesis
    %   based indexing but that's only in matlab r2021
    
    properties (Access = private)
        diag_offset = nla.TriMatrixDiag.REMOVE_DIAGONAL % offset by -1 to not include the central diagonal
        index_matrix
    end
    properties
        v % vector holding all data elements, which can themselves be multidimensional
        size % the largest row/col index corresponding to an element
    end
    
    methods (Access = private)
        function dims = elementDims(obj)
            import nla.* % required due to matlab package system quirks
            full_dims = size(obj.v);
            dims = full_dims(2:end);
        end
        
        function count = numElementDims(obj)
            dims = size(obj.v);
            if numel(dims) == 2
                if dims(2) == 1
                    count = 0; % scalar
                else
                    count = 1;
                end
            else
                count = ndims(obj.v);
            end
        end
        
%           the ghosts of indexing past
%         function ind = indexCol(obj, row, col)
%             %INDEX Vector index corresponding to matrix index
%             row(col > (row + obj.diag_offset)) = NaN;
%             ind = row + ((col - 1) .* (double(obj.size) + 1 + obj.diag_offset)) - helpers.triNum(col) + 1 + obj.diag_offset;
%         end
%         function ind = index(obj, row, col)
%             ind_all = bsxfun(@obj.indexCol, row.', col);
%             ind = ind_all(~isnan(ind_all));
%         end
        
%         function ind = index(obj, row, col)
%             index_matrix(obj.size, obj.size) = uint32(0);
%             contained = tril(true(obj.size, obj.size), obj.diag_offset);
%             index_matrix(contained) = [1:helpers.triNum(obj.size + obj.diag_offset)];
%             ind2 = index_matrix(row, col);
%             ind = ind2(contained(row, col));
%         end

        function calcIndexMatrix(obj)
            import nla.* % required due to matlab package system quirks
            obj.index_matrix = zeros(obj.size, obj.size, 'uint32');
            % we convert obj.size from uint32 to int32 here because matlab
            % doesn't understand integer promotion
            obj.index_matrix(tril(true(obj.size, obj.size), obj.diag_offset)) = [1:helpers.triNum(int32(obj.size) + obj.diag_offset)];
        end
        
        function ind = index(obj, row, col)
            import nla.* % required due to matlab package system quirks
            ind = nonzeros(obj.index_matrix(row, col));
        end
    end
    methods
        function obj = TriMatrix(varargin)
            import nla.* % required due to matlab package system quirks
            %% Matlab argument parsing because of no default values for functions
            % Construct Trimatrix from first argument if it's a matrix, or
            % create an empty matrix if not

            % Optional diagonal offset parameter - defaults to removing diag
            if nargin >= 2 && isnumeric(varargin{nargin})
                obj.diag_offset = varargin{nargin};
            end
            
            if isscalar(varargin{1})
                obj.size = uint32(varargin{1});
                
                typename = 'double';
                if nargin >= 2 && (isstring(varargin{2}) || ischar(varargin{2}))
                    typename = varargin{2};
                end
                    
                obj.v = zeros(helpers.triNum(int32(obj.size) + obj.diag_offset), 1, typename);
            else
                data = varargin{1};
                
                % length of one edge of the triangle matrix
                obj.size = uint32(size(data, 1));
                
                % we can still create a triangular matrix from a NxN-1 matrix,
                % if we're excluding the diagonal. Therefore, the width of input
                % data may differ
                width = size(data,2);
                
                % dimensions of elements of triangle matrix
                old_dims = size(data);
                element_dims = old_dims(3:end);
                if isempty(element_dims)
                    element_dims = 1;
                end

                % n x n matrix of elements -> n*n vector of elements
                new_dims = [obj.size * width, element_dims];
                data = reshape(data, new_dims);

                % index of each element to grab from n*n vector
                index_vec = tril(ones(obj.size), obj.diag_offset) == 1;

                % Transfer lower triangle elements to the data member, accounting for
                % dimensionality. A similar process is explained further in get()
                element_dimslice = repmat({':'},1,ndims(data)-1);
                
                obj.v = data(index_vec, element_dimslice{:});
            end
            
            assert(obj.size > 1, "TriMatrix must be at least 2x2")

            obj.calcIndexMatrix();
        end
        
        function newTriMatrix = makeCopyFromSubset(obj, colsToCopy)
            %Make properly sized triMatrix with empty values
            import nla.* % required due to matlab package system quirks
            newTriMatrix = nla.TriMatrix(obj.size, obj.diag_offset);
            newTriMatrix.v = obj.v(:,colsToCopy);
        end
        
        function returned = get(obj, row, col)
            % Return the elements at the given indices. The vector of
            import nla.* % required due to matlab package system quirks
            indexes = obj.index(row, col);
            returned = obj.v(indexes, :);
            returned = squeeze(reshape(returned, [size(indexes, 1), obj.elementDims()]));
        end
        
        function set(obj, row, col, value)
            import nla.* % required due to matlab package system quirks
            % Set the element at the index to the given value.
            % N-dimensional indexing is relatively slow so we handle common
            % cases specially
            num_dims = obj.numElementDims();
            if num_dims == 0
                obj.v(obj.index(row, col)) = value; % scalar elements
            elseif num_dims == 1
                obj.v(obj.index(row, col), :) = value; % vector elements
            elseif num_dims == 2
                obj.v(obj.index(row, col), :) = value; % matrix elements
            else
                % n-dimensional elements
                element_dimslice = repmat({':'}, 1, ndims(obj.v) - 1);
                obj.v(obj.index(row, col), element_dimslice{:}) = value;
            end
        end
        
        function returned = asMatrix(obj)
            import nla.* % required due to matlab package system quirks
            %ASMATRIX Return the TriMatrixes contents in matrix form. Slow.
            % If the object is a numeric data type(or matrix thereof), preallocate
            % This is hideous but MATLAB(tm) does not allow array creation
            % from a type and has thus forced my hand.
            if isnumeric(obj.v)
                returned = NaN([obj.size * (obj.size), obj.elementDims()]);
            elseif islogical(obj.v)
                returned = false([obj.size * (obj.size), obj.elementDims()]);
            end
            
            % Place each element at the  corresponding location within the matrix
            returned(obj.index_matrix ~= 0, :) = obj.v([1:size(obj.v, 1)], :);
            
            % Reshape the matrix to the correct dimensions
            returned = reshape(returned, [obj.size, obj.size, obj.elementDims()]);
        end
        
        function num = numElements(obj)
            import nla.* % required due to matlab package system quirks
            num = size(obj.v, 1);
        end
        
        function diagElemIdxs = getDiagElemIdxs(obj)
            diagElemIdxs = diag(obj.index_matrix);
            %Return as row vector to allow looping
            diagElemIdxs = reshape(diagElemIdxs,1,numel(diagElemIdxs));
        end
        
        function offDiagElemIdxs = getOffDiagElemIdxs(obj)
            offDiagSquare = tril(obj.index_matrix,-1); %get all elems below diagonal
            offDiagElemIdxs = offDiagSquare(offDiagSquare>0);
            %Return as row vector to allow looping
            offDiagElemIdxs = reshape(offDiagElemIdxs,1,numel(offDiagElemIdxs));
        end
        
        function [rowIdx, colIdx] = getRowAndColOfElem(obj, elemIdx)
            isElementMtx = obj.index_matrix == elemIdx;
            rowIdx = find(sum(isElementMtx,2),1);
            colIdx = find(sum(isElementMtx,1),1);
        end
    end
end

