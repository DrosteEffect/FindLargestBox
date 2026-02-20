function [bbox,dims,area,info] = findLargestBox2D(mask,varargin)
% Find the largest axis-aligned rectangle in a 2D boolean mask.
%
% Finds the maximum-area axis-aligned rectangle within a 2D boolean mask
% using a reasonably efficient O(rows*cols) histogram-based algorithm. The
% mask uses TRUE/non-zero for usable pixels and FALSE/zero for unusable pixels.
%
%%% Syntax %%%
%
%   bbox = findLargestBox2D(mask)
%   bbox = findLargestBox2D(pixR,pixC)
%   bbox = findLargestBox2D(...,<name-value options>)
%   [bbox,dims,area,info] = findLargestBox2D(...)
%
%% Algorithm %%
%
% Uses the classic histogram-based "largest rectangle in histogram" method:
% 1. Build cumulative height histogram for each row,
% 2. For each row, find the largest rectangle in that histogram,
% 3. Track the global maximum across all rows.
%
% Time  complexity: O(rows*cols)
% Space complexity: O(cols)
%
% For sparse/index inputs, only one row at a time is created in full,
% providing significant memory savings for very sparse data.
%
%% Examples %%
%
%   >> mask = sparse(10000, 10000);
%   >> mask(1000:1010, 2000:2050) = 1; % 11x51
%   >> [bbox, dims, area] = findLargestBox2D(mask)
%   bbox = [1000,1010, 2000,2050]
%   dims = [11,51]
%   area = 561
%
%   >> mask = false(9,9);
%   >> mask(2:5, 2:3) = true; % 4x2
%   >> mask(5:7, 3:8) = true; % 3x6
%   >> [bbox, dims, area] = findLargestBox2D(mask)
%   bbox = [5,7, 3,8]
%   dims = [3,6]
%   area = 18
%
%   >> [rows, cols] = find(mask);
%   >> [bbox, dims, area] = findLargestBox2D(rows,cols)
%   bbox = [5,7, 3,8]
%   dims = [3,6]
%   area = 18
%
%   >> [~,~,~,info] = findLargestBox2D(mask);
%   >> info.box.height = 3
%   >> info.box.width  = 6
%   >> info.box.area   = 18
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
% maxN      | 1<=maxN<=Inf** | The maximum number of rectangles to return.
% ----------|----------------|---------------------------------------------
% minArea   | **1<=minA<=Inf | The minimum rectangle area (# of pixels).
% ----------|----------------|---------------------------------------------
% maxArea   | 1<=maxA<=Inf** | The maximum rectangle area (# of pixels).
% ----------|----------------|---------------------------------------------
% minHeight | **1<=minH<Inf  | The minimum rectangle height (# of rows).
% ----------|----------------|---------------------------------------------
% maxHeight | 1<=maxH<=Inf** | The maximum rectangle height (# of rows).
% ----------|----------------|---------------------------------------------
% minWidth  | **1<=minW<Inf  | The minimum rectangle width (# of columns).
% ----------|----------------|---------------------------------------------
% maxWidth  | 1<=maxW<=Inf** | The maximum rectangle width (# of columns).
% ----------|----------------|---------------------------------------------
%
%% Input Arguments %%
%
%   mask = 2D logical or numeric or sparse matrix where:
%          TRUE / non-zero == empty/usable pixel
%          FALSE / zero    == blocked/unusable pixel
%   pixR = NumericVector of M usable pixel row indices.
%   pixC = NumericVector of M usable pixel column indices.
%   <name-value> optional arguments as per the "Options" table above.
%
%% Output Arguments %%
%
%   bbox = Nx4 matrix with columns [r1,r2,c1,c2], the corner indices of
%          the largest rectangle(s) consisting of TRUE/~0 only, where:
%          r1,c1 = the first row and column indices,
%          r2,c2 = the last row and column indices,
%          If no rectangle is found then bbox=[].
%   dims = Nx2 matrix with columns [h,w], the rectangle size(s), where:
%          h,w = the height and width of the rectangle(s), in pixels.
%          If no rectangle is found then dims=[].
%   area = Numeric scalar, the area of the rectangle(s), in pixels.
%   info = Structure with geometry information (if a rectangle is found):
%          .box.area      : same as output <area>
%          .box.indices   : same as output <bbox>
%          .box.corners   : [r1-1/2,r2+1/2,c1-1/2,c2+1/2]
%          .box.diagonal  : distance between farthest corners
%          .box.center    : where the diagonals meet
%          .box.height    : number of pixel rows
%          .box.width     : number of pixel columns
%          .box.perimeter : perimeter length
%          and some useful information about the function/algorithm:
%          .options       : the used option set
%          .inputFormat   : 'indices', 'matrix', or 'sparse'
%          .rowsProcessed : number of mask rows processed
%          .numBoxes      : number of rectangles found
%          .timeTotal     : total execution time in seconds
%
%% Dependencies %%
%
% * MATLAB R2009b or later.
%
% See also FINDLARGESTBOX3D SPARSE FULL FIND SUB2IND ACCUMARRAY POLY2MASK
% REGIONPROPS IMFILL BWLABEL BWCONNCOMP BWAREAOPEN BWAREAFILT CONVHULL
tic0 = tic();
bbox = [];
dims = [];
area = 0;
%
%% Default Options %%
%
stpo = struct(... Default option values
	'display','silent', 'maxN',Inf, 'minArea',1, 'maxArea',Inf,...
	'minHeight',1, 'maxHeight',Inf, 'minWidth',1, 'maxWidth',Inf);
%
%% Input Wrangling %%
%
arg = cellfun(@flb2ss2c,varargin,'UniformOutput',false);
ixc = cellfun('isclass',arg,'char') & cellfun('ndims',arg)<3 & cellfun('size',arg,1)==1;
if any(ixc) % options as <name-value> pairs
	ix1 = find(ixc,1,'first');
	opts = cell2struct(arg(ix1+1:2:end),arg(ix1:2:end),2);
	stpo = flb2Options(stpo,opts);
	varargin(ix1:end) = [];
elseif numel(arg) && isstruct(arg{end}) % options in a struct
	opts = structfun(@flb2ss2c,arg{end},'UniformOutput',false);
	stpo = flb2Options(stpo,opts);
	varargin(end) = [];
end
%
info = struct('options',stpo, 'rowsProcessed',0, 'numBoxes',0);
%
assert(stpo.minArea<=stpo.maxArea,...
	'SC:findLargestBox2D:options:InvertedAreaValues',...
	'The minArea (%g) must not exceed maxArea (%g).', stpo.minArea, stpo.maxArea)
assert(stpo.minHeight<=stpo.maxHeight,...
	'SC:findLargestBox2D:options:InvertedHeightValues',...
	'The minHeight (%g) must not exceed maxHeight (%g).', stpo.minHeight, stpo.maxHeight)
assert(stpo.minWidth<=stpo.maxWidth,...
	'SC:findLargestBox2D:options:InvertedWidthValues',...
	'The minWidth (%g) must not exceed maxWidth (%g).', stpo.minWidth, stpo.maxWidth)
assert(stpo.minHeight*stpo.minWidth <= stpo.maxArea,...
	'SC:findLargestBox2D:options:MinDimsExceedMaxArea',...
	'The minHeight*minWidth (%g) exceeds maxArea (%g).', stpo.minHeight*stpo.minWidth, stpo.maxArea)
assert(stpo.maxHeight*stpo.maxWidth >= stpo.minArea,...
	'SC:findLargestBox2D:options:MaxDimsSubceedMinArea',...
	'The minArea (%g) exceeds maxHeight*maxWidth (%g).', stpo.minArea, stpo.maxHeight*stpo.maxWidth)
%
switch numel(varargin)
	case 0
		if issparse(mask)
			info.inputFormat = 'sparse';
			isrc = true;
			assert(isreal(mask),...
				'SC:findLargestBox2D:mask:complexData',...
				'1st input <mask> must be real, not complex!')
			[pixR,pixC] = find(mask);
			minr = min(pixR);
			minc = min(pixC);
			maxr = max(pixR);
			maxc = max(pixC);
		else
			info.inputFormat = 'matrix';
			isrc = false;
			assert(islogical(mask)||isnumeric(mask),...
				'SC:findLargestBox2D:mask:invalidType',...
				'1st input <mask> must be a logical, numeric, or a sparse matrix.')
			assert(ndims(mask)<3,...
				'SC:findLargestBox2D:mask:invalidSize',...
				'1st input <mask> must be a 2D matrix.') %#ok<ISMAT>
			tmpr = any(mask,2);
			tmpc = any(mask,1);
			minr = find(tmpr,1,'first');
			minc = find(tmpc,1,'first');
			maxr = find(tmpr,1,'last');
			maxc = find(tmpc,1,'last');
		end
	case 1
		info.inputFormat = 'indices';
		isrc = true;
		pixR = flb2CheckIndex('1st','pixR',mask);
		pixC = flb2CheckIndex('2nd','pixC',varargin{1});
		assert(isequal(numel(pixR),numel(pixC)),...
			'SC:findLargestBox2D:indices:differentLengths',...
			'1st & 2nd inputs <pixR> & <pixC> must have the same length')
		minr = min(pixR);
		minc = min(pixC);
		maxr = max(pixR);
		maxc = max(pixC);
	otherwise
		error('SC:findLargestBox2D:unsupportedInputs',...
			'Either one matrix (mask) or two index vectors are supported')
end
%
if numel([minr,minc,maxr,maxc])~=4
	info.timeTotal = toc(tic0);
	return
elseif isrc % sparse or indices
	rIdx = accumarray(pixR,pixC,[maxr,1], @(x){x}, {[]});
end
%
assert((maxr*maxc)<=9007199254740992,... flintmax('double') = 2^53
	'SC:findLargestBox2D:areaTooLarge',...
	'Index area (%dx%d) exceeds 2^53, use smaller dimensions.',maxr,maxc);
%
isvb = strcmpi(stpo.display,'verbose');
iswb = strcmpi(stpo.display,'waitbar');
if isvb || iswb
	mfnm = mfilename();
	rItr = 1+maxr-minr;
	cItr = 1+maxc-minc;
	tItr = rItr*cItr;
	if isvb
		fprintf('%s:  Starting ...\n',mfnm);
	end
	if iswb
		wBar = waitbar(0,'Starting ...', 'Name',mfnm);
	end
end
%
%% Histogram-Based Rectangle Finding %%
%
heights  = zeros(1,maxc);
stackPos = zeros(1,maxc+1);
stackHgt = zeros(1,maxc+1);
%
rowCnt = 0;
bestR1 = nan(0,1);
bestC1 = nan(0,1);
bestHt = nan(0,1);
bestWd = nan(0,1);
%
for rr = minr:maxr
	%
	rowCnt = rowCnt + 1;
	if isrc % sparse or indices
		rOne = false(1,maxc);
		rOne(rIdx{rr}) = true;
	else % logical or numeric
		rOne = logical(mask(rr,1:maxc));
	end
	% Update cumulative heights
	heights(rOne)  = heights(rOne) + 1;
	heights(~rOne) = 0;
	% Find largest rectangle in current histogram using stack-based algorithm
	stackSize = 0;
	%
	for cc = minc:maxc
		%
		if isvb || iswb
			nItr = (cc-minc) + (rr-minr) * cItr;
			tETR = flb2TimeText(ceil(toc(tic0)*(tItr-nItr)./nItr));
			tTmp = sprintf('%d of %d    %s',nItr+1,tItr,tETR);
			if isvb
				fprintf('%s:  %s\n',mfnm, tTmp);
			end
			if iswb
				waitbar(nItr./tItr, wBar, tTmp);
			end
		end
		%
		hh = heights(cc);
		start = cc;
		% Pop elements from stack while they're taller than current height
		while stackSize>0 && stackHgt(stackSize)>hh
			popH = stackHgt(stackSize);
			popC = stackPos(stackSize);
			popW = cc - popC;
			stackSize = stackSize - 1;
			% Find maximum achievable area given constraints
			Hmax = min(popH, stpo.maxHeight);
			Wmax = min(popW, stpo.maxWidth);
			effA = 0;
			for eH = stpo.minHeight:Hmax
    			eW = min(Wmax, floor(stpo.maxArea/eH));
    			if eW >= stpo.minWidth && eH*eW > effA
        			effA = eH*eW;
    			end
			end
			% Collect ALL (eH,eW) shape pairs that achieve effA
			if effA >= stpo.minArea
				shapes = zeros(0,2);
				for eH = stpo.minHeight:Hmax
					eW = min(Wmax, floor(stpo.maxArea/eH));
					if eH*eW==effA && eW>=stpo.minWidth
						shapes(end+1,:) = [eH, eW]; %#ok<AGROW>
					end
				end
				if ~isempty(shapes)
					if effA>area
						area = effA;
						bestR1 = nan(0,1); bestC1 = nan(0,1);
						bestHt = nan(0,1); bestWd = nan(0,1);
					end
					if effA==area
						for si = 1:size(shapes,1)
							effH = shapes(si,1);
							effW = shapes(si,2);
							for dR = 0:(popH-effH)
								r1c = rr-popH+1+dR;
								for dC = 0:(popW-effW)
									c1c = popC+dC;
									if numel(bestR1)>=stpo.maxN, break; end
									if ~any(bestR1==r1c & bestC1==c1c & bestHt==effH & bestWd==effW)
										bestR1(end+1,1) = r1c; %#ok<AGROW>
										bestC1(end+1,1) = c1c; %#ok<AGROW>
										bestHt(end+1,1) = effH; %#ok<AGROW>
										bestWd(end+1,1) = effW; %#ok<AGROW>
									end
								end
								if numel(bestR1)>=stpo.maxN, break; end
							end
							if numel(bestR1)>=stpo.maxN, break; end
						end
					end
				end
			end
			start = popC;
		end
		% Push current height onto stack if it is positive and different
		if hh>0 && (stackSize==0 || stackHgt(stackSize)<hh)
			stackSize = stackSize + 1;
			stackPos(stackSize) = start;
			stackHgt(stackSize) = hh;
		end
	end
	% Process remaining elements in stack (end of row)
	cEnd = maxc + 1;
	while stackSize>0
		popH = stackHgt(stackSize);
		popC = stackPos(stackSize);
		popW = cEnd - popC;
		stackSize = stackSize - 1;
		% Find maximum achievable area given constraints
		Hmax = min(popH, stpo.maxHeight);
		Wmax = min(popW, stpo.maxWidth);
		effA = 0;
		for eH = stpo.minHeight:Hmax
			eW = min(Wmax, floor(stpo.maxArea/eH));
			if eW >= stpo.minWidth && eH*eW > effA
				effA = eH*eW;
			end
		end
		% Collect ALL (eH,eW) shape pairs that achieve effA
		if effA >= stpo.minArea
			shapes = zeros(0,2);
			for eH = stpo.minHeight:Hmax
				eW = min(Wmax, floor(stpo.maxArea/eH));
				if eH*eW==effA && eW>=stpo.minWidth
					shapes(end+1,:) = [eH, eW]; %#ok<AGROW>
				end
			end
			if ~isempty(shapes)
				if effA>area
					area = effA;
					bestR1 = nan(0,1); bestC1 = nan(0,1);
					bestHt = nan(0,1); bestWd = nan(0,1);
				end
				if effA==area
					for si = 1:size(shapes,1)
						effH = shapes(si,1);
						effW = shapes(si,2);
						for dR = 0:(popH-effH)
							r1c = rr-popH+1+dR;
							for dC = 0:(popW-effW)
								c1c = popC+dC;
								if numel(bestR1)>=stpo.maxN, break; end
								if ~any(bestR1==r1c & bestC1==c1c & bestHt==effH & bestWd==effW)
									bestR1(end+1,1) = r1c; %#ok<AGROW>
									bestC1(end+1,1) = c1c; %#ok<AGROW>
									bestHt(end+1,1) = effH; %#ok<AGROW>
									bestWd(end+1,1) = effW; %#ok<AGROW>
								end
							end
							if numel(bestR1)>=stpo.maxN, break; end
						end
						if numel(bestR1)>=stpo.maxN, break; end
					end
				end
			end
		end
	end
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
if area
	bestR2 = bestR1 + bestHt - 1;
	bestC2 = bestC1 + bestWd - 1;
	bbox = [bestR1,bestR2,bestC1,bestC2];
	dims = [bestHt,bestWd];
	if nargout>3
		info.numBoxes = numel(bestR1);
		info.box = arrayfun(@flb2Geometry, bestR1,bestR2,bestC1,bestC2,bestHt,bestWd);
	end
end
%
info.rowsProcessed = rowCnt;
info.timeTotal = toc(tic0);
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%findLargestBox2D
function out = flb2CheckIndex(ord,anm,inp)
assert(isnumeric(inp)&&isreal(inp)&&(isvector(inp)||isequal(inp,[])),...
	sprintf('SC:findLargestBox2D:%s:notRealNumericVector',anm),...
	'%s input <%s> must be a real numeric vector',ord,anm)
assert(isinteger(inp) || all(fix(inp)==inp),...
	sprintf('SC:findLargestBox2D:%s:fractionalValues',anm),...
	'%s input <%s> must not contain fractional values',ord,anm)
assert(all(inp>0),...
	sprintf('SC:findLargestBox2D:%s:negativeValues',anm),...
	'%s input <%s> must not contain zero/negative values',ord,anm)
out = double(inp(:));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%flb2CheckIndex
function ss = flb2Geometry(bR1,bR2,bC1,bC2,bHt,bWd)
% Return basic geometry information about the provided rectangle.
ss = struct('indices',[bR1,bR2,bC1,bC2]); % 1x4
ss.corners = [bR1-0.5, bR2+0.5, bC1-0.5, bC2+0.5]; % 1x4
ss.center  = ss.corners*[1,0; 1,0; 0,1; 0,1]./2; % 1x2
ss.height = bHt;
ss.width  = bWd;
ss.area   = bHt * bWd;
ss.perimeter = 2*(bHt + bWd);
ss.diagonal  = sqrt(bHt.^2 + bWd.^2);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%flb2Geometry
function str = flb2TimeText(toa)
if ~isfinite(toa)
	str = 'TBD...';
	return
end
dpf = 1e2;
spl = [0,0,0,ceil(toa*dpf)./dpf]; % s.f
spl(3:4) = flb2FixRem(spl(4),60); % m:s
spl(2:3) = flb2FixRem(spl(3),60); % h:m
spl(1:2) = flb2FixRem(spl(2),24); % d:h
idx = spl~=0 | [false(1,3),~any(spl)];
spl(2,:) = 'dhms';
str = sprintf('%g%c',spl(:,idx));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%flb2TimeText
function V = flb2FixRem(N,D)
V = [fix(N./D),rem(N,D)];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%flb2FixRem
function stpo = flb2Options(stpo,opts)
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
		error('SC:findLargestBox2D:options:UnknownOptionName',...
			'Unknown option: <%s>.\nOptions are:%s.',ofn,ont(2:end))
	elseif nnz(oix)>1
		dnt = sprintf(', <%s>',ofc{oix});
		error('SC:findLargestBox2D:options:DuplicateOptionNames',...
			'Duplicate option names:%s.',dnt(2:end))
	end
	arg = opts.(ofn);
	dfn = dfc{dix};
	switch dfn
		case {'maxArea','maxHeight','maxWidth','maxN'}
			flb2Scalar(@le,8804)
		case {'minArea','minHeight','minWidth'}
			flb2Scalar(@lt,60)
		case 'display'
			flb2String('silent','verbose','waitbar')
		otherwise
			error('SC:findLargestBox2D:options:MissingCase','Please report this bug.')
	end
	stpo.(dfn) = arg;
end
%
%% Nested Functions %%
%
	function flb2String(varargin) % text.
		if ~(ischar(arg)&&ndims(arg)<3&&size(arg,1)==1&&any(strcmpi(arg,varargin))) %#ok<ISMAT>
			tmp = sprintf(', "%s"',varargin{:});
			error(sprintf('SC:findLargestBox2D:%s:UnknownValue',dfn),...
				'The <%s> value must be one of:%s.',dfn,tmp(2:end));
		end
		arg = lower(arg);
	end
	function flb2Scalar(fnh,utf)
		assert(isnumeric(arg)&&isscalar(arg),...
			sprintf('SC:findLargestBox2D:%s:NotScalarNumeric',dfn),...
			'The <%s> value must be a scalar numeric.',dfn)
		assert(isreal(arg),...
			sprintf('SC:findLargestBox2D:%s:NotRealNumeric',dfn),...
			'The <%s> value cannot be complex. Input: %g%+gi',dfn,real(arg),imag(arg))
		assert(arg>0 && fnh(arg,Inf),...
			sprintf('SC:findLargestBox2D:%s:OutOfRange',dfn),...
			'The <%s> value must be 1\x2264%s%cInf. Input: %g',dfn,dfn,utf,arg)
		assert(fix(arg)==arg,...
			sprintf('SC:findLargestBox2D:%s:NotWholeNumeric',dfn),...
			'The <%s> value must be a whole number. Input: %g',dfn,arg)
		arg = double(arg);
	end
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%flb2Options
function arr = flb2ss2c(arr)
% If scalar string then extract the character vector, otherwise data is unchanged.
if isa(arr,'string') && isscalar(arr)
	arr = arr{1};
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%flb2ss2c
% Copyright (c) 2026 Stephen Cobeldick
%
% Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%license