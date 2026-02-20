function [bbox,dims,volume,info] = findLargestBox3D(mask,varargin)
% Find the largest empty axis-aligned box in a 3D boolean mask.
%
% Finds the maximum-volume axis-aligned rectangular cuboid within a 3D
% boolean mask using exact slab-collapse along the smallest dimension. The
% mask uses TRUE/non-zero for usable voxels and FALSE for unusable voxels.
% For each slab range, a 2D footprint is analyzed using findLargestBox2D.
%
%%% Syntax %%%
%
%   bbox = findLargestBox3D(mask)
%   bbox = findLargestBox3D(vxR,vxC,vxP)
%   bbox = findLargestBox3D(...,<name-value options>)
%   [bbox,dims,volume,info] = findLargestBox3D(...)
%
%% Algorithm %%
%
% Exact slab-collapse method:
% 1. Choose the smallest dimension for slab iteration (minimize N^2 cost)
% 2. For each starting slab k1:
%    a. For each ending slab k2 >= k1:
%       - Compute 2D footprint via logical AND of slabs k1:k2
%       - Call findLargestBox2D to find max area in footprint
%       - Calculate volume = area * thickness
%       - Track global maximum
%       - Apply depth bounds and empty-slab early exit
% 3. Map final bounding box back to original coordinate system
%
% Time complexity:  O(M*N^2) where N = min dimension, M = product of other dims
% Space complexity: O(M) for the 2D slab footprint
%
% For index inputs, no explicit mask matrices are created - all processing
% is done using coordinate intersection, providing massive memory savings.
%
%% Examples %%
%
%   >> mask = false(9,9,9);
%   >> mask(2:3, 2:5, 2:4) = true; % 2x4x3
%   >> mask(3:5, 3:7, 3:6) = true; % 3x5x4
%   >> [bbox, dims, volume] = findLargestBox3D(mask)
%   bbox = [3,5, 3,7, 3,6]
%   dims = [3,5,4]
%   volume = 60
%
%   >> [vxR,vxC,vxP] = ind2sub(size(mask), find(mask));
%   >> [bbox, dims, volume] = findLargestBox3D(vxR,vxC,vxP)
%   bbox = [3,5, 3,7, 3,6]
%   dims = [3,5,4]
%   volume = 60
%
%   >> [~,~,~,info] = findLargestBox3D(mask);
%   >> info.box.height = 3
%   >> info.box.width  = 5
%   >> info.box.depth  = 4
%   >> info.box.volume = 60
%
%% Options %%
%
% The options may be supplied either
% 1) in a scalar structure, or
% 2) as a comma-separated list of name-value pairs.
%
% Field names and string values are case-insensitive. The following field
% names and values are permitted as options (**=default value):
%
% Field     | Permitted      |
% Name:     | Values:        | Description (example):
% ==========|================|=============================================
% display   | 'silent'**     | No feedback displayed.
%           | 'verbose'      | Print progress in the command window.
%           | 'waitbar'      | Progress bar with estimated time remaining.
% ----------|----------------|---------------------------------------------
% maxN      | 1<=maxN<=Inf** | The maximum number of cuboids to return.
% ----------|----------------|---------------------------------------------
% minVolume | **1<=minV<=Inf | The minimum cuboid volume (# of voxels).
% ----------|----------------|---------------------------------------------
% maxVolume | 1<=maxV<=Inf** | The maximum cuboid volume (# of voxels).
% ----------|----------------|---------------------------------------------
% minHeight | **1<=minH<Inf  | The minimum cuboid height (# of rows).
% ----------|----------------|---------------------------------------------
% maxHeight | 1<=maxH<=Inf** | The maximum cuboid height (# of rows).
% ----------|----------------|---------------------------------------------
% minWidth  | **1<=minW<Inf  | The minimum cuboid width (# of columns).
% ----------|----------------|---------------------------------------------
% maxWidth  | 1<=maxW<=Inf** | The maximum cuboid width (# of columns).
% ----------|----------------|---------------------------------------------
% minDepth  | **1<=minD<Inf  | The minimum cuboid depth (# of pages).
% ----------|----------------|---------------------------------------------
% maxDepth  | 1<=maxD<=Inf** | The maximum cuboid depth (# of pages).
% ----------|----------------|---------------------------------------------
%
%% Input Arguments %%
%
%   mask = 3D logical or numeric array where:
%          TRUE / non-zero == empty/usable voxel
%          FALSE / zero    == blocked/unusable voxel
%   vxR  = NumericVector of M usable voxel row indices.
%   vxC  = NumericVector of M usable voxel column indices.
%   vxP  = NumericVector of M usable voxel page indices.
%   <name-value> optional arguments as per the "Options" table above.
%
%% Output Arguments %%
%
%   bbox = Nx6 matrix with columns [r1,r2, c1,c2, p1,p2], the corner
%          indices of the largest cuboid(s) consisting of TRUE only, where:
%          r1,r2 = first and last row indices,
%          c1,c2 = first and last column indices,
%          p1,p2 = first and last page indices.
%          If no cuboid is found then bbox=[].
%   dims = Nx3 matrix with columns [h,w,d], the cuboid size(s), where:
%          h,w,d = the height, width, & depth of the cuboid(s), in voxels.
%          If no cuboid is found then dims=[].
%   volume = Numeric scalar, the volume of the largest cuboid, in voxels.
%   info = Structure with geometry information (if a cuboid is found):
%          .box.indices   : same as output <bbox>
%          .box.volume    : same as output <volume>
%          .box.corners   : [r1-1/2,r2+1/2, c1-1/2,c2+1/2, p1-1/2,p2+1/2]
%          .box.diagonal  : distance between farthest corners
%          .box.center    : where the diagonals meet
%          .box.height    : number of voxel rows
%          .box.width     : number of voxel columns
%          .box.depth     : number of voxel pages
%          .box.area      : total surface area
%          and some useful information about the function/algorithm:
%          .options       : the used option set
%          .inputFormat   : 'array' or 'indices'
%          .slabDimension : dimension used for slab iteration (1, 2, or 3)
%          .slabsProcessed: total slab pairs processed
%          .numBoxes      : number of cuboids found
%          .timeTotal     : total execution time in seconds
%          .time2DFun     : 2D function execution time in seconds
%
%% Dependencies %%
%
% * findLargestBox2D.m
% * MATLAB R2009b or later.
%
% See also FINDLARGESTBOX2D SPARSE FULL FIND IND2SUB ACCUMARRAY PERMUTE
% REGIONPROPS3 IMFILL BWLABELN BWCONNCOMP BWAREAOPEN CONVHULLN ALPHASHAPE
tic0 = tic();
bbox = [];
dims = [];
volume = 0;
time2D = 0;
%
%% Default Options %%
%
stpo = struct(... Default option values
	'display','silent', 'maxN',Inf, 'minVolume',1, 'maxVolume',Inf, ...
	'minHeight',1, 'maxHeight',Inf, 'minWidth',1, 'maxWidth',Inf, ...
	'minDepth',1, 'maxDepth',Inf);
%
%% Input Wrangling %%
%
arg = cellfun(@flb3ss2c,varargin,'UniformOutput',false);
ixc = cellfun('isclass',arg,'char') & cellfun('ndims',arg)<3 & cellfun('size',arg,1)==1;
if any(ixc) % options as <name-value> pairs
	ix1 = find(ixc,1,'first');
	opts = cell2struct(arg(ix1+1:2:end),arg(ix1:2:end),2);
	stpo = flb3Options(stpo,opts);
	varargin(ix1:end) = [];
elseif numel(arg) && isstruct(arg{end}) % options in a struct
	opts = structfun(@flb3ss2c,arg{end},'UniformOutput',false);
	stpo = flb3Options(stpo,opts);
	varargin(end) = [];
end
%
info = struct('options',stpo, 'slabsProcessed',0, 'numBoxes',0);
%
assert(stpo.minVolume<=stpo.maxVolume,...
	'SC:findLargestBox3D:options:InvertedVolumeValues',...
	'The minVolume (%g) must not exceed maxVolume (%g).', stpo.minVolume, stpo.maxVolume)
assert(stpo.minHeight<=stpo.maxHeight,...
	'SC:findLargestBox3D:options:InvertedHeightValues',...
	'The minHeight (%g) must not exceed maxHeight (%g).', stpo.minHeight, stpo.maxHeight)
assert(stpo.minWidth<=stpo.maxWidth,...
	'SC:findLargestBox3D:options:InvertedWidthValues',...
	'The minWidth (%g) must not exceed maxWidth (%g).', stpo.minWidth, stpo.maxWidth)
assert(stpo.minDepth<=stpo.maxDepth,...
	'SC:findLargestBox3D:options:InvertedDepthValues',...
	'The minDepth (%g) must not exceed maxDepth (%g).', stpo.minDepth, stpo.maxDepth)
assert(stpo.minHeight*stpo.minWidth*stpo.minDepth <= stpo.maxVolume,...
	'SC:findLargestBox3D:options:MinDimsExceedMaxVolume',...
	'The minHeight*minWidth*minDepth (%g) exceeds maxVolume (%g).', stpo.minHeight*stpo.minWidth*stpo.minDepth, stpo.maxVolume)
assert(stpo.maxHeight*stpo.maxWidth*stpo.maxDepth >= stpo.minVolume,...
	'SC:findLargestBox3D:options:MaxDimsSubceedMinVolume',...
	'The minVolume (%g) exceeds maxHeight*maxWidth*maxDepth (%g).', stpo.minVolume, stpo.maxHeight*stpo.maxWidth*stpo.maxDepth)
%
switch numel(varargin)
	case 0
		info.inputFormat = 'array';
		isx = false;
		assert(islogical(mask)||isnumeric(mask),...
			'SC:findLargestBox3D:mask:invalidType',...
			'1st input <mask> must be a logical or numeric array.')
		assert(ndims(mask)<4,...
			'SC:findLargestBox3D:mask:invalidSize',...
			'1st input <mask> must be a 3D array.')
		iszV = size(mask);
		iszV(end+1:3) = 1;
	case 2
		info.inputFormat = 'indices';
		isx = true;
		vxR = flb3CheckIndex('1st','vxR',mask);
		vxC = flb3CheckIndex('2nd','vxC',varargin{1});
		vxP = flb3CheckIndex('3rd','vxP',varargin{2});
		assert(isequal(numel(vxR),numel(vxC),numel(vxP)),...
			'SC:findLargestBox3D:indices:differentLengths',...
			'Inputs <vxR>, <vxC>, & <vxP> must have the same length')
		iszV = [max(vxR), max(vxC), max(vxP)];
	otherwise
		error('SC:findLargestBox3D:unsupportedInputs',...
			'Either one 3D array (mask) or three index vectors are supported')
end
%
nTotal = prod(iszV);
%
if numel(iszV)~=3 || ~nTotal
	info.timeTotal = toc(tic0);
	return
end
%
assert(nTotal <= 9007199254740992,... % flintmax('double') = 2^53
	'SC:findLargestBox3D:volumeTooLarge',...
	'Mask volume (%dx%dx%d) exceeds 2^53, use smaller dimensions.',...
	iszV(1), iszV(2), iszV(3));
%
%% Identify Smallest Dimension and Setup Iteration %%
%
[~,idm] = min(iszV);
info.slabDimension = idm;
%
% Determine permutation to move smallest dimension to position 3
% idmPerm maps original positions to permuted positions
idmPerm = [1:idm-1, idm+1:3, idm];
% invPerm maps permuted positions back to original positions
invPerm = idmPerm;
invPerm(idmPerm) = 1:3;
%
% Size in permuted space (smallest dimension is now in position 3)
jszV = iszV(idmPerm);
jszR = jszV(1);
jszC = jszV(2);
jszP = jszV(3);
%
% For index inputs, organize voxels by slab
if isx
	% Determine which original coordinate corresponds to slab dimension
	vxAll = {vxR, vxC, vxP};
	vxDim1 = vxAll{idmPerm(1)}; % First dimension in 2D slice
	vxDim2 = vxAll{idmPerm(2)}; % Second dimension in 2D slice
	vxSlab = vxAll{idmPerm(3)}; % The dimension to iterate through
	%
	% Organize indices by slab for fast lookup
	tmp = 1:numel(vxSlab);
	slabIdx = accumarray(vxSlab, tmp(:), [jszP,1], @(x){x}, {[]});
end
%
%% Display Setup %%
%
isvb = strcmpi(stpo.display,'verbose');
iswb = strcmpi(stpo.display,'waitbar');
if isvb || iswb
	mfnm = mfilename();
	tItr = jszP * (jszP + 1) / 2;
	if isvb
		fprintf('%s:  Starting ...\n',mfnm)
	end
	if iswb
		wBar = waitbar(0,'Starting ...','Name',mfnm);
	end
end
%
%% Histogram-Based Box Finding via Slab Collapse %%
%
slabCnt = 0;
bestVol = 0;
bestBox = nan(0,6); % [r1,r2,c1,c2,s1,s2] in permuted space
%
tempMin = [stpo.minHeight, stpo.minWidth, stpo.minDepth];
tempMax = [stpo.maxHeight, stpo.maxWidth, stpo.maxDepth];
slabMin = tempMin(idmPerm(3));
slabMax = tempMax(idmPerm(3));
%
opts2D = struct('display','silent', 'maxN',Inf,...
    'minHeight',tempMin(idmPerm(1)), 'maxHeight',tempMax(idmPerm(1)),...
    'minWidth', tempMin(idmPerm(2)), 'maxWidth', tempMax(idmPerm(2)));
if stpo.maxN<2
	opts2D.maxN = 1;
end
%
for ii = 1:jszP
	%
	% Initialize slab accumulator
	if isx % indices
		% do nothing
	else % logical or numeric
		slab = true(jszR,jszC);
	end
	%
	for jj = ii:jszP
		slabCnt = slabCnt + 1;
		thickness = jj - ii + 1;
		%
		if isvb || iswb
			nItr = (ii-1) * (2*jszP - ii + 2) / 2 + (jj - ii + 1);
			tETR = flb3TimeText(ceil(toc(tic0)*(tItr-nItr)./nItr));
			tTmp = sprintf('%d of %d    %s',nItr+1,tItr,tETR);
			if isvb
				fprintf('%s:  %s\n',mfnm,tTmp)
			end
			if iswb
				waitbar(nItr./tItr, wBar, tTmp)
			end
		end
		%
		if isx % indices
			%
			% Compute intersection of coordinates across slabs ii:jj
			if isempty(slabIdx{ii})
				break % First slab is empty
			end
			%
			% Start with first slab
			idx = slabIdx{ii};
			slabCoords = unique([vxDim1(idx), vxDim2(idx)], 'rows');
			%
			% Intersect with each subsequent slab
			for kk = ii+1:jj
				if isempty(slabCoords)
					break % Intersection already empty
				end
				if isempty(slabIdx{kk})
					slabCoords = []; % Empty slab means empty intersection
					break;
				end
				%
				idx = slabIdx{kk};
				nextCoords = unique([vxDim1(idx), vxDim2(idx)], 'rows');
				slabCoords = intersect(slabCoords, nextCoords, 'rows');
			end
			%
			if isempty(slabCoords)
				break % No intersection across all slabs
			end
			%
		else % logical or numeric
			%
			% Extract jj-th slab from original mask and permute
			switch idm
				case 1 % Iterating through rows
					slice2D = permute(mask(jj,:,:),[2,3,1]);
				case 2 % Iterating through columns
					slice2D = permute(mask(:,jj,:),[1,3,2]);
				case 3 % Iterating through pages
					slice2D = mask(:,:,jj);
			end
			%
			% Accumulate via logical AND
			slab = slab & logical(slice2D);
			%
			if ~any(slab(:))
				break % Empty footprint, no point continuing
			end
			%
		end
		%
		% Apply maxDepth constraint: stop extending slabs beyond max depth
		if thickness > slabMax
			break
		end
		%
		% Apply minDepth constraint: skip 2D call if not thick enough yet
		if thickness < slabMin
			continue
		end
		%
		% Compute 2D area bounds from volume constraints and slab thickness
		minArea2 = ceil(stpo.minVolume / thickness);
		maxArea2 = floor(stpo.maxVolume / thickness);
		if minArea2 > maxArea2
			continue % Cannot satisfy volume constraints at this thickness
		end
		%
		% Build options for findLargestBox2D call
		opts2D.minArea = minArea2;
		opts2D.maxArea = maxArea2;
		%
		% Pass to 2D function
		tic2 = tic();
		if isx % indices
			[bbox2,~,area2] = findLargestBox2D(slabCoords(:,1),slabCoords(:,2),opts2D);
		else % logical or numeric
			[bbox2,~,area2] = findLargestBox2D(slab,opts2D);
		end
		time2D = time2D + toc(tic2);
		%
		if ~area2
			continue
		end
		%
		% Calculate volume
		tempVol = area2 * thickness;
		%
		bbox2(:,5) = ii;
		bbox2(:,6) = jj;
		%
		if tempVol > bestVol % Update best if larger volume
			bestVol = tempVol;
			bestBox = bbox2;
		elseif tempVol == bestVol && size(bestBox,1) < stpo.maxN
			bestBox = [bestBox;bbox2]; %#ok<AGROW>
			if size(bestBox,1) > stpo.maxN % Trim to maxN
				bestBox = bestBox(1:stpo.maxN,:);
			end
		end
		%
	end
	%
end
%
if isvb
	fprintf('%s:  completed\n',mfnm)
end
if iswb
	delete(wBar)
end
%
%% Outputs %%
%
volume = bestVol;
%
if volume
	bbox = reshape(bestBox,[],2,3);
	bbox = bbox(:,:,invPerm);
	bbox = reshape(bbox,[],6);
	bR1 = bbox(:,1);
	bR2 = bbox(:,2);
	bC1 = bbox(:,3);
	bC2 = bbox(:,4);
	bP1 = bbox(:,5);
	bP2 = bbox(:,6);
	bHt = bR2-bR1+1;
	bWd = bC2-bC1+1;
	bDp = bP2-bP1+1;
	dims = [bHt,bWd,bDp];
	if nargout>3
		info.numBoxes = numel(bR1);
		info.box = arrayfun(@flb3Geometry, bR1,bR2,bC1,bC2,bP1,bP2,bHt,bWd,bDp);
	end
end
%
info.slabsProcessed = slabCnt;
info.time2DFun = time2D;
info.timeTotal = toc(tic0);
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%findLargestBox3D
function out = flb3CheckIndex(ord,anm,inp)
assert(isnumeric(inp)&&isreal(inp)&&(isvector(inp)||isequal(inp,[])),...
	sprintf('SC:findLargestBox3D:%s:notRealNumericVector',anm),...
	'%s input <%s> must be a real numeric vector', ord, anm)
assert(isinteger(inp) || all(fix(inp)==inp),...
	sprintf('SC:findLargestBox3D:%s:fractionalValues',anm),...
	'%s input <%s> must not contain fractional values', ord, anm)
assert(all(inp>0),...
	sprintf('SC:findLargestBox3D:%s:negativeValues',anm),...
	'%s input <%s> must not contain zero/negative values', ord, anm)
out = double(inp(:));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%flb3CheckIndex
function ss = flb3Geometry(bR1,bR2,bC1,bC2,bP1,bP2,bHt,bWd,bDp)
% Return basic geometry information about the provided cuboid.
ss = struct('indices',[bR1,bR2,bC1,bC2,bP1,bP2]); % 1x6
ss.corners = [bR1-0.5,bR2+0.5, bC1-0.5,bC2+0.5, bP1-0.5,bP2+0.5]; % 1x6
ss.center  = ss.corners*[1,0,0; 1,0,0; 0,1,0; 0,1,0; 0,0,1; 0,0,1]./2; % 1x3
ss.height = bHt;
ss.width  = bWd;
ss.depth  = bDp;
ss.volume = bHt * bWd * bDp;
ss.area   = 2*(bHt*bWd + bHt*bDp + bWd*bDp);
ss.diagonal = sqrt(bHt.^2 + bWd.^2 + bDp.^2);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%flb3Geometry
function str = flb3TimeText(toa)
if ~isfinite(toa)
	str = 'TBD...';
	return
end
dpf = 1e2;
spl = [0,0,0,ceil(toa*dpf)./dpf]; % s.f
spl(3:4) = flb3FixRem(spl(4),60); % m:s
spl(2:3) = flb3FixRem(spl(3),60); % h:m
spl(1:2) = flb3FixRem(spl(2),24); % d:h
idx = spl~=0 | [false(1,3),~any(spl)];
spl(2,:) = 'dhms';
str = sprintf('%g%c',spl(:,idx));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%flb3TimeText
function V = flb3FixRem(N,D)
V = [fix(N./D),rem(N,D)];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%flb3FixRem
function stpo = flb3Options(stpo,opts)
% Options check: only supported fieldnames with suitable option values.
%
dfc = fieldnames(stpo);
ofc = fieldnames(opts);
%
for k = 1:numel(ofc)
	ofn = ofc{k};
	dix = strcmpi(ofn,dfc);
	oix = strcmpi(ofn,ofc);
	if ~any(dix)
		dfs = sort(dfc);
		ont = sprintf(', <%s>',dfs{:});
		error('SC:findLargestBox3D:options:UnknownOptionName',...
			'Unknown option: <%s>.\nOptions are:%s.',ofn,ont(2:end))
	elseif nnz(oix)>1
		dnt = sprintf(', <%s>',ofc{oix});
		error('SC:findLargestBox3D:options:DuplicateOptionNames',...
			'Duplicate option names:%s.',dnt(2:end))
	end
	arg = opts.(ofn);
	dfn = dfc{dix};
	switch dfn
		case {'maxVolume','maxHeight','maxWidth','maxDepth','maxN'}
			flb3Scalar(@le,8804)
		case {'minVolume','minHeight','minWidth','minDepth'}
			flb3Scalar(@lt,60)
		case 'display'
			flb3String('silent','verbose','waitbar')
		otherwise
			error('SC:findLargestBox3D:options:MissingCase','Please report this bug.')
	end
	stpo.(dfn) = arg;
end
%
%% Nested Functions %%
%
	function flb3String(varargin) % text.
		if ~(ischar(arg)&&ndims(arg)<3&&size(arg,1)==1&&any(strcmpi(arg,varargin))) %#ok<ISMAT>
			tmp = sprintf(', "%s"',varargin{:});
			error(sprintf('SC:findLargestBox3D:%s:UnknownValue',dfn),...
				'The <%s> value must be one of:%s.',dfn,tmp(2:end));
		end
		arg = lower(arg);
	end
	function flb3Scalar(fnh,utf)
		assert(isnumeric(arg)&&isscalar(arg),...
			sprintf('SC:findLargestBox3D:%s:NotScalarNumeric',dfn),...
			'The <%s> value must be a scalar numeric.',dfn)
		assert(isreal(arg),...
			sprintf('SC:findLargestBox3D:%s:NotRealNumeric',dfn),...
			'The <%s> value cannot be complex. Input: %g%+gi',dfn,real(arg),imag(arg))
		assert(arg>0 && fnh(arg,Inf),...
			sprintf('SC:findLargestBox3D:%s:OutOfRange',dfn),...
			'The <%s> value must be 1\x2264%s%cInf. Input: %g',dfn,dfn,utf,arg)
		assert(fix(arg)==arg,...
			sprintf('SC:findLargestBox3D:%s:NotWholeNumeric',dfn),...
			'The <%s> value must be a whole number. Input: %g',dfn,arg)
		arg = double(arg);
	end
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%flb3Options
function arr = flb3ss2c(arr)
% If scalar string then extract the character vector, otherwise data is unchanged.
if isa(arr,'string') && isscalar(arr)
	arr = arr{1};
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%flb3ss2c
% Copyright (c) 2026 Stephen Cobeldick
%
% Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%license
