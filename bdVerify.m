function bdVerify(sys)
    %BdVerify - Verify the format of a sys struct.
    %Use bdVerify to check the validty of a Brain Dynamics sys struct.
    %
    %EXAMPLE
    %  >> sys = ODEdemo1();
    %  >> bdVerify(sys);
    %  Calling Y = sys.odefun(t,Y0,a,b)
    %  where t=0 and Y0 is size [1 1]
    %  returns Y as size [1 1]
    %  sys.odefun format is OK
    %  ---
    %  ALL TESTS PASSED OK
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

    % check that sys is a struct
    assert(isstruct(sys), 'sys must be a struct');

    % check the existence of basic fields in the sys struct
    assert(isfield(sys,'pardef'), 'sys.pardef does not exist');
    assert(isfield(sys,'vardef'), 'sys.vardef does not exist');
    assert(isfield(sys,'tspan'), 'sys.tspan does not exist');
    
    % check that odefun is a function handle (if it has been defined)
    if isfield(sys,'odefun')
        assert(isa(sys.odefun,'function_handle'), 'sys.odefun must be a function handle');
    end
    
    % check that auxfun is a function handle (if it has been defined)
    if isfield(sys,'auxfun')
        assert(isa(sys.auxfun,'function_handle'), 'sys.auxfun must be a function handle');
    end

    % check that ddefun is a function handle (if it has been defined)
    if isfield(sys,'ddefun')
        assert(isa(sys.ddefun,'function_handle'), 'sys.ddefun must be a function handle');
    end
    
    % check that sdefun is a function handle (if it has been defined)
    if isfield(sys,'sdefun')
        assert(isa(sys.sdefun,'function_handle'), 'sys.sdefun must be a function handle');
    end
    
    % check that ddefun and lagdef co-exist
    if isfield(sys,'ddefun')
        assert(isfield(sys,'lagdef'), 'sys.lagdef must exist when sys.ddefun exists');
        
        % check sys.lagdef
        assert(iscell(sys.lagdef), 'sys.lagdef must be a cell array');
        assert(size(sys.lagdef,2)==2, 'sys.lagdef must have exactly two columns');
        for indx=1:size(sys.lagdef,1)
            assert(ischar(sys.lagdef{indx,1}), num2str(indx,'sys.lagdef{%d,1} must be a string'));
            assert(isnumeric(sys.lagdef{indx,2}), num2str(indx,'sys.lagdef{%d,2} must be numeric'));
        end
    end
    
    % check sys.pardef
    assert(iscell(sys.pardef), 'sys.pardef must be a cell array');
    assert(size(sys.pardef,2)==2, 'sys.pardef must have exactly two columns');
    for indx=1:size(sys.pardef,1)
        assert(ischar(sys.pardef{indx,1}), num2str(indx,'sys.pardef{%d,1} must be a string'));
        assert(isnumeric(sys.pardef{indx,2}), num2str(indx,'sys.pardef{%d,2} must be numeric'));
    end

    % check sys.vardef
    assert(iscell(sys.vardef), 'sys.vardef must be a cell array');
    assert(size(sys.vardef,2)==2, 'sys.vardef must have exactly two columns');
    for indx=1:size(sys.vardef,1)
        assert(ischar(sys.vardef{indx,1}), num2str(indx,'sys.vardef{%d,1} must be a string'));
        assert(isnumeric(sys.vardef{indx,2}), num2str(indx,'sys.vardef{%d,2} must be numeric'));
    end
    
    % ODE solver checks
    if isfield(sys,'odesolver')
        assert(iscell(sys.odesolver), 'sys.odesolver must be a cell array');
        assert(size(sys.odesolver,1)==1 || size(sys.odesolver,2)==1, 'sys.odesolver cell array must be one dimensional');
        for indx=1:numel(sys.odesolver)
            assert(isa(sys.odesolver{indx},'function_handle')), num2str(indx,'sys.odesolver{%d} must be a function handle');
        end
        assert(isfield(sys,'odefun'), 'sys.odefun must be defined for odesolver'); 
        assert(isfield(sys,'odeoption'), 'sys.odeoption must be defined for odesolver'); 
        assert(isstruct(sys.odeoption), 'sys.odeoption must be a struct (see odeset)');
    end
        
    % DDE solver checks
    if isfield(sys,'ddesolver')
        assert(iscell(sys.ddesolver), 'sys.ddesolver must be a cell array');
        assert(size(sys.ddesolver,1)==1 || size(sys.ddesolver,2)==1, 'sys.ddesolver cell array must be one dimensional');
        for indx=1:numel(sys.ddesolver)
            assert(isa(sys.ddesolver{indx},'function_handle')), num2str(indx,'sys.ddesolver{%d} must be a function handle');
        end
        assert(isfield(sys,'ddefun'), 'sys.ddefun must be defined for ddesolver'); 
        assert(isfield(sys,'ddeoption'), 'sys.ddeoption must be defined for ddesolver'); 
        assert(isstruct(sys.ddeoption), 'sys.ddeoption must be a struct (see ddeset)');
    end
        
    % SDE solver checks
    if isfield(sys,'sdesolver')
        assert(iscell(sys.sdesolver), 'sys.sdesolver must be a cell array');
        assert(size(sys.sdesolver,1)==1 || size(sys.sdesolver,2)==1, 'sys.sdesolver cell array must be one dimensional');
        for indx=1:numel(sys.sdesolver)
            assert(isa(sys.sdesolver{indx},'function_handle')), num2str(indx,'sys.sdesolver{%d} must be a function handle');
        end
        assert(isfield(sys,'odefun'), 'sys.odefun must be defined for sdesolver'); 
        assert(isfield(sys,'sdefun'), 'sys.sdefun must be defined for sdesolver'); 
        assert(isfield(sys,'sdeoption'), 'sys.sdeoption must be defined for sdesolver'); 
        assert(isstruct(sys.sdeoption), 'sys.sdeoption must be a struct');
        assert(isfield(sys.sdeoption,'NoiseSources'), 'sys.sdeoption.NoiseSources must be defined for sdesolver');
        assert(isnumeric(sys.sdeoption.NoiseSources), 'sys.sdeoption.NoiseSources must be a numeric value');
        assert(numel(sys.sdeoption.NoiseSources)==1, 'sys.sdeoption.NoiseSources must be a scalar value');
        assert(mod(sys.sdeoption.NoiseSources,1)==0, 'sys.sdeoption.NoiseSources must be an integer value');
        % Validate sys.sdeoption.randn (if it exists)
        if isfield(sys.sdeoption,'randn') && ~isempty(sys.sdeoption.randn)
            [m,tcount] = size(sys.sdeoption.randn);
            assert(m==sys.sdeoption.NoiseSources, 'Number of rows in sys.sdeoption.randn must equal sys.sdeoption.NoiseSources'); 
        end
    end
    
    % check that at least one of odesolver, ddesolver, sdesolver exist
    assert( (isfield(sys,'odesolver') || isfield(sys,'ddesolver') || isfield(sys,'sdesolver')), 'Missing sys.odesolver, sys.ddesolver or sys.sdesolver');
    
    % check sys.tspan
    assert(isnumeric(sys.tspan),'sys.tspan must be numeric');
    assert(size(sys.tspan,1)==1 && size(sys.tspan,2)==2,'sys.tspan must be a 1x2 vector');
    
    % test sys.odefun
    if isfield(sys,'odefun')
        if isempty(sys.pardef)
            parnames=',';
        else
            parnames = sprintf('%s,',sys.pardef{:,1});
        end
        t = sys.tspan(1);
        Y0 = bdGetValues(sys.vardef);        
        disp(['Calling Y = sys.odefun(t,Y0,',parnames(1:end-1),') where']);
        disp(['t is size [', num2str(size(t)), ']']);
        disp(['Y0 is size [', num2str(size(Y0)), ']']);
        for indx = 1:size(sys.pardef,1)
            pname = sys.pardef{indx,1};
            psize = size(sys.pardef{indx,2});
            disp([pname ' is size [', num2str(psize), ']']);
        end
        Y = sys.odefun(t,Y0,sys.pardef{:,2});
        disp(num2str(size(Y),'returns Y as size [%d %d]'));      
        assert(size(Y,2)==1, 'sys.odefun must return Y as a column vector');        
        disp('sys.odefun format is OK');
        disp('---');
    end
    
    % test sys.ddefun
    if isfield(sys,'ddefun')
        if isempty(sys.pardef)
            parnames=',';
        else
            parnames = sprintf('%s,',sys.pardef{:,1});
        end
        t = sys.tspan(1);
        Y0 = bdGetValues(sys.vardef);
        lags = bdGetValues(sys.lagdef);
        n = size(Y0,1);
        l = size(lags,1);
        Z = Y0*ones(1,l);
        disp(['Calling Y = sys.ddefun(t,Y0,Z,',parnames(1:end-1),') where']);
        disp(['t is size [', num2str(size(t)), ']']);
        disp(['Y0 is size [', num2str(size(Y0)), ']']);
        disp(['Z is size [', num2str(size(Z)), ']']);
        for indx = 1:size(sys.pardef,1)
            pname = sys.pardef{indx,1};
            psize = size(sys.pardef{indx,2});
            disp([pname ' is size [', num2str(psize), ']']);
        end
        Y = sys.ddefun(t,Y0,Z,sys.pardef{:,2});
        disp(num2str(size(Y),'returns Y as size [%d %d]'));      
        assert(size(Y,2)==1, 'sys.ddefun must return Y as a column vector');        
        assert(size(Y,1)==n, 'sys.ddefun must return Y as size [%d 1]',n);
        disp('sys.ddefun format is OK');
        disp('---');
    end
    
    % test sys.sdefun
    if isfield(sys,'sdefun')
        if isempty(sys.pardef)
            parnames=',';
        else
            parnames = sprintf('%s,',sys.pardef{:,1});
        end
        t = sys.tspan(1);
        Y0 = bdGetValues(sys.vardef);        
        disp(['Calling G = sys.sdefun(t,Y0,',parnames(1:end-1),') where']);
        disp(['t is size [', num2str(size(t)), ']']);
        disp(['Y0 is size [', num2str(size(Y0)), ']']);
        for indx = 1:size(sys.pardef,1)
            pname = sys.pardef{indx,1};
            psize = size(sys.pardef{indx,2});
            disp([pname ' is size [', num2str(psize), ']']);
        end
        G = sys.sdefun(t,Y0,sys.pardef{:,2});
        disp(num2str(size(G),'returns G as size [%d %d]'));      
        assert(size(G,1)==size(Y0,1), 'sys.sdefun must return G with the same row dim as Y0');      
        assert(size(G,2)==sys.sdeoption.NoiseSources, 'sys.sdefun must return G with col dim equal to sys.sdeoption.NoiseSources');      
        
        disp('sys.sdefun format is OK');
        disp('---');
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
