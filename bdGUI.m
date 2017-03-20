classdef bdGUI < handle
    %bdGUI - The Brain Dynamics Toolbox Graphic User Interface.
    %   Opens a dynamical system model (sys) with the Brain Dynamics
    %   Toolbox graphical user interface.
    %   
    %EXAMPLE
    %   sys = ODEdemo1();
    %   gui = bdGUI(sys);
    %
    %AUTHORS
    %  Stewart Heitmann (2016a,2017a)

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

    properties
        fig             % handle to the application figure
    end
    
    properties (Dependent)
        sys             % system definition structure
        sol             % current output of the solver
        sox             % current auxiliary variables
        panels          % current panel object handles
    end
    
    properties (Access=private)
        control         % handle to the bdControl object
        uipanel1        % handle to uipanel 1
        uipanel2        % handle to uipanel 2
        tabgroup        % handle to tabgroup in panel1
        panelobjs = {}; % list of handles to panel objects
    end
    
    methods
        % bdGUI(sys) or bdGUI()
        function this = bdGUI(varargin)
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
                        this.panelobjs{end+1} = feval(classname,this.tabgroup,this.control);
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
            % first remove any stale (deleted) handles from panelobjs
            for indx = numel(this.panelobjs):-1:1
                if ~isvalid(this.panelobjs{indx})
                    this.panelobjs(indx) = [];
                end
            end           
            % return a panels struct with object handles arranged by name
            panels = [];
            for indx = 1:numel(this.panelobjs)
                obj = this.panelobjs{indx};
                meta = metaclass(obj);
                name = meta.Name;
                if isfield(panels,name)
                    objs = getfield(panels,name);
                    objs(end+1) = obj;
                else
                    objs = obj;
                end
                panels = setfield(panels,name,objs);
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
                   'Label','Load sys', ...
                   'Callback', @(~,~) SystemLoad() );
            uimenu('Parent',menuobj, ...
                   'Label','Save sys', ...
                   'Callback', @(~,~) SystemSave() );
            uimenu('Parent',menuobj, ...
                   'Label','Quit', ...
                   'Separator','on', ...
                   'Callback', @(~,~) SystemQuit() );

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
                fname = uigetfile({'*.mat','MATLAB data file'},'Load system file');
                if fname~=0
                    fdata = load(fname,'sys');
                    if isfield(fdata,'sys')
                        gui = bdGUI(fdata.sys);
                    else
                        uiwait( warndlg({'Missing ''sys'' variable','System is unchanged'},'Load failed') );
                    end
                end
            end

            % Callback for System-Save menu
            function SystemSave()
                [fname,pname] = uiputfile('*.mat','Save system file');
                if fname~=0
                    sys = this.control.sys;
                    if isfield(sys,'odeoption')
                        sys.odeoption = odeset(sys.odeoption,'OutputFcn',[]);
                    end
                    if isfield(sys,'ddeoption')
                        sys.ddeoption = ddeset(sys.ddeoption,'OutputFcn',[]);
                    end
                    if isfield(sys,'sdeoption')
                        sys.sdeoption = odeset(sys.sdeoption,'OutputFcn',[]);
                    end
                    save(fullfile(pname,fname),'sys');
                end
            end      
            
            % Callback for System-Quit menu
            function SystemQuit()
                delete(this.fig);
            end
        end
        
        % Construct the Panel menu
        function menuobj = PanelsMenu(this,sys)
            classnames = {'bdLatexPanel','bdTimePortrait','bdPhasePortrait','bdSpaceTime','bdCorrPanel','bdSolverPanel'};
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
                    'Label','Solver Panel', ...
                    'Callback', @(~,~) NewPanel('bdSolverPanel'));
      
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
                    % construct the panel and remember the handle
                    this.panelobjs{end+1} = feval(classname,this.tabgroup,this.control);
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


