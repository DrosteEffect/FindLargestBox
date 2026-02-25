function [bbox,dims,volume,info] = findLargestBox3D_GUI(varargin)
% Interactive demonstration of findLargestBox3D cuboid finder.
%
% Tri-planar slice GUI for demonstrating the findLargestBox3D largest
% cuboid finder. Three synchronised slice views (row, column, page) show
% the boolean mask with colored outlines of any identified cuboids.
%
%%% Syntax %%%
%
%   findLargestBox3D_GUI()
%   findLargestBox3D_GUI(mask)
%   findLargestBox3D_GUI(vxR,vxC,vxP)
%   findLargestBox3D_GUI(...,<name-value options>)
%   [bbox,dims,volume,info] = findLargestBox3D_GUI(...)
%
%% Input Arguments %%
%
% As per findLargestBox3D. If no inputs are provided a demo mask is used.
%
%% Output Arguments %%
%
% As per findLargestBox3D. Outputs are captured when the GUI window closes.
%
%% Dependencies %%
%
% * MATLAB R2020b or later.
% * findLargestBox3D.m
%
% See also FINDLARGESTBOX3D FINDLARGESTBOX2D FINDLARGESTBOX2D_GUI
persistent fgh fgc axArr imArr recArr sldArr edtArr grdArr ...
	spinN cstrSpn cstrFlds stpo egArr actIdx actCand memFun ...
	clr0 clr1 clrF clrIn clrOut drpCase txtBbox txtDims txtVol txtInfo ...
	bboxOut dimsOut volOut infoOut btnPrev btnNext lblCand
% R2020b: uigridlayout, uislider, disableDefaultInteractivity
% R2017a: memoize
% R2016a: uifigure
%
%% Default Option Values %%
%
stpo = struct('maxN',Inf, ...
	'minVolume',1, 'maxVolume',Inf, ...
	'minHeight',1, 'maxHeight',Inf, ...
	'minWidth' ,1, 'maxWidth' ,Inf, ...
	'minDepth' ,1, 'maxDepth' ,Inf);
%
%% Input Wrangling %%
%
egArr = flb3DemoMasks();
%
ido = cellfun(@(a)isnumeric(a)||islogical(a), varargin);
id1 = find([~ido, true], 1, 'first');
%
switch id1
	case 1  % do nothing
	case 2  % mask array
		egArr(end+1).name  = 'User Volume';
		egArr(end).default = flb3ParseMask(varargin{1});
	case 4  % index vectors
		egArr(end+1).name  = 'User Indices';
		egArr(end).default = flb3Idx2Mask(varargin{1:3});
	otherwise
		error('SC:findLargestBox3D_GUI:unsupportedInputs', ...
			'Either one 3D array (mask) or three index vectors (vxR,vxC,vxP) are supported.')
end
%
egArr = egArr(end:-1:1);
[egArr.current] = deal(egArr.default);
%
%% Parse Options %%
%
varg = varargin(id1:end);
dfns = fieldnames(stpo);
%
if isscalar(varg) && isstruct(varg{1})
	opts = varg{1};
	fnms = fieldnames(opts);
	for kk = 1:numel(fnms)
		ixR = strcmpi(fnms{kk}, dfns);
		if any(ixR)
			stpo.(dfns{ixR}) = opts.(fnms{kk});
		end
	end
else
	for kk = 1:2:numel(varg)
		if ischar(varg{kk}) || isstring(varg{kk})
			ixR = strcmpi(varg{kk}, dfns);
			if any(ixR)
				stpo.(dfns{ixR}) = varg{kk+1};
			end
		else
			error('SC:findLargestBox3D_GUI:notNameValuePairs', ...
				'Options must be supplied as a scalar struct or as name-value pairs.')
		end
	end
end
%
%% Figure Creation / Reuse %%
%
if isempty(fgh) || ~ishghandle(fgh)
	actIdx  = 1;
	actCand = 0;
	bboxOut = [];
	dimsOut = [];
	volOut  = 0;
	infoOut = struct();
	flb3NewFigure()
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
	memFun = memoize(@findLargestBox3D);
end
%
flb3DropClBk()
%
%% Output Handling %%
%
if nargout
	waitfor(fgh)
	[bbox, dims, volume, info] = memFun(egArr(actIdx).current,stpo);
else
	clear bbox
