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

% Create the shufflings
% Begin by reindexing the leaves:
simpleshuf = false;
v.EB  = palm_reindex(v.EB,'fixleaves');

% Then create the permutation tree:
Ptree = palm_tree(v.EB,v.M);

% Then the set of permutations:
Pset  = palm_shuftree(Ptree,v.P,v.CMCp,v.EE,v.ISE,true);

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

% ===============================
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
% 
% _____________________________________
% Anderson M. Winkler
% FMRIB / University of Oxford
% Oct/2013
% http://brainder.org
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

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
% 
% _____________________________________
% Anderson M. Winkler
% FMRIB / University of Oxford
% Dec/2013
% http://brainder.org
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
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
        warning('The digit 0 should be avoided as block indicator (level %d).\n',recdepth); %#ok
        warned = true;
        
    elseif rem(U(u),1) ~= 0
        
        % Let's avoid fractional indices too.
        warning('Non-integer indices should be avoided (level %d).\n',recdepth); %#ok
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
        warning('Not all blocks are identical after level %d to allow valid whole-block permutation.\n',recdepth); %#ok
        warned = true;
    end
end

% ==========================================
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
%
% _____________________________________
% Anderson M. Winkler
% FMRIB / University of Oxford
% Nov/2013
% http://brainder.org
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
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

% ==========================================
function maxb = palm_maxshuf(Ptree,stype,uselog)
% Computes the maximum number of possible permutations given
% a tree that specifies the depencence between the observations.
%
% Usage:
% maxb = palm_maxshuf(Ptree,ptype,uselog)
% 
% - Ptree  : Permutation tree, generated by palm_tree.
% - stype  : Shuffling type to count. It can be one of:
%            - 'perms' for permutations.
%            - 'flips' for sign-flips
%            - 'both' for permutations with sign-flips.
% - uselog : A true/false indicating whether compute in logs.
%            Default is false.
% - maxb   : Maximum number of possible shufflings.
%
% _____________________________________
% Anderson M. Winkler
% FMRIB / University of Oxford
% Oct/2013
% http://brainder.org
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if nargin == 1
    stype  = 'perms';
    uselog = false;
elseif nargin == 2
    uselog = false;
end

if uselog
    switch lower(stype)
        case 'perms'
            maxb = lmaxpermnode(Ptree,0);
        case 'flips'
            maxb = lmaxflipnode(Ptree,0);
            maxb = maxb/log2(exp(1));
        case 'both'
            maxp = lmaxpermnode(Ptree,0);
            maxs = lmaxflipnode(Ptree,0);
            maxs = maxs/log2(exp(1));
            maxb = maxp + maxs;
    end
else
    switch lower(stype)
        case 'perms'
            maxb = maxpermnode(Ptree,1);
        case 'flips'
            maxb = maxflipnode(Ptree,1);
        case 'both'
            maxp = maxpermnode(Ptree,1);
            maxs = maxflipnode(Ptree,1);
            maxb = maxp * double(maxs);
    end
end

% ==============================================================
function np = maxpermnode(Ptree,np)
% Number of permutations per node, recursive and
% incremental.
for u = 1:size(Ptree,1)
    np = np * seq2np(Ptree{u,1}(:,1));
    if size(Ptree{u,3},2) > 1
        np = maxpermnode(Ptree{u,3},np);
    end
end

% ==============================================================
function np = seq2np(S)
% Takes a sequence of integers and computes the 
% number of possible permutations.
U   = unique(S);
nU  = numel(U);
cnt = zeros(size(U));
for u = 1:nU
    cnt(u) = sum(S == U(u));
end
np = factorial(numel(S))/prod(factorial(cnt));

% ==============================================================
function ns = maxflipnode(Ptree,ns)
% Number of sign-flips per node, recursive and
% incremental.
for u = 1:size(Ptree,1)
    if size(Ptree{u,3},2) > 1
        ns = maxflipnode(Ptree{u,3},ns);
    end
    ns = ns * 2^length(Ptree{u,2});
end

% ==============================================================
function np = lmaxpermnode(Ptree,np)
% Number of permutations per node, recursive and
% incremental.
for u = 1:size(Ptree,1)
    np = np + lseq2np(Ptree{u,1}(:,1));
    if size(Ptree{u,3},2) > 1
        np = lmaxpermnode(Ptree{u,3},np);
    end
end

