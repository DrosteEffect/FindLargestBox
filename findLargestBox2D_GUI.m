function [bbox,area,info] = findLargestBox2D_GUI(varargin)
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
%   [bbox,area,info] = findLargestBox2D_GUI(...)
%
%% Input Arguments %%
%
%   mask = 2D logical or numeric or sparse matrix where:
%          TRUE / non-zero == empty/usable pixel
%          FALSE / zero    == blocked/unusable pixel
%   pxr  = NumericVector of N usable pixel row indices.
%   pxc  = NumericVector of N usable pixel column indices.
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
persistent fgh fgc actIdx memFun drpCase spinX spinY txtBbox txtArea txtInfo clr0 clr1 clrR
% R2020b: uigridlayout
% R2017a: memoize
% R2016a: uifigure
%
%% Input Wrangling %%
%
egMat = flb2DemoMatrices();
%
switch nargin
	case 0 % do nothing
	case 1 % mask matrix
		egMat(end+1).name = 'User Matrix';
		egMat(end).default = flb2ParseMask(varargin{:});
	case 2 % index vectors
		egMat(end+1).name = 'User Indices';
		egMat(end).default = flb2Idx2Mask(varargin{:});
	otherwise
		error('SC:findLargestBox2D_GUI:TooManyInputs',...
			'Too many input arguments. Either 1 matrix or 2 vectors are supported.')
end
%
egMat = egMat(end:-1:1);
[egMat.current] = deal(egMat.default);
%
if isempty(fgh) || ~ishghandle(fgh)
	flb2NewFigure()
else
	% do nothing
end
%
if isempty(memFun)
	memFun = memoize(@findLargestBox2D);
	actIdx = NaN;
