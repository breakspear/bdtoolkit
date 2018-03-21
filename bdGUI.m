classdef bdGUI < handle
    %bdGUI - The Brain Dynamics Toolbox Graphical User Interface (GUI).
    %
    %   gui = bdGUI();
    %   gui = bdGUI(sys);
    %   gui = bdGUI(sys,'sol',sol);
    %
    %The bdGUI application is the graphical user interface for the Brain
    %Dynamics Toolbox. It loads and runs the dynamical model defined by
    %the system structure (sys). The system structure defines the names
    %and initial values of the model's parameters and state variables.
    %It also contains a handle to the model-specific function which defines
    %the dynamical equation to be solved. The system structure may be
    %passed to bdGUI as an input parameter or loaded from a mat file.
    %If bdGUI is invoked with no parameters then it prompts the user to
    %load a mat file which is assumed to contain a valid sys. 
    %A previously computed solution (sol) for the model can be loaded in
    %tandem with the model's system structure. If no solution is provided
    %then bdGUI automatically computes one at start-up.
    %
    %EXAMPLE
    %   >> cd bdtoolkit
    %   >> addpath models
    %   >> sys = LinearODE();
    %   >> gui = bdGUI(sys);
    %
    %The call to bdGUI returns a handle (gui) to the bdGUI class. That
    %handle can be used to control the graphical user interface from the
    %matlab workspace.
    %
    %   gui = bdGUI with properties:
    %       version: '2018a'
    %           fig: [1×1 Figure]
    %           par: [1×1 struct]
    %          var0: [1×1 struct]
    %           var: [1×1 struct]
    %             t: [1×612 double]
    %         tindx: [1×612 logical]
    %           lag: [1×1 struct]
    %           sys: [1×1 struct]
    %           sol: [1×1 struct]
    %        panels: [1×1 struct]
    %
    % Where
    %   gui.version is the version string of the toolbox (read-only)
    %   gui.fig is a handle to the application figure (read/write)
    %   gui.par is a struct containing the model parameters (read/write)
    %   gui.var0 is a struct containing the initial conditions (read/write)
    %   gui.var is a struct containing the computed time-series (read-only)
    %   gui.t contains the time steps for the computed solution (read-only)
    %   gui.tindx contains the indices of the non-transient time steps (read-only)
    %   gui.lag is a struct containing the DDE lag parameters (read/write)
    %   gui.sys is a copy of the model's system structure (read-only)
    %   gui.sol is the output of the solver (read-only)
    %   gui.panels contains the outputs of the display panels (read-only)
    %
    %SEE ALSO
    %   The 'Getting Started' section of the 'Handbook for the Brain
    %   Dynamics Toolbox'.
    %
    %AUTHORS
    %   Stewart Heitmann (2016a-2018a)

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

    properties (Constant=true)
        version = '2018a';      % version number of the toolbox
    end
    
    properties
        fig             % graphics handle for the application figure
    end
        
    properties (Dependent)
        par             % system parameters (read/write)
        var0            % initial conditions (read/write)
        var             % solution varables (read only)
        t               % solution time steps (read only)
        tindx           % logical index of the non-transient time steps (read only)
        lag             % DDE time lags (read/write)
        sys             % system definition structure (read only)
        sol             % current output of the solver (read only)
        panels          % current panel object handles (read only)
    end
    
    properties (Access=private)
        control         % handle to the bdControl object
        display         % handle to the bdDisplay object
    end
    
    methods
        function this = bdGUI(varargin)
            % Constructor
            %
            % gui = bdGUI();
            % gui = bdGUI(sys);
            % gui = bdGUI(sys,'sol',sol);
            
            % add the bdtoolkit/solvers directory to the path
            addpath(fullfile(fileparts(mfilename('fullpath')),'solvers'));

            % add the bdtoolkit/panels directory to the path
            addpath(fullfile(fileparts(mfilename('fullpath')),'panels'));
          
            % variable input parameters
            switch nargin
                case 0      % case of bdGUI()
                    try
                        % load the sys (and sol) struct from mat file 
                        [sys,sol] = loadsys();
                        if isempty(sys)
                            % user cancelled the load operation
                            this = bdGUI.empty();
                            return
                        end
                    catch ME
                        ME.throwAsCaller;
                    end
                        
                otherwise   % case of bdGUI(sys,'sol',sol)
                    try
                        % define a syntax for the input parser
                        syntax = inputParser;
                        syntax.CaseSensitive = false;
                        syntax.FunctionName = 'bdGUI(sys,''sol'',sol)';
                        syntax.KeepUnmatched = false;
                        syntax.PartialMatching = false;
                        syntax.StructExpand = false;
                        addRequired(syntax,'sys',@(sys) ~isempty(bd.syscheck(sys)));
                        addParameter(syntax,'sol',[], @(sol) solcheck(sol));

                        % call the input parser
                        parse(syntax,varargin{:});
                        sys = syntax.Results.sys;
                        sol = syntax.Results.sol;

                        % check that the sol and sys are compatabile
                        solsyscheck(sol,sys);
                        
                    catch ME
                        ME.throwAsCaller;
                    end
            end     
                                    
            % construct figure
            figw = 800;
            figh = 500;
            this.fig = figure('Units','pixels', ...
                'Position',[randi(100,1,1) randi(100,1,1) figw figh], ...
                'name', 'Brain Dynamics Toolbox', ...
                'NumberTitle','off', ...
                'MenuBar','none', ...
                'DockControls','off', ...
                'Toolbar','figure');

            % construct the control panel and attach it to the figure
            this.control = bdControl(this.fig,sys);

            % construct the display panel and attach it to the figure
            this.display = bdDisplay(this.fig,sys);

            % Construct the System menu
            this.SystemMenu(sys);

            % Customize the Toolbar
            this.CustomizeToolbar();

            try
                % construct the display panels menu
                this.display.PanelsMenu(this.fig,this.control);
            catch ME
                close(this.fig);
                ME.throwAsCaller;
            end

            % resize the uipanels (putting them in their exact position)
            this.SizeChanged();

            % load all of the display panels specified in sys.panels
            this.display.LoadPanels(this.control);

            % register a callback for resizing the figure
            set(this.fig,'SizeChangedFcn', @(~,~) this.SizeChanged());

            if isempty(sol)
                % force a recompute
                notify(this.control,'recompute');
            else
                % load the given sol and issue a redraw event
                this.control.LoadSol(sol);
            end
                      
        end
       
        % Get par property
        function par = get.par(this)
            % return a struct with paramater values stored by name
            par = this.control.par;
            
            % the old way
            %par = [];
            %for indx = 1:numel(this.control.sys.pardef)
            %    name = this.control.sys.pardef(indx).name;
            %    value = this.control.sys.pardef(indx).value;
            %    par.(name) = value;
            %end
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
            
            % Notify the control panel to refresh its pardef widgets
            % and then to recompute the trajectory.
            notify(this.control,'pardef');
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
            
            % Notify the control panel to refresh its vardef widgets
            % and then to recompute the trajectory.
            notify(this.control,'vardef');
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
        
        % Get tindx (index of the non-transient time steps) property
        function tindx = get.tindx(this)
            tindx = this.control.tindx;
        end

        % Get lag property
        function lag = get.lag(this)
            % return a struct with initial values stored by name
            lag = this.control.lag;
            
            %the old way
            %lag = [];
            %if isfield(this.control.sys,'lagdef')
            %    for indx = 1:numel(this.control.sys.lagdef)
            %        name = this.control.sys.lagdef(indx).name;
            %        value = this.control.sys.lagdef(indx).value;
            %        lag.(name) = value;
            %    end
            %end
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
            
            % Notify the control panel to refresh its lagdef widgets
            % and then to recompute the trajectory.
            notify(this.control,'lagdef');
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
        
        % Get panels property
        function panels = get.panels(this)
           panels = this.display.ExportPanels(); 
        end
 
    end
       
    
    methods (Access=private)
        
        % Construct the System menu
        function menuobj = SystemMenu(this,sys)
            % construct System menu
            menuobj = uimenu('Parent',this.fig, 'Label','System');

            % construct menu items
            uimenu('Parent',menuobj, ...
                   'Label','About', ...
                   'Callback',@(~,~) SystemAbout() );
            uimenu('Parent',menuobj, ...
                   'Label','New', ...
                   'Callback', @(~,~) bdGUI(this.control.sys) );
            uimenu('Parent',menuobj, ...
                   'Label','Load', ...
                   'Callback', @(~,~) bdGUI() );
            uimenu('Parent',menuobj, ...
                   'Label','Save', ...
                   'Callback', @(~,~) this.SystemSaveDialog() );
            uimenu('Parent',menuobj, ...
                   'Label','Quit', ...
                   'Separator','on', ...
                   'Callback', @(~,~) delete(this.fig));

            % Callback for System-About menu
            function SystemAbout()
                msg = {'The Brain Dynamics Toolbox'
                       ['Version ' this.version]
                       'http://www.bdtoolbox.org'
                       ''
                       'Stewart Heitmann, Michael Breakspear'
                       'Copyright (C) 2016-2018'
                       'QIMR Berghofer Medical Research Institute'
                       'BSD 2-clause License'
                       };
                uiwait(helpdlg(msg,'About'));
            end
            
        end
        
        % Customize the Figure Toolbar
        function CustomizeToolbar(this)
            % get handle to the toolbar
            hToolBar = findall(this.fig,'tag','FigureToolBar');
            if isempty(hToolBar)
                return
            end
            
            % customize the NewFigure tool
            hnd = findall(hToolBar,'tag','Standard.NewFigure');
            if ~isempty(hnd)
                hnd.ClickedCallback =  @(~,~) bdGUI(this.control.sys); 
                hnd.TooltipString = 'New Instance';
            end
            
            % customize the FileOpen tool
            hnd = findall(hToolBar,'tag','Standard.FileOpen');
            if ~isempty(hnd)
                hnd.ClickedCallback =  @(~,~) bdGUI(); 
                hnd.TooltipString = 'Load System';
            end
            
            % customize the SaveFigure tool
            hnd = findall(hToolBar,'tag','Standard.SaveFigure');
            if ~isempty(hnd)
                hnd.ClickedCallback =  @(~,~) this.SystemSaveDialog(); 
                hnd.TooltipString = 'Save System';
            end
            
            % delete the PrintFigure tool
            delete( findall(hToolBar,'tag','Standard.PrintFigure') );
            
            % delete the EditPlot tool
            delete( findall(hToolBar,'tag','Standard.EditPlot') );

            % delete the Data Linking tool
            delete( findall(hToolBar,'tag','DataManager.Linking') );
            
            % delete the Annotation tools
            delete( findall(hToolBar,'tag','Annotation.InsertLegend') );
            delete( findall(hToolBar,'tag','Annotation.InsertColorbar') );
            
            % delete the PlotTools
            delete( findall(hToolBar,'tag','Plottools.PlottoolsOn') );
            delete( findall(hToolBar,'tag','Plottools.PlottoolsOff') );
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

            % Construct scrolling uipanel. We create it with an arbitrary
            % height (1000 pixels) that will be adjusted once the panel
            % contents have been created.
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
                'TooltipString', 'sys is the system structure', ...
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
                'TooltipString', 'sol is the solution structure', ...
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
                dims = size(this.control.sys.pardef(indx).value);

                % parameter check box
                uicontrol('Style','checkbox', ...
                    'String', name, ...
                    'UserData', struct('name',name,'indx',indx), ...
                    'Tag', 'bdExportPar', ...
                    'TooltipString', num2str(dims,[name ' is %dx%d']), ...
                    'HorizontalAlignment', 'left', ...
                    'FontUnits', 'pixels', ...
                    'FontSize', 12, ...
                    'Parent', scrollpanel, ...
                    'Position', [20 panelh-yoffset panelw boxh]);

                % next row
                yoffset = yoffset + rowh;
            end

            % If our system has lag parmaters then include them in teh menu
            if isfield(this.control.sys,'lagdef')
                % skip quarter row
                yoffset = yoffset + 0.25*rowh;

                % TIME LAG title
                uicontrol('Style','text', ...
                    'String','Time Lags', ...
                    'HorizontalAlignment','left', ...
                    'FontUnits','pixels', ...
                    'FontSize',12, ...
                    'FontWeight','bold', ...
                    'Parent', scrollpanel, ...
                    'Position',[10 panelh-yoffset panelw boxh]);

                % next row
                yoffset = yoffset + rowh;

                % for each entry in sys.lagdef
                for indx = 1:numel(this.control.sys.lagdef)
                    % get name of parameter
                    name = this.control.sys.lagdef(indx).name;
                    dims = size(this.control.sys.lagdef(indx).value);

                    % parameter check box
                    uicontrol('Style','checkbox', ...
                        'String', name, ...
                        'UserData', struct('name',name,'indx',indx), ...
                        'Tag', 'bdExportLag', ...
                        'TooltipString', num2str(dims,[name ' is %dx%d']), ...
                        'HorizontalAlignment', 'left', ...
                        'FontUnits', 'pixels', ...
                        'FontSize', 12, ...
                        'Parent', scrollpanel, ...
                        'Position', [20 panelh-yoffset panelw boxh]);

                    % next row
                    yoffset = yoffset + rowh;
                end
            end
            
            % skip quarter row
            yoffset = yoffset + 0.25*rowh;

            % STATE VARIABLES title
            uicontrol('Style','text', ...
                'String','State Variables', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','bold', ...
                'Parent', scrollpanel, ...
                'Position',[10 panelh-yoffset panelw boxh]);

            % next row
            yoffset = yoffset + rowh;  

            % for each entry in sys.vardef
            for indx = 1:numel(this.control.sys.vardef)
                % get name and size of the variable
                name = this.control.sys.vardef(indx).name;
                vlen = numel(this.control.sys.vardef(indx).value);
                tlen = numel(this.control.sol.x);
                
                % get the indexes of the variable in sol
                solindx = this.control.sys.vardef(indx).solindx;
                
                % variable check box
                uicontrol('Style','checkbox', ...
                    'String',name, ...
                    'UserData', struct('name',name,'solindx',solindx), ...
                    'Tag', 'bdExportVar', ...
                    'TooltipString', num2str([vlen tlen],[name ' is %dx%d']), ...
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
                'TooltipString', num2str(numel(this.sol.x),'t is 1x%d'), ...
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

            % get the names of the current display panels
            panelnames = this.display.PanelNames(); 

            % for each type of display panel  ...
            for cindx = 1:numel(panelnames)
                panelclass = panelnames(cindx).panelclass;
                paneltitle = panelnames(cindx).paneltitle;

                % Panel Name
                uicontrol('Style','checkbox', ...
                'String',panelclass, ...
                'UserData',panelnames(cindx), ...
                'TooltipString', paneltitle, ...
                'Tag', 'bdExportPanel', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', scrollpanel, ...
                'Position',[20 panelh-yoffset panelw boxh]);

                % next row
                yoffset = yoffset + rowh;
            end
            
            % Adjust the height of the scrollpanel and vertically align
            % the widgets to the (new) top of the panel.
            scrollpanel.Position(4) = yoffset + 30;
            bd.alignTop(scrollpanel,10);
        end
        
        % System-Save menu callback
        function SystemSaveMenu(this,dlg,panel)
            % initialise the outgoing data
            data = [];
            
            % The matlab save function wont save an empty struct
            % so we ensure that our struct always has something in it.
            data.bdtoolbox = this.version;      % toolkit version string
            data.date = date();                 % today's date
                
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
            if ~isempty(objs)
                objs = objs(end:-1:1);                  % reverse the order of the found widgets (because find returns the most recently created widget first)
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
            end
            
            % find all time lag checkbox widgets in the scroll panel
            objs = findobj(panel,'Tag','bdExportLag');
            if ~isempty(objs)
                objs = objs(end:-1:1);                  % reverse the order of the found widgets (because find returns the most recently created widget first)          
                for obj = objs'                         % for each checkbox widget ...
                    if obj.Value>0                      % if checkbox is enabled then ...
                        name = obj.UserData.name;       % get the parameter name
                        indx = obj.UserData.indx;       % get the parameter indx
                        % ensure data.lag exists
                        if ~isfield(data,'lag')
                            data.lag = [];
                        end
                        % include the lag parameter values in the outgoing data
                        data.lag.(name) = this.control.sys.lagdef(indx).value;
                    end
                end
            end
            
            % find all solution variable checkbox widgets in the scroll panel
            objs = findobj(panel,'Tag','bdExportVar');
            if ~isempty(objs)
                objs = objs(end:-1:1);                  % reverse the order of the found widgets (because find returns the most recently created widget first)
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
            end
            
            % find the time checkbox widget in the scroll panel
            objs = findobj(panel,'Tag','bdExportTime');
            if objs.Value>0
                % include the time steps in the outgoing data
                data.t = this.control.sol.x;
            end

            % find all panel-related checkbox widgets in the scroll panel
            objs = findobj(panel,'Tag','bdExportPanel');
            if ~isempty(objs)
                objs = objs(end:-1:1);                          % reverse the order of the found widgets (because find returns the most recently created widget first)
                for obj = objs'                                 % for each checkbox widget ...
                    if obj.Value>0                              % if checkbox is enabled then ...
                        % ensure data.panels exists
                        if ~isfield(data,'panels')
                            data.panels = [];
                        end
                        % get the name of the panel class from the widget UserData
                        panelclass = obj.UserData.panelclass;
                        % copy the panel data to the outgoing data
                        data.panels.(panelclass) = this.display.ExportPanel(panelclass);
                    end
                end
            end
            
            % Close the dialog box
            delete(dlg);

            % Save data to mat file
            [fname,pname] = uiputfile('*.mat','Save system file');
            if fname~=0
                save(fullfile(pname,fname),'-struct','data');
            end
            
        end
        
        % Callback for window resize events
        function SizeChanged(this)
            % resize the control panel
            this.control.SizeChanged(this.fig);
            % resize the display panel
            this.display.SizeChanged(this.fig);
        end
        
    end
    
 
end


% Performs a basic check of the format of the sol structure.
% Throws an exception if any problem is detected.
function solcheck(sol)
    if ~isstruct(sol)
        throw(MException('bdGUI:badsol','The sol variable must be a struct'));
    end
    if ~isfield(sol,'solver')
        throw(MException('bdGUI:badsol','The sol.solver field is missing'));
    end
    if ~isfield(sol,'x')
        throw(MException('bdGUI:badsol','The sol.x field is missing'));
    end
    if ~isfield(sol,'y')
        throw(MException('bdGUI:badsol','The sol.y field is missing'));
    end
    if ~isfield(sol,'stats')
        throw(MException('bdGUI:badsol','The sol.stats field is missing'));
    end
    if ~isstruct(sol.stats)
        throw(MException('bdGUI:badsol','The sol.stats field must be a struct'));
    end
    if ~isfield(sol.stats,'nsteps')
        throw(MException('bdGUI:badsol','The sol.stats.nsteps field is missing'));
    end
    if ~isfield(sol.stats,'nfailed')
        throw(MException('bdGUI:badsol','The sol.stats.nfailed field is missing'));
    end
    if ~isfield(sol.stats,'nfevals')
        throw(MException('bdGUI:badsol','The sol.stats.nfevals field is missing'));
    end    
end

% Cross-checks the format of the sol struct against the sys struct.
function solsyscheck(sol,sys)
    if isempty(sol)
        return
    end
    if numel(bdGetValues(sys.vardef)) ~= size(sol.y,1)
        throw(MException('bdGUI:badsol','The sol and sys structs are incompatible'));
    end
end

% Prompt the user to load a sys struct (and optionally a sol struct) from a matlab file. 
function [sys,sol] = loadsys()
    % init the return values
    sys = [];
    sol = [];

    % prompt the user to select a mat file
    [fname, pname] = uigetfile({'*.mat','MATLAB data file'},'Load system file');
    if fname==0
        return      % user cancelled the operation
    end

    % load the mat file that the user selected
    warning('off','MATLAB:load:variableNotFound');
    fdata = load(fullfile(pname,fname),'sys','sol');
    warning('on','MATLAB:load:variableNotFound');
    
    % extract the sys structure 
    if isfield(fdata,'sys')
        sys = fdata.sys;
    else
        msg = {'The load operation has failed because the selected mat file does not contain a ''sys'' structure.'
               ''
               'Explanation: Every model is defined by a special data structure that is named ''sys'' by convention. The System-Load menu has failed to find a data structure of that name in the selected mat file.'
               ''
               'To succeed, select a mat file that you know contains a ''sys'' structure. Example models are provided in the ''bdtoolkit'' installation directory. See Chapter 1 of the Handbook for the Brain Dynamics Toolbox for a list.'
               ''
               };
        uiwait( warndlg(msg,'Load failed') );
        throw(MException('bdGUI:badsys','Missing sys structure'));
    end

    % check the sys struct and display a dialog box if errors are found
    try
        % check the validity of the sys structure
        sys = bd.syscheck(sys);                        
    catch ME
        switch ME.identifier
            case {'bdtoolkit:syscheck:odefun'
                  'bdtoolkit:syscheck:ddefun'
                  'bdtoolkit:syscheck:sdeF'
                  'bdtoolkit:syscheck:sdeG'}
                msg = {ME.message
                       ''
                       'Explanation: The model could not be loaded because its ''sys'' structure contains a handle to a function that is not in the matlab search path.'
                       ''
                       'To succeed, ensure that all functions belonging to the model are accessible to matlab via the search path. See ''Getting Started'' in the Handbook for the Brain Dynamics Toolbox.'
                       ''
                       };
                uiwait( warndlg(msg,'Missing Function') );
            
            otherwise
                msg = {ME.message
                       ''
                       'Explanation: The model could not be loaded because its ''sys'' structure is invalid. Use the ''bdSysCheck'' command-line tool to diagnose the exact problem. Refer to the Handbook for the Brain Dynamics Toolbox for a comprehensive description of the format of the ''sys'' structure.'
                       ''
                       };
                uiwait( warndlg(msg,'Invalid sys structure') );
        end
        throw(MException('bdGUI:badsys','Invalid sys structure'));
    end
        
    % extract the sol structure (if it exists) 
    if isfield(fdata,'sol')
        sol = fdata.sol;
        try
            % check that the sol struct matches the sys struct.
            solsyscheck(sol,sys);
        catch ME
            msg = {ME.message
                   ''
                   'Explanation: The solution (sol) found in the mat file is not compatible with this model (sys). The solution data is ignored.'
                   ''
                   };
            uiwait( warndlg(msg,'Solution not loaded') );
            sol = [];
        end
    end
end