% ==============================================================
function np = lseq2np(S)
% Takes a sequence of integers and computes the 
% number of possible permutations.
nS  = numel(S);
U   = unique(S);
nU  = numel(U);
cnt = zeros(size(U));
for u = 1:nU
    cnt(u) = sum(S == U(u));
end
lfac = palm_factorial(nS);
np   = lfac(nS+1) - sum(lfac(cnt+1));

% ==============================================================
function ns = lmaxflipnode(Ptree,ns)
% Number of sign-flips per node, recursive and
% incremental. Note the in/output are base2 logarithm.
for u = 1:size(Ptree,1)
    if size(Ptree{u,3},2) > 1
        ns = lmaxflipnode(Ptree{u,3},ns);
    end
    ns = ns + length(Ptree{u,2});
end

% =============================
function [Pset,idx] = palm_permtree(Ptree,nP,cmc,idxout,maxP)
% Return a set of permutations from a permutation tree.
% 
% Usage:
% Pset = palm_permtree(Ptree,nP,cmc,idxout,maxP)
% 
% Inputs:
% - Ptree  : Tree with the dependence structure between
%            observations, as generated by 'palm_tree'.
% - nP     : Number of permutations. Use 0 for exhaustive.
% - cmc    : A boolean indicating whether conditional
%            Monte Carlo should be used or not. If not used,
%            there is a possibility of having repeated
%            permutations. The more possible permutations,
%            the less likely to find repetitions.
% - idxout : (Optional) is supplied, Pset is an array of indices
%            rather than a cell array with sparse matrices.
% - maxP   : (Optional) Maximum number of possible permutations.
%            If not supplied, it's calculated internally. If
%            supplied, it's not calculated internally and some
%            warnings that could be printed are omitted.
%            Also, this automatically allows nP>maxP (via CMC).
%
% Outputs:
% - Pset   : A cell array of size nP by 1 containing sparse
%            permutation matrices. If the option idxout is true
%            then it's an array of permutation indices.
% - idx    : Indices that allow sorting the branches of the
%            tree back to the original order. Useful to
%            reorder the sign-flips.
%
% Reference:
% * Winkler AM, Webster MA, Vidaurre D, Nichols TE, Smith SM.
%   Multi-level block permutation. Neuroimage. 2015;123:253-68.
%
% _____________________________________
% Anderson M. Winkler
% FMRIB / University of Oxford
% Oct/2013
% http://brainder.org
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Get the number of possible permutations.
% The 2nd output, idx, is for internal use only, so
% no need to print anything.
if nargout == 1 && nargin < 5
    maxP = palm_maxshuf(Ptree,'perms');
    if nP > maxP
        nP = maxP; % the cap is only imposed if maxP isn't supplied
    end
end
if nargin < 4
    idxout = false;
end

% Permutation #1 is no permutation, regardless.
P = pickperm(Ptree,[])';
P = horzcat(P,zeros(length(P),nP-1));

% All other permutations up to nP
if nP == 1
    % Do nothing if only 1 permutation is to be done. This is
    % here only for speed and because of the idx output that is
    % used when sorting the sign-flips (palm_fliptree.m).
elseif nP == 0 || nP == maxP
    % This will compute exhaustively all possible permutations,
    % shuffling one branch at a time. If nP is too large,
    % print a warning.
    if nP > 1e5 && nargin <= 3
        warning([...
            'Number of possible permutations is %g.\n' ...
            '         Performing all exhaustively.'],maxP);
    end
    for p = 2:maxP
        Ptree  = nextperm(Ptree);
        P(:,p) = pickperm(Ptree,[])';
    end
    
elseif cmc || nP > maxP
    % Conditional Monte Carlo. Repeated permutations allowed.
    for p = 2:nP
        Ptree  = randomperm(Ptree);
        P(:,p) = pickperm(Ptree,[])';
    end
    
else
    
    % Otherwise, repeated permutations are not allowed.
    % For this to work, maxP needs to be reasonably larger than
    % nP, otherwise it will take forever to run, so print a
    % warning.
    if nP > maxP/2 && nargin <= 3
        warning([
            'The maximum number of permutations (%g) is not much larger than\n' ...
            'the number you chose to run (%d). This means it may take a while (from\n' ...
            'a few seconds to several minutes) to find non-repeated permutations.\n' ...
            'Consider instead running exhaustively all possible' ...
            'permutations. It may be faster.'],maxP,nP);
    end
    
    % For each perm, keeps trying to find a new, non-repeated
    % permutation.
    for p = 2:nP
        whiletest = true;
        while whiletest
            Ptree     = randomperm(Ptree);
            P(:,p)    = pickperm(Ptree,[])';
            whiletest = any(all(bsxfun(@eq,P(:,p),P(:,1:p-1))));
        end
    end