end
%
flb2DropClBk()
%
if nargout
	waitfor(fgh)
	% Return results from active case when GUI closes
	[bbox,area,info] = memFun(egMat(actIdx).current);
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
		set([egMat.image],'Visible','off');
		arrayfun(@(s)set(s.text,'Visible','off'),egMat);
		%
		actIdx = drpCase.ValueIndex;
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
		set([egMat.rectangle],'Visible','off');
		%
		try
			[bboxOut,areaOut,infoOut] = memFun(mask);
		catch ME
			fgh.Pointer = fgp;
			if startsWith(ME.identifier,'SC:findLargestBox2D:')
				txtInfo.FontColor = [1,0,0];
				txtInfo.Value = ME.message;
				txtBbox.Value = '';
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
			txtArea.Value = 0;
		else
			% Convert bbox indices to rectangle position
			% bbox = [r1,r2; c1,c2] (inclusive indices)
			r1 = bboxOut(1,1);
			r2 = bboxOut(1,2);
			c1 = bboxOut(2,1);
			c2 = bboxOut(2,2);
			%
			% Rectangle Position = [x,y,w,h]
			% Account for pixel edges at half-integers
			xPos = c1 - 0.5;
			yPos = r1 - 0.5;
			wPos = c2 - c1 + 1;
			hPos = r2 - r1 + 1;
			%
			egMat(actIdx).rectangle.Position = [xPos,yPos,wPos,hPos];
			egMat(actIdx).rectangle.Visible = 'on';
			%
			txtBbox.Value = sprintf('[%d,%d; %d,%d]',r1,r2,c1,c2);
			txtArea.Value = areaOut;
		end
		%
		% Update info display
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
		uig = uigridlayout(fgh,[4,6]);
		uig.RowHeight = {'1x','fit','fit','fit'};
		uig.ColumnWidth = {'fit','2x','fit','2x','fit','3x'};
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
		ax0 = axes(uig);
		ax0.XLim = 0:1;
		ax0.YLim = 0:1;
		ax0.XTick = [];
		ax0.YTick = [];
		ax0.Box = 'off';
		ax0.Visible = 'off';
		ax0.Layout.Row = 1;
		ax0.Layout.Column = [1,6];
		ax0.Units = 'normalized';
		ax0.Position = [0,0,1,1];
		text(ax0, 0.5, 0.5, 'Empty Mask!', 'Visible','on',...
			'HorizontalAlignment','center','Color',[1,0,0],...
			'VerticalAlignment','middle', 'FontSize',14)
		%
		for k = 1:numel(egMat)
			%
			mask = egMat(k).current;
			[szY,szX] = size(mask);
			%
			axh = axes(uig); %#ok<LAXES>
			axh.XLim = [0.5,max(1,szX)+0.5];
			axh.YLim = [0.5,max(1,szY)+0.5];
			axh.XTick = [];
			axh.YTick = [];
			axh.Box = 'on';
			axh.YDir = 'reverse';
			axh.ButtonDownFcn = @flb2ClickClBk;
			axh.Visible = 'off';
			axh.Colormap = [clr0;clr1];
			axh.CLim = [0,1];
			axh.Layout.Row = 1;
			axh.Layout.Column = [1,6];
			axh.Units = 'normalized';
			axh.Position = [0,0,1,1];
			axh.NextPlot = 'add';
			try %#ok<TRYNC>
				axh.Tooltip = 'Click on the cells to toggle the values!';
			end
			%
			% Create image
			imh = imagesc(axh, mask, 'ButtonDownFcn',@flb2ClickClBk);
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
			% Create rectangle overlay
			rah = rectangle(axh,...
				'Position',[0,0,1,1],...
				'EdgeColor',clrR,...
				'LineWidth',3,...
				'Visible','off');
			%
			uistack(imh,'bottom')
			uistack(rah,'top')
			%
			egMat(k).axes = axh;
			egMat(k).image = imh;
			egMat(k).text = reshape(txh,szY,szX);
			egMat(k).rectangle = rah;
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
		drpCase.Layout.Column = 6;
		drpCase.Tooltip = 'Select preset example or user case';
		drpCase.ValueChangedFcn = @flb2DropClBk;
		%
		% Reset button
		btnReset = uibutton(uig);
		btnReset.Visible = 'on';
		btnReset.Text = 'Reset';
		btnReset.Layout.Row = 3;
		btnReset.Layout.Column = 5:6;
		btnReset.Tooltip = 'Reset current case to original values and dimensions';
		btnReset.ButtonPushedFcn = @flb2ResetClBk;
		%
		% Output display
		lblBbox = uilabel(uig);
		lblBbox.Visible = 'on';
		lblBbox.Text = 'BBox';
		lblBbox.HorizontalAlignment = 'right';
		lblBbox.Layout.Row = 3;
		lblBbox.Layout.Column = 1;
		%
		txtBbox = uieditfield(uig);
		txtBbox.Visible = 'on';
		txtBbox.Value = 'X';
		txtBbox.Editable = false;
		txtBbox.Layout.Row = 3;
		txtBbox.Layout.Column = 2;
		txtBbox.Tooltip = '1st output <bbox>: the rectangle corners';
		%
		lblArea = uilabel(uig);
		lblArea.Visible = 'on';
		lblArea.Text = 'Area';
		lblArea.HorizontalAlignment = 'right';
		lblArea.Layout.Row = 3;
		lblArea.Layout.Column = 3;
		%
		txtArea = uieditfield(uig,'numeric');
		txtArea.Visible = 'on';
		txtArea.Value = 0;
		txtArea.Editable = false;
		txtArea.Layout.Row = 3;
		txtArea.Layout.Column = 4;
		txtArea.Tooltip = '2nd output <area>: the rectangle area';
		%
		txtInfo = uitextarea(uig);
		txtInfo.Visible = 'on';
		txtInfo.Value = 'X';
		txtInfo.Editable = false;
		txtInfo.FontColor = fgc;
		txtInfo.FontName = 'monospaced';
		txtInfo.Layout.Row = 4;
		txtInfo.Layout.Column = [1,6];
		txtInfo.Tooltip = '3rd output <info>: algorithm information';
	end
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%findLargestBox2D_GUI
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
S(3).name = 'Vertical Corridor';
S(3).default = false(6,8);
S(3).default(:,3:5) = 1;
%
S(2).name = 'Diagonal Band';
S(2).default = tril(triu(true(8),-1),1);
%
S(1).name = 'Scattered Islands';
S(1).default = false(10,10);
S(1).default(2:3,2:4) = 1;
S(1).default(2:4,7:9) = 1;
S(1).default(6:8,2:3) = 1;
S(1).default(7:9,6:8) = 1;
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