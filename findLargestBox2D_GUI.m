function [bbox,dims,area,info] = findLargestBox2D_GUI(varargin)
% Interactive demonstration of findLargestBox2D rectangle finder.
%
% Interactive GUI for demonstrating findLargestBox2D largest rectangle
% finder. Grid visualization allows interactive toggling of mask values,
% with real-time updates of the displayed rectangle and outputs.
%
%%% Syntax %%%
%
%   findLargestBox2D_GUI()
%   findLargestBox2D_GUI(mask)
%   findLargestBox2D_GUI(pxr,pxc)
%   findLargestBox2D_GUI(...,<name-value options>)
%   [bbox,dims,area,info] = findLargestBox2D_GUI(...)
%
%% Input Arguments %%
%
% As per findLargestBox2D.
%
% If no input/s are provided then a demo matrix is used.
%
%% Output Arguments %%
%
% As per findLargestBox2D.
%
%% Dependencies %%
%
% * MATLAB R2020b or later.
% * findLargestBox2D.m function
%
% See also FINDLARGESTBOX2D
persistent fgh fgc actIdx memFun drpCase spinX spinY txtBbox txtDims txtArea txtInfo clr0 clr1 clrR
% R2020b: uigridlayout
% R2017a: memoize
% R2016a: uifigure
%
%% Input Wrangling %%
%
egMat = flb2DemoMatrices();
%
ido = cellfun(@(a)isnumeric(a)||islogical(a),varargin);
id1 = find([~ido,true],1,'first');
%
switch id1
	case 1 % do nothing
	case 2 % mask matrix
		egMat(end+1).name = 'User Matrix';
		egMat(end).default = flb2ParseMask(varargin{1});
	case 3 % index vectors
		egMat(end+1).name = 'User Indices';
		egMat(end).default = flb2Idx2Mask(varargin{1:2});
	otherwise
		error('SC:findLargestBox2D_GUI:unsupportedInputs',...
			'Either one matrix (mask) or two index vectors are supported')
end
%
egMat = egMat(end:-1:1);
[egMat.current] = deal(egMat.default);
%
if isempty(fgh) || ~ishghandle(fgh)
	actIdx = 1;
	flb2NewFigure()
else
	figure(fgh)
end
%
if isempty(memFun)
	memFun = memoize(@findLargestBox2D);
end
%
flb2DropClBk()
%
if nargout
	waitfor(fgh)
	% Return results from active case when GUI closes
	[bbox,dims,area,info] = memFun(egMat(actIdx).current,varargin{id1:end});
else
	clear bbox
end
%
%% Callback Functions %%
%
	function flb2ClickClBk(~,~) % Click on axes or image to toggle element
		%
		mcp = egMat(actIdx).axes.CurrentPoint;
		xcp = round(mcp(1,1));
		ycp = round(mcp(1,2));
		%
		if any([ycp,xcp]<1 | [ycp,xcp]>size(egMat(actIdx).current))
			return
		end
		%
		val = ~egMat(actIdx).current(ycp,xcp);
		egMat(actIdx).current(ycp,xcp) = val;
		egMat(actIdx).image.CData(ycp,xcp) = val;
		egMat(actIdx).text(ycp,xcp).String = char('0'+val);
		%
		flb2ComputeAndDisplay()
	end
%
	function flb2SpinClBk(src,~,flag) % Spinner change callback
		%
		mask = egMat(actIdx).current;
		[newY,newX] = size(mask);
		%
		switch flag
			case 'rows'
				newY = src.Value;
			case 'cols'
				newX = src.Value;
			otherwise
				error('This should not happen')
		end
		%
		mask(end+1:newY,:) = 0;
		mask(:,end+1:newX) = 0;
		mask(newY+1:end,:) = [];
		mask(:,newX+1:end) = [];
		%
		egMat(actIdx).current = mask;
		egMat(actIdx).image.CData = mask;
		%
		flb2UpdateDimensions()
		flb2ComputeAndDisplay()
	end