end

% The grouping into branches screws up the original order, which
% can be restored by noting that the 1st permutation is always
% the identity, so with indices 1:N. This same variable idx can
% be used to likewise fix the order of sign-flips (separate func).
[~,idx] = sort(P(:,1));
P = P(idx,:);

% For compatibility, convert each permutaion to a sparse permutation
% matrix. This section may be removed in the future if the
% remaining of the code is modified.
if idxout
    Pset = P;
else
    Pset = cell(nP,1);
    for p = 1:nP
        Pset{p} = palm_idx2perm(P(:,p));
    end
end

% ==============================================================
function [Ptree,flagsucs] = nextperm(Ptree)
% Make the next single shuffle of tree branches, and return
% the shuffled tree. This can be used to compute exhaustively
% all possible permutations.

% Some vars for later
nU   = size(Ptree,1);
sucs = false(nU,1);

% Make sure this isn't the last level (marked as NaN).
if size(Ptree,2) > 1
    
    % For each branch of the current node
    for u = 1:nU
        
        % If this is within-block at this level (marked as NaN),
        % go deeper without trying to shuffle things.
        [Ptree{u,3},sucs(u)] = nextperm(Ptree{u,3});
        if sucs(u)
            if u > 1
                Ptree(1:u-1,:) = resetperms(Ptree(1:u-1,:));
            end
            break;
        elseif ~ isnan(Ptree{u,1})
            Ptree{u,1}(:,3) = (1:size(Ptree{u,1},1))';
            [tmp,sucs(u)] = palm_nextperm(Ptree{u,1});
            if sucs(u)
                Ptree{u,1} = tmp;
                Ptree{u,3} = resetperms(Ptree{u,3});
                Ptree{u,3} = Ptree{u,3}(Ptree{u,1}(:,3),:);
                if u > 1
                    Ptree(1:u-1,:) = resetperms(Ptree(1:u-1,:));
                end
                break;
            end
        end
    end
end

% Pass along to the upper level the information that all
% the branches at this node finished (or not).
flagsucs = any(sucs);

% ==============================================================
function Ptree = resetperms(Ptree)
% Recursively reset all permutations of a permutation tree
% back to the original state

if size(Ptree,2) > 1
    for u = 1:size(Ptree,1)
        if isnan(Ptree{u,1})
            Ptree{u,3} = resetperms(Ptree{u,3});
        else
            Ptree{u,1}(:,3) = Ptree{u,1}(:,2);
            [Ptree{u,1},idx] = sortrows(Ptree{u,1});
            Ptree{u,3} = Ptree{u,3}(idx,:);
            Ptree{u,3} = resetperms(Ptree{u,3});
        end
    end
end

% ==============================================================
function Ptree = randomperm(Ptree)
% Make a random shuffle of all branches in the tree.

% For each branch of the current node
nU = size(Ptree,1);
for u = 1:nU
    
    % Make sure this isn't within-block at 1st level (marked as NaN)
    if ~ isnan(Ptree{u,1}(1))
        tmp = Ptree{u,1}(:,1);
        Ptree{u,1} = Ptree{u,1}(randperm(size(Ptree{u,1},1)),:);
        % Only shuffle if at least one of the branches actually changes
        % its position (otherwise, repeated branches would be needlessly
        % shuffled, wasting permutations).
        if any(tmp ~= Ptree{u,1}(:,1))
            Ptree{u,3} = Ptree{u,3}(Ptree{u,1}(:,3),:);
        end
    end

    % Make sure the next isn't the last level.
    if size(Ptree{u,3},2) > 1
        Ptree{u,3} = randomperm(Ptree{u,3});
    end
end

% ==============================================================
function P = pickperm(Ptree,P)
% Take a tree in a given state and return the permutation. This
% won't permute, only return the indices for the already permuted
% tree. This function is recursive and for the 1st iteration,
% P = [], i.e., a 0x0 array.

nU = size(Ptree,1);
if size(Ptree,2) == 3
    for u = 1:nU
        P = pickperm(Ptree{u,3},P);
    end
