classdef bdGUI < handle
    %bdGUI - The Brain Dynamics Toolbox Graphic User Interface.
    %   Opens a dynamical system model (sys) with the Brain Dynamics
    %   Toolbox graphical user interface.
    %   
    %EXAMPLE
    %   sys = LinearODE();
    %   gui = bdGUI(sys);
    %
    %AUTHORS
    %  Stewart Heitmann (2016a,2017a,2017b,2017c)

    % Copyright (C) 2016,2017 QIMR Berghofer Medical Research Institute
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

    properties (Constant=true)
        version = '2017b';
    end
    
    properties
        fig             % handle to the application figure
    end
        
    properties (Dependent)
        par             % system parameters (read/write)
        var0            % initial conditions (read/write)
        var             % solution varables (read only)
        t               % solution time steps
        lag             % DDE time lags (read/write)
        sys             % system definition structure (read only)
        sol             % current output of the solver (read only)
        sox             % current auxiliary variables (read only)
        panels          % current panel object handles (read only)
    end
    
    properties (Access=private)
        control         % handle to the bdControl object
        uipanel1        % handle to uipanel 1
        uipanel2        % handle to uipanel 2
        tabgroup        % handle to tabgroup in panel1
        panelmgr = [];  % contains handles to panel class objects
    end
    
    methods
        % bdGUI(sys) or bdGUI()
        function this = bdGUI(varargin)
            % add the bdtoolkit/solvers directory to the path
            addpath(fullfile(fileparts(mfilename('fullpath')),'solvers'));

            % add the bdtoolkit/panels directory to the path
            addpath(fullfile(fileparts(mfilename('fullpath')),'panels'));
            
            % process the input arguments
            switch nargin
                case 0
                    % prompt user to select a system file to load
                    [filename,pathname] = uigetfile({'*.mat','MATLAB data file'},'Load system file');
                    if filename==0
                        % user cancelled the operation
                        this = [];
                        return;
                    end
                    % load the mat file
                    fullname = fullfile(pathname,filename);
                    fdata = load(fullname);
                    if ~isfield(fdata,'sys')
                        % the mat file does not contain a sys struct
                        error('No system data in %s',filename);
                    end
                    % open the bdGUI using the sys data we just loaded
                    this = bdGUI(fdata.sys);
                    return
                    
                case 1
                    % User has supplied a sys parameter. 
                    % Proceed as normal.
                    
                otherwise
                    error('Too many input arguments');
            end

            % Incoming sys parameter
            sys = varargin{1};

            % construct figure
            this.fig = figure('Units','pixels', ...
                'Position',[randi(100,1,1) randi(100,1,1) 900 600], ...
                'name', 'Brain Dynamics Toolbox', ...
                'NumberTitle','off', ...
                'MenuBar','none', ...
                'Toolbar','figure');
            
            % construct the LHS panel (using an approximate position)
            this.uipanel1 = uipanel(this.fig,'Units','pixels','Position',[5 5 600 600],'BorderType','none');
            this.tabgroup = uitabgroup(this.uipanel1);
            
            % construct the RHS panel (using an approximate position)
            this.uipanel2 = uipanel(this.fig,'Units','pixels','Position',[5 5 300 600],'BorderType','none');

            % construct the control panel
            this.control = bdControl(this.uipanel2,sys);

            % resize the panels (putting them in their exact position)
            this.SizeChanged();

            % Construct the System menu
            this.SystemMenu(sys);

            % Construct the Panels menu
            this.PanelsMenu(sys);

            % Construct the Solver menu
            this.SolverMenu(this.control);

            % load each gui panel listed in sys.panels
            if isfield(sys,'panels')
                panelnames = fieldnames(sys.panels);
                for indx = 1:numel(panelnames)
                    classname = panelnames{indx};
                    if exist(classname,'class')
                        % construct the panel, keep a handle to it.
                        classhndl = feval(classname,this.tabgroup,this.control);
                        if ~isfield(this.panelmgr,classname)
                            this.panelmgr.(classname) = classhndl;
                        else
                            this.panelmgr.(classname)(end+1) = classhndl;
                        end
                    else
                        dlg = warndlg({['''', classname, '.m'' not found'],'That panel will not be displayed'},'Missing file','modal');
                        uiwait(dlg);
                    end
                end
            end
            
            % register a callback for resizing the figure
            set(this.fig,'SizeChangedFcn', @(~,~) this.SizeChanged());

            % force a recompute
            notify(this.control,'recompute');            
        end       
        
        % Get par property
        function par = get.par(this)
            % return a struct with paramater values stored by name
            par = [];
            for indx = 1:numel(this.control.sys.pardef)
                name = this.control.sys.pardef(indx).name;
                value = this.control.sys.pardef(indx).value;
                par.(name) = value;
            end
        end 
        
        % Set par property
        function set.par(this,value)
            % Assert the incoming value is a struct
            if ~isstruct(value)
                warning('bdGUI: Illegal par value. Input must be a struct');
                return
            end
            
            % Make a working copy of the control.sys.pardef array 
            syspardef = this.control.sys.pardef;
            
            % For each field name in the incoming value struct ... 
            vfields = fieldnames(value);
            for vindx = 1:numel(vfields)
                % Get the name, value and size of the field
                vfield = vfields{vindx};
                vvalue = value.(vfield);
                vsize = size(vvalue);
                
                % Find the syspardef entry with the same name                
                [val,idx] = bdGetValue(syspardef,vfield);
                if isempty(val)
                    warning(['bdGUI: Unknown parameter [',vfield,'].']);
                    return
                end
                
                % Assert the incoming value is the correct shape and size.
                if ~isequal(size(val),vsize)
                    warning(['bdGUI: Parameter size mismatch [',vfield,'].']);
                    return
                end
                
                % Update the  working copy
                syspardef(idx).value = vvalue;
            end
            
            % Everything must have gone well, so update the sys.pardef 
            % in teh control panel with the working copy.
            this.control.sys.pardef = syspardef;
            
            % Notify the control panel to refresh its widgets
            % and then to recompute the trajectory.
            notify(this.control,'refresh');
            notify(this.control,'recompute');
        end

        % Get var0 (initial conditions) property
        function var0 = get.var0(this)
            % return a struct with initial values stored by name
            var0 = [];
            for indx = 1:numel(this.control.sys.vardef)
                name = this.control.sys.vardef(indx).name;
                value = this.control.sys.vardef(indx).value;
                var0.(name) = value;
            end
        end 
        
        % Set var0 (initial conditions) property
        function set.var0(this,value)
            % Assert the incoming value is a struct
            if ~isstruct(value)
                warning('bdGUI: Illegal var value. Input must be a struct');
                return
            end
            
            % Make a working copy of the control.sys.vardef array 
            sysvardef = this.control.sys.vardef;
            
            % For each field name in the incoming value struct ... 
            vfields = fieldnames(value);
            for vindx = 1:numel(vfields)
                % Get the name, value and size of the field
                vfield = vfields{vindx};
                vvalue = value.(vfield);
                vsize = size(vvalue);
                
                % Find the sysvardef entry with the same name                
                [val,idx] = bdGetValue(sysvardef,vfield);
                if isempty(val)
                    warning(['bdGUI: Unknown variable [',vfield,'].']);
                    return
                end
                
                % Assert the incoming value is the correct shape and size.
                if ~isequal(size(val),vsize)
                    warning(['bdGUI: Variable size mismatch [',vfield,'].']);
                    return
                end
                
                % Update the  working copy
                sysvardef(idx).value = vvalue;
            end
            
            % Everything must have gone well, so update the sys.vardef 
            % in the control panel with the working copy.
            this.control.sys.vardef = sysvardef;
            
            % Notify the control panel to refresh its widgets
            % and then to recompute the trajectory.
            notify(this.control,'refresh');
            notify(this.control,'recompute');
        end
        
        % Get var (solution variables) property
        function var = get.var(this)
            % return a struct with the solution variables stored by name
            var = [];
            solindx = 0;
            for indx = 1:numel(this.control.sys.vardef)
                % get name and length of variable
                name = this.control.sys.vardef(indx).name;
                len = numel(this.control.sys.vardef(indx).value);
                % compute the index of the variable in sol.y
                solindx = solindx(end) + (1:len);
                % return the solution variables
                var.(name) = this.control.sol.y(solindx,:);
            end
        end

        % Get t (solution time steps) property
        function t = get.t(this)
            t = this.control.sol.x;
        end

        % Get lag property
        function lag = get.lag(this)
            % return a struct with initial values stored by name
            lag = [];
            if isfield(this.control.sys,'lagdef')
                for indx = 1:numel(this.control.sys.lagdef)
                    name = this.control.sys.lagdef(indx).name;
                    value = this.control.sys.lagdef(indx).value;
                    lag.(name) = value;
                end
            end
        end 
        
        % Set lag property
        function set.lag(this,value)
            % Assert the incoming value is a struct
            if ~isstruct(value)
                warning('bdGUI: Illegal lag value. Input must be a struct');
                return
            end
            
            % Assert the current system has lag parameters
            if ~isfield(this.control.sys,'lagdef')
                warning('bdGUI: No lag parameters exist in this model');
                return
            end
            
            % Make a working copy of the control.sys.lagdef array
            syslagdef = this.control.sys.lagdef;
            
            % For each field name in the incoming value struct ... 
            vfields = fieldnames(value);
            for vindx = 1:numel(vfields)
                % Get the name, value and size of the field
                vfield = vfields{vindx};
                vvalue = value.(vfield);
                vsize = size(vvalue);
                
                % Find the syslagdef entry with the same name                
                [val,idx] = bdGetValue(syslagdef,vfield);
                if isempty(val)
                    warning(['bdGUI: Unknown lag parameter [',vfield,'].']);
                    return
                end
                
                % Assert the incoming value is the correct shape and size.
                if ~isequal(size(val),vsize)
                    warning(['bdGUI: Lag parameter size mismatch [',vfield,'].']);
                    return
                end
                
                % Update the  working copy
                syslagdef(idx).value = vvalue;
            end
            
            % Everything must have gone well, so update the sys.lagdef 
            % in the control panel with the working copy.
            this.control.sys.lagdef = syslagdef;
            
            % Notify the control panel to refresh its widgets
            % and then to recompute the trajectory.
            notify(this.control,'refresh');
            notify(this.control,'recompute');
        end       
        
        % Get sys property
        function sys = get.sys(this)
            sys = this.control.sys;
        end
        
        % Get sol property
        function sol = get.sol(this)
            sol = this.control.sol;
        end
        
        % Get sox property
        function sox = get.sox(this)
            sox = this.control.sox;
        end
        
        % Get panels property
        function panels = get.panels(this) 
            % Returns a deep copy of the class properties in panelmgr
            panels = [];

            % Clean the panelmgr of any stale handles to panel classes
            % that have since been destroyed.
            this.CleanPanelMgr();

            % for each class in panelmgr
            classnames = fieldnames(this.panelmgr);
            for cindx = 1:numel(classnames)
                classname = classnames{cindx};
                classcount = numel(this.panelmgr.(classname));
                panels.(classname) = [];

                % for each instance of the class
                for iindx = 1:classcount
                    % for each field in the class
                    fldnames = fieldnames(this.panelmgr.(classname));
                    for findx = 1:numel(fldnames)
                        fname = fldnames{findx};
                        % deep copy of class properties to output
                        panels.(classname)(iindx).(fname) = this.panelmgr.(classname)(iindx).(fname);
                    end                    
                end
            end    
        end

    end
       
    
    methods (Access=private)
        
        % Construct the System menu
        function menuobj = SystemMenu(this,sys)
            % construct System menu
            menuobj = uimenu('Parent',this.fig, 'Label','System');

            % construct menu items
            if isfield(sys,'self')
                uimenu('Parent',menuobj, ...
                       'Label','Reconfigure', ...
                       'Callback', @(~,~) SystemNew() );
            else
                uimenu('Parent',menuobj, ...
                       'Label','Reconfigure', ...
                       'Enable', 'off');
            end
            uimenu('Parent',menuobj, ...
                   'Label','Load', ...
                   'Callback', @(~,~) SystemLoad() );
            uimenu('Parent',menuobj, ...
                   'Label','Save', ...
                   'Callback', @(~,~) this.SystemSaveDialog() );
            uimenu('Parent',menuobj, ...
                   'Label','Quit', ...
                   'Separator','on', ...
                   'Callback', @(~,~) delete(this.fig));

            % Callback for System-New menu
            function SystemNew()
                if isfield(this.control.sys,'self')
                    newsys = feval(this.control.sys.self);
                    if ~isempty(newsys)
                        bdGUI(newsys);
                    end
                end
            end

            % Callback for System-Load menu
            function gui = SystemLoad()
                [fname, pname] = uigetfile({'*.mat','MATLAB data file'},'Load system file');
                if fname~=0
                    fdata = load(fullfile(pname,fname),'sys');
                    if isfield(fdata,'sys')
                        gui = bdGUI(fdata.sys);
                    else
                        uiwait( warndlg({'Missing ''sys'' structure.','Load aborted.'},'Load failed') );
                    end
                end
            end            
        end
        
        % Construct the System-Save Dialog
        function SystemSaveDialog(this)
            % construct dialog box
            dlg = figure('Units','pixels', ...
                'Position',[randi(300,1,1) randi(300,1,1), 200, 450], ...
                'MenuBar','none', ...
                'Name','System Save', ...
                'NumberTitle','off', ...
                'ToolBar', 'none', ...
                'Resize','off');

            % container for the scrolling panel
            panel = uipanel('Parent', dlg, ...
                'Units','pixels', ...
                'Position',[10 50 182 390], ...
                'BorderType','none');

            % Construct scrolling uipanel with fixed width and height.
            % The height will be adjusted by PopulateSaveDialog.
            scroll = bdScroll(panel,175, 1000);
            
            % Populate the contents of the scrolling uipanel
            this.PopulateSaveDialog(scroll.panel)
            
            % construct the 'Cancel' button
            uicontrol('Style','pushbutton', ...
                'String','Cancel', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', dlg, ...
                'Callback', @(~,~) delete(dlg), ...
                'Position',[60 15 60 20]);

            % construct the 'Save' button
            uicontrol('Style','pushbutton', ...
                'String','Save', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', dlg, ...
                'Callback', @(~,~) this.SystemSaveMenu(dlg,scroll.panel), ... 
                'Position',[130 15 60 20]);
        end
        
        % Populate the System Save Dialog panel with model data
        function PopulateSaveDialog(this,scrollpanel)
            % geometry of the panel
            panelw = scrollpanel.Position(3);
            panelh = scrollpanel.Position(4);

            % Begin placing widgets at the top left of panel
            yoffset = 25;
            boxh = 20;
            rowh = 22;            

            % SYSTEM title
            uicontrol('Style','text', ...
                'String','System', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','bold', ...
                'Parent', scrollpanel, ...
                'Position',[10 panelh-yoffset panelw boxh]);

            % next row
            yoffset = yoffset + rowh;

            % sys check box
            uicontrol('Style','checkbox', ...
                'String','sys', ...
                'Value', 1, ...
                'Tag', 'bdExportSys', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', scrollpanel, ...
                'Position',[20 panelh-yoffset panelw boxh]);

            % next row
            yoffset = yoffset + rowh;

            % sol check box
            uicontrol('Style','checkbox', ...
                'String','sol', ...
                'Tag', 'bdExportSol', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', scrollpanel, ...
                'Position',[20 panelh-yoffset panelw boxh]);

            % next row
            yoffset = yoffset + 1.25*rowh;

            % PARAMETERS title
            uicontrol('Style','text', ...
                'String','Parameters', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','bold', ...
                'Parent', scrollpanel, ...
                'Position',[10 panelh-yoffset panelw boxh]);

            % next row
            yoffset = yoffset + rowh;

            % for each entry in sys.pardef
            for indx = 1:numel(this.control.sys.pardef)
                % get name of parameter
                name = this.control.sys.pardef(indx).name;

                % parameter check box
                uicontrol('Style','checkbox', ...
                    'String', name, ...
                    'UserData', struct('name',name,'indx',indx), ...
                    'Tag', 'bdExportPar', ...
                    'HorizontalAlignment', 'left', ...
                    'FontUnits', 'pixels', ...
                    'FontSize', 12, ...
                    'Parent', scrollpanel, ...
                    'Position', [20 panelh-yoffset panelw boxh]);

                % next row
                yoffset = yoffset + rowh;
            end

            % skip quarter row
            yoffset = yoffset + 0.25*rowh;

            % SOLUTION title
            uicontrol('Style','text', ...
                'String','Solution Variables', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','bold', ...
                'Parent', scrollpanel, ...
                'Position',[10 panelh-yoffset panelw boxh]);

            % next row
            yoffset = yoffset + rowh;  

            % for each entry in sys.vardef
            solindx = 0;
            for indx = 1:numel(this.control.sys.vardef)
                % get name and length of variable
                name = this.control.sys.vardef(indx).name;
                len = numel(this.control.sys.vardef(indx).value);
                % compute the index of the variable in sol.y
                solindx = solindx(end) + (1:len);
                % variable check box
                uicontrol('Style','checkbox', ...
                    'String',name, ...
                    'UserData', struct('name',name,'solindx',solindx), ...
                    'Tag', 'bdExportVar', ...
                    'HorizontalAlignment','left', ...
                    'FontUnits','pixels', ...
                    'FontSize',12, ...
                    'Parent', scrollpanel, ...
                    'Position',[20 panelh-yoffset panelw boxh]);

                % next row
                yoffset = yoffset + rowh;
            end

            % skip quarter row
            yoffset = yoffset + 0.25*rowh;

            % TIME DOMAIN title
            uicontrol('Style','text', ...
                'String','Time Domain', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','bold', ...
                'Parent', scrollpanel, ...
                'Position',[10 panelh-yoffset panelw boxh]);

            % next row
            yoffset = yoffset + rowh;                                    

            % time check box
            uicontrol('Style','checkbox', ...
                'String','t', ...
                'Tag', 'bdExportTime', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', scrollpanel, ...
                'Position',[20 panelh-yoffset panelw boxh]);

            % next row
            yoffset = yoffset + 1.25*rowh;

            % PANELS title
            uicontrol('Style','text', ...
                'String','Panels', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','bold', ...
                'Parent', scrollpanel, ...
                'Position',[10 panelh-yoffset panelw boxh]);

            % next row
            yoffset = yoffset + rowh;

            % Clean the panelmgr of any stale handles to panel classes
            % that have since been destroyed.
            this.CleanPanelMgr();

            % for each class in panelmgr
            classnames = fieldnames(this.panelmgr);
            for cindx = 1:numel(classnames)
                classname = classnames{cindx};

                % Panel Name
                uicontrol('Style','text', ...
                'String',classname, ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', scrollpanel, ...
                'Position',[20 panelh-yoffset panelw boxh]);

                % next row
                yoffset = yoffset + rowh;

                % for each field in the class
                fldnames = fieldnames(this.panelmgr.(classname));
                for findx = 1:numel(fldnames)
                    fldname = fldnames{findx};

                    % field checkbox
                    uicontrol('Style','checkbox', ...
                        'String',fldname, ...
                        'Tag', [classname,'.',fldname], ...
                        'HorizontalAlignment','left', ...
                        'FontUnits','pixels', ...
                        'FontSize',12, ...
                        'Parent', scrollpanel, ...
                        'Position',[30 panelh-yoffset panelw boxh]);      

                    % next row
                    yoffset = yoffset + rowh;
                end
            end
            
            % Fit the scroll panel height to the number of widgets.
             panely = scrollpanel.Position(2);
             panelh = scrollpanel.Position(4);
             offset = yoffset - panelh;
             scrollpanel.Position(4)= panelh+offset;    % this invokes the SizeChangedCallback
             scrollpanel.Position(2)= panely-offset;    % this does not
        end
        
        % System-Save menu callback
        function SystemSaveMenu(this,dlg,panel)
            % initialise the outgoing data
            data = [];
            
            % The matlab save function wont save an empty struct
            % so we ensure that our struct always has something in it.
            data.bdtoolbox = this.version;      % toolkit version string
            data.date = date();                 % today's date
                
            % Clean the panelmgr of any stale handles to panel classes
            % that have since been destroyed.
            this.CleanPanelMgr();
            
            % find the sys checkbox widget in the scroll panel
            objs = findobj(panel,'Tag','bdExportSys');
            if objs.Value>0
                % include the sys struct in the outgoing data
                data.sys = this.control.sys;
                % remove any OutputFcn options from the sys struct 
                if isfield(data.sys,'odeoption') && isfield(data.sys.odeoption,'OutputFcn')
                    data.sys.odeoption = rmfield(data.sys.odeoption,'OutputFcn');
                end
                if isfield(data.sys,'ddeoption') && isfield(data.sys.ddeoption,'OutputFcn')
                    data.sys.ddeoption = rmfield(data.sys.ddeoption,'OutputFcn');
                end
                if isfield(data.sys,'sdeoption') && isfield(data.sys.sdeoption,'OutputFcn')
                    data.sys.sdeoption = rmfield(data.sys.sdeoption,'OutputFcn');
                end
                % remove empty sdeoption.randn field 
                if isfield(data.sys,'sdeoption') && isfield(data.sys.sdeoption,'randn') && isempty(data.sys.sdeoption.randn)
                    data.sys.sdeoption = rmfield(data.sys.sdeoption,'randn');
                end
            end

            % find the sol checkbox widget in the scroll panel
            objs = findobj(panel,'Tag','bdExportSol');
            if objs.Value>0
                % include the sol struct in the outgoing data
                data.sol = this.control.sol;
                % remove the OutputFcn option from the sol.extdata.options struct 
                if isfield(data.sol,'extdata') && isfield(data.sol.extdata,'options') && isfield(data.sol.extdata.options,'OutputFcn')
                    data.sol.extdata.options = rmfield(data.sol.extdata.options,'OutputFcn');
                end
            end

            % find all parameter checkbox widgets in the scroll panel
            objs = findobj(panel,'Tag','bdExportPar');
            for obj = objs'                         % for each checkbox widget ...
                if obj.Value>0                      % if checkbox is enabled then ...
                    name = obj.UserData.name;       % get the parameter name
                    indx = obj.UserData.indx;       % get the parameter indx
                    % ensure data.par exists
                    if ~isfield(data,'par')
                        data.par = [];
                    end
                    % include the parameter values in the outgoing data
                    data.par.(name) = this.control.sys.pardef(indx).value;
                end
            end

            % find all solution variable checkbox widgets in the scroll panel
            objs = findobj(panel,'Tag','bdExportVar');
            for obj = objs'                         % for each checkbox widget ...
                if obj.Value>0                      % if checkbox is enabled then ...
                    name = obj.UserData.name;       % get the variable name
                    solindx = obj.UserData.solindx; % get the solution indx
                    % ensure data.var exists
                    if ~isfield(data,'var')
                        data.var = [];
                    end
                    % include the variable values in the outgoing data
                    data.var.(name) = this.control.sol.y(solindx,:);
                end
            end

            % find the time checkbox widget in the scroll panel
            objs = findobj(panel,'Tag','bdExportTime');
            if objs.Value>0
                % include the time steps in the outgoing data
                data.t = this.control.sol.x;
            end

            % for each class in panelmgr
            classnames = fieldnames(this.panelmgr);
            for cindx = 1:numel(classnames)
                classname = classnames{cindx};
                classcount = numel(this.panelmgr.(classname));
               
                % for each instance of the class
                for iindx = 1:classcount                    
                    % for each field in the class
                    fldnames = fieldnames(this.panelmgr.(classname));
                    for findx = 1:numel(fldnames)
                        fldname = fldnames{findx};

                        % find the matching checkbox widget
                        objs = findobj(panel,'Tag',[classname,'.',fldname]);
                        if objs.Value>0        % if the checkbox is enabled then ...
                            % ensure data.panels exists
                            if ~isfield(data,'panels')
                                data.panels = [];
                            end
                            % ensure data.panels.(classname) exists
                            if ~isfield(data.panels,classname)
                                data.panels.(classname) = [];
                            end
                            % ensure data.panels.(classname).(fldname) exists
                            if ~isfield(data.panels.(classname),fldname)
                                data.panels.(classname).(fldname) = [];
                            end
                            % include the field values in the outgoing data
                            data.panels.(classname)(iindx).(fldname) = this.panelmgr.(classname)(iindx).(fldname);
                        end
                    end
               
                end
            end
            
            % Save data to mat file
            [fname,pname] = uiputfile('*.mat','Save system file');
            if fname~=0
                save(fullfile(pname,fname),'-struct','data');
            end
            
            % Close the dialog box
            delete(dlg);
        end
        
        % Construct the Panel menu
        function menuobj = PanelsMenu(this,sys)
            classnames = {'bdLatexPanel','bdTimePortrait','bdPhasePortrait','bdSpaceTime','bdCorrPanel','bdHilbert','bdSurrogate','bdSolverPanel','bdTrapPanel'};
            menuobj = uimenu('Parent',this.fig, 'Label','New Panel');
            uimenu('Parent',menuobj, ...
                    'Label','Equations', ...
                    'Callback', @(~,~) NewPanel('bdLatexPanel'));
            uimenu('Parent',menuobj, ...
                    'Label','Time Portrait', ...
                    'Callback', @(~,~) NewPanel('bdTimePortrait'));
            uimenu('Parent',menuobj, ...
                    'Label','Phase Portrait', ...
                    'Callback', @(~,~) NewPanel('bdPhasePortrait'));
            uimenu('Parent',menuobj, ...
                    'Label','Space-Time', ...
                    'Callback', @(~,~) NewPanel('bdSpaceTime'));
            uimenu('Parent',menuobj, ...
                    'Label','Correlations', ...
                    'Callback', @(~,~) NewPanel('bdCorrPanel'));
            uimenu('Parent',menuobj, ...
                    'Label','Hilbert Transform', ...
                    'Callback', @(~,~) NewPanel('bdHilbert'));
            uimenu('Parent',menuobj, ...
                    'Label','Surrogate Signal', ...
                    'Callback', @(~,~) NewPanel('bdSurrogate'));
            uimenu('Parent',menuobj, ...
                    'Label','Solver Panel', ...
                    'Callback', @(~,~) NewPanel('bdSolverPanel'));
            uimenu('Parent',menuobj, ...
                    'Label','Trap Panel', ...
                    'Callback', @(~,~) NewPanel('bdTrapPanel'));
      
            % add any custom gui panels to the menu and also to this.panelclasses
            if isfield(sys,'panels')
                panelnames = fieldnames(sys.panels);
                for indx = 1:numel(panelnames)
                    classname = panelnames{indx};
                    if exist(classname,'class')
                        switch classname
                            case classnames
                                % Nothing to do. We have this one already.
                            otherwise
                                % Add a menu item for the novel panel
                                uimenu('Parent',menuobj, ...
                                       'Label',classname, ...
                                       'Callback', @(~,~) NewPanel(classname));
                                % Remember the name of the novel panel class
                                classnames{end} = classname;
                        end
                    end
                end
            end 
            
            % Menu Callback function
            function NewPanel(classname)
               if exist(classname,'class')
                    % construct the panel, keep a handle to it.
                    classhndl = feval(classname,this.tabgroup,this.control);
                    if ~isfield(this.panelmgr,classname)
                        this.panelmgr.(classname) = classhndl;
                    else
                        this.panelmgr.(classname)(end+1) = classhndl;
                    end
                    
                    % force a redraw event
                    notify(this.control,'redraw');
                else
                    dlg = warndlg({['''', classname, '.m'' not found'],'That panel will not be displayed'},'Missing file','modal');
                    uiwait(dlg);
                end          
            end
            
        end
  
        % Construct the Solver menu
        function menuobj = SolverMenu(this,control)
            menuobj = uimenu('Parent',this.fig, 'Label','Solver', 'Tag','bdSolverPanelMenu');
            checkstr='on';
             for indx = 1:numel(control.solvermap)
                uimenu('Parent',menuobj, ...
                    'Label',control.solvermap(indx).solvername, ...
                    'Tag', 'bdSolverSelector', ...
                    'UserData', indx, ...
                    'Checked',checkstr, ...
                    'Callback', @(menuitem,~) SolverCallback(menuobj,menuitem,control) );
                checkstr='off';                
            end
        
            % Solver Menu Item Callback
            function SolverCallback(menuobj,menuitem,control)
                % Find all solver menu items and un-check them.
                menuitems = findobj(menuobj,'Tag','bdSolverSelector');
                for ix=1:numel(menuitems)                
                    menuitems(ix).Checked='off';
                end
                % Now check the newly selected menu item
                menuitem.Checked = 'on';
                % Set the index of the active solver in the control object
                control.solveridx = menuitem.UserData;
                % Recompute using the new solver
                notify(control,'recompute');  
            end
        end        
        
        % Remove stale (deleted) class handles from this.panelmgr.
        % We need to do this because the panel classes can delete themselves
        % without informing the GUI that they are gone.
        function CleanPanelMgr(this)
            % for each class in panelmgr
            classnames = fieldnames(this.panelmgr);
            for cindx = 1:numel(classnames)
                classname = classnames{cindx};
                classcount = numel(this.panelmgr.(classname));

                % for each instance of the class (in reverse order)
                for iindx = classcount:-1:1
                    % remove any handles to invalid classes
                    if ~isvalid(this.panelmgr.(classname)(iindx))
                        this.panelmgr.(classname)(iindx) = [];
                    end
                end
                
                % remove empty classes
                if isempty(this.panelmgr.(classname))
                    % remove it from this.panelmgr
                    this.panelmgr = rmfield(this.panelmgr,classname);
                end
            end    
            
        end
        
        % Callback for window resize events
        function SizeChanged(this)
            % get the new figure size
            figw = this.fig.Position(3);
            figh = this.fig.Position(4);
            
            % dont allow small figures to cramp our panels
            figw = max(figw,300);
            figh = max(figh,300);
            
            % width of the RHS panel
            panel2w = 105;
            
            % resize the LHS panel
            w1 = figw - panel2w - 10;
            h1 = figh - 10;
            this.uipanel1.Position = [5 5 w1 h1];
            
            % resize the RHS panel
            w2 = panel2w;
            h2 = figh - 10;
            this.uipanel2.Position = [8+w1 5 w2 h2];            
        end
        
    end
    
end