%
	function flb2DropClBk(~,~) % Handle case selection from dropdown
		%
		try
			tmpI = [egMat.image];
		catch
			return
		end
		set(tmpI,'Visible','off');
		arrayfun(@(s)set(s.text,'Visible','off'),egMat);
		%
		actIdx = drpCase.ValueIndex;
		%
		delete([egMat.rectangles]);
		egMat(actIdx).rectangles = gobjects(0);
		%
		[nowY,nowX] = size(egMat(actIdx).current);
		spinY.Value = nowY;
		spinX.Value = nowX;
		%
		flb2ComputeAndDisplay()
	end
%
	function flb2ResetClBk(~,~) % Reset current case to default
		%
		mask = egMat(actIdx).default;
		[oldY,oldX] = size(egMat(actIdx).current);
		egMat(actIdx).current = mask;
		[newY,newX] = size(egMat(actIdx).current);
		egMat(actIdx).image.CData = mask;
		%
		if oldY~=newY || oldX~=newX
			% Dimensions changed - update spinners and graphics
			%
			spinY.Value = newY;
			spinX.Value = newX;
			%
			flb2UpdateDimensions()
			%
		else % all
			%
			set(egMat(actIdx).text,{'String'},num2cell(char('0'+mask(:))));
			%
		end
		%
		flb2ComputeAndDisplay()
	end
%
%% Helper Functions %%
%
	function flb2UpdateDimensions()
		% Update dimensions by managing text handles efficiently
		%
		% Strategy: minimize object creation/deletion
		% - Delete only superfluous objects
		% - Create only necessary new objects
		% - Reuse existing objects where possible
		%
		txh = egMat(actIdx).text;
		axh = egMat(actIdx).axes;
		mask = egMat(actIdx).current;
		%
		[oldY,oldX] = size(txh);
		[newY,newX] = size(mask);
		%
		% shrink
		delete(txh(:,newX+1:end));
		txh(:,newX+1:end) = [];
		delete(txh(newY+1:end,:));
		txh(newY+1:end,:) = [];
		%
		if isempty(mask)
			axh.XLim = [0.5,1.5];
			axh.YLim = [0.5,1.5];
		else
			axh.XLim = [0.5,0.5+newX];
			axh.YLim = [0.5,0.5+newY];
			%
			if newY>oldY || newX>oldX % expand
				[matX,matY] = meshgrid(1:newX,1:newY);
				idxM = matY(:)>oldY | matX(:)>oldX;
				txh(newY,newX) = gobjects(1);
				txh(idxM) = text(axh, matX(idxM), matY(idxM), 'X',...
					'HorizontalAlignment','center', 'Color',clrR,...
					'VerticalAlignment','middle', 'FontSize',10,...
					'ButtonDownFcn',@flb2ClickClBk);
			end
		end
		%
		set(txh,{'String'},num2cell(char('0'+mask(:)))); % all
		egMat(actIdx).text = txh;
	end
