classdef test_flb_fun < handle
	% Class for comparing actual function output against expected output.
	%
	%% Dependencies %%
	%
	% * MATLAB R2009b or later.
	%
	% See also 
	properties
		funHnd % handle to function under test
		prgBar % handle to waitbar
		fmtOTL % format string open-to-line
		inpArg = {}; % input arguments
		outExp = {}; % expected output arguments
		cntNow = 0; % count of current test
		cntTot = 0; % count of all tests
		cntFld = 0; % count of failed tests
		cntFlg = true; % count vs compare
	end
	methods
		function obj = test_flb_fun(fnh) % constructor
			dbs = dbstack();
			fmt = '%s|%3d:';
			try %#ok<TRYNC> Octave
				if feature('hotlinks')
					fmt = '<a href="matlab:opentoline(''%1$s'',%2$d)">%1$s|%2$d:</a>';
				end
			end
			obj.funHnd = fnh;
			obj.fmtOTL = fmt;
			obj.prgBar = waitbar(0,'Counting tests...', 'IntegerHandle','off', 'Name',dbs(2).name);
			drawnow()
		end
		function warn(obj,txt) % warning text
			if obj.cntFlg
				warning(txt)
			end
		end
		function out = o(obj,varargin) % expected outputs
			obj.outExp = varargin;
			if nargout
				out = obj;
			else
				obj.check();
			end
		end
		function out = i(obj,varargin) % input arguments
			obj.inpArg = varargin;
			if nargout
				out = obj;
			else
				obj.check();
			end
		end
		function start(obj) % start execution
			obj.cntFlg = false;
			waitbar(0,obj.prgBar,'Starting tests...');
			drawnow()
		end
		function finish(obj) % finish execution
			dbs = dbstack();
			fprintf(obj.fmtOTL, dbs(2).file, dbs(2).line);
			fprintf(' %d of %d tests failed.\n', obj.cntFld, obj.cntTot)
			close(obj.prgBar);
		end
		function check(obj) % compare expected against actual output
			if obj.cntFlg % count
				obj.cntTot = obj.cntTot + 1;
			else % execute & compare
				obj.cntNow = obj.cntNow + 1;
				waitbar(obj.cntNow/obj.cntTot, obj.prgBar, sprintf('Running test %d of %d', obj.cntNow, obj.cntTot));
				drawnow()
				dbs = dbstack();
				inC = obj.inpArg;
				xpC = obj.outExp;
				opC =  cell(size(xpC));
				boo = false(size(xpC));
				[opC{:}] = obj.funHnd(inC{:});
				for k = 1:numel(xpC)
					opA = opC{k};
					xpA = xpC{k};
					if isequal(xpA,@i)
						% ignore this output
					elseif ~isequal(class(opA),class(xpA))
						boo(k) = true;
						opT = class(opA);
						xpT = class(xpA);
					elseif ~isequal(opA,xpA)
						boo(k) = true;
						opT = flbPretty(opA);
						xpT = flbPretty(xpA);
					end
					if boo(k)
						dmn = min(numel(opT),numel(xpT));
						dmx = max(numel(opT),numel(xpT));
						erT = repmat('^',1,dmx);
						erT(opT(1:dmn)==xpT(1:dmn)) = ' ';
						%
						fprintf(obj.fmtOTL, dbs(3).file, dbs(3).line);
						fprintf(' (output #%d)\n',k);
						fprintf('actual: %s\n', opT);
						fprintf('expect: %s\n', xpT);
						fprintf('     \x394: ')
						fprintf(2,'%s\n',erT); % red!
					end
				end
				obj.cntFld = obj.cntFld + any(boo);
				obj.inpArg = {};
			end
		end
	end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%test_flb_fun
function out = flbPretty(inp)
if isempty(inp)|| ndims(inp)>2 %#ok<ISMAT>
	out = sprintf('x%u',size(inp));
	out = sprintf('%s %s',out(2:end),class(inp));
elseif isnumeric(inp) || islogical(inp)
	out = regexprep(mat2str(inp,23),'\s+',',');
elseif ischar(inp)
	if size(inp,1)>1
		out = mat2str(inp,15);
	else
		out = sprintf('''%s''',inp);
	end
elseif isa(inp,'string')
	if isscalar(inp)
		out = sprintf('"%s"',inp);
	else
		fmt = repmat(',"%s"',1,size(inp,2));
		out = sprintf([';',fmt(2:end)],inp.');
		out = sprintf('[%s]',out(2:end));
	end
elseif iscell(inp)
	tmp = cellfun(@flbPretty,inp.','uni',0);
	fmt = repmat(',%s',1,size(inp,2));
	out = sprintf([';',fmt(2:end)],tmp{:});
	out = sprintf('{%s}',out(2:end));
else
	error('Class "%s" is not supported.',class(inp))
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%flbPretty
% Copyright (c) 2012-2026 Stephen Cobeldick
%
% Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%license