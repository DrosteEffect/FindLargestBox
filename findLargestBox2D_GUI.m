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
% As per findLargestBox2D. If no inputs are provided a demo mask is used.
%
%% Output Arguments %%
%
% As per findLargestBox2D. Outputs are captured when the GUI window closes.
%
%% Dependencies %%
%
% * MATLAB R2020b or later.
% * findLargestBox2D.m function
%
% See also FINDLARGESTBOX2D FINDLARGESTBOX3D FINDLARGESTBOX3D_GUI
persistent fgh fgc axh imh txPool actIdx memFun drpCase ...
	spinX spinY spinN txtBbox txtDims txtArea txtInfo clr0 clr1 clrF ...
	clrIn clrOut stpo cstrSpn cstrFlds
% R2020b: uigridlayout
% R2017a: memoize
% R2016a: uifigure
%
%% Default Option Values %%
%
stpo = struct('maxN',Inf,...
	'minArea'  ,1, 'maxArea'  ,Inf,...
	'minHeight',1, 'maxHeight',Inf,...
	'minWidth' ,1, 'maxWidth' ,Inf);
%
%% Input Wrangling %%
%
egMat = flb2DemoMasks(); % renew all masks on each function call.
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
			'Either one matrix (mask) or two index vectors (pxR,pxC) are supported')
end
%
egMat = egMat(end:-1:1);
[egMat.current] = deal(egMat.default);
%
%% Options %%
%
varg = varargin(id1:end);
dfns = fieldnames(stpo);
%
if isscalar(varg) && isstruct(varg{1})
	opts = varg{1};
	fnms = fieldnames(opts);
	for kk = 1:numel(fnms)
		ix = strcmpi(fnms{kk},dfns);
		if any(ix)
			stpo.(dfns{ix}) = opts.(fnms{kk});
		end
	end
else
	for kk = 1:2:numel(varg)
		if ischar(varg{kk}) || isstring(varg{kk})
			ix = strcmpi(varg{kk},dfns);
			if any(ix)
				stpo.(dfns{ix}) = varg{kk+1};
			end
		else
			error('SC:findLargestBox2D_GUI:notNameValuePairs',...
				'Optional inputs must be in one scalar structure or name-value pairs.')
		end
	end
end
%
if isempty(fgh) || ~ishghandle(fgh)
	actIdx = 1;
	flb2NewFigure()
else
	actIdx = drpCase.ValueIndex;
	spinN.Value = stpo.maxN;
	for kk = 1:numel(cstrFlds)
		cstrSpn(kk).Value = stpo.(cstrFlds{kk});
	end
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
	% Return results from active mask when GUI closes
	[bbox,dims,area,info] = memFun(egMat(actIdx).current,stpo);
else
	clear bbox
end
%
%% Callback Functions %%
%
	function flb2ClickClBk(~,~)
		% Click on axes or image to toggle element value.
		%
		mcp = axh.CurrentPoint;
		xcp = round(mcp(1,1));
		ycp = round(mcp(1,2));
		%
		if any([ycp,xcp]<1 | [ycp,xcp]>size(egMat(actIdx).current))
			return
		end
		%
		val = ~egMat(actIdx).current(ycp,xcp);
		egMat(actIdx).current(ycp,xcp) = val;
		imh.CData(ycp,xcp) = val;
		txPool(ycp,xcp).String = char('0'+val);
		%
		flb2ComputeAndDisplay()
	end
%
	function flb2SpinClBk(src,~,flag)
		% Spinner change callback
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
		%
		flb2UpdateDimensions()
		flb2ComputeAndDisplay()
	end
%
	function flb2DropClBk(~,~)
		% Handle mask selection from dropdown menu.
		%
		if isempty(axh) || ~ishghandle(axh)
			return
		end
		%
		% Hide rectangles of the current example.
		set(egMat(actIdx).rectangles,'Visible','off');
		%
		actIdx = drpCase.ValueIndex;
		%
		[nowY,nowX] = size(egMat(actIdx).current);
		spinY.Value = nowY;
		spinX.Value = nowX;
		%
		flb2UpdateDimensions()
		flb2ComputeAndDisplay()
	end