%
	function flb2ComputeAndDisplay() % Compute rectangle and update displays
		%
		fgp = fgh.Pointer;
		fgh.Pointer = 'watch';
		drawnow()
		%
		mask = egMat(actIdx).current;
		%
		delete(egMat(actIdx).rectangles);
		egMat(actIdx).rectangles = gobjects(0);
		%
		try
			[bboxOut,dimsOut,areaOut,infoOut] = memFun(mask,varargin{id1:end});
		catch ME
			fgh.Pointer = fgp;
			if startsWith(ME.identifier,'SC:findLargestBox2D:')
				txtInfo.FontColor = [1,0,0];
				txtInfo.Value = ME.message;
				txtBbox.Value = '';
				txtDims.Value = '';
				txtArea.Value = NaN;
				return
			else
				rethrow(ME)
			end
		end
		%
		% Update rectangle position:
		if isempty(bboxOut)
			txtBbox.Value = '[]';
			txtDims.Value = '[]';
			txtArea.Value = 0;
		else
			% bbox is Nx4: [r1,r2,c1,c2] per row
			axh = egMat(actIdx).axes;
			nmR = size(bboxOut,1);
			reH = gobjects(1,nmR);
			colors = flb2RectColors(nmR);
			for ii = 1:nmR
				r1 = bboxOut(ii,1);
				r2 = bboxOut(ii,2);
				c1 = bboxOut(ii,3);
				c2 = bboxOut(ii,4);
				reH(ii) = rectangle(axh,...
					'Position',[c1-0.5, r1-0.5, c2-c1+1, r2-r1+1],...
					'EdgeColor',colors(ii,:),...
					'LineWidth',3);
				uistack(reH(ii),'top');
			end
			egMat(actIdx).rectangles = reH;
			%
			txtBbox.Value = compose('[%d,%d,%d,%d]',bboxOut);
			txtDims.Value = compose('[%d,%d]',dimsOut);
			txtArea.Value = areaOut;
		end
		%
		% Update info display
		fnm = fieldnames(infoOut);
		iss = structfun(@isstruct,infoOut);
		infoOut = rmfield(infoOut,fnm(iss));
		try
			txt = formattedDisplayText(infoOut);
		catch
			txt = evalc('disp(infoOut)'); % ugh!
		end
		txtInfo.FontColor = fgc;
		txtInfo.Value = txt;
		%
		egMat(actIdx).image.Visible = 'on';
		set(egMat(actIdx).text,'Visible','on');
		%
		fgh.Pointer = fgp;
		%
		drawnow
	end
