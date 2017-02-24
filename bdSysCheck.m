function bdSysCheck(sys)
    %bdSysCheck - Verifies the format of a sys struct.
    %Use bdSysCheck to check the validity of a user-defined sys struct.
    %
    %EXAMPLE
    %  >> sys = LinearODE2D();
    %  >> bdSysCheck(sys);
    %
    %  sys struct format is OK
    %  Calling Y = sys.odefun(t,Y0,a,b,c,d) where
    %  t is size [1  1]
    %  Y0 is size [2  1]
    %  a is size [1  1]
    %  b is size [1  1]
    %  c is size [1  1]
    %  d is size [1  1]
    %  returns Y as size [2 1]
    %  sys.odefun format is OK
    %  ALL TESTS PASSED OK
    %
    %AUTHORS
    %  Stewart Heitmann (2016a, 2017a)
    
    % Copyright (C) 2016, QIMR Berghofer Medical Research Institute
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

    % check that sys is valid and fill missing fields with defaults   
    try
        sys = bdUtils.syscheck(sys);
    catch ME
        throwAsCaller(MException('bdtoolkit:bdVerify',ME.message));
    end
    disp('sys struct format is OK');
    
    % test sys.odefun
    if isfield(sys,'odefun')
        if isempty(sys.pardef)
            parnames=',';
        else            
            parnames = sprintf('%s,',sys.pardef.name);
        end
        t = sys.tspan(1);
        Y0 = bdGetValues(sys.vardef);        
        disp(['Calling Y = sys.odefun(t,Y0,',parnames(1:end-1),') where']);
        disp(['  t is size [', num2str(size(t)), ']']);
        disp(['  Y0 is size [', num2str(size(Y0)), ']']);
        for indx = 1:numel(sys.pardef)
            pname = sys.pardef(indx).name;
            psize = size(sys.pardef(indx).value);
            disp(['  ' pname ' is size [', num2str(psize), ']']);
        end
        par = {sys.pardef.value};
        Y = sys.odefun(t,Y0,par{:});
        disp(['  ',num2str(size(Y),'Returns Y as size [%d %d]')]);
        if size(Y,2)~=1
            throwAsCaller(MException('bdtoolkit:bdVerify','sys.odefun must return Y as a column vector'));
        end
        disp('sys.odefun format is OK');
    end
    
    % test sys.ddefun
    if isfield(sys,'ddefun')
        if isempty(sys.pardef)
            parnames=',';
        else
            parnames = sprintf('%s,',sys.pardef.name);
        end
        t = sys.tspan(1);
        Y0 = bdGetValues(sys.vardef);
        lags = bdGetValues(sys.lagdef);
        n = size(Y0,1);
        l = size(lags,1);
        Z = Y0*ones(1,l);
        disp(['Calling Y = sys.ddefun(t,Y0,Z,',parnames(1:end-1),') where']);
        disp(['  t is size [', num2str(size(t)), ']']);
        disp(['  Y0 is size [', num2str(size(Y0)), ']']);
        disp(['  Z is size [', num2str(size(Z)), ']']);
        for indx = 1:numel(sys.pardef)
            pname = sys.pardef(indx).name;
            psize = size(sys.pardef(indx).value);
            disp(['  ' pname ' is size [', num2str(psize), ']']);
        end
        par = {sys.pardef.value};
        Y = sys.ddefun(t,Y0,Z,par{:});
        disp(['  ',num2str(size(Y),'Returns Y as size [%d %d]')]);
        if size(Y,2)~=1
            throwAsCaller(MException('bdtoolkit:bdVerify','sys.ddefun must return Y as a column vector'));
        end
        if size(Y,1)~=n
            throwAsCaller(MException('bdtoolkit:bdVerify','sys.odefun must return Y as size [%d 1]',n));
        end
        disp('sys.ddefun format is OK');
    end
    
    % test sys.sdeF
    if isfield(sys,'sdeF')
        if isempty(sys.pardef)
            parnames=',';
        else            
            parnames = sprintf('%s,',sys.pardef.name);
        end
        t = sys.tspan(1);
        Y0 = bdGetValues(sys.vardef);        
        disp(['Calling Y = sys.sdeF(t,Y0,',parnames(1:end-1),') where']);
        disp(['  t is size [', num2str(size(t)), ']']);
        disp(['  Y0 is size [', num2str(size(Y0)), ']']);
        for indx = 1:numel(sys.pardef)
            pname = sys.pardef(indx).name;
            psize = size(sys.pardef(indx).value);
            disp(['  ' pname ' is size [', num2str(psize), ']']);
        end
        par = {sys.pardef.value};
        Y = sys.sdeF(t,Y0,par{:});
        disp(['  ',num2str(size(Y),'Returns Y as size [%d %d]')]);
        if size(Y,2)~=1
            throwAsCaller(MException('bdtoolkit:bdVerify','sys.sdeF must return Y as a column vector'));
        end
        disp('sys.sdeF format is OK');
    end
    
    % test sys.sdeG
    if isfield(sys,'sdeG')
        if isempty(sys.pardef)
            parnames=',';
        else
            parnames = sprintf('%s,',sys.pardef.name);
        end
        t = sys.tspan(1);
        Y0 = bdGetValues(sys.vardef);        
        disp(['Calling G = sys.sdeG(t,Y0,',parnames(1:end-1),') where']);
        disp(['  t is size [', num2str(size(t)), ']']);
        disp(['  Y0 is size [', num2str(size(Y0)), ']']);
        for indx = 1:numel(sys.pardef)
            pname = sys.pardef(indx).name;
            psize = size(sys.pardef(indx).value);
            disp(['  ' pname ' is size [', num2str(psize), ']']);
        end
        par = {sys.pardef.value};
        G = sys.sdeG(t,Y0,par{:});
        disp(['  ',num2str(size(G),'Returns G as size [%d %d]')]);      
        if size(G,1)~=size(Y0,1)
            throwAsCaller(MException('bdtoolkit:bdVerify','sys.sdeG must return an (nxm) matrix where n=numel(Y0)'));
        end
        if size(G,2)~=sys.sdeoption.NoiseSources
            throwAsCaller(MException('bdtoolkit:bdVerify','sys.sdeG must return an (nxm) matrix where m=sys.sdeoption.NoiseSources'));
        end
        disp('sys.sdeG format is OK');
    end
        
    % test sys.auxfun
    if isfield(sys,'auxfun')
        if isempty(sys.pardef)
            parnames=',';
        else
            parnames = sprintf('%s,',sys.pardef{:,1});
        end
        % generate a faux time domain from tspan
        tcount = 11;
        t = linspace(sys.tspan(1), sys.tspan(2), tcount);
        % generate faux Y values by replicating the initial conditions 
        Y0 = bdGetValues(sys.vardef);
        Y = Y0(:,ones(1,tcount));
        % call the auxfun
        disp(['Calling Yaux = sys.auxfun(t,Y,',parnames(1:end-1),') where']);
        disp(['t is size [', num2str(size(t)), ']']);
        disp(['Y is size [', num2str(size(Y)), ']']);
        for indx = 1:size(sys.pardef,1)
            pname = sys.pardef{indx,1};
            psize = size(sys.pardef{indx,2});
            disp([pname ' is size [', num2str(psize), ']']);
        end
        Yaux = sys.auxfun(t,Y,sys.pardef{:,2});
        disp(num2str(size(Yaux),'returns Yaux as size [%d %d]'));      
        assert(size(Yaux,2)==tcount, 'sys.auxfun must return Yaux with the same number of columns as t');        
        disp('sys.auxfun format is OK');
        disp('---');
    end
  
    disp('ALL TESTS PASSED OK');
end


% function vec = GetDefValues(xxxdef)
% %GetDefValues returns the values stored in a pardef or vardef cell array.
% %This function is useful for extracting the values stored in a user-defined
% %vardef array as a single vector for use by the ODE solver.
% %Usage:
% %   vec = GetDefValues(xxxdef)
% %where xxxdef is a cell array of {'name',value} pairs. 
% %Example:
% %  vardef = {'a',1;
% %            'b',[2 3 4];
% %            'c',[5 8; 6 9; 7 10]};
% %  y0 = GetDefValues(vardef);
% %  ...
% %  sol = ode45(@odefun,tspan,y0,...)
% 
%     % extract the second column of xxxdef
%     vec = xxxdef(:,2);
%     
%     % convert each cell entry to a column vector
%     for indx=1:numel(vec)
%         vec{indx} = reshape(vec{indx},[],1);
%     end
%     
%     % concatenate the column vectors to a simple vector
%     vec = cell2mat(vec);
% end
