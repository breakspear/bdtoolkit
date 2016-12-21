%bdGetValue  Read a named value from a pardef/vardef/lagdef cell array.
%Usage:
%   val = bdGetValue(xxxdef,'name')
%where
%   xxxdef is the incoming pardef, vardef, lagdef or auxdef cell array.
%   name is the string name of the element to be updated.
%   val is the corresponding value found in the cell array or [] if
%     no mathcing name field was found.
%
%EXAMPLE
%  pardef = {'a',1; 'b',[2 3 4]; 'c',5};
%  val = bdGetValue(pardef,'b')
%
%  val =
%     2     3     4
%  
%AUTHORS
%  Stewart Heitmann (2016a)

% Copyright (c) 2016, Queensland Institute Medical Research (QIMR)
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
function val = bdGetValue(xxxdef,name)
    val = [];
    nvar = size(xxxdef,1);
    for indx=1:nvar
        if strcmp(xxxdef{indx,1},name)==1
            val = xxxdef{indx,2};
            return
        end
    end
    warning('bdUtils.getValue() failed to find a matching name');
end