%
	function flb2NewFigure()
		%
		fgh = uifigure();
		fgh.Name = 'Interactive Largest Rectangle Demo';
		fgh.Tag = mfilename;
		fgh.HandleVisibility = 'off';
		fgh.IntegerHandle = 'off';
		%
		% Create grid layout
		uig = uigridlayout(fgh,[4,8]);
		uig.RowHeight = {'1x','fit','fit','fit'};
		uig.ColumnWidth = {'fit','1x','fit','1x','fit','2x','1x','1x'};
		%
		% Create a temporary label to get foreground color for light/dark detection
		tmpLbl = uilabel(uig);
		fgc = tmpLbl.FontColor;
		delete(tmpLbl);
		%
		fgg = fgc*[0.298936;0.587043;0.114021];
		if fgg<0.54 % lightmode
			clr0 = [0.95,0.85,0.85]; % light red
			clr1 = [0.85,0.95,0.85]; % light green
			clrR = [0,0,0]; % black rectangle/text
		else % darkmode
			clr0 = [0.25,0.15,0.15]; % dark red
			clr1 = [0.15,0.25,0.15]; % dark green
			clrR = [1,1,1]; % white rectangle/text
		end
		%
		axp = uipanel(uig);
		axp.BorderWidth = 0;
		axp.Layout.Row = 1;
		axp.Layout.Column = [1,8];
		%
		ax0 = axes(axp);
		ax0.XLim = 0:1;
		ax0.YLim = 0:1;
		ax0.XTick = [];
		ax0.YTick = [];
		ax0.Box = 'off';
		ax0.Visible = 'off';
		ax0.Toolbar.Visible = 'off';
		ax0.Units = 'normalized';
		ax0.Position = [0,0,1,1];
		ax0.PositionConstraint = 'innerposition';
		ax0.NextPlot = 'add';
		text(ax0, 0.5, 0.5, 'Empty Mask!', 'Visible','on',...
			'HorizontalAlignment','center','Color',[1,0,0],...
			'VerticalAlignment','middle', 'FontSize',14)
		%
		for k = 1:numel(egMat)
			%
			mask = egMat(k).current;
			[szY,szX] = size(mask);
			%
			axh = axes(axp); %#ok<LAXES>
			axh.XLim = [0.5,max(1,szX)+0.5];
			axh.YLim = [0.5,max(1,szY)+0.5];
			axh.XTick = [];
			axh.YTick = [];
			axh.Box = 'on';
			axh.YDir = 'reverse';
			axh.ButtonDownFcn = @flb2ClickClBk;
			axh.Visible = 'off';
			axh.Toolbar.Visible = 'off';
			axh.Colormap = [clr0;clr1];
			axh.CLim = [0,1];
			axh.Units = 'normalized';
			axh.Position = [0,0,1,1];
			axh.PositionConstraint = 'innerposition';
			axh.NextPlot = 'add';
			try %#ok<TRYNC>
				axh.Tooltip = 'Click on the cells to toggle the values!';
			end
			%
			% Create image
			imh = imagesc(axh, mask, 'ButtonDownFcn',@flb2ClickClBk);
			uistack(imh,'bottom')
			%
			% Create text
			if numel(mask)
				matC = char('0'+mask);
				[matX,matY] = meshgrid(1:szX,1:szY);
				txh = text(axh, matX(:), matY(:), matC(:),...
					'HorizontalAlignment','center', 'Color',clrR,...
					'VerticalAlignment','middle', 'FontSize',10,...
					'ButtonDownFcn',@flb2ClickClBk);
			else
				txh = gobjects(szY,szX);
			end
			%
			egMat(k).axes = axh;
			egMat(k).image = imh;
			egMat(k).text = reshape(txh,szY,szX);
			egMat(k).rectangles = gobjects(0);
		end
		%
		% Row spinner
		lblY = uilabel(uig);
		lblY.Visible = 'on';
		lblY.Text = 'Rows';
		lblY.HorizontalAlignment = 'center';
		lblY.Layout.Row = 2;
		lblY.Layout.Column = 1;
		%
		spinY = uispinner(uig);
		spinY.Visible = 'on';
		spinY.Limits = [0,Inf];
		spinY.Step = 1;
		spinY.Value = szY;
		spinY.ValueChangedFcn = {@flb2SpinClBk,'rows'};
		spinY.Layout.Row = 2;
		spinY.Layout.Column = 2;
		spinY.Tooltip = 'Number of rows in the current case';
		%
		% Column spinner
		lblX = uilabel(uig);
		lblX.Visible = 'on';
		lblX.Text = 'Columns';
		lblX.HorizontalAlignment = 'center';
		lblX.Layout.Row = 2;
		lblX.Layout.Column = 3;
		%
		spinX = uispinner(uig);
		spinX.Visible = 'on';
		spinX.Limits = [0,Inf];
		spinX.Step = 1;
		spinX.Value = szX;
		spinX.ValueChangedFcn = {@flb2SpinClBk,'cols'};
		spinX.Layout.Row = 2;
		spinX.Layout.Column = 4;
		spinX.Tooltip = 'Number of columns in the current case';
		%
		% Case dropdown
		txtCase = uilabel(uig);
		txtCase.Visible = 'on';
		txtCase.Text = 'Example';
		txtCase.HorizontalAlignment = 'center';
		txtCase.Layout.Row = 2;
		txtCase.Layout.Column = 5;
		%
		drpCase = uidropdown(uig);
		drpCase.Visible = 'on';
		drpCase.Items = {egMat.name};
		drpCase.Layout.Row = 2;
		drpCase.Layout.Column = [6,7];
		drpCase.Tooltip = 'Select preset example or user case';
		drpCase.ValueChangedFcn = @flb2DropClBk;
		%
		% Reset button
		btnReset = uibutton(uig);
		btnReset.Visible = 'on';
		btnReset.Text = 'Reset';
		btnReset.Layout.Row = 2;
		btnReset.Layout.Column = 8;
		btnReset.Tooltip = 'Reset current case to original values and dimensions';
		btnReset.ButtonPushedFcn = @flb2ResetClBk;
		%
		% Output display
		lblBbox = uilabel(uig);
		lblBbox.Visible = 'on';
		lblBbox.Text = '↓ BBox [r1,r2,c1,c2]';
		lblBbox.HorizontalAlignment = 'left';
		lblBbox.Layout.Row = 3;
		lblBbox.Layout.Column = [3,4];
		%
		txtBbox = uitextarea(uig);
		txtBbox.Visible = 'on';
		txtBbox.Value = 'X';
		txtBbox.Editable = false;
		txtBbox.Layout.Row = 4;
		txtBbox.Layout.Column = [3,4];
		txtBbox.Tooltip = '1st output <bbox>: the rectangle corner indices';
		%
		lblDims = uilabel(uig);
		lblDims.Visible = 'on';
		lblDims.Text = '↓ Dims [h,w]';
		lblDims.HorizontalAlignment = 'left';
		lblDims.Layout.Row = 3;
		lblDims.Layout.Column = [1,2];
		%
		txtDims = uitextarea(uig);
		txtDims.Visible = 'on';
		txtDims.Value = 'X';
		txtDims.Editable = false;
		txtDims.Layout.Row = 4;
		txtDims.Layout.Column = [1,2];
		txtDims.Tooltip = '2nd output <dims>: the rectangle sizes/dimensions';
		%
		lblArea = uilabel(uig);
		lblArea.Visible = 'on';
		lblArea.Text = 'Area';
		lblArea.HorizontalAlignment = 'right';
		lblArea.Layout.Row = 3;
		lblArea.Layout.Column = 7;
		%
		txtArea = uieditfield(uig,'numeric');
		txtArea.Visible = 'on';
		txtArea.Value = 0;
		txtArea.Editable = false;
		txtArea.Layout.Row = 3;
		txtArea.Layout.Column = 8;
		txtArea.Tooltip = '3rd output <area>: the rectangle area';
		%
		lblInfo = uilabel(uig);
		lblInfo.Visible = 'on';
		lblInfo.Text = '↓ Info';
		lblInfo.HorizontalAlignment = 'left';
		lblInfo.Layout.Row = 3;
		lblInfo.Layout.Column = [5,6];
		%
		txtInfo = uitextarea(uig);
		txtInfo.Visible = 'on';
		txtInfo.Value = 'X';
		txtInfo.Editable = false;
		txtInfo.FontColor = fgc;
		txtInfo.FontName = 'monospaced';
		txtInfo.Layout.Row = 4;
		txtInfo.Layout.Column = [5,8];
		txtInfo.Tooltip = '4th output <info>: algorithm information';
	end
