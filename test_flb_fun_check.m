function test_flb_fun_check()
% Quick sanity check of the findLargestBox test class.
%
%% Dependencies %%
%
% * MATLAB R2017a or later.
% * test_flb_fun.m
%
% See also TEST_FLB_FUN
obj = test_flb_fun(@deal);
mainfun(obj) % count
obj.start()
mainfun(obj) % check
obj.finish()
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%test_flb_fun_check
function mainfun(chk)
% All should pass:
chk.i([],'',{},"X").o([],'',{},"X")
chk.i(123:4567,NaN).o(123:4567,NaN)
% 1st should pass, 2nd should fail:
chk.i([],[]).o([],'') % double vs char
chk.i([],[]).o([],"") % double vs string
chk.i([],'').o([],{}) % char vs cell
chk.i(true,true,true).o(true,false,true) % true vs false
chk.i(false,[false,false]).o(false,[false,true]) % false vs true
chk.i([1,2,3,4],[5,6,Inf]).o([1,2,3,4],[5,6,NaN]) % Inf vs NaN
chk.i([1,2,3,4],[5,6,7,8]).o([1,2,3,4],[5,6,NaN]) % 4 vs 3 elements
chk.i([1,2,3,4],[5,6,7,8]).o([1,2,3,4],[5;6;7;8]) % row vs column
chk.i(nan(2,3),nan(4,5,6)).o(nan(2,3),nan(4,5,0)) % 120 vs 0 elements
chk.i("",cat(3,"hi","me")).o("",cat(3,"hi","me","!")) % 2 vs 3 elements
chk.i('hello','hello you').o('hello','hello world') % 'you' vs 'world'
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%mainfun
% Copyright (c) 2012-2026 Stephen Cobeldick
%
% Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%license