elseif size(Ptree,2) == 1
    for u = 1:nU
        P(numel(P)+1:numel(P)+numel(Ptree{u,1})) = Ptree{u,1};
    end
end

% ========================================================
function Pset = palm_fliptree(Ptree,nP,cmc,idxout,maxP)
% Return a set of permutations from a permutation tree.
% 
% Usage:
% Sset = palm_fliptree(Ptree,nS,cmc,idxout,maxS)
% 
% Inputs:
% - Ptree  : Tree with the dependence structure between
%            observations, as generated by 'palm_tree'.
% - nS     : Number of permutations. Use 0 for exhaustive.
% - cmc    : A boolean indicating whether conditional
%            Monte Carlo should be used or not. If not used,
%            there is a possibility of having repeated
%            permutations. The more possible permutations,
%            the less likely to find repetitions.
% - idxout : (Optional) is supplied, Pset is an array of indices
%            rather than a cell array with sparse matrices.
% - maxS   : (Optional) Maximum number of possible sign flips.
%            If not supplied, it's calculated internally. If
%            supplied, it's not calculated internally and some
%            warnings that could be printed are omitted.
%            Also, this automatically allows nS>maxS (via CMC).
%
% Outputs:
% - Sset   : A cell array of size nP by 1 containing sparse
%            sign-flipping matrices.
% 
% Reference:
% * Winkler AM, Webster MA, Vidaurre D, Nichols TE, Smith SM.
%   Multi-level block permutation. Neuroimage. 2015;123:253-68.
%
% _____________________________________
% Anderson M. Winkler
% FMRIB / University of Oxford
% Nov/2013
% http://brainder.org
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Note that the varnames follow the pattern of the similar
% function palm_permtree.m, for easier readability.

% Get the number of possible sign-flips.
if nargin < 5
    maxP = palm_maxshuf(Ptree,'flips');
    if nP > maxP
        nP = maxP; % the cap is only imposed if maxP isn't supplied
    end
end
if nargin < 4
    idxout = false;
end

