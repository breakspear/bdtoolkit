classdef bdGUI < handle
    %bdGUI - The Brain Dynamics Toolbox Graphical User Interface (GUI).
    %
    %The bdGUI application is the graphical user interface for the Brain
    %Dynamics Toolbox. It loads and runs the model defined by the given
    %system structure (sys). That structure contains a handle to the
    %model's ODE function (sys.odefun). It also defines the names and
    %initial values of the system parameters/variables.
    %
    %   gui = bdGUI(sys);
    %
    %The system structure may be passed to bdGUI as an input parameter or
    %loaded from a mat file. If bdGUI is invoked with no parameters then it
    %prompts the user to load a mat file which is assumed to contain a sys.
    %
    %   gui = bdGUI();
    %
    %A previously computed solution (sol) can be loaded in tandem with the
    %model's system structure. If no solution is provided then bdGUI
    %automatically computes one at start-up.
    %
    %   gui = bdGUI(sys,'sol',sol);
    %
    %The call to bdGUI returns a handle (gui) to the bdGUI class. That
    %handle can be used to control the graphical user interface from the
    %matlab workspace.
    %
    %EXAMPLE
    %   >> cd bdtoolkit
    %   >> addpath models
    %   >> sys = LinearODE();
    %   >> gui = bdGUI(sys);
    %
    %   gui = bdGUI with properties:
    %       version: '2019a'
    %           fig: [1x1 Figure]
    %           par: [1x1 struct]
    %          var0: [1x1 struct]
    %          var1: [1x1 struct]
    %         tspan: [0 20]
    %          tval: 0
    %             t: [1x116 double]
    %         tindx: [1x116 logical]
    %           lag: [1x1 struct]
    %           sys: [1x1 struct]
    %           sol: [1x1 struct]
    %        panels: [1x1 struct]
    %          halt: 0
    %        evolve: 0
    %       perturb: 0
    %
    % Where
    %   gui.version is the version string of the toolbox (read-only)
    %   gui.fig is a handle to the application figure (read/write)
    %   gui.par is a struct containing the model parameters (read/write)
    %   gui.var0 is a struct containing the initial conditions (read/write)
    %   gui.var1 is a struct containing the computed time-series (read-only)
    %   gui.tspan is the time span of the simulation (read/write)
    %   gui.tval is the current value of the time slider (read/write)
    %   gui.t contains the time steps for the computed solution (read-only)
    %   gui.tindx contains the indices of the non-transient time steps (read-only)
    %   gui.lag is a struct containing the DDE lag parameters (read/write)
    %   gui.sys is a copy of the model's system structure (read-only)
    %   gui.sol is the output of the solver (read-only)
    %   gui.panels contains the outputs of the display panels (read-only)
    %   gui.halt is the state of the HALT button (read/write)
    %   gui.evolve is the state of the EVOLVE button (read/write)
    %   gui.perturb is the state of the PERTURB button (read/write)
    %
    %SOFTWARE MANUAL
    %   Handbook for the Brain Dynamics Toolbox: Version 2019a.
    %
    %ONLINE COURSES (bdtoolbox.org)
    %   Toolbox Basics - Getting started with the Brain Dynamics Toolbox
    %   Modeller's Workshop - Building custom models with the Brain Dynamics Toolbox
    %
    %AUTHORS
    %   Stewart Heitmann (2016a-2019a)

    % Copyright (C) 2016-2019 QIMR Berghofer Medical Research Institute
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
        version = '2019a';      % version number of the toolbox
    end
    
    properties
        fig             % graphics handle for the application figure
    end
        
    properties (Dependent)
        par             % system parameters (read/write)
        var0            % initial conditions (read/write)
        var1            % solution varables (read only)
        tspan           % time domain (read/write)
        tval            % time slider value (read/write) 
        t               % solution time steps (read only)
        tindx           % logical index of the non-transient time steps (read only)
        lag             % DDE time lags (read/write)
        sys             % system definition structure (read only)
        sol             % current output of the solver (read only)
        panels          % current panel object handles (read only)
        halt            % halt button state (read/write)
        evolve          % evolve button state (read/write)
        perturb         % perturb button state (read/write)
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
                        
                        % ensure that sys.tspan matches the computed solution
                        if ~isempty(sol) && isfield(sol,'x')
                            sys.tspan = sol.x([1 end]);
                        end
                        
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
                % recompute and wait until complete
                this.control.RecomputeWait();    
            else
                % load the given sol and issue a redraw event
                this.control.LoadSol(sol);
            end
                      
        end
       
        % Get par property
        function par = get.par(this)
            % return a struct with paramater values stored by name
            par = this.control.par;
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
            notify(this.control,'pardef');
            
            % recompute and wait until complete
            this.control.RecomputeWait();    
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
            notify(this.control,'vardef');
            
            % recompute and wait until complete
            this.control.RecomputeWait();         
        end
        
        % Get var1 (solution variables) property
        function var1 = get.var1(this)
            % return a struct with the solution variables stored by name
            var1 = [];
            solindx = 0;
            for indx = 1:numel(this.control.sys.vardef)
                % get name and length of variable
                name = this.control.sys.vardef(indx).name;
                len = numel(this.control.sys.vardef(indx).value);
                % compute the index of the variable in sol.y
                solindx = solindx(end) + (1:len);
                % return the solution variables
                var1.(name) = this.control.sol.y(solindx,:);
            end
        end

        % Get tspan (time domain) property
        function tspan = get.tspan(this)
            tspan = this.control.sys.tspan;
        end 
        
        % Set tspan (time domain) property
        function set.tspan(this,tspan)
            % error handling
            if ~isnumeric(tspan) || numel(tspan)~=2
                throwAsCaller(MException('bdGUI:tspan','gui.tspan must contain exactly two numeric values'));
            end
            if tspan(1) >= tspan(2)
                throwAsCaller(MException('bdGUI:tspan','gui.tspan=[t0 t1] must have t0<t1'));
            end
            
            % update the system structure
            this.control.sys.tspan = tspan;
            this.control.sys.tval = max(tspan(1),this.control.sys.tval);
            this.control.sys.tval = min(tspan(2),this.control.sys.tval);
            
            % Notify the control panel to refresh its widgets
            notify(this.control,'refresh');
            
            % recompute and wait until complete
            this.control.RecomputeWait();         
        end
        
        % Get tval (time slider value) property
        function tval = get.tval(this)
            tval = this.control.sys.tval;
        end
        
        % Set tval (time slider value) property
        function set.tval(this,tval)
            % error handling
            if ~isnumeric(tval) || numel(tval)~=1
                throwAsCaller(MException('bdGUI:tval','gui.tval must be numeric'));
            end
            
            % update the system structure
            this.control.sys.tval = tval;

            % adjust tspan if necessary
            Tspan = this.control.sys.tspan;
            if tval<Tspan(1) || tval>Tspan(2)
                Tspan(1) = min(Tspan(1),tval);
                Tspan(2) = max(Tspan(2),tval);
                this.control.sys.tspan = Tspan;
            
                % Notify the control panel to refresh its widgets
                notify(this.control,'refresh');
            
                % recompute and wait until complete
                this.control.RecomputeWait();
            else
                % Notify the control panel to refresh its widgets
                notify(this.control,'refresh');

                % update the indicies of the non-tranient time steps in sol.x
                this.control.tindx = (this.control.sol.x >= this.control.sys.tval);

                % Notify all panels to redraw
                notify(this.control,'redraw');                
                drawnow;
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
            notify(this.control,'lagdef');
            
            % recompute and wait until complete
            this.control.RecomputeWait();    
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
 
        % Get halt property
        function halt = get.halt(this)
           halt = logical(this.control.sys.halt); 
        end
 
        % Set halt property
        function set.halt(this,value)
            % error handling
            if ~isnumeric(value) || numel(value)~=1
                throwAsCaller(MException('bdGUI:halt','gui.halt must be 0 or 1'));
            end
            % update the halt property of the control panel
            this.control.sys.halt = logical(value);
            % notify all control panel widgets to refresh themselves
            notify(this.control,'refresh');
            % if the halt state is now OFF then ...
            if ~this.control.sys.halt
                % recompute and wait until complete
                this.control.RecomputeWait();    
            end
        end
        
        % Get evolve property
        function evolve = get.evolve(this)
           evolve = logical(this.control.sys.evolve); 
        end
 
        % Set evolve property
        function set.evolve(this,value)
            % error handling
            if ~isnumeric(value) || numel(value)~=1
                throwAsCaller(MException('bdGUI:evolve','gui.evolve must be 0 or 1'));
            end
            % update the evolve property of the control panel
            this.control.sys.evolve = logical(value);
            % notify the panel widgets to refresh themselves
            notify(this.control,'refresh');
            % if the evolve state is now ON then ...
            if this.control.sys.evolve
                % recompute and wait until complete
                this.control.RecomputeWait();    
            end
        end
        
        % Get perturb property
        function perturb = get.perturb(this)
           perturb = logical(this.control.sys.perturb); 
        end
 
        % Set perturb property
        function set.perturb(this,value)
            % error handling
            if ~isnumeric(value) || numel(value)~=1
                throwAsCaller(MException('bdGUI:perturb','gui.perturb must be 0 or 1'));
            end
            % update the perturb property of the control panel
            this.control.sys.perturb = logical(value);
            % notify the widgets to refresh themselves
            notify(this.control,'refresh');
            % if the perturb state is now ON then ...
            if this.control.sys.perturb
                % recompute and wait until complete
                this.control.RecomputeWait();    
            end
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
                   'Label','Load', ...
                   'Callback', @(~,~) bdGUI() );
            uimenu('Parent',menuobj, ...
                   'Label','Save', ...
                   'Callback', @(~,~) this.SystemSaveDialog() );
            uimenu('Parent',menuobj, ...
                   'Label','Export', ...
                   'Callback', @(~,~) this.SystemExportDialog() );
            uimenu('Parent',menuobj, ...
                   'Label','Duplicate', ...
                   'Callback', @(~,~) bdGUI(this.control.sys) );
            uimenu('Parent',menuobj, ...
                   'Label','Quit', ...
                   'Separator','on', ...
                   'Callback', @(~,~) delete(this.fig));

            % Callback for System-About menu
            function SystemAbout()
                dlg = dialog('Position',[300 300 500 300],'Name',['Brain Dynamics Toolbox: Version ' this.version]);
                ax = axes('Parent',dlg, 'Position',[0 0 1 1]);
                img = imread('About.png');
                imshow(img,'Parent',ax);
                uicontrol('Parent',dlg, 'Position',[430 20 50 25], ...
                    'String','Close', ...
                    'Callback',@(src,evnt) delete(dlg));
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
            % widget geometry
            panelw = 180;
            panelh = 390;
            yoffset = 30;
            boxh = 20;
            rowh = 22;            

            % construct dialog box
            dlg = figure('Units','pixels', ...
                'Position',[randi(300,1,1) randi(300,1,1), panelw, panelh], ...
                'MenuBar','none', ...
                'Name','Save to File', ...
                'NumberTitle','off', ...
                'ToolBar', 'none', ...
                'Resize','off');

            % SYSTEM title
            uicontrol('Style','text', ...
                'String','System', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','bold', ...
                'Parent', dlg, ...
                'Position',[10 panelh-yoffset panelw boxh]);

            % next row
            yoffset = yoffset + rowh;

            % sys check box
            uicontrol('Style','checkbox', ...
                'String','sys', ...
                'Value', 1, ...
                'Tag', 'bdSaveSys', ...
                'TooltipString', 'sys is the system structure', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', dlg, ...
                'Position',[20 panelh-yoffset panelw boxh]);

            % next row
            yoffset = yoffset + rowh;

            % sol check box
            uicontrol('Style','checkbox', ...
                'String','sol', ...
                'Tag', 'bdSaveSol', ...
                'TooltipString', 'sol is the solution structure', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', dlg, ...
                'Position',[20 panelh-yoffset panelw boxh]);

            % next row
            yoffset = yoffset + 1.5*rowh;

            % PARAMETERS title
            uicontrol('Style','text', ...
                'String','Parameters', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','bold', ...
                'Parent', dlg, ...
                'Position',[10 panelh-yoffset panelw boxh]);

            % next row
            yoffset = yoffset + rowh;

            % par check box
            uicontrol('Style','checkbox', ...
                'String','par', ...
                'Tag', 'bdSavePar', ...
                'TooltipString', 'par contains the system parameters', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', dlg, ...
                'Position',[20 panelh-yoffset panelw boxh]);      
            
            % next row
            yoffset = yoffset + rowh;

            % If our system has lag parameters then enable that checkbox
            if isfield(this.control.sys,'lagdef')
                lagEnable = 'on';
            else
                lagEnable = 'off';
            end

            % lag check box
            uicontrol('Style','checkbox', ...
                'String','lag', ...
                'Tag', 'bdSaveLag', ...
                'TooltipString', 'lag contains the time-lag parameters', ...
                'Enable', lagEnable, ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', dlg, ...
                'Position',[20 panelh-yoffset panelw boxh]);
            
            % next row
            yoffset = yoffset + 1.5*rowh;           

            % STATE VARIABLES title
            uicontrol('Style','text', ...
                'String','State Variables', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','bold', ...
                'Parent', dlg, ...
                'Position',[10 panelh-yoffset panelw boxh]);

            % next row
            yoffset = yoffset + rowh;

            % var0 check box
            uicontrol('Style','checkbox', ...
                'String','var0', ...
                'Tag', 'bdSaveVar0', ...
                'TooltipString', 'var0 contains the initial conditions', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', dlg, ...
                'Position',[20 panelh-yoffset panelw boxh]);
            
            % next row
            yoffset = yoffset + rowh;  
            
            % var1 check box
            uicontrol('Style','checkbox', ...
                'String','var1', ...
                'Tag', 'bdSaveVar1', ...
                'TooltipString', 'var1 contains the computed trajectories', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', dlg, ...
                'Position',[20 panelh-yoffset panelw boxh]);
           
            % next row
            yoffset = yoffset + 1.5*rowh;

            % TIME DOMAIN title
            uicontrol('Style','text', ...
                'String','Time Domain', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','bold', ...
                'Parent', dlg, ...
                'Position',[10 panelh-yoffset panelw boxh]);

            % next row
            yoffset = yoffset + rowh;                                    

            % time check box
            uicontrol('Style','checkbox', ...
                'String','t', ...
                'Tag', 'bdSaveTime', ...
                'TooltipString', num2str(numel(this.sol.x),'t is 1x%d'), ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', dlg, ...
                'Position',[20 panelh-yoffset panelw boxh]);
            
            % next row
            yoffset = yoffset + 2.75*rowh;
            
            % button group for the FORMAT radio buttons
            bgrp = uibuttongroup('Visible','on', ...
                'Parent', dlg, ...
                'Title', 'File Format', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Units', 'pixels', ...
                'Position',[10, panelh-yoffset, panelw-20, 2*rowh] );
            
            % v6 radio button
            uicontrol('Style','radiobutton', ...
                'String','v6', ...
                'Value', 0, ...
                'Tag', 'bdSaveV6', ...
                'TooltipString', 'v6 files will load in MATLAB 5.0 (R8) or later', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', bgrp, ...
                'Units','pixels', ...
                'Position',[5 5 50 rowh]);

            % v7 radio button
            uicontrol('Style','radiobutton', ...
                'String','v7', ...
                'Value', 0, ...
                'Tag', 'bdSaveV7', ...
                'TooltipString', 'v7 files will load in MATLAB 7.0 (R14) or later', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', bgrp, ...
                'Units','pixels', ...
                'Position',[55 5 50 rowh]);

            % v7.3 radio button
            uicontrol('Style','radiobutton', ...
                'String','v7.3', ...
                'Value', 1, ...
                'Tag', 'bdSaveV73', ...
                'TooltipString', 'v7.3 files will load in MATLAB 7.3 (R2006b) or later', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', bgrp, ...
                'Units','pixels', ...
                'Position',[105 5 50 rowh]);
            
            % construct the 'Cancel' button
            uicontrol('Style','pushbutton', ...
                'String','Cancel', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', dlg, ...
                'Callback', @(~,~) delete(dlg), ...
                'Position',[10 15 60 20]);

            % construct the 'Save' button
            uicontrol('Style','pushbutton', ...
                'String','Save', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', dlg, ...
                'Callback', @(~,~) this.SystemSaveMenu(dlg), ... 
                'Position',[panelw-70 15 60 20]);
        end
        
        % System-Save menu callback
        function SystemSaveMenu(this,dlg)
            % initialise the outgoing data
            data = [];
            
            % The matlab save function wont save an empty struct
            % so we ensure that our struct always has something in it.
            data.bdtoolbox = this.version;      % toolkit version string
            data.date = date();                 % today's date
                
            % find the sys checkbox widget in the dialog box
            objs = findobj(dlg,'Tag','bdSaveSys');
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

            % find the sol checkbox widget in the dialog box
            objs = findobj(dlg,'Tag','bdSaveSol');
            if objs.Value>0
                % include the sol struct in the outgoing data
                data.sol = this.control.sol;
                % remove the OutputFcn option from the sol.extdata.options struct 
                if isfield(data.sol,'extdata') && isfield(data.sol.extdata,'options') && isfield(data.sol.extdata.options,'OutputFcn')
                    data.sol.extdata.options = rmfield(data.sol.extdata.options,'OutputFcn');
                end
            end

            % find the par checkbox widget in the dialog box
            objs = findobj(dlg,'Tag','bdSavePar');
            if objs.Value>0
                % include the par struct in the outgoing data
                data.par = this.par;
            end
            
            % find the lag checkbox widget in the dialog box
            objs = findobj(dlg,'Tag','bdSaveLag');
            if objs.Value>0
                % include the lag parameter values in the outgoing data
                data.lag = this.lag;
            end
            
            % find the var0 checkbox widget in the dialog box
            objs = findobj(dlg,'Tag','bdSaveVar0');
            if objs.Value>0
                % include the initial values in the outgoing data
                data.var0 = this.var0;
            end

            % find the var1 checkbox widget in the dialog box
            objs = findobj(dlg,'Tag','bdSaveVar1');
            if objs.Value>0
                % include the initial values in the outgoing data
                data.var1 = this.var1;
            end
            
            % find the time checkbox widget in the dialog box
            objs = findobj(dlg,'Tag','bdSaveTime');
            if objs.Value>0
                % include the time steps in the outgoing data
                data.t = this.t;
            end
            
            % find the File Format radio buttons in the dialog box
            vflag = [];            
            objs = findobj(dlg,'Tag','bdSaveV6');   % -v6 option
            if objs.Value
                vflag = '-v6';
            end
            objs = findobj(dlg,'Tag','bdSaveV7');   % -v7 option
            if objs.Value
                vflag = '-v7';
            end
            objs = findobj(dlg,'Tag','bdSaveV73');   % -v4 option
            if objs.Value
                vflag = '-v7.3';
            end
            
            % Close the dialog box
            delete(dlg);

            % Save data to mat file
            [fname,pname] = uiputfile('*.mat','Save mat file');
            if fname~=0
                save(fullfile(pname,fname),'-struct','data',vflag);
            end
            
        end
        
        % Construct the System-Export Dialog
        function SystemExportDialog(this)
            labs = {'gui','fig','par','var0','var1','t','lag','sys','sol'};
            vars = {'gui','fig','par','var0','var1','t','lag','sys','sol'};
            vals = {this, this.fig, this.par,this.var0,this.var1,this.t,this.lag,this.sys,this.sol};
            export2wsdlg(labs,vars,vals,'Export to Workspace',false(numel(labs),1));
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
function  solsyscheck(sol,sys)
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

