function varargout = palm_quickperms(varargin)
    % Create a set of permutations that is left in the Octave/Matlab workspace
    % for later use, or to be exported to other programs.
    %
    % [Pset,VG] = palm_quickperms(M,EB,P,EE,ISE,CMCx,CMCp)
    %
    % Inputs (to skip an argument, use an empty array, []):
    % M       : Design matrix. It can be the full, unpartitioned design, or
    %           if there are nuisance, simply the part that contains the EVs
    %           of interest. This distinction is only relevant if there are
    %           discrete EVs of interest and nuisance variables that are
    %           continuous. You may consider a partitioning as in the
    %           function palm_partition.m.
    %           If you have no idea what to use, it is in general, it is in
    %           general safe to use as M simply a vector (1:N)'.
    %           You can also simply leave it empty ([]) if EB is supplied, and
    %           by default it will be (1:N)'. If an EB isn't supplied, you can
    %           simply use N and by default it will be (1:N)'.
    % EB      : Exchangeability blocks (can be multi-level). For freely
    %           exchangeable data, use ones(N,1). You can also leave it
    %           empty ([]) if a valid, non-empty M was supplied.
    % P       : Desired number of permutations. The actual number may be
    %           smaller if N is too small. Use 0 for exhaustive.
    %           Default is 10000.
    % EE      : True/False indicating whether to assume exchangeable errors,
    %           which allow permutations.
    % ISE     : True/False indicating whether to assume independent and
    %           symmetric errors, which allow sign-flippings.
    % CMCx    : True/False indicating whether repeated rows in the design
    %           should be be ignored. Default is false.
    % CMCp    : True/False indicating whether repeated permutations should
    %           be ignored. Default is false.
    %
    % Outputs:
    % Pset    : Permutation set. It contains one permutation per column.
    % VG      : Variance groups (VGs), to be used with a statistic that is
    %           robust to heteroscedasticity.
    %
    % _____________________________________
    % Anderson M. Winkler
    % FMRIB / University of Oxford
    % Sep/2015
    % http://brainder.org

    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    % PALM -- Permutation Analysis of Linear Models
    % Copyright (C) 2015 Anderson M. Winkler
    %
    % This program is free software: you can redistribute it and/or modify
    % it under the terms of the GNU General Public License as published by
    % the Free Software Foundation, either version 3 of the License, or
    % any later version.
    %
    % This program is distributed in the hope that it will be useful,
    % but WITHOUT ANY WARRANTY; without even the implied warranty of
    % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    % GNU General Public License for more details.
    %
    % You should have received a copy of the GNU General Public License
    % along with this program.  If not, see <http://www.gnu.org/licenses/>.
    % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    % Take the inputs:
    v.M       = [];
    v.EB      = [];
    v.P       = 10000;
    v.EE      = true;
    v.ISE     = false;
    v.CMCx    = false;
    v.CMCp    = false;
    fields = fieldnames(v);
    for a = 1:nargin
        if ~ isempty(varargin{a})
            v.(fields{a}) = varargin{a};
        end
    end
    if ~ v.EE && ~ v.ISE
        error('At least one of EE or ISE must be given as "true".');
    end
    if v.P < 0
        error('P must not be negative');
    end
    if isempty(v.M ), v.M  = 0; end
    if isempty(v.EB), v.EB = 0; end 

    % Number of subjects
    N = max(size(v.M,1),size(v.EB,1));
    if N == 1
        N = max(v.M,v.EB);
    elseif N == 0
        error('Design matrix and exchangeability blocks cannot be both empty.');
    end
    if v.M  == 0, v.M  = N; end
    if v.EB == 0, v.EB = N; end 
    if ...
            (size(v.M,1)  > 1 && N ~= size(v.M,1))  || ...
            (isscalar(v.M)    && N ~= v.M)          || ...
            (size(v.EB,1) > 1 && N ~= size(v.EB,1)) || ...
            (isscalar(v.EB)   && N ~= v.EB)
        error('Design matrix and exchangeability blocks of incompatible sizes');
    end

    % Design matrix:
    if isempty(v.M) || isscalar(v.M) || v.CMCx
        v.M = (1:N)';
    end

    % Create the shufflings:
    if ...
            isempty(v.EB)   || ...
            isscalar(v.EB)  || ...
            (isvector(v.EB) && numel(unique(v.EB)) == 1)
        
        % If no EBs were given, use simple shuffling:
        simpleshuf = true;
        Pset  = palm_shuffree(v.M,v.P,v.CMCp,v.EE,v.ISE,true);

    else
        
        % Or use the multi-level blocks. Begin by reindexing the leaves:
        simpleshuf = false;
        v.EB  = palm_reindex(v.EB,'fixleaves');
        
        % Then create the permutation tree:
        Ptree = palm_tree(v.EB,v.M);
        
        % Then the set of permutations:
        Pset  = palm_shuftree(Ptree,v.P,v.CMCp,v.EE,v.ISE,true);
    end
    varargout{1} = Pset;

    % Define the variance groups (for heteroscedasticity, if needed):
    if nargout == 2
        
        % Create the VGs:
        if simpleshuf
            VG = ones(N,1);
        else
            VG = palm_ptree2vg(Ptree);
        end
        varargout{2} = VG;
    end