%
	function colors = flb2RectColors(N)
		% Generate N maximally-distinct colors using evenly-spaced OKLCh hues.
		% Starting hue ~240deg (blue) to contrast with red/green cell background.
		C = 0.13; % Conservative chroma, stays mostly in sRGB gamut.
		hue = (4*pi/3) + linspace(0, 2*pi, N+1);
		hue(end) = [];
		Lab  = [hue(:), C*cos(hue(:)), C*sin(hue(:))];
		Lab(:,1) = 0.55 + 0.20*clrR(1); % 0.55 light mode, 0.75 dark mode.
		colors = min(1, max(0, OKLab2sRGB(Lab)));
	end
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%findLargestBox2D_GUI
function rgb = OKLab2sRGB(Lab)
%
M1 = [... XYZ to approximate cone responses:
	+0.8189330101, +0.3618667424, -0.1288597137;...
	+0.0329845436, +0.9293118715, +0.0361456387;...
	+0.0482003018, +0.2643662691, +0.6338517070];
M2 = [... nonlinear cone responses to Lab:
	+0.2104542553, +0.7936177850, -0.0040720468;...
	+1.9779984951, -2.4285922050, +0.4505937099;...
	+0.0259040371, +0.7827717662, -0.8086757660];
lmsp = Lab / M2.';
lms  = lmsp.^3;
XYZ  = lms / M1.';
%
M0 = [... IEC 61966-2-1:1999 (for compatibility)
	0.4124,0.3576,0.1805;...
	0.2126,0.7152,0.0722;...
	0.0193,0.1192,0.9505];