%
	function flb2ResetClBk(~,~)
		% Reset the current mask to its default size and values.
		%
		egMat(actIdx).current = egMat(actIdx).default;
		[newY,newX] = size(egMat(actIdx).current);
		spinY.Value = newY;
		spinX.Value = newX;
		%
		flb2UpdateDimensions()
		flb2ComputeAndDisplay()
	end
%
	function flb2OptionsClBk(src,~,field,pSpn,pFld,bFcn)
		% Constraint/maxN spinner callback.
		stpo.(field) = src.Value;
		if nargin>3
			pSpn.Value = bFcn(pSpn.Value, src.Value);
			stpo.(pFld) = pSpn.Value;
		end
		flb2ComputeAndDisplay()
	end
%
%% Helper Functions %%
%
	function flb2UpdateDimensions()
		% Update the shared axes, image, and text pool for the active example.
		% The pool grows as needed but never shrinks; surplus texts are hidden.
		%
		mask = egMat(actIdx).current;
		[newY,newX] = size(mask);
		[poolY,poolX] = size(txPool);
		%
		% Update axes limits
		if isempty(mask)
			axh.XLim = [0.5,1.5];
			axh.YLim = [0.5,1.5];
		else
			axh.XLim = [0.5,0.5+newX];
			axh.YLim = [0.5,0.5+newY];
		end
		%
		% Update shared image
		imh.CData = mask;
		%
		% Expand pool if the new mask is larger in either dimension
		if newY > poolY || newX > poolX
			bigY = max(newY,poolY);
			bigX = max(newX,poolX);
			[matX,matY] = meshgrid(1:bigX,1:bigY);
			idxM = matY(:)>poolY | matX(:)>poolX;
			txPool(bigY,bigX) = gobjects(1);
			txPool(idxM) = text(axh, matX(idxM), matY(idxM), '0',...
				'HorizontalAlignment','center', 'Color',clrF,...
				'VerticalAlignment','middle', 'FontSize',10,...
				'ButtonDownFcn',@flb2ClickClBk, 'Visible','off');
			[poolY,poolX] = size(txPool);
		end
		%
		% Update the active region: strings and visibility
		if ~isempty(mask)
			set(txPool(1:newY,1:newX),{'String'},num2cell(char('0'+mask(:))));
			set(txPool(1:newY,1:newX),'Visible','on');
		end
		% Hide surplus rows
		if poolY > newY
			set(txPool(newY+1:end,:),'Visible','off');
		end
		% Hide surplus columns within active rows
		if poolX > newX && newY > 0
			set(txPool(1:newY,newX+1:end),'Visible','off');
		end
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
			[bboxOut,dimsOut,areaOut,infoOut] = memFun(mask,stpo);
		catch ME
			fgh.Pointer = fgp;
			if startsWith(ME.identifier,'SC:findLargestBox2D:')
				txtInfo.FontColor = [1,0,0];
				txtInfo.Value = sprintf('Error: %s',ME.message);
				txtBbox.Value = '';
				txtDims.Value = '';
				txtArea.Value = 0;
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
		else % bbox is Nx4: [r1,r2,c1,c2] per row
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
		dispInfo = rmfield(infoOut,fnm(iss));
		try
			txt = formattedDisplayText(dispInfo);
		catch
			txt = evalc('disp(dispInfo)'); % ugh!
		end
		txtInfo.FontColor = fgc;
		txtInfo.Value = txt;
		%
		imh.Visible = 'on';
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
		% Create a temporary label to get foreground color for light/dark detection
		tmpLbl = uilabel(fgh);
		fgc = tmpLbl.FontColor;
		delete(tmpLbl);
		%
		fgg = fgc*[0.298936;0.587043;0.114021]; % perceived luminance
		if fgg<0.54 % lightmode
			clr0 = [0.95,0.85,0.85]; % FALSE
			clr1 = [0.85,0.95,0.85]; % TRUE
			clrF = [0,0,0]; % foreground
			clrIn  = [0.75, 0.80, 1.00]; % inputs
			clrOut = [0.92, 0.92, 1.00]; % outputs
		else % darkmode
			clr0 = [0.25,0.15,0.15]; % FALSE
			clr1 = [0.15,0.25,0.15]; % TRUE
			clrF = [1,1,1]; % foreground
			clrIn  = [0.25, 0.20, 0.00]; % inputs
			clrOut = [0.13, 0.13, 0.25]; % outputs
		end
		%
		% Main grid layout
		glMG = uigridlayout(fgh,[2,2]);
		glMG.RowHeight = {'1x','fit'};
		glMG.ColumnWidth = {'1x','fit'};
		%
		% Bottom row layout
		glBR = uigridlayout(glMG,[3,8]);
		glBR.Padding = [0,0,0,0];
		glBR.RowHeight = {'fit','fit','fit'};
		glBR.ColumnWidth = {'fit','1x','fit','1x','fit','2x','1x','1x'};
		glBR.Layout.Row = 2;
		glBR.Layout.Column = [1,2];
		%
		% Right column layout
		glRC = uigridlayout(glMG,[4,1]);
		glRC.Padding = [0,0,0,0];
		glRC.RowHeight = {'fit','fit','fit','1x'};
		glRC.ColumnWidth = {123};
		glRC.Layout.Row = 1;
		glRC.Layout.Column = 2;
		%
		gl2C = uigridlayout(glRC,[6,2]);
		gl2C.Padding = [0,0,0,0];
		gl2C.RowHeight = {'fit','fit','fit','fit','fit','fit'};
		gl2C.ColumnWidth = {'1x','1x'};
		gl2C.RowSpacing = 5;
		gl2C.Layout.Row = 3;
		gl2C.Layout.Column = 1;
		%
		%% Area/Height/Width Limits
		%
		lblN = uilabel(glRC);
		lblN.Visible = 'on';
		lblN.Text = '↓ Max. # Rectangles';
		lblN.HorizontalAlignment = 'center';
		%lblN.VerticalAlignment = 'bottom';
		lblN.Layout.Row = 1;
		lblN.Layout.Column = 1;
		%
		spinN = uispinner(glRC);
		spinN.BackgroundColor = clrIn;
		spinN.Visible = 'on';
		spinN.Limits = [1,Inf];
		spinN.Step = 1;
		spinN.Value = stpo.maxN;
		spinN.RoundFractionalValues = 'on';
		spinN.ValueChangedFcn = {@flb2OptionsClBk,'maxN'};
		spinN.Layout.Row = 2;
		spinN.Layout.Column = 1;
		spinN.Tooltip = 'Option <maxN>: the maximum number of rectangles';
		%
		CName = {'Area';   'Height';  'Width'};
		CUnit = {'pixels'; 'rows';    'columns'};
		CWord = {'Minimum', 'Maximum'};
		numNm = numel(CName);
		numWd = numel(CWord);
		cstrDef(numNm,numWd) = struct('label','','field','','tooltip','');
		%
		% Couple min/max values
		for ii = 1:numNm
			for jj = 1:numWd
				fld = [lower(CWord{jj}(1:3)),CName{ii}];
				cstrDef(ii,jj).label = sprintf('↓ %s%s',CWord{jj}(1:3),CName{ii}(1));
				cstrDef(ii,jj).field = fld;
				cstrDef(ii,jj).tooltip = sprintf('Option <%s>: %s rectangle %s (%s)',...
					fld, lower(CWord{jj}), lower(CName{ii}), CUnit{ii});
			end
		end
		%
		cstrSpn = gobjects(numNm,numWd);
		%
		for ii = 1:numNm
			for jj = 1:numWd
				lbl = uilabel(gl2C);
				lbl.Visible = 'on';
				lbl.Text = cstrDef(ii,jj).label;
				lbl.HorizontalAlignment = 'center';
				lbl.Layout.Row = 2*ii-1;
				lbl.Layout.Column = jj;
				%
				spn = uispinner(gl2C);
				spn.BackgroundColor = clrIn;
				spn.Visible = 'on';
				spn.Limits = [1,Inf];
				spn.Step = 1;
				spn.Value = stpo.(cstrDef(ii,jj).field);
				spn.RoundFractionalValues = 'on';
				%spn.ValueChangedFcn = {@flb2OptionsClBk, cstrDef(ii,jj).field};
				spn.Layout.Row = 2*ii;
				spn.Layout.Column = jj;
				spn.Tooltip = cstrDef(ii,jj).tooltip;
				cstrSpn(ii,jj) = spn;
			end
		end
		bFcns = {@max, @min};
		for ii = 1:numNm
			for jj = 1:numWd
				pSpn = cstrSpn(ii,3-jj);
				pFld = cstrDef(ii,3-jj).field;
				cstrSpn(ii,jj).ValueChangedFcn = {@flb2OptionsClBk, cstrDef(ii,jj).field, pSpn, pFld, bFcns{jj}};
			end
		end
		cstrFlds = {cstrDef.field};
		%
		%% Main Axes
		%
		uip1 = uipanel(glMG);
		uip1.BorderType = 'none';
		uip1.BorderWidth = 0;
		uip1.Title = '';
		uip1.Layout.Row = 1;
		uip1.Layout.Column = 1;
		%
		ax0 = uiaxes(uip1);
		ax0.XLim = 0:1;
		ax0.YLim = 0:1;
		ax0.XTick = [];
		ax0.YTick = [];
		ax0.Box = 'off';
		ax0.Visible = 'off';
		ax0.Toolbar.Visible = 'off';
		ax0.Units = 'normalized';
		ax0.Position = [0,0,1,1];
		ax0.PositionConstraint = 'outerposition';
		ax0.NextPlot = 'add';
		text(ax0, 0.5, 0.5, 'Empty Mask!', 'Visible','on',...
			'HorizontalAlignment','center','Color',[1,0,0],...
			'VerticalAlignment','middle', 'FontSize',14)
		%
		% Single shared axes for all examples
		mask = egMat(actIdx).current;
		[szY,szX] = size(mask);
		%
		axh = axes(uip1); % AXES are the only reliable way to get precise position control.
		axh.XLim = [0.5,max(1,szX)+0.5];
		axh.YLim = [0.5,max(1,szY)+0.5];
		axh.XTick = [];
		axh.YTick = [];
		axh.XLabel.String = '';
		axh.YLabel.String = '';
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
		uip1.AutoResizeChildren = 'off';
		uip1.SizeChangedFcn = @(~,~)set([ax0,axh],'Position',[0,0,1,1], 'Units','normalized');
		%
		% Shared image
		imh = imagesc(axh, mask, 'ButtonDownFcn',@flb2ClickClBk);
		uistack(imh,'bottom')
		%
		% Initial text pool for the active example
		if numel(mask)
			matC = char('0'+mask);
			[matX,matY] = meshgrid(1:szX,1:szY);
			txPool = text(axh, matX(:), matY(:), matC(:),...
				'HorizontalAlignment','center', 'Color',clrF,...
				'VerticalAlignment','middle', 'FontSize',10,...
				'ButtonDownFcn',@flb2ClickClBk);
			txPool = reshape(txPool,szY,szX);
		else
			txPool = gobjects(0,0);
		end
		%
		% Initialise rectangle store for all examples
		for jjj = 1:numel(egMat)
			egMat(jjj).rectangles = gobjects(0);
		end
		%
		%% Mask Size
		%
		lblY = uilabel(glBR);
		lblY.Visible = 'on';
		lblY.Text = 'Rows:';
		lblY.HorizontalAlignment = 'right';
		lblY.Layout.Row = 1;
		lblY.Layout.Column = 1;
		%
		spinY = uispinner(glBR);
		spinY.Visible = 'on';
		spinY.Limits = [0,Inf];
		spinY.Step = 1;
		spinY.Value = szY;
		spinY.RoundFractionalValues = 'on';
		spinY.ValueChangedFcn = {@flb2SpinClBk,'rows'};
		spinY.Layout.Row = 1;
		spinY.Layout.Column = 2;
		spinY.Tooltip = 'Number of rows in the current example';
		%
		lblX = uilabel(glBR);
		lblX.Visible = 'on';
		lblX.Text = 'Columns:';
		lblX.HorizontalAlignment = 'right';
		lblX.Layout.Row = 1;
		lblX.Layout.Column = 3;
		%
		spinX = uispinner(glBR);
		spinX.Visible = 'on';
		spinX.Limits = [0,Inf];
		spinX.Step = 1;
		spinX.Value = szX;
		spinX.RoundFractionalValues = 'on';
		spinX.ValueChangedFcn = {@flb2SpinClBk,'cols'};
		spinX.Layout.Row = 1;
		spinX.Layout.Column = 4;
		spinX.Tooltip = 'Number of columns in the current mask';
		%
		%% Examples Menu
		%
		txtCase = uilabel(glBR);
		txtCase.Visible = 'on';
		txtCase.Text = 'Example:';
		txtCase.HorizontalAlignment = 'right';
		txtCase.Layout.Row = 1;
		txtCase.Layout.Column = 5;
		%
		drpCase = uidropdown(glBR);
		drpCase.Visible = 'on';
		drpCase.Items = {egMat.name};
		drpCase.Layout.Row = 1;
		drpCase.Layout.Column = [6,7];
		drpCase.Tooltip = 'Select preset example or user mask';
		drpCase.ValueChangedFcn = @flb2DropClBk;
		%
		btnReset = uibutton(glBR);
		btnReset.Visible = 'on';
		btnReset.Text = 'Reset';
		btnReset.Layout.Row = 1;
		btnReset.Layout.Column = 8;
		btnReset.Tooltip = 'Reset the current mask to original values and dimensions';
		btnReset.ButtonPushedFcn = @flb2ResetClBk;
		%
		%% Output Display
		%
		lblBbox = uilabel(glBR);
		lblBbox.Visible = 'on';
		lblBbox.Text = '↓ [r1,r2,c1,c2]';
		lblBbox.HorizontalAlignment = 'left';
		lblBbox.Layout.Row = 2;
		lblBbox.Layout.Column = [3,4];
		%
		txtBbox = uitextarea(glBR);
		txtBbox.BackgroundColor = clrOut;
		txtBbox.Visible = 'on';
		txtBbox.Value = 'X';
		txtBbox.Editable = false;
		txtBbox.Layout.Row = 3;
		txtBbox.Layout.Column = [3,4];
		txtBbox.Tooltip = '1st output <bbox>: the rectangle corner indices';
		%
		lblDims = uilabel(glBR);
		lblDims.Visible = 'on';
		lblDims.Text = '↓ [h,w]';
		lblDims.HorizontalAlignment = 'left';
		lblDims.Layout.Row = 2;
		lblDims.Layout.Column = [1,2];
		%
		txtDims = uitextarea(glBR);
		txtDims.BackgroundColor = clrOut;
		txtDims.Visible = 'on';
		txtDims.Value = 'X';
		txtDims.Editable = false;
		txtDims.Layout.Row = 3;
		txtDims.Layout.Column = [1,2];
		txtDims.Tooltip = '2nd output <dims>: the rectangle sizes/dimensions';
		%
		lblArea = uilabel(glBR);
		lblArea.Visible = 'on';
		lblArea.Text = 'Area:';
		lblArea.HorizontalAlignment = 'right';
		lblArea.Layout.Row = 2;
		lblArea.Layout.Column = [6,7];
		%
		txtArea = uieditfield(glBR,'numeric');
		txtArea.BackgroundColor = clrOut;
		txtArea.Visible = 'on';
		txtArea.Value = 0;
		txtArea.Editable = false;
		txtArea.Layout.Row = 2;
		txtArea.Layout.Column = 8;
		txtArea.Tooltip = '3rd output <area>: the rectangle area';
		%
		lblInfo = uilabel(glBR);
		lblInfo.Visible = 'on';
		lblInfo.Text = '↓ Info';
		lblInfo.HorizontalAlignment = 'left';
		lblInfo.Layout.Row = 2;
		lblInfo.Layout.Column = [5,6];
		%
		txtInfo = uitextarea(glBR);
		txtInfo.BackgroundColor = clrOut;
		txtInfo.Visible = 'on';
		txtInfo.Value = 'X';
		txtInfo.Editable = false;
		txtInfo.FontColor = fgc;
		txtInfo.FontName = 'monospaced';
		txtInfo.Layout.Row = 3;
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
		Lab(:,1) = 0.55 + 0.20*clrF(1); % 0.55 light mode, 0.75 dark mode.
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
function S = flb2DemoMasks()
% Define some preset 2D binary masks for the example dropdown.
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%flb2DemoMasks
% Copyright (c) 2026 Stephen Cobeldick
%
% Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%license