% Sign-flip #1 is no flip, regardless.
P = cell2mat(pickflip(Ptree,{},ones(size(Ptree,1)))');
P = horzcat(P,zeros(length(P),nP-1));

% All other sign flips up to nP
if nP == 0 || nP == maxP
    
    % This will compute exhaustively all possible sign flips,
    % one branch at a time. If nP is too large print a warning.
    if nP > 1e5 && nargin <= 3
        warning([...
            'Number of possible sign-flips is %g.\n' ...
            '         Performing all exhaustively.'],maxP);
    end
    for p = 2:maxP
        Ptree  = nextflip(Ptree);
        P(:,p) = cell2mat(pickflip(Ptree,{},ones(size(Ptree,1)))');
    end
    
elseif cmc || nP > maxP

    % Conditional Monte Carlo. Repeated sign flips allowed.
    for p = 2:nP
        Ptree  = randomflip(Ptree);
        P(:,p) = cell2mat(pickflip(Ptree,{},ones(size(Ptree,1)))');
    end
    
else
    
    % Otherwise, repeated sign-flips are not allowed.
    % For this to work, maxP needs to be reasonably larger than
    % nP, otherwise it will take forever to run, so print a
    % warning.
    if nP > maxP/2 && nargin <= 3
        warning([
            'The maximum number of sign flips (%g) is not much larger than\n' ...
            'the number you chose to run (%d). This means it may take a while (from\n' ...
            'a few seconds to several minutes) to find non-repeated sign flips.\n' ...
            'Consider instead running exhaustively all possible' ...
            'flips. It may be faster.'],maxP,nP);
    end
    
    % For each flip, keeps trying to find a new, non-repeated instance
    for p = 2:nP
        whiletest = true;
        while whiletest
            Ptree  = randomflip(Ptree);
            P(:,p) = cell2mat(pickflip(Ptree,{},ones(size(Ptree,1)))');
            whiletest = any(all(bsxfun(@eq,P(:,p),P(:,1:p-1))));
        end
    end
end

% Sort correctly rows using the 1st permutation
[~,idx] = palm_permtree(Ptree,1,false);
P = P(idx,:);

% For compatibility, convert each permutaion to a sparse permutation
% matrix. This section may be removed in the future if the
% remaining of the code is modified.
if idxout
    Pset = P;
else
    Pset = cell(nP,1);
    for p = 1:nP
        Pset{p} = sparse(diag(P(:,p)));
    end
end

% ==============================================================
function [Ptree,incremented] = nextflip(Ptree)
% Make the next sign flip of tree branches, and returns
% the shuffled tree. This can be used to compute exhaustively
% all possible sign flippings.

% Some vars for later
nU = size(Ptree,1);

% For each branch of the current node
for u = 1:nU
    if isempty(Ptree{u,2})
        
        % If the branches at this node cannot be considered for
        % flipping, go to the deeper levels, if they exist.
        if size(Ptree{u,3},2) > 1
            [Ptree{u,3},incremented] = nextflip(Ptree{u,3});
            if incremented
                if u > 1
                    Ptree(1:u-1,:) = resetflips(Ptree(1:u-1,:));
                end
                break;
            end
        end
        
    else
        % If the branches at this node are to be considered
        % for sign-flippings (already being done or not)
        
        if sum(Ptree{u,2}) < numel(Ptree{u,2})
            % If the current branch can be flipped, but haven't
            % reached the last possibility yet, flip and break
            % the loop.
            Ptree{u,2} = palm_incrbin(Ptree{u,2});
            incremented = true;
            if u > 1
                Ptree(1:u-1,:) = resetflips(Ptree(1:u-1,:));
            end
            break;
        else
            % If the current branch could be flipped, but
            % it's the last possibility, reset it and 
            % don't break the loop.
            incremented = false;
        end
    end
end

% ==============================================================
function Ptree = resetflips(Ptree)
% Recursively reset all flips of a permutation tree
% back to the original state

for u = 1:size(Ptree,1)
    if isempty(Ptree{u,2}) && size(Ptree{u,3},2) > 1
        Ptree{u,3} = resetflips(Ptree{u,3});
    else
        Ptree{u,2} = false(size(Ptree{u,2}));
    end
end

% ==============================================================
function Ptree = randomflip(Ptree)
% Make the a random sign-flip of all branches in the tree.

% For each branch of the current node
nU = size(Ptree,1);
for u = 1:nU
    if isempty(Ptree{u,2}) == 1 && size(Ptree{u,3},2) > 1
        % Go down more levels
        Ptree{u,3} = randomflip(Ptree{u,3});
    else
        % Or make a random flip if no deeper to go
        Ptree{u,2} = rand(size(Ptree{u,2})) > .5;
    end
end

% ==============================================================
function P = pickflip(Ptree,P,sgn)
% Take a tree in a given state and return the sign flip. This
% won't flip, only return the indices for the already flipped
% tree. This function is recursive and for the 1st iteration,
% P = {}, i.e., a 0x0 cell.

nU = size(Ptree,1);
if size(Ptree,2) == 3
    for u = 1:nU
        if isempty(Ptree{u,2})
            bidx = sgn(u)*ones(size(Ptree{u,3},1),1);
        else
            bidx = double(~Ptree{u,2});
            bidx(Ptree{u,2}) = -1;
        end
        P = pickflip(Ptree{u,3},P,bidx);
    end
elseif size(Ptree,2) == 1
    for u = 1:nU
        if numel(sgn) == 1
            v = 1;
        else
            v = u;
        end
        P{numel(P)+1} = sgn(v)*ones(size(Ptree{u}));
    end
end

% =============================================================================
function Pnew = palm_swapfmt(Pset)
% Convert a set of permutation matrices to an array
% of permutation indices and vice versa.
%
%         Cell array <===> Shuffling indices
%  Shuffling indices <===> Cell array
% 
% Pnew = palm_swapfmt(Pset)
% 
% Pset : Set of permutations, sign-flips or both.
%        This can be supplied either as a cell array
%        of (sparse) permutation matrices, or an
%        array of permutation indices.
% Pnew : The converted set of permutations.
% 
% _____________________________________
% Anderson M. Winkler
% FMRIB / University of Oxford
% Dec/2013
% http://brainder.org
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if iscell(Pset)
    Pnew = zeros(size(Pset{1},1),numel(Pset));
    I = (1:size(Pset{1},1))';
    for p = 1:numel(Pset)
        Pnew(:,p) = Pset{p}*I;
    end
    if size(unique(abs(Pnew)','rows'),1) == 1
        Pnew = sign(Pnew);
    end
else
    P = speye(size(Pset,1));
    Pnew = cell(size(Pset,2),1);
    for p = 1:size(Pset,2)
        sgn = sign(Pset(:,p));
        idx = abs(Pset(:,p));
        if all(true(size(idx)) == idx)
            Pnew{p} = sparse(diag(sgn));
        else
            Pnew{p} = sparse(diag(sgn))*P(idx,:);
        end
    end
end

% ==========================================================
function varargout = palm_metrics(varargin)
% Compute some permutation metrics:
% - For permutation trees, return the entropies.
% - For sets of permutations, return the average Hamming distance.
% 
% Usage:
% [lW,lW0,C] = palm_metrics(Ptree,X,stype)
% [Hamm,HammX,Eucl,EuclX,Spear] = palm_metrics(Pset,X)
% 
% Inputs:
% - Ptree : Permutation tree.
% - X     : Design matrix (only the EVs of interest for the Freedman-Lane
%           and most methods, or the full matrix for ter Braak).
%           Note that the metrics are only meaningful if X is the same
%           used when Ptree was created originally.
% - stype : Shuffling type. It can be 'perms', 'flips' or 'both'.
% - Pset  : Set of shufflings (permutations or sign-flips).
% 
% Outputs
% - lW    : Log of the max number of permutations with the restrictions
%           imposed by the tree and the original design used to create the
%           tree.
% - lW0   : Log of the max number of permutations without the restrictions
%           imposed by the tree, but with the restrictions imposed by the
%           input design X.
% - C     : Huberman & Hogg complexity (C) of a given tree.
%           For this to give exactly the same result as in the original
%           paper, such that it measures the relationships in the tree
%           itself, rather than the actual values found in X, the input
%           Ptree must have been constructed with X = ones(N,1) (or any
%           other constant). However, C doesn't depend on the X that is
%           input (i.e., it's not an argument needed to compute C, but
%           it's implicitly taken into account through the tree).
% - Hamm  : Average Hamming distance across the given permutation set,
%           i.e., it's the average change that a permutation cause on
%           the original indices.
% - HammX : Same as Hamm, but consider the possibility of repeated
%           elements in X. If X isn't supplied, or if X has no ties,
%           or if X is the same used originally to create the permutation
%           set, Hamm and HammX are the same.
% - Eucl  : Same as Hamm, but using the Euclidean distance.
% - EuclX : Same as HammX, but using the Euclidean distance.
% - Spear : Same as Hamm, but using the Spearman correlation. X is always
%           taken into account.
%
% _____________________________________
% Anderson M. Winkler
% FMRIB / University of Oxford
% Feb/2014 (updated Oct/2014)
% http://brainder.org
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Take args and decide what to do
X = [];
if iscell(varargin{1})
    dowhat = 'entropy';
    Ptree  = varargin{1};
    N      = numel(palm_permtree(Ptree,1,false,true));
else
    dowhat = 'distances';
    Pset   = varargin{1};
    N      = size(Pset,1);
end
if nargin == 1
    X     = (1:N)';
    stype = 'perms';
elseif nargin == 2
    X     = varargin{2};
    stype = 'perms';
elseif nargin == 3
    X     = varargin{2};
    stype = varargin{3};
end
if isempty(X)
    X = (1:N)';
end

switch dowhat
    case 'entropy'
        
        % Normalised entropy or anisotropy. This is computed
        % if the first input is a cell array (Ptree).
        
        % Number of permutations (log) given the data structure.
        % It is assumed that Ptree was constructed using the
        % same X as input.
        lW = palm_maxshuf(Ptree,stype,true);
        varargout{1} = lW;
        
        % Number of permutations (log) if there were no data structure:
        if nargout > 1
            lfac = palm_factorial(N);
            [~,~,S] = unique(X,'rows');
            U   = unique(S);
            nU  = numel(U);
            if strcmpi(stype,'perms') || strcmpi(stype,'both')
                cnt = zeros(nU,1);
                for u = 1:nU
                    cnt(u) = sum(S == U(u));
                end
                plW0 = lfac(N+1) - sum(lfac(cnt+1));
            else
                plW0 = 0;
            end
            if strcmpi(stype,'flips') || strcmpi(stype,'both')
                cnt = zeros(nU,1);
                for u = 1:nU
                    cnt(u) = sum(S == U(u));
                end
                slW0 = nU*log(2);
            else
                slW0 = 0;
            end
            lW0 = plW0 + slW0;
            varargout{2} = lW0;
        end
        
        % If the user wants, output also the Huberman & Hogg complexity,
        % which is computed recursively below
        if nargout > 2
            varargout{3} = hhcomplexity(Ptree,1) - 1;
        end
        
    case 'distances'
        
        % Average change per permutation, i.e., average
        % Hamming distance.
        varargout{1} = mean(sum(bsxfun(@ne,Pset(:,1),Pset),1),2);
        
        % Average Euclidean distance per permutation.
        varargout{3} = mean(sum(bsxfun(@minus,Pset(:,1),Pset).^2,1).^.5,2);
        
        % For the Hamming and Euclidean, now take ties in X into account.
        % Also, compute the Spearman for each case
        if strcmpi(stype,'perms')
            XP = X(Pset);
            varargout{5} = mean(1-6*sum(bsxfun(@minus,Pset(:,1),Pset).^2,1)/N/(N^2-1),2);
        elseif strcmpi(stype,'flips')
            XP = bsxfun(@times,X,Pset);
            [~,iXP] = sort(XP);
            varargout{5} = mean(1-6*sum(bsxfun(@minus,iXP(:,1),iXP).^2,1)/N/(N^2-1),2);
        elseif strcmpi(stype,'both')
            XP = X(abs(Pset));
            XP = sign(Pset).*XP;
            [~,iXP] = sort(XP);
            varargout{5} = mean(1-6*sum(bsxfun(@minus,iXP(:,1),iXP).^2,1)/N/(N^2-1),2);
        end
        varargout{2} = mean(sum(bsxfun(@ne,XP(:,1),XP),1),2);
        varargout{4} = mean(sum(bsxfun(@minus,XP(:,1),XP).^2,1).^.5,2);
end

% ==============================================================
function D = hhcomplexity(Ptree,D)
% Computes recursively the Huberman & Hogg complexity.
% For the 1st iteration, D = 1.

for u = 1:size(Ptree,1)
    if isnan(Ptree{u,1}(1))
        k = size(Ptree{u,3},1);
    else
        k = numel(unique(Ptree{u,1}(:,1)));
    end
    D = D * (2^k - 1);
    if size(Ptree{u,3},2) > 1
        D = hhcomplexity(Ptree{u,3},D);
    end
end

% =================================
function VG = palm_ptree2vg(Ptree)
% Define the variance groups based on a block tree.
% 
% Usage:
% VG = palm_ptree2vg(Ptree)
% 
% Ptree : Tree with the dependence structure between
%         observations, as generated by 'palm_tree'.
% VG    : Vector with the indexed variance groups.
% 
% Reference:
% * Winkler AM, Webster MA, Vidaurre D, Nichols TE, Smith SM.
%   Multi-level block permutation. Neuroimage. 2015;123:253-68.
% 
% _____________________________________
% Anderson M. Winkler
% FMRIB / University of Oxford
% Nov/2013
% http://brainder.org
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

% Generate the variance groups, then reindex to integers
% for easier readability.
n = 1;
[VG,~] = pickvg(Ptree,isnan(Ptree{1,1}),n);
[~,~,VG] = unique(VG);

% Fix the sorting of rows using the 1st permutation
[~,idx] = palm_permtree(Ptree,1,false);
VG = VG(idx,:);

% ==============================================
function [VG,n] = pickvg(Ptree,withinblock,n)
% This is the one that actually does the job, recursively
% along the tree branches.

% Vars for later
nU = size(Ptree,1);
VG = [];

if size(Ptree,2) > 1
    % If this is not a terminal branch
    
    if withinblock   
        % If these branches cannot be swapped (within-block only),
        % define vargroups for each of them, separately, going
        % down more levels.
        for u = 1:nU
            [VGu,n] = pickvg(Ptree{u,3},isnan(Ptree{u,1}),n);
            VG      = vertcat(VG,VGu); %#ok it's just a small vector
        end
        
    else
        % If these branches can be swapped (whole-block), then it
        % suffices to define the vargroups for the first one only,
        % then replicate for the others.
        [VGu,n] = pickvg(Ptree{1,3},isnan(Ptree{1,1}),n);
        VG      = repmat(VGu,[nU 1]);
    end
    
else
    % If this is a terminal branch
    
    if withinblock   
        % If the observations cannot be shuffled, each has to belong
        % to its own variance group, so one random number for each
        sz = size(Ptree,1) - 1;
        VG = (n:n+sz)';
        n  = n + sz + 1;
    else
        % If the observations can be shuffled, then all belong to a
        % single vargroup.
        VG = n*ones(size(Ptree,1),1);
        n  = n + 1;
    end
end