% M = [... Derived from ITU-R BT.709-6
%    0.412390799265959,0.357584339383878,0.180480788401834;...
%    0.212639005871510,0.715168678767756,0.072192315360734;...
%    0.019330818715592,0.119194779794626,0.950532152249661];
% M = [... <http://brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.html>
% 	0.4124564,0.3575761,0.1804375;...
% 	0.2126729,0.7151522,0.0721750;...
% 	0.0193339,0.1191920,0.9503041];
%
rgb = sGammaCor(XYZ / M0.');
rgb = max(0,min(1,rgb));
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%OKLab2sRGB
function out = sGammaCor(inp)
% Forward Gamma correction: Nx3 linear RGB -> Nx3 sRGB.
idx = inp > 0.0031308;
out = 12.92 * inp;
out(idx) = real(1.055 * inp(idx).^(1./2.4) - 0.055);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%sGammaCor


function mask = flb2ParseMask(input)
% Parse mask input (numeric, logical, or sparse)
if issparse(input)
	mask = full(logical(input));
elseif isnumeric(input) || islogical(input)
	mask = logical(input);
else
	error('SC:findLargestBox2D_GUI:mask:InvalidType',...
		'1st input <mask> must be numeric, logical, or sparse matrix.')
end
%
assert(ismatrix(mask),...
	'SC:findLargestBox2D_GUI:mask:NotMatrix',...
	'1st input <mask> must be a 2D matrix.')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%flb2ParseMask
function mask = flb2Idx2Mask(pxr,pxc)
% Convert index vectors to mask
assert(isnumeric(pxr) && isnumeric(pxc),...
	'SC:findLargestBox2D_GUI:indices:NotNumeric',...
	'1st and 2nd inputs <pxr> and <pxc> must be numeric.')
%
pxr = pxr(:);
pxc = pxc(:);
%
assert(numel(pxr)==numel(pxc),...
	'SC:findLargestBox2D_GUI:indices:SizeMismatch',...
	'1st and 2nd inputs <pxr> and <pxc> must have the same length.')
%
if isempty(pxr)
	mask = [];
	return
end
%
M = max(pxr);
N = max(pxc);
%
mask = false(M,N);
mask(sub2ind([M,N],pxr,pxc)) = true;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%flb2Idx2Mask
function S = flb2DemoMatrices()
% Define some interesting example matrices
%
S(9).name = 'Smiley Face';
S(9).default = [1,1,0,0,1,1,1,1,1,0,1,1;1,0,1,1,0,1,1,1,0,0,1,1;1,0,1,1,0,1,1,1,1,0,1,1;1,0,1,1,0,1,1,1,1,0,1,1;1,1,0,0,1,1,1,1,0,0,0,1;1,1,1,1,1,1,1,1,1,1,1,1;1,1,1,1,1,1,1,1,1,1,1,1;0,0,1,1,1,1,1,1,1,1,0,0;0,0,0,1,1,1,1,1,1,0,0,0;1,0,0,0,0,0,0,0,0,0,0,1;1,1,0,0,0,0,0,0,0,0,1,1];
%
S(8).name = 'All Blocked';
S(8).default = false(6,8);
%
S(7).name = 'All Usable';
S(7).default = true(6,8);
%
S(6).name = 'Single Obstacle';
S(6).default = true(6,8);
S(6).default(3,4) = 0;
%
S(5).name = 'L-Shape Obstacle';
S(5).default = false(6,8);
S(5).default(4:end,5:end) = 1;
%
S(4).name = 'L-Shape Usable';
S(4).default = true(6,8);
S(4).default(4:end,5:end) = 0;
%
S(3).name = 'Diagonal Band';
S(3).default = tril(triu(true(8),-1),1);
%
S(2).name = 'Scattered Islands';
S(2).default = false(10,10);
S(2).default(2:3,2:4) = 1;
S(2).default(2:4,7:9) = 1;
S(2).default(6:8,2:3) = 1;
S(2).default(7:9,6:8) = 1;
%
S(1).name = 'Random';
S(1).default = randi(0:1,6,8);
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%flb2DemoMatrices
% Copyright (c) 2026 Stephen Cobeldick
%
% Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%license