% ======================================================
function Br = palm_reindex(varargin)
    % Reindexes blocks so that each is numbered natural numbers,
    % starting from 1. There are two pure possibilities: the numbering
    % goes continuously for each level, crossing block definitions,
    % or it restarts at 1 for each new block. A third method is a
    % mixture of both, i.e., it restarts at each block, but at the
    % last block it is continuous, crossing blocks.
    % Finally (and the default), it is also possible to add one
    % extra column to treat the simplification in which the last
    % level is omited for whole-block permutation ('fixleaves').
    %
    % Usage:
    % Br = palm_reindex(B,method)
    % 
    % B     : Block definitions (multilevel).
    % meth  : Method for reindexing: 'continuous', 'restart',
    %         'mixed' or 'fixleaves' as described above.
    %         Default: 'fixleaves'.
    % Br    : Reindexed block definitions.


    % Default
    meth = 'fixleaves';

    % Take care of input and output vars
    B  = varargin{1};
    Br = zeros(size(B));
    if nargin > 1
        meth = varargin{2};
    end

    switch lower(meth)
        
        case 'continuous'
            
            % Renumber using sequential natural numbers starting
            % from 1 and crossing blocks. The first level is
            % treated differently as it doesn't have a
            % "previous" block.
            U = unique(B(:,1));
            for u = 1:numel(U)
                idx = B(:,1) == U(u);
                Br(idx,1) = u*sign(U(u));
            end
            for b = 2:size(B,2) % 2nd onwards
                Bb = B(:,b);
                Bp = Br(:,b-1); % previous
                Up = unique(Bp);
                cnt = 1;
                for up = 1:numel(Up)
                    idxp = Bp == Up(up);
                    U = unique(Bb(idxp));
                    for u = 1:numel(U)
                        idx = (Bb == U(u)) & idxp;
                        Br(idx,b) = cnt*sign(U(u));
                        cnt = cnt + 1;
                    end
                end
            end
            
        case 'restart'
            
            % Renumber using sequential natural numbers
            % starting from 1 but never crossing blocks,
            % restarting instead for each block.
            Br = renumber(B);
            
        case 'mixed'
            
            % This mixes both above
            Ba = palm_reindex(B,'restart');
            Bb = palm_reindex(B,'continuous');
            Br = horzcat(Ba(:,1:end-1),Bb(:,end));
            
        case 'fixleaves'
            
            % Renumber using sequential natural numbers
            % starting from 1 but never crossing blocks,
            % restarting instead for each block.
            [Br,addcol] = renumber(B);
            if addcol
                Br = horzcat(Br,(1:size(Br,1))');
                Br = renumber(Br);
            end
            
        otherwise
            error('Unknown method: %s',meth);
    end

% ==============================================
function [Br,addcol] = renumber(B)
    % Note that this runs recursively.

    B1 = B(:,1);
    U = unique(B1);
    addcolvec = false(size(U));
    nU = numel(U);
    Br = zeros(size(B));
    for u = 1:nU
        idx = B1 == U(u);
        Br(idx,1) = u*sign(U(u));
        if size(B,2) > 1
            [Br(idx,2:end),addcolvec(u)] = renumber(B(idx,2:end));
        elseif sum(idx) > 1
            addcol = true;
            Br(idx) = -abs(B(idx));
        else
            addcol = false;
        end
    end

    if size(B,2) > 1
        addcol = any(addcolvec);
    end

% ===================================================
function Ptree = palm_tree(B,M)
    % Generates a tree that takes the dependence structure
    % between observations into account. From this tree, the
    % permutations can be generated later.
    %
    % Usage:
    % Ptree = palm_tree(B,M)
    %
    % - B       : Multi-level block definitions.
    % - M       : Design matrix.
    % - Ptree   : Permutation tree, from which permutations are generated
    %             later.
    %
    % Each node is a cell with 4 elements:
    % N{1,1}  : A 3-column array for whole block in which:
    %           - the 1st is a sequence of indices that indicates the
    %             current lexicographic permutation.
    %           - the 2nd are indices that indicate the current
    %             shuffling in relation to the original
    %           - the 3rd are indices that indicate the current
    %             permutation in relation to the previous
    %          For within-block, this is a NaN.
    % N{1,2} : A logical vector indicating the current state of sign
    %          flips for the tree. 0 is treated as 1, and 1 as -1.
    % N{1,3} : The branches that begin here.
    %
    % Reference:
    % * Winkler AM, Webster MA, Vidaurre D, Nichols TE, Smith SM.
    %   Multi-level block permutation. Neuroimage. 2015;123:253-68.

    if nargin == 1 || isempty(M)
        M = (1:size(B,1))';
    elseif size(B,1) ~= size(M,1)
        error('The two inputs must have the same number of rows.');
    end

    % Make some initial sanity checks:
    Bs = sortrows(B);
    warned = checkblk(Bs,Bs(1)>=0,0);
    if warned
        error([...
            'Due to one or more of the issues listed above, the block\n' ...
            'definition may cause problems when the permutations are generated.\n'  ...
            'Please, correct the block definition file and try again.%s'],'');
    end

    % Order of the observations in the original data. Note
    % that B should have not been sorted, and should retain
    % the order as originally entered by the user (even if
    % the rows are totally scrambled).
    O = (1:size(M,1))';

    % Now make the actual tree.
    % The sanity of the block definitions should have already
    % been taken care of by the wrapper function, so no need to
    % check validity here. If the first element is negative,
    % it is fair to assume that so are the remaining of the
    % elements in the first column.
    wholeblock = B(1) > 0;
    Ptree = cell(1,3);
    [Ptree{1},Ptree{3}] = maketree( ...
        B(:,2:end),M,O,wholeblock,wholeblock);
    if wholeblock
        Ptree{2} = false(size(Ptree{3},1),1);
    else
        Ptree{2} = [];
    end

% ==============================================================
function [S,Ptree] = maketree(B,M,O,wholeblock,nosf)
    % Now makes the actual tree, each branch recursively.
    % - B    : Block definitions
    % - M    : Design matrix
    % - O    : Observation indices
    % - wholeblock : boolean, indicates if this is part of whole-block
    %          at the immediately upper level.
    % - nosf : It also implies no signflip this level, because
    %          of a higher whole-block)

    % Unique blocks at this level & some other vars for later
    B1 = B(:,1);
    U  = unique(B1);
    nU = numel(U);
    if size(B,2) > 1
        Ptree = cell(nU,3);
    else
        Ptree = cell(nU,1);
    end

    % For each block
    for u = 1:nU
        
        % Enter into each unique block
        idx = B1 == U(u);
        
        % If this isn't the last level, continue constructing
        % the branches recursively.
        if size(B,2) > 1
            wholeblockb = B(find(idx,1),1) > 0;
            [Ptree{u,1},Ptree{u,3}] = ...
                maketree(             ...
                B(idx,2:end),         ...
                M(idx,:),             ...
                O(idx),               ...
                wholeblockb,          ...
                wholeblockb || nosf);
            Ptree{u,2} = [];
            
            % Count the number of possible sign-flips for these branches
            if nosf
                % If it was flipped at higher levels (whole-block)
                Ptree{u,2} = [];
                
            elseif size(Ptree{u,3},2) > 1
                % If it might be flipped here, but there are distal branches:
                % If this is whole-block, assign a number. If within-block,
                % no sign-flips allowed at this level.
                if isnan(Ptree{u,1}(1))
                    Ptree{u,2} = [];
                else
                    Ptree{u,2} = false(size(Ptree{u,3},1),1);
                end            
            else
                % If there are no further branches
                Ptree{u,2} = false(size(Ptree{u,3},1),1);
            end
            
        else
            % At the terminal branches, there is no more tree, so
            % just keep track of the observation indices.
            Ptree{u,1} = O(idx);
        end
    end

    % Make the sequence of values that are the reference for the
    % lexicographic permutations to be done later. This is doesn't
    % apply to the highest level.
    if wholeblock && nU > 1
        
        % Identify repeated sets of rows, which receive then
        % the same index; these repetitions are taken care of
        % later by the Algorithm L.
        B1M     = sortrows([B1 M]); % B1 is here to be together with M during sorting
        Ms      = B1M(:,2:end);     % but its removed here, as it's of no use.
        [~,~,S] = unique(reshape(Ms',[numel(Ms)/nU nU])','rows');
        
        % Put in ascending order, and (un)shuffle the branches
        % accordingly
        [S,idx] = sort(S);
        S = [S (1:numel(S))' (1:numel(S))'];
        Ptree = Ptree(idx,:);
        
    elseif wholeblock && nU == 1
        % For whole block starting at the second level, the
        % permutation matrix is simply the number 1.
        S = [1 1 1];
        
    else
        % There isn't whole-block permutation at the 1st level,
        % only within-block, so this case is marked as NaN.
        S = NaN;
    end

% ==============================================================
function warned = checkblk(B,wholeblock,recdepth)
    % For a given block, check if:
    % - the leftmost column is valid.
    % - the blocks are of the same size for whole-block permutation.
    % - the sign indicator is the same for all blocks for whole-block
    %   permutation.
    % - the indices aren't 0 or non-integer.
    % - the tree branches are all identical for whole-block permutation.
    % Note this uses recursion.

    % Vars for later
    warned = false;
    B1     = B(:,1);
    U      = unique(B1);
    nU     = numel(U);
    Ucnt   = zeros(nU,1);
    Usgn   = Ucnt;
    Uvec   = cell(nU,1);

    % Using positive/negative indices implies that the leftmost column must
    % exist and be filled entirely with the same digit.
    if recdepth == 0 && numel(U) > 1
        error('The highest level (leftmost column) must be entirely filled by the same value.');
    end

    % For each block
    for u = 1:nU
        
        if U(u) == 0
            
            % The index 0 cannot be considered valid (neither
            % positive or negative).
            warning('The digit 0 should be avoided as block indicator (level %d).\n',recdepth);
            warned = true;
            
        elseif rem(U(u),1) ~= 0
            
            % Let's avoid fractional indices too.
            warning('Non-integer indices should be avoided (level %d).\n',recdepth);
            warned = true;
            
        else
            
            % Enter into each unique block to see what else
            idx = B1 == U(u);
            if size(B,2) > 1
                
                % Here the test for whole-block permutation allows 0 as index,
                % just so that these otherwise invalid blocks are not ignored.
                % The warning message above should raise the user attention.
                checkblk(B(idx,2:end),B(find(idx,1),1)>=0,recdepth+1);
                
                % This is to check if the remainder cols are all equal. It's
                % necessary that the rows of the original B are sorted for this
                % to work.
                tmp = B(idx,2:end);
                Uvec{u} = tmp(:)';
            end
            
            % Check the size and sign of the sub-blocks
            Ucnt(u) = sum(idx);
            Usgn(u) = sign(U(u));
        end
    end

    % Check if all subblocks within each EB are of the same size.
    if wholeblock && any(diff(Ucnt))
        
        % Note that counting the number of times Matlab/Octave
        % reports as the source of the error the line above where
        % palm_renumber is called again also helps to identify
        % which is the offending block level.
        error('Not al sub-blocks within an EB are of the same size at level %d.\n',recdepth);
        
    elseif wholeblock && numel(unique(Usgn)) > 1
        
        % Make sure that for whole-block permutation, there is no mix of
        % sub-blocks with positive and negative signs, as these cannot be
        % shuffled.
        error('Not all sub-blocks within an EB have the same sign indicator at level %d.\n',recdepth);
        
    elseif wholeblock
        
        % Now check whether the branches that begin at a given level are all
        % identical, as needed for whole-block permutation. Note that for this
        % check to work, the blocks must be numbered using the "restart" (i.e.,
        % not "continuous") method. See the function palm_reindex.m.
        Uvec = cell2mat(Uvec);
        Ur = unique(Uvec,'rows');
        if size(Ur,1) > 1
            warning('Not all blocks are identical after level %d to allow valid whole-block permutation.\n',recdepth);
            warned = true;
        end
    end

% ==================================================================
function [Bset,nB,mtr] = palm_shuftree(varargin)
    % This is a wrapper for the palm_permtree.m and palm_fliptree.m
    % that generates a sigle set of permutations. It can also generate
    % only permutations with sign-flipping depending on the input
    % arguments.
    %
    % Usage (style 1)
    % [Bset,nB] = palm_shuftree(Ptree,nP0,CMC,EE,ISE,idxout)
    %
    % Inputs:
    % - Ptree   : Permutation tree.
    % - nP0     : Requested number of permutations.
    % - CMC     : Use Conditional Monte Carlo.
    % - EE      : Allow permutations?
    % - ISE     : Allow sign-flips?
    %             If you supply the EE argument, you must
    %             also supply ISE argument. If one is omited,
    %             the other needs to be omited too.
    %             Default is true for EE, and false for ISE.
    % - idxout  : (Optional) If true, the output isn't a cell
    %             array with permutation matrices, but an array
    %             with permutation indices.
    %
    % Outputs:
    % - Bset    : Set of permutations and/or sign flips.
    % - nB      : Number of permutations and/or sign-flips.
    %
    %
    % Usage (style 2, to be used by the PALM main function):
    % [Bset,nB,metr] = palm_shuftree(opts,plm)
    %
    % Inputs:
    % - opts    : Struct with PALM options
    % - plm     : Struct with PALM data
    %
    % Outputs:
    % - Bset    : Set of permutations and/or sign flips.
    % - nB      : Number of permutations and/or sign-flips.

    % Take arguments
    if nargin == 2 || nargin == 4
        opts     = varargin{1};
        plm      = varargin{2};
        EE       = opts.EE;
        ISE      = opts.ISE;
        nP0      = opts.nP0;
        CMC      = opts.cmcp;
        seq      = plm.seq{varargin{3}}{varargin{4}};
        Ptree    = palm_tree(plm.EB,seq);
        idxout   = false;
    elseif nargin == 3 || nargin == 5 || nargin == 6
        Ptree    = varargin{1};
        nP0      = varargin{2};
        CMC      = varargin{3};
        if nargin == 5 || nargin == 6
            EE   = varargin{4};
            ISE  = varargin{5};
        else
            EE   = true;
            ISE  = false;
        end
        if nargin == 6
            idxout = varargin{6};
        else
            idxout = false;
        end
    else
        error('Incorrect number of input arguments');
    end
    if ~EE && ~ISE
        error('EE and/or ISE must be enabled, otherwise there is nothing to shuffle.')
    end

    % Maximum number of shufflings (perms, sign-flips or both)
    maxP = 1;
    maxS = 1;
    if EE
        lmaxP = palm_maxshuf(Ptree,'perms',true);
        maxP = exp(lmaxP);
        if isinf(maxP)
            fprintf('Number of possible permutations is exp(%g).\n',lmaxP);
        else
            fprintf('Number of possible permutations is %g.\n',maxP);
        end
    end
    if ISE
        lmaxS = palm_maxshuf(Ptree,'flips',true);
        maxS = exp(lmaxS);
        if isinf(maxS)
            fprintf('Number of possible sign-flips is exp(%g).\n',lmaxS);
        else
            fprintf('Number of possible sign-flips is %g.\n',maxS);
        end
    end
    maxB = maxP * maxS;

    % String for the screen output below
    if EE && ~ISE
        whatshuf  = 'permutations only';
        whatshuf2 = 'perms';
    elseif ISE && ~EE
        whatshuf  = 'sign-flips only';
        whatshuf2 = 'flips';
    elseif EE && ISE
        whatshuf  = 'permutations and sign-flips';
        whatshuf2 = 'both';
    end

    % Generate the Pset and Sset
    Pset = {};
    Sset = {};
    if nP0 == 0 || nP0 >= maxB
        % Run exhaustively if the user requests too many permutations.
        % Note that here CMC is irrelevant.
        fprintf('Generating %g shufflings (%s).\n',maxB,whatshuf);
        if EE
            Pset = palm_permtree(Ptree,round(maxP),[],false,round(maxP));
        end
        if ISE
            Sset = palm_fliptree(Ptree,round(maxS),[],false,round(maxS));
        end
    elseif nP0 < maxB
        % Or use a subset of possible permutations. The nested conditions
        % are to avoid repetitions, and to compensate fewer flips with more
        % perms or vice versa as needed in the tight situations
        fprintf('Generating %g shufflings (%s).\n',nP0,whatshuf);
        if EE
            if nP0 >= maxP
                Pset = palm_permtree(Ptree,round(maxP),CMC,false,round(maxP));
            else
                Pset = palm_permtree(Ptree,nP0,CMC,false,round(maxP));
            end
        end
        if ISE
            if nP0 >= maxS
                Sset = palm_fliptree(Ptree,round(maxS),CMC,false,round(maxS));
            else
                Sset = palm_fliptree(Ptree,nP0,CMC,false,round(maxS));
            end
        end
    end

    % This ensures that there is at least 1 permutation (no permutation)
    % and 1 sign-flipping (no sign-flipping).
    nP = numel(Pset);
    nS = numel(Sset);
    if nP > 0 && nS == 0
        Sset{1} = Pset{1};
        nS = 1;
    elseif nP == 0 && nS > 0
        Pset{1} = Sset{1};
        nP = 1;
    end

    % Generate the set of shufflings, mixing permutations and
    % sign-flippings as needed.
    if nS == 1
        % If only 1 sign-flip is possible, ignore it.
        Bset = Pset;
    elseif nP == 1
        % If only 1 permutation is possible, ignore it.
        Bset = Sset;
    elseif nP0 == 0 || nP0 >= maxB
        % If the user requested too many shufflings, do all
        % those that are possible.
        Bset = cell(maxB,1);
        b = 1;
        for p = 1:numel(Pset)
            for s = 1:numel(Sset)
                Bset{b} = Pset{p} * Sset{s};
                b = b + 1;
            end
        end
    else
        % The typical case, with an enormous number of possible
        % shufflings, and the user choses a moderate number
        Bset = cell(nP0,1);
        % 1st shuffling is no shuffling, regardless
        Bset{1} = Pset{1} * Sset{1};
        if CMC
            % If CMC, no need to take care of repetitions.
            for b = 2:nP0
                Bset{b} = Pset{randi(nP)} * Sset{randi(nS)};
            end
        else
            % Otherwise, avoid them
            [~,idx] = sort(rand(nP*nS,1));
            idx = idx(1:nP0);
            [pidx,sidx] = ind2sub([nP nS],idx);
            for b = 2:nP0
                Bset{b} = Pset{pidx(b)} * Sset{sidx(b)};
            end
        end
    end
    nB = numel(Bset);

    % In the draft mode, the permutations can't be in lexicographic
    % order, but entirely shuffled.
    if nargin == 2 || nargin == 4
        if opts.accel.negbin
            Bset2 = cell(size(Bset));
            [~,idx] = sort(rand(nB,1));
            for p = 2:nB
                Bset2{p} = Bset(idx(p));
            end
            Bset = Bset2;
        end
    end

    % If the desired outputs are permutation indices instead
    % of permutation matrices, output them
    if idxout || ... % indices out instead of a cell array
            (nargout == 3 && nargin == 4) % save metrics
        
        % Convert formats
        Bidx = palm_swapfmt(Bset);
            
        % Compute some metrics
        if nargout == 3
            Ptree1 = palm_tree(plm.EB,ones(size(seq)));
            mtr = zeros(9,1);
            [mtr(1),mtr(2),mtr(4)] = ...
                palm_metrics(Ptree,seq,whatshuf2);
            [~,~,mtr(3)] = ...
                palm_metrics(Ptree1,ones(size(seq)),whatshuf2);
            [mtr(5),mtr(6),mtr(7),mtr(8),mtr(9)] = palm_metrics(Bidx,seq,whatshuf2);
        end
        
        % Output as indices if needed
        if idxout
            Bset = Bidx;
        end
    end
% ================================================
function [Bset,nB,mtr] = palm_shuffree(varargin)
    % A single function to generate a set of permutations and/or
    % sign-flips. This function is a faster replacement to
    % palm_shuftree.m when all observations are freely exchangeable,
    % i.e., when there are no block restrictions and no tree needs
    % to be constructed.
    % 
    % Usage
    % [Bset,nB] = palm_shuffree(M,nP0,CMC,EE,ISE,idxout)
    % 
    % Inputs:
    % - M        : Design matrix.
    % - nP0      : Requested number of permutations.
    % - CMC      : Use Conditional Monte Carlo?
    % - EE       : Allow permutations?
    % - ISE      : Allow sign-flips?
    %              If you supply the EE argument, you must
    %              also supply ISE argument. If one is omited,
    %              the other needs to be omited too.
    %              Default is true for EE, and false for ISE.
    % - idxout   : (Optional) If true, the output isn't a cell
    %              array with permutation matrices, but an array
    %              with permutation indices.
    % 
    % Outputs:
    % - Bset     : Set of permutations and/or sign flips.
    % - nB       : Number of permutations and/or sign-flips.
    % - mtr      : Some metrics. See palm_metrics.m for details.
    % 
    % _____________________________________
    % Anderson M. Winkler
    % FMRIB / University of Oxford
    % Jan/2014
    % http://brainder.org

    % Accept arguments
    if nargin < 2 || nargin > 6 || nargin == 4
        error('Incorrect number of arguments');
    end
    M   = varargin{1};
    nP0 = varargin{2};
    if nargin > 2
        CMC = varargin{3};
    else
        CMC = false;
    end
    if nargin > 4
        EE  = varargin{4};
        ISE = varargin{5};
    else
        EE  = true;
        ISE = false;
    end
    if nargin > 5
        idxout = varargin{6};
    else
        idxout = false;
    end
    if ~EE && ~ISE
        error('EE and/or ISE must be enabled, otherwise there is nothing to shuffle.')
    end

    % Sequence of unique values to shuffle
    N = size(M,1);
    [~,~,seq] = unique(M,'rows');
    seqS = sortrows(horzcat(seq,(1:N)'));
    U    = unique(seq);
    nU   = numel(U);

    % Logs, to help later
    lfac = palm_factorial(N);

    % Number of unique permutations & sign flips
    maxP  = 1;
    maxS  = 1;
    lmaxP = 0;
    lmaxS = 0;
    if EE
        nrep = zeros(size(U));
        for u = 1:nU
            nrep(u) = sum(seqS(:,1) == U(u));
        end
        lmaxP = lfac(N+1) - sum(lfac(nrep+1));
        maxP  = round(exp(lmaxP));
        if nU == N
            if isinf(maxP)
                fprintf('Number of possible permutations is exp(%g) = %d!.\n',lmaxP,N);
            else
                fprintf('Number of possible permutations is %g = %d!.\n',maxP,N);
            end
        else
            if isinf(maxP)
                fprintf('Number of possible permutations is exp(%g).\n',lmaxP);
            else
                fprintf('Number of possible permutations is %g.\n',maxP);
            end
        end
    end
    if ISE
        lmaxS = N * log(2);
        maxS  = 2^N;
        if isinf(maxS)
            fprintf('Number of possible sign-flips is exp(%g) = 2^%d.\n',lmaxS,N);
        else
            fprintf('Number of possible sign-flips is %g = 2^%d.\n',maxS,N);
        end
    end
    maxB  =  maxP * maxS;
    lmaxB = lmaxP + lmaxS;

    % String for the screen output below
    if EE && ~ISE
        whatshuf = 'permutations only';
        stype    = 'perms';
    elseif ISE && ~EE
        whatshuf = 'sign-flips only';
        stype    = 'flips';
    elseif EE && ISE
        whatshuf = 'permutations and sign-flips';
        stype    = 'both';
    end

    % This ensures that there is at least 1 permutation (no permutation)
    % and 1 sign-flipping (no sign-flipping). These are modified below as
    % needed.
    Pset = seqS(:,2);
    Sset = ones(N,1);

    % Generate the Pset and Sset
    if nP0 == 0 || nP0 >= maxB
        % Run exhaustively if the user requests more permutations than possible.
        % Note that here CMC is irrelevant.
        fprintf('Generating %g shufflings (%s).\n',maxB,whatshuf);
        if EE
            Pset = horzcat(Pset,zeros(N,maxP-1));
            for p = 2:maxP
                seqS = palm_nextperm(seqS);
                Pset(:,p) = seqS(:,2);
            end
        end
        if ISE
            if N <= 52
                Sset = palm_d2b(0:maxS-1,N)';
                Sset(~~Sset) = -1;
                Sset( ~Sset) =  1;
                Sset = flipud(Sset);
            else
                Sset = false(N,maxS);
                for s = 2:maxS
                    Sset(:,s) = palm_incrbin(Sset(:,s-1));
                end
            end
        end
    elseif nP0 < maxB
        % Or use a subset of possible permutations. The nested conditions
        % are to avoid repetitions, and to compensate fewer flips with more
        % perms or vice versa as needed in the tight situations
        fprintf('Generating %g shufflings (%s).\n',nP0,whatshuf);
        if EE
            if nP0 >= maxP
                Pset = horzcat(Pset,zeros(N,maxP-1));
                for p = 2:maxP
                    seqS = palm_nextperm(seqS);
                    Pset(:,p) = seqS(:,2);
                end
            else
                Pset = horzcat(Pset,zeros(N,nP0-1));
                if CMC
                    for p = 1:nP0
                        Pset(:,p) = randperm(N)';
                    end
                else
                    Pseq = zeros(size(Pset));
                    Pseq(:,1) = seqS(:,2);
                    for p = 2:nP0
                        whiletest = true;
                        while whiletest
                            Pset(:,p) = randperm(N)';
                            Pseq(:,p) = seqS(Pset(:,p));
                            whiletest = any(all(bsxfun(@eq,Pseq(:,p),Pseq(:,1:p-1))));
                        end
                    end
                end
            end
        end
        if ISE
            if nP0 >= maxS
                Sset = palm_d2b(0:maxS-1,N)';
                Sset(~~Sset) = -1;
                Sset( ~Sset) =  1;
            else
                if CMC
                    Sset = double(rand(N,nP0) > .5);
                    Sset(:,1) = 0;
                    Sset(~~Sset) = -1;
                    Sset( ~Sset) =  1;
                else
                    Sset = zeros(N,nP0);
                    for p = 2:nP0
                        whiletest = true;
                        while whiletest
                            Sset(:,p) = rand(N,1) > .5;
                            whiletest = any(all(bsxfun(@eq,Sset(:,p),Sset(:,1:p-1))));
                        end
                    end
                    Sset(~~Sset) = -1;
                    Sset( ~Sset) =  1;
                end
            end
        end
    end

    % Generate the set of shufflings, mixing permutations and
    % sign-flippings as needed.
    nP = size(Pset,2);
    nS = size(Sset,2);
    if nS == 1
        % If only 1 sign-flip is possible, ignore it.
        Bset = Pset;
    elseif nP == 1
        % If only 1 permutation is possible, ignore it.
        Bset = bsxfun(@times,Pset,Sset);
    elseif nP0 == 0 || nP0 >= maxB
        % If the user requested too many shufflings, do all
        % those that are possible.
        Bset = zeros(N,maxB);
        b = 1;
        for p = 1:size(Pset,2)
            for s = 1:size(Sset,2)
                Bset(:,b) = Pset(:,p) .* Sset(:,s);
                b = b + 1;
            end
        end
    else
        % The typical case, with an enormous number of possible
        % shufflings, and the user choses a moderate number
        Bset = zeros(N,nP0);
        % 1st shuffling is no shuffling, regardless
        Bset(:,1) = (1:N)';
        if CMC
            % If CMC, no need to take care of repetitions.
            for b = 2:nP0
                Bset(:,b) = Pset(:,randi(nP)) .* Sset(:,randi(nS));
            end
        else
            % Otherwise, avoid them
            [~,bidx] = sort(rand(nP*nS,1));
            bidx = bidx(1:nP0);
            [pidx,sidx] = ind2sub([nP nS],bidx);
            for b = 2:nP0
                Bset(:,b) = Pset(:,pidx(b)) .* Sset(:,sidx(b));
            end
        end
    end
    nB = size(Bset,2);

    % Sort back to the original order
    Bset = sortrows(Bset);

    % Compute some metrics
    if nargout == 3
        mtr      = zeros(9,1);
        mtr(1:2) = lmaxB;
        mtr(4)   = 2^nU - 1;
        [mtr(5),mtr(6),mtr(7),mtr(8),mtr(9)] = palm_metrics(Bset,seq,stype);
    end

    % If the desired outputs are permutation matrices instead of indices
    if ~ idxout
        Bset = palm_swapfmt(Bset);
    end
% ===========================================
function lfac = palm_factorial(N)
    % Computes the log(factorial(0:N)), so dealing with
    % precision issues.
    %
    % lfac = palm_factorial(N)
    %
    % _____________________________________
    % Anderson M. Winkler
    % FMRIB / University of Oxford
    % Dec/2012
    % http://brainder.org

    persistent lf;
    if isempty(lf) || length(lf) < N+1
        lf = zeros(N+1,1);
        for n = 1:N
            lf(n+1) = log(n) + lf(n);
        end
    end
    lfac = lf;
% ====================================
function [a,succ] = palm_nextperm(a)
    % Given a sequence of integers "a", returns the next lexicographic
    % permutation of this sequence. If "a" is already the last possible
    % permutation, returns a vector of zeros of size(a).
    % Note that to shuffle vectors, they must be supplied as
    % column vectors (N by 1).
    % 
    % Usage:
    % [a1,succ] = palm_nextperm(a)
    % 
    % a    : 2D array to be shuffled. Only the 1st column is
    %        considered for the permutations. The rows as a whole
    %        are shuffled together.
    % a1   : Permuted sequence of values that corresponds to the
    %        next lexicographic permutation.
    % succ : If a is already the last possible permutation,
    %        a1 = flipud(a) and succ is false.
    %        Otherwise sucs is true.
    % 
    % This function is an implementation of the "Algorithm L",
    % by D. Knuth (see "The Art of Computer Programming", Vol.4,
    % Fasc.2: Generating All Tuples and Permutations.
    % See also palm_algol.m to produce all possible permutations for
    % a given sequence in a single function.
    %
    % _____________________________________
    % Anderson M. Winkler
    % FMRIB / University of Oxford
    % Feb/2012 (first version)
    % Oct/2013 (this version)
    % http://brainder.org

    % Algorithm L
    % Step L2
    n = size(a,1);
    j = n - 1;
    while j > 0 && a(j,1) >= a(j+1,1)
        j = j - 1;
    end

    % If this isn't yet the last permutation, bring up the next one.
    if j > 0
        
        % Step L3
        l = n;
        while a(j,1) >= a(l,1)
            l = l - 1;
        end
        tmp  = a(j,:);
        a(j,:) = a(l,:);
        a(l,:) = tmp;
        
        % Step L4
        k = j + 1;
        l = n;
        while k < l
            tmp  = a(k,:);
            a(k,:) = a(l,:);
            a(l,:) = tmp;
            k = k + 1;
            l = l - 1;
        end
        
        % Was the permutation successful?
        succ = true;
        
    else
        % If the input is the last permutation, then there is no next.
        % Return then the first shuffle and a successful flag "false"
        % that can be tested outside.
        a    = flipud(a);
        succ = false;
    end