end
%
%% Callback Functions %%
%
	function flb3UpdateGrid()
		% Draw new grid lines and store their handles.
		%
		hh = vertcat(grdArr{:});
		delete(hh(ishghandle(hh)))
		%
		for si = 1:3
    		xv = 0.5:1:axArr(si).XLim(2);
			yv = 0.5:1:axArr(si).YLim(2);
			hx = plot(axArr(si), [xv;xv], repmat(axArr(si).YLim.',1,numel(xv)), ...
				'Color',[fgc,0.2], 'LineWidth',1, 'HitTest','off', 'PickableParts','none');
			hy = plot(axArr(si), repmat(axArr(si).XLim.',1,numel(yv)), [yv;yv], ...
				'Color',[fgc,0.2], 'LineWidth',1, 'HitTest','off', 'PickableParts','none');
			grdArr{si} = [hx(:);hy(:)];
		end
		%
		cellfun(@(r) uistack(r(ishghandle(r)), 'top'), recArr);
	end
%
	function flb3ClickClBk(~, ~, sliceId)
		% Click on a slice image or axes to toggle the voxel under the cursor.
		%
		sm = struct('row',1,'column',2,'page',3);
		ax = axArr(sm.(sliceId));
		%
		mcp = ax.CurrentPoint; % 2x3; row 1 = near plane position
		xcp = round(mcp(1,1));
		ycp = round(mcp(1,2));
		%
		mask = egArr(actIdx).current;
		[nR,nC,nP] = size(mask);
		curR = round(sldArr(1).Value);
		curC = round(sldArr(2).Value);
		curP = round(sldArr(3).Value);
		%
		% Map clicked (xcp,ycp) and fixed slider index to (row,col,page).
		switch sliceId
			case 'row'
				jxR = curR; jxC = ycp;  jxP = xcp;
			case 'column'
				jxR = ycp;  jxC = curC; jxP = xcp;
			case 'page'
				jxR = ycp;  jxC = xcp;  jxP = curP;
		end
		%
		% Reject clicks outside the valid voxel range.
		if any([jxR,jxC,jxP]<1) || jxR>nR || jxC>nC || jxP>nP
			return
		end
		%
		% Toggle the voxel and refresh.
		egArr(actIdx).current(jxR,jxC,jxP) = ~mask(jxR,jxC,jxP);
		%
		% mask = egArr(actIdx).current;
		% fprintf('%d x %d x %d\n',size(mask))
		% fprintf(',%d',find(mask))
		% fprintf('\n')
		%
		flb3UpdateSlices()
		flb3ComputeAndDisplay()
	end
%
	function flb3ResetClBk(~, ~)
		% Reset the active example to its default mask and recompute.
		%
		egArr(actIdx).current = egArr(actIdx).default;
		%
		mask = egArr(actIdx).current;
		%
		[nR,nC,nP] = size(mask);
		nR = max(nR,1);
		nC = max(nC,1);
		nP = max(nP,1);
		%
		flb3SetSlider(sldArr(1), edtArr(1), nR)
		flb3SetSlider(sldArr(2), edtArr(2), nC)
		flb3SetSlider(sldArr(3), edtArr(3), nP)
		%
		axArr(1).XLim = [0.5,nP+0.5];  axArr(1).YLim = [0.5,nC+0.5];
		axArr(2).XLim = [0.5,nP+0.5];  axArr(2).YLim = [0.5,nR+0.5];
		axArr(3).XLim = [0.5,nC+0.5];  axArr(3).YLim = [0.5,nR+0.5];
		%
		flb3UpdateGrid()
		flb3UpdateSlices()
		flb3ComputeAndDisplay()
	end
%
	function flb3SliderClBk(~, event, flag)
		% Fired by both ValueChangingFcn (drag) and ValueChangedFcn (release).
		val = round(event.Value);
		switch flag
			case 'row'
				val = min(max(val,1), sldArr(1).Limits(2));
				sldArr(1).Value = val;
				edtArr(1).Value = val;
			case 'column'
				val = min(max(val,1), sldArr(2).Limits(2));
				sldArr(2).Value = val;
				edtArr(2).Value = val;
			case 'page'
				val = min(max(val,1), sldArr(3).Limits(2));
				sldArr(3).Value = val;
				edtArr(3).Value = val;
		end
		flb3UpdateSlices()
		flb3UpdateOverlays()
	end
%
	function flb3EdtClBk(src, ~, flag)
		% Spinner next to slider changed: clamp and sync slider.
		switch flag
			case 'row'
				val = min(max(round(src.Value),1), sldArr(1).Limits(2));
				src.Value  = val;
				sldArr(1).Value = val;
			case 'column'
				val = min(max(round(src.Value),1), sldArr(2).Limits(2));
				src.Value  = val;
				sldArr(2).Value = val;
			case 'page'
				val = min(max(round(src.Value),1), sldArr(3).Limits(2));
				src.Value  = val;
				sldArr(3).Value = val;
		end
		flb3UpdateSlices()
		flb3UpdateOverlays()
	end
%
	function flb3OptionsClBk(src, ~, field, pSpn, pFld, bFcn)
		% Constraint/maxN spinner callback with min/max clamping.
		stpo.(field) = src.Value;
		if nargin>3
			pSpn.Value  = bFcn(pSpn.Value, src.Value);
			stpo.(pFld) = pSpn.Value;
		end
		flb3ComputeAndDisplay()
	end
%
	function flb3DropClBk(~, ~)
		% Example selected from the dropdown (or called programmatically).
		if isempty(axArr) || ~ishghandle(axArr(1))
			return
		end
		%
		flb3DeleteOverlays()
		%
		actIdx = drpCase.ValueIndex;
		%
		mask = egArr(actIdx).current;
		%
		[nR,nC,nP] = size(mask);
		nR = max(nR,1);
		nC = max(nC,1);
		nP = max(nP,1);
		%
		flb3SetSlider(sldArr(1), edtArr(1), nR)
		flb3SetSlider(sldArr(2), edtArr(2), nC)
		flb3SetSlider(sldArr(3), edtArr(3), nP)
		%
		axArr(1).XLim = [0.5,nP+0.5];  axArr(1).YLim = [0.5,nC+0.5];
		axArr(2).XLim = [0.5,nP+0.5];  axArr(2).YLim = [0.5,nR+0.5];
		axArr(3).XLim = [0.5,nC+0.5];  axArr(3).YLim = [0.5,nR+0.5];
		%
		flb3UpdateGrid()
		flb3UpdateSlices()
		flb3ComputeAndDisplay()
	end
%
	function flb3NavClBk(~, ~, dirn)
		% Navigate to next (dirn=+1) or previous (dirn=-1) cuboid.
		nCand = size(bboxOut, 1);
		if nCand<1
			return
		end
		actCand = mod(actCand+dirn,nCand+1);
		if actCand
			lblCand.Text = sprintf('%d / %d', actCand, nCand);
		else
			lblCand.Text = 'center';
		end
		flb3CenterOnCand()
		flb3UpdateOverlays()
	end
%
	function flb3ComputeAndDisplay()
		% Run solver, refresh all outputs and overlays.
		fgp = fgh.Pointer;
		fgh.Pointer = 'watch';
		drawnow()
		%
		flb3DeleteOverlays()
		mask = egArr(actIdx).current;
		%
		try
			[bboxOut, dimsOut, volOut, infoOut] = memFun(mask, stpo);
		catch ME
			fgh.Pointer = fgp;
			if startsWith(ME.identifier, 'SC:findLargestBox3D:')
				txtInfo.FontColor = [1,0,0];
				txtInfo.Value     = sprintf('Error: %s', ME.message);
				txtBbox.Value     = '';
				txtDims.Value     = '';
				txtVol.Value      = 0;
			else
				rethrow(ME)
			end
			return
		end
		%
		% Update info display
		fnms     = fieldnames(infoOut);
		dispInfo = rmfield(infoOut, fnms(structfun(@isstruct, infoOut)));
		try
			txt = formattedDisplayText(dispInfo);
		catch
			txt = evalc('disp(dispInfo)');
		end
		txtInfo.FontColor = fgc;
		txtInfo.Value     = txt;
		%
		if isempty(bboxOut)
			txtBbox.Value  = '[]';
			txtDims.Value  = '[]';
			txtVol.Value   = 0;
			actCand        = 0;
			lblCand.Text   = '0 / 0';
			btnPrev.Enable = 'off';
			btnNext.Enable = 'off';
		else % bbox is Nx6: [r1,r2,c1,c2,p1,p2] per row
			txtBbox.Value = compose('[%d,%d, %d,%d, %d,%d]', bboxOut);
			txtDims.Value = compose('[%d,%d,%d]', dimsOut);
			txtVol.Value  = volOut;
			actCand       = 0;
			flb3CreateOverlays()
			flb3UpdateOverlays()
			nCand          = size(bboxOut, 1);
			lblCand.Text   = 'center';
			btnPrev.Enable = flb3OnOff(nCand>0);
			btnNext.Enable = flb3OnOff(nCand>0);
		end
		%
		fgh.Pointer = fgp;
		drawnow()
	end
%
%% Inner Helper Functions %%
%
	function flb3UpdateSlices()
		% Refresh all three slice images from current mask and slider positions.
		mask = egArr(actIdx).current;
		%
		%% Images %%
		%
		if isempty(mask)
			imArr(1).CData = false;
			imArr(2).CData = false;
			imArr(3).CData = false;
			return
		end
		%
		[nR,nC,nP] = size(mask);
		curP = min(round(sldArr(3).Value), nP);
		curR = min(round(sldArr(1).Value), nR);
		curC = min(round(sldArr(2).Value), nC);
		%
		imArr(1).CData = logical(permute(mask(curR,:,:), [2,3,1]));
		imArr(2).CData = logical(permute(mask(:,curC,:), [1,3,2]));
		imArr(3).CData = logical(mask(:,:,curP));
		%
		axArr(1).Title.String = sprintf('Slice row = %d'   , round(sldArr(1).Value));
		axArr(2).Title.String = sprintf('Slice column = %d', round(sldArr(2).Value));
		axArr(3).Title.String = sprintf('Slice page = %d'  , round(sldArr(3).Value));
		%
		%% Grid Highlights %%
		%
		hh = vertcat(grdArr{:});
		set(hh(ishghandle(hh)), 'Color', [fgc,0.2]);
		%
		curR = round(sldArr(1).Value);
		curC = round(sldArr(2).Value);
		curP = round(sldArr(3).Value);
		%
		nX1 = round(axArr(1).XLim(2) - 0.5) + 1;
		nX2 = round(axArr(2).XLim(2) - 0.5) + 1;
		nX3 = round(axArr(3).XLim(2) - 0.5) + 1;
		%
		hlnArr{1} = grdArr{1}([curP, curP+1, nX1+curC, nX1+curC+1]);
		hlnArr{2} = grdArr{2}([curP, curP+1, nX2+curR, nX2+curR+1]);
		hlnArr{3} = grdArr{3}([curC, curC+1, nX3+curR, nX3+curR+1]);
		%
		for si = 1:3
			set(hlnArr{si}, 'Color',1-clrF);
		end
	end
%
	function flb3SetSlider(sld, edt, n)
		% Configure a slider+spinner pair for a dimension of size n.
		n   = max(n, 1);
		mid = max(1, round(n/2));
		sld.Limits = [1, max(n,2)];
		sld.Value  = mid;
		sld.Enable = flb3OnOff(n > 1);
		edt.Limits = [1, n];
		edt.Value  = mid;
	end
%
	function flb3DeleteOverlays()
		% Delete all live overlay rectangle handles.
		for si = 1:3
			hh = recArr{si};
			if ~isempty(hh) && any(ishghandle(hh))
				delete(hh(ishghandle(hh)));
			end
			recArr{si} = gobjects(0);
		end
	end
%
	function flb3CreateOverlays()
		% Allocate one rectangle per cuboid per slice view.
		nCand = size(bboxOut, 1);
		if ~nCand
			return
		end
		colors = flb3RectColors(nCand);
		for si = 1:3
			recArr{si} = gobjects(1,nCand);
		end
		for ii = 1:nCand
			r1=bboxOut(ii,1); r2=bboxOut(ii,2);
			c1=bboxOut(ii,3); c2=bboxOut(ii,4);
			p1=bboxOut(ii,5); p2=bboxOut(ii,6);
			ec = colors(ii,:);
			recArr{1}(ii) = rectangle(axArr(1), ...
				'Position', [p1-0.5, c1-0.5, p2-p1+1, c2-c1+1], ...
				'EdgeColor', ec, 'LineWidth', 2, 'Visible', 'off');
			recArr{2}(ii) = rectangle(axArr(2), ...
				'Position', [p1-0.5, r1-0.5, p2-p1+1, r2-r1+1], ...
				'EdgeColor', ec, 'LineWidth', 2, 'Visible', 'off');
			recArr{3}(ii) = rectangle(axArr(3), ...
				'Position', [c1-0.5, r1-0.5, c2-c1+1, r2-r1+1], ...
				'EdgeColor', ec, 'LineWidth', 2, 'Visible', 'off');
		end
	end
%
	function flb3UpdateOverlays()
		% Show or hide rectangles based on current slice positions.
		nCand = size(bboxOut, 1);
		if ~nCand || isempty(recArr{1})
			return
		end
		curR = round(sldArr(1).Value);
		curC = round(sldArr(2).Value);
		curP = round(sldArr(3).Value);
		for ii = 1:nCand
			if ~ishghandle(recArr{1}(ii))
				continue
			end
			r1=bboxOut(ii,1); r2=bboxOut(ii,2);
			c1=bboxOut(ii,3); c2=bboxOut(ii,4);
			p1=bboxOut(ii,5); p2=bboxOut(ii,6);
			show = ~actCand || ii==actCand;
			recArr{1}(ii).Visible = flb3OnOff(show && r1<=curR && curR<=r2);
			recArr{2}(ii).Visible = flb3OnOff(show && c1<=curC && curC<=c2);
			recArr{3}(ii).Visible = flb3OnOff(show && p1<=curP && curP<=p2);
		end
	end
%
	function flb3CenterOnCand()
		% Center sliders on the active cuboid, or reset to midpoints for "all".
		if isempty(bboxOut)
			return
		end
		if ~actCand % "all" view
			flb3SnapSlider(sldArr(1), edtArr(1), round(sldArr(1).Limits(2)/2));
			flb3SnapSlider(sldArr(2), edtArr(2), round(sldArr(2).Limits(2)/2));
			flb3SnapSlider(sldArr(3), edtArr(3), round(sldArr(3).Limits(2)/2));
		else
			r1=bboxOut(actCand,1); r2=bboxOut(actCand,2);
			c1=bboxOut(actCand,3); c2=bboxOut(actCand,4);
			p1=bboxOut(actCand,5); p2=bboxOut(actCand,6);
			flb3SnapSlider(sldArr(1), edtArr(1), round((r1+r2)/2));
			flb3SnapSlider(sldArr(2), edtArr(2), round((c1+c2)/2));
			flb3SnapSlider(sldArr(3), edtArr(3), round((p1+p2)/2));
		end
		flb3UpdateSlices()
	end
%
	function flb3SnapSlider(sld, edt, val)
		val = min(max(val, sld.Limits(1)), sld.Limits(2));
		sld.Value = val;
		edt.Value = val;
	end
%
	function colors = flb3RectColors(N)
		C   = 0.13;
		hue = (4*pi/3) + linspace(0, 2*pi, N+1);
		hue(end) = [];
		Lab = [hue(:), C*cos(hue(:)), C*sin(hue(:))];
		Lab(:,1) = 0.55 + 0.20*clrF(1);
		colors = min(1, max(0, sOKLab2sRGB(Lab)));
	end
%
	function str = flb3OnOff(tf)
		if tf
			str = 'on';
		else
			str = 'off';
		end
	end
%
	function flb3NewFigure()
		%
		fgh = uifigure();
		fgh.Name             = 'Interactive Largest Cuboid Demo';
		fgh.Tag              = mfilename;
		fgh.HandleVisibility = 'off';
		fgh.IntegerHandle    = 'off';
		%
		% Light / dark theme detection via temporary label
		tmpLbl = uilabel(fgh);
		fgc    = tmpLbl.FontColor;
		delete(tmpLbl);
		%
		fgg = fgc * [0.298936; 0.587043; 0.114021]; % perceived luminance
		if fgg < 0.54 % lightmode
			clr0 = [0.80, 0.80, 0.80]; % FALSE
			clr1 = [1.00, 1.00, 1.00]; % TRUE
			clrF = [0,0,0]; % foreground
			clrIn  = [0.75, 0.80, 1.00]; % inputs
			clrOut = [0.92, 0.92, 1.00]; % outputs
		else % darkmode
			clr0 = [0.15, 0.15, 0.15]; % FALSE
			clr1 = [0.42, 0.42, 0.42]; % TRUE
			clrF = [1,1,1]; % foreground
			clrIn  = [0.25, 0.20, 0.00]; % inputs
			clrOut = [0.10, 0.10, 0.20]; % outputs
		end
		%
		recArr = {gobjects(0), gobjects(0), gobjects(0)};
		grdArr = {gobjects(0), gobjects(0), gobjects(0)};
		%
		glMG = uigridlayout(fgh, [3,2]);
		glMG.RowHeight     = {'1x','fit','fit'};
		glMG.ColumnWidth   = {'1x', 123};
		%
		% Slice view
		glSL = uigridlayout(glMG, [1,3]);
		glSL.Padding       = [0,0,0,0];
		glSL.RowHeight     = {'1x'};
		glSL.ColumnWidth   = {'1x','1x','1x'};
		glSL.Layout.Row    = 1;
		glSL.Layout.Column = 1;
		%
		sliceIds    = {    'row', 'column',    'page'};
		sliceXlbls  = {  'pages',  'pages', 'columns'};
		sliceYlbls  = {'columns',   'rows',    'rows'};
		sliceTips   = {...
			'Row slice. Horizontal axis = pages. Vertical axis = columns. Light/dark = usable/blocked voxel. Click to toggle.',...
			'Column slice. Horizontal axis = pages. Vertical axis = rows. Light/dark = usable/blocked voxel. Click to toggle.',...
			'Page slice. Horizontal axis = columns. Vertical axis = rows. Light/dark = usable/blocked voxel. Click to toggle.'};
		%
		axArr = gobjects(1,3);
		imArr = gobjects(1,3);
		%
		for si = 1:3
			pSL = uipanel(glSL);
			pSL.BorderType    = 'none';
			pSL.Layout.Row    = 1;
			pSL.Layout.Column = si;
			%
			ax = axes(pSL); %#ok<LAXES>
			ax.Units         = 'normalized';
			ax.OuterPosition = [0,0,1,1];
			ax.PositionConstraint = 'outerposition';
			ax.XTick         = [];
			ax.YTick         = [];
			ax.XTickLabel    = {};
			ax.YTickLabel    = {};
			ax.TickLength    = [0,0];
			ax.Box           = 'on';
			ax.YDir          = 'normal';
			ax.Colormap      = [clr0; clr1];
			ax.CLim          = [0,1];
			ax.NextPlot      = 'add';
			ax.Toolbar.Visible = 'off';
			ax.Title.String  = 'X';
			ax.XLabel.String = sliceXlbls{si};
			ax.YLabel.String = sliceYlbls{si};
			ax.Title.Color   = fgc;
			ax.XLabel.Color  = fgc;
			ax.YLabel.Color  = fgc;
			ax.XLabel.Rotation = 0;  % horizontal
			ax.YLabel.Rotation = 90; % vertical
			ax.LooseInset = [0,0,0,0];
			try %#ok<TRYNC>
				ax.Tooltip = sliceTips{si};
			end
			%
			% Suppress the datatip dot and wire click-to-toggle.
			ax.ButtonDownFcn = {@flb3ClickClBk, sliceIds{si}};
			%
			im = imagesc(ax, false(1,1));
			im.ButtonDownFcn = {@flb3ClickClBk, sliceIds{si}};
			uistack(im(:), 'bottom');
			%
			pSL.AutoResizeChildren = 'off';
			pSL.SizeChangedFcn = @(~,~)set(ax, 'OuterPosition',[0,0,1,1], 'Units','normalized');
			%
			axArr(si) = ax;
			imArr(si) = im;
		end
		%
		%% Right Panel %%
		%
		% glRC spans the slice and slider rows of the right column.
		% Its bottom aligns with the bottom of the sliders row.
		% It contains ONLY the maxN spinner and dimension/volume constraints.
		%
		glRC = uigridlayout(glMG, [4,1]);
		glRC.Padding       = [0,0,0,0];
		glRC.RowHeight     = {'fit','fit','fit','1x'};
		glRC.ColumnWidth   = {123};
		glRC.Layout.Row    = [1,2];
		glRC.Layout.Column = 2;
		%
		% maximum number of cuboids
		lblN = uilabel(glRC);
		lblN.Text          = '↓ Max. # Cuboids';
		lblN.HorizontalAlignment = 'center';
		lblN.Layout.Row    = 1;
		lblN.Layout.Column = 1;
		%
		spinN = uispinner(glRC);
		spinN.BackgroundColor = clrIn;
		spinN.Limits        = [1,Inf];
		spinN.Step          = 1;
		spinN.Value         = stpo.maxN;
		spinN.RoundFractionalValues = 'on';
		spinN.ValueChangedFcn = {@flb3OptionsClBk,'maxN'};
		spinN.Layout.Row    = 2;
		spinN.Layout.Column = 1;
		spinN.Tooltip = 'Option <maxN>: maximum number of cuboids returned';
		%
		% Constraint spinner sub-grid
		gl2C = uigridlayout(glRC, [8,2]);
		gl2C.Padding       = [0,0,0,0];
		gl2C.RowHeight     = repmat({'fit'},1,8);
		gl2C.ColumnWidth   = {'1x','1x'};
		gl2C.RowSpacing    = 5;
		gl2C.Layout.Row    = 3;
		gl2C.Layout.Column = 1;
		%
		CName = {'Volume';  'Height'; 'Width';   'Depth'};
		CUnit = {'voxels';  'rows';   'columns'; 'pages'};
		CWord = {'Minimum', 'Maximum'};
		numNm = numel(CName);
		numWd = numel(CWord);
		%
		cstrDef(numNm,numWd) = struct('label','','field','','tooltip','');
		for ii = 1:numNm
			for jj = 1:numWd
				fld = [lower(CWord{jj}(1:3)),CName{ii}];
				cstrDef(ii,jj).label = sprintf('↓ %s%s',CWord{jj}(1:3),CName{ii}(1));
				cstrDef(ii,jj).field = fld;
				cstrDef(ii,jj).tooltip = sprintf( ...
					'Option <%s>: %s cuboid %s (%s)', fld, ...
					lower(CWord{jj}), lower(CName{ii}), CUnit{ii});
			end
		end
		%
		cstrSpn = gobjects(numNm, numWd);
		for ii = 1:numNm
			for jj = 1:numWd
				lbl = uilabel(gl2C);
				lbl.Text          = cstrDef(ii,jj).label;
				lbl.HorizontalAlignment = 'center';
				lbl.Layout.Row    = 2*ii-1;
				lbl.Layout.Column = jj;
				%
				spn = uispinner(gl2C);
				spn.BackgroundColor = clrIn;
				spn.Limits        = [1,Inf];
				spn.Step          = 1;
				spn.Value         = stpo.(cstrDef(ii,jj).field);
				spn.RoundFractionalValues = 'on';
				spn.Layout.Row    = 2*ii;
				spn.Layout.Column = jj;
				spn.Tooltip       = cstrDef(ii,jj).tooltip;
				cstrSpn(ii,jj) = spn;
			end
		end
		%
		% Couple min/max values.
		bFcns = {@max, @min};
		for ii = 1:numNm
			for jj = 1:numWd
				pSpn = cstrSpn(ii, 3-jj);
				pFld = cstrDef(ii, 3-jj).field;
				cstrSpn(ii,jj).ValueChangedFcn = { ...
					@flb3OptionsClBk, cstrDef(ii,jj).field, pSpn, pFld, bFcns{jj}};
			end
		end
		cstrFlds = {cstrDef.field};
		%
		%% Sliders Row %%
		%
		mask0 = egArr(actIdx).current;
		[nR0, nC0, nP0] = size(mask0);
		nR0=max(nR0,1);  nC0=max(nC0,1);  nP0=max(nP0,1);
		%
		glSLD = uigridlayout(glMG, [3,3]);
		glSLD.Padding       = [0,0,0,0];
		glSLD.RowHeight     = {'fit','fit','fit'};
		glSLD.ColumnWidth   = {'fit','1x','fit'};
		glSLD.RowSpacing    = 2;
		glSLD.Layout.Row    = 2;
		glSLD.Layout.Column = 1;
		%
		sldDef = { ...
			'Row:',    'row', nR0; ...
			'Col:', 'column', nC0; ...
			'Page:',  'page', nP0};
		%
		sldArr = gobjects(1,3);
		edtArr = gobjects(1,3);
		for si = 1:3
			tt = sprintf('Modify the %s slice',sldDef{si,2});
			%
			flag = sldDef{si,2};
			n    = sldDef{si,3};
			mid  = max(1, round(n/2));
			%
			lbl = uilabel(glSLD);
			lbl.Text          = sldDef{si,1};
			lbl.HorizontalAlignment = 'right';
			lbl.Layout.Row    = si;
			lbl.Layout.Column = 1;
			%
			sld = uislider(glSLD);
			sld.Limits        = [1, max(n,2)];
			sld.Value         = mid;
			sld.MajorTicks    = [];
			sld.MinorTicks    = [];
			sld.Enable        = flb3OnOff(n > 1);
			sld.ValueChangedFcn  = {@flb3SliderClBk, flag};
			sld.ValueChangingFcn = {@flb3SliderClBk, flag};
			sld.Tooltip       = tt;
			sld.Layout.Row    = si;
			sld.Layout.Column = 2;
			%
			edt = uispinner(glSLD);
			edt.Limits        = [1,n];
			edt.Value         = mid;
			edt.Step          = 1;
			edt.RoundFractionalValues = 'on';
			edt.ValueChangedFcn = {@flb3EdtClBk, flag};
			edt.Tooltip       = tt;
			edt.Layout.Row    = si;
			edt.Layout.Column = 3;
			%
			sldArr(si) = sld;
			edtArr(si) = edt;
		end
		%
		%% Bottom Row %%
		%
		glBR = uigridlayout(glMG, [3,8]);
		glBR.Padding       = [0,0,0,0];
		glBR.RowHeight     = {'fit','fit','fit'};
		glBR.ColumnWidth   = {'2x','fit','fit','2x','fit','2x','1x','1x'};
		glBR.Layout.Row    = 3;
		glBR.Layout.Column = [1,2];
		%
		%% Row 1 — controls %%
		%
		lblTemp = uilabel(glBR);
		lblTemp.Visible = 'off';
		lblTemp.Text          = '999 / 999';
		lblTemp.Layout.Row    = 1;
		lblTemp.Layout.Column = [2,3];
		%
		lblCand = uilabel(glBR);
		lblCand.Text          = '0 / 0';
		lblCand.HorizontalAlignment = 'center';
		lblCand.Layout.Row    = 1;
		lblCand.Layout.Column = [2,3];
		%
		btnPrev = uibutton(glBR);
		btnPrev.Text          = '◀ Prev';
		btnPrev.Enable        = 'off';
		btnPrev.Tooltip = 'Center view on previous cuboid';
		btnPrev.ButtonPushedFcn = {@flb3NavClBk,-1};
		btnPrev.Layout.Row    = 1;
		btnPrev.Layout.Column = 1;
		%
		btnNext = uibutton(glBR);
		btnNext.Text          = 'Next ▶';
		btnNext.Enable        = 'off';
		btnNext.Tooltip = 'Center view on next cuboid';
		btnNext.ButtonPushedFcn = {@flb3NavClBk,+1};
		btnNext.Layout.Row    = 1;
		btnNext.Layout.Column = 4;
		%
		lblCase = uilabel(glBR);
		lblCase.Text          = 'Example:';
		lblCase.HorizontalAlignment = 'right';
		lblCase.Layout.Row    = 1;
		lblCase.Layout.Column = 5;
		%
		drpCase = uidropdown(glBR);
		drpCase.Items         = {egArr.name};
		drpCase.Tooltip = 'Select a preset or user-supplied 3D volume';
		drpCase.ValueChangedFcn = @flb3DropClBk;
		drpCase.Layout.Row    = 1;
		drpCase.Layout.Column = [6,7];
		%
		btnReset = uibutton(glBR);
		btnReset.Text          = 'Reset';
		btnReset.Tooltip = 'Reset the current mask to its original values';
		btnReset.ButtonPushedFcn = @flb3ResetClBk;
		btnReset.Layout.Row    = 1;
		btnReset.Layout.Column = 8;
		%
		%% Row 2 — output labels %%
		%
		lblDims = uilabel(glBR);
		lblDims.Text          = '↓ [h,w,d]';
		lblDims.HorizontalAlignment = 'left';
		lblDims.Layout.Row    = 2;
		lblDims.Layout.Column = [1,2];
		%
		lblBbox = uilabel(glBR);
		lblBbox.Text          = '↓ [r1,r2,c1,c2,p1,p2]';
		lblBbox.HorizontalAlignment = 'left';
		lblBbox.Layout.Row    = 2;
		lblBbox.Layout.Column = [3,4];
		%
		lblInfo = uilabel(glBR);
		lblInfo.Text          = '↓ Info';
		lblInfo.HorizontalAlignment = 'left';
		lblInfo.Layout.Row    = 2;
		lblInfo.Layout.Column = 5;
		%
		lblVol = uilabel(glBR);
		lblVol.Text          = 'Volume:';
		lblVol.HorizontalAlignment = 'right';
		lblVol.Layout.Row    = 2;
		lblVol.Layout.Column = 7;
		%
		txtVol = uieditfield(glBR, 'numeric');
		txtVol.BackgroundColor = clrOut;
		txtVol.Value         = 0;
		txtVol.Editable      = false;
		txtVol.Tooltip = '3rd output <volume>: volume of the largest cuboid in voxels';
		txtVol.Layout.Row    = 2;
		txtVol.Layout.Column = 8;
		%
		%% Row 3 — output text areas %%
		%
		txtDims = uitextarea(glBR);
		txtDims.BackgroundColor = clrOut;
		txtDims.Editable      = false;
		txtDims.Value         = 'X';
		txtDims.Tooltip = '2nd output <dims>: cuboid dimensions [h,w,d] in voxels per row';
		txtDims.Layout.Row    = 3;
		txtDims.Layout.Column = [1,2];
		%
		txtBbox = uitextarea(glBR);
		txtBbox.BackgroundColor = clrOut;
		txtBbox.Editable      = false;
		txtBbox.Value         = 'X';
		txtBbox.Tooltip = '1st output <bbox>: corner indices [r1,r2, c1,c2, p1,p2] per row';
		txtBbox.Layout.Row    = 3;
		txtBbox.Layout.Column = [3,4];
		%
		txtInfo = uitextarea(glBR);
		txtInfo.BackgroundColor = clrOut;
		txtInfo.Editable      = false;
		txtInfo.Value         = 'X';
		txtInfo.FontName      = 'monospaced';
		txtInfo.FontColor     = fgc;
		txtInfo.Tooltip = '4th output <info>: algorithm information structure';
		txtInfo.Layout.Row    = 3;
		txtInfo.Layout.Column = [5,8];
		%
	end
%
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%findLargestBox3D_GUI
function rgb = sOKLab2sRGB(Lab)
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%sOKLab2sRGB
function out = sGammaCor(inp)
% Forward sRGB gamma correction: Nx3 linear RGB -> Nx3 sRGB.
idx = inp > 0.0031308;
out = 12.92 * inp;
out(idx) = real(1.055 * inp(idx).^(1/2.4) - 0.055);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%sGammaCor
function mask = flb3ParseMask(input)
% Validate and convert a user-supplied array to a 3D logical mask.
assert(islogical(input) || isnumeric(input), ...
	'SC:findLargestBox3D_GUI:mask:InvalidType', ...
	'1st input <mask> must be a numeric or logical array.')
assert(ndims(input) < 4, ...                           %#ok<ISMAT>
	'SC:findLargestBox3D_GUI:mask:NotVolume', ...
	'1st input <mask> must be a 3D (or lower) array.')
mask = logical(input);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%flb3ParseMask
function mask = flb3Idx2Mask(vxR, vxC, vxP)
% Convert triplet index vectors to a 3D logical mask.
assert(isnumeric(vxR) && isnumeric(vxC) && isnumeric(vxP), ...
	'SC:findLargestBox3D_GUI:indices:NotNumeric', ...
	'Index inputs <vxR>, <vxC>, <vxP> must be numeric.')
vxR = vxR(:); 
vxC = vxC(:);
vxP = vxP(:);
assert(isequal(numel(vxR), numel(vxC), numel(vxP)), ...
	'SC:findLargestBox3D_GUI:indices:SizeMismatch', ...
	'Index inputs <vxR>, <vxC>, <vxP> must have the same length.')
if isempty(vxR)
	mask = false(0,0,0);
	return
end
M = max(vxR);
N = max(vxC);
P = max(vxP);
mask = false(M,N,P);
mask(sub2ind([M,N,P], vxR,vxC,vxP)) = true;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%flb3Idx2Mask
function S = flb3DemoMasks()
% Define some preset 3D binary masks for the example dropdown.
%
S(9).name    = 'Utah Teapot';
S(9).default = false(11,23,15);
S(9).default([80,82,91,92,93,94,95,102,103,104,105,106,113,114,115,116,117,124,125,126,127,128,135,136,137,138,139,146,147,148,157,322,323,324,325,333,334,335,336,337,343,345,347,348,349,354,360,361,365,371,372,376,382,383,387,391,392,393,398,400,401,402,403,410,411,412,413,421,422,423,564,565,566,567,574,575,576,577,578,579,584,585,590,591,592,595,596,602,603,606,613,614,617,624,625,628,635,636,639,646,647,650,651,656,657,658,661,662,666,667,674,675,676,677,685,686,687,806,807,808,816,817,818,819,820,821,826,827,832,833,834,837,844,845,848,856,859,867,870,878,881,889,892,900,903,910,911,914,915,920,921,922,925,926,930,931,938,939,940,941,949,950,1048,1058,1059,1060,1061,1062,1068,1069,1073,1074,1075,1079,1086,1087,1090,1098,1101,1109,1112,1120,1123,1131,1134,1142,1145,1153,1156,1164,1167,1174,1175,1178,1179,1184,1185,1186,1190,1193,1194,1195,1202,1203,1204,1300,1301,1302,1303,1310,1311,1313,1314,1315,1316,1321,1327,1328,1329,1332,1339,1340,1343,1351,1354,1362,1365,1373,1375,1376,1384,1386,1387,1395,1397,1398,1406,1409,1417,1420,1428,1431,1438,1439,1442,1443,1447,1448,1449,1454,1455,1456,1457,1458,1466,1467,1468,1478,1479,1490,1522,1523,1524,1525,1526,1533,1537,1543,1544,1548,1553,1554,1555,1556,1559,1563,1564,1567,1568,1569,1570,1574,1581,1582,1585,1593,1596,1604,1607,1615,1617,1618,1626,1627,1628,1629,1637,1638,1639,1640,1648,1649,1650,1651,1659,1661,1662,1670,1673,1681,1684,1691,1692,1695,1701,1702,1703,1707,1711,1718,1719,1722,1730,1731,1733,1734,1735,1743,1744,1745,1746,1747,1757,1758,1769,1775,1776,1777,1778,1779,1786,1787,1790,1796,1797,1801,1806,1807,1808,1809,1812,1816,1817,1820,1821,1822,1823,1827,1834,1835,1838,1846,1849,1857,1860,1868,1870,1871,1879,1880,1881,1882,1891,1892,1893,1901,1902,1903,1904,1912,1914,1915,1923,1926,1934,1937,1944,1945,1948,1954,1955,1956,1960,1965,1971,1972,1976,1983,1984,1987,1988,1996,1997,1998,1999,2000,2009,2010,2011,2021,2022,2028,2029,2030,2031,2032,2039,2043,2049,2050,2054,2059,2060,2061,2062,2065,2069,2070,2073,2074,2075,2076,2080,2087,2088,2091,2099,2102,2110,2113,2121,2123,2124,2132,2133,2134,2135,2143,2144,2145,2146,2154,2155,2156,2157,2165,2167,2168,2176,2179,2187,2190,2197,2198,2201,2207,2208,2209,2213,2217,2224,2225,2228,2236,2237,2239,2240,2241,2249,2250,2251,2252,2253,2263,2264,2275,2312,2313,2314,2315,2322,2323,2325,2326,2327,2328,2333,2339,2340,2341,2344,2351,2352,2355,2363,2366,2374,2377,2385,2387,2388,2396,2398,2399,2407,2409,2410,2418,2421,2429,2432,2440,2443,2450,2451,2454,2455,2459,2460,2461,2466,2467,2468,2469,2470,2478,2479,2480,2490,2491,2502,2566,2576,2577,2578,2579,2580,2586,2587,2591,2592,2593,2597,2604,2605,2608,2615,2616,2619,2627,2630,2638,2641,2649,2652,2660,2663,2671,2674,2682,2685,2692,2693,2696,2697,2702,2703,2704,2708,2711,2712,2713,2720,2721,2722,2830,2831,2832,2840,2841,2842,2843,2844,2845,2850,2851,2855,2856,2857,2861,2868,2869,2872,2880,2883,2891,2894,2902,2905,2913,2916,2924,2927,2934,2935,2938,2939,2944,2945,2946,2949,2950,2954,2955,2962,2963,2964,2973,2974,3094,3095,3096,3104,3105,3106,3107,3108,3109,3114,3115,3119,3120,3121,3125,3126,3132,3133,3136,3143,3144,3147,3154,3155,3158,3165,3166,3169,3176,3177,3180,3181,3185,3186,3187,3188,3191,3192,3196,3197,3204,3205,3206,3215,3216,3217,3358,3359,3360,3369,3370,3371,3372,3373,3379,3381,3383,3384,3385,3390,3396,3397,3401,3407,3408,3412,3418,3419,3423,3427,3428,3429,3434,3436,3437,3438,3439,3446,3447,3448,3457,3458,3459,3622,3624,3633,3634,3635,3636,3637,3644,3645,3646,3647,3648,3655,3656,3657,3658,3659,3666,3667,3668,3669,3670,3677,3678,3679,3680,3681,3688,3689,3690,3699]) = true;
%
S(8).name    = 'All Usable';
S(8).default = true(7,8,9);
%
S(7).name    = 'All Blocked';
S(7).default = false(7,8,9);
%
S(6).name    = 'One Cuboid';
S(6).default = false(9,9,9);
S(6).default(2:4,7:8,2:5) = true; % 3x2x4 = 24
%
S(5).name    = 'Two Cuboids';
S(5).default = false(9,9,9);
S(5).default(2:4,7:8,2:5) = true; % 3x2x4 = 24
S(5).default(6:7,2:6,2:7) = true; % 2x5x6 = 60
%
S(4).name    = 'Three Cuboids';
S(4).default = false(9,9,9);
S(4).default(2:4,7:8,2:5) = true; % 3x2x4 = 24
S(4).default(6:7,2:6,2:7) = true; % 2x5x6 = 60
S(4).default(2:4,2:5,2:6) = true; % 3x4x5 = 60
%
S(3).name    = 'Four Cuboids';
S(3).default = false(9,9,9);
S(3).default(2:4,7:8,2:5) = true; % 3x2x4 = 24
S(3).default(6:7,2:6,2:7) = true; % 2x5x6 = 60
S(3).default(2:4,2:5,2:6) = true; % 3x4x5 = 60
S(3).default(7:8,8:8,5:7) = true; % 2x1x3 = 6
%
S(2).name    = 'Missing Block';
S(2).default = true(7,8,9);
S(2).default(1:4,1:5,1:6) = false;
%
S(1).name    = 'Random';
S(1).default = logical(randi([0,1], 7,8,9));
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%flb3DemoMasks