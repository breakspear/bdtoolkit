%bdSetValue  Write a value in a pardef/vardef/lagdef cell array.
%Usage:
%   yyydef = bdSetValue(xxxdef,'name',val)
%where
%   xxxdef is the incoming pardef, vardef or lagdef cell array.
%   name is the string name of the element to be updated.
%   val is the new value to be applied.
%   yyydef is the returned cell array.
%
%EXAMPLE
%  pardef = [ struct('name','a', 'value', 1);
%             struct('name','b', 'value',[2,3,4]);
%             struct('name','c', 'value',[5 6; 7 8]) ];
%  pardef = bdSetValue(pardef,'b',[3 6 9]);
%  bdGetValue(pardef,'b')
%
%  ans =
%     3     6     9
%  
%AUTHORS
%  Stewart Heitmann (2016a,2017a)

% Copyright (C) 2016-2018 QIMR Berghofer Medical Research Institute
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions
% are met:
%
% 1. Redistributions of source code must retain the above copyright
%    notice, this list of conditions and the following disclaimer.
% 
% 2. Redistributions in binary form must reproduce the above copyright
%    notice, this list of conditions and the following disclaimer in
%    the documentation and/or other materials provided with the
%    distribution.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
% "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
% LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
% FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
% COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
% INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
% BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
% LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
% CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
% LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
% ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.
function yyydef = bdSetValue(xxxdef,name,val)
    yyydef = xxxdef;
    nvar = numel(yyydef);
    for indx=1:nvar
        if strcmp(yyydef(indx).name,name)==1
            yyydef(indx).value = val;
            return
        end
    end
    warning([name, ' not found in xxxdef']);
end
