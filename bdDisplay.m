classdef bdDisplay < handle
    %bdDisplay  Display panel for the Brain Dynamics Toolbox GUI.
    %  This class is specialised for use with bdGUI. It is not intended 
    %  to be called directly by users.
    % 
    %AUTHORS
    %  Stewart Heitmann (2018a)

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
    
    properties
        tabgroup        % handle to the tab group
    end
    
    properties (Access=private)
        dpanel          % handle to container panel
        panelmgr = [];  % contains handles to panel class objects
    end
    
    properties (Constant)
        dpanely = 51;    % vertical position of the display panel
        dpanelm = 10;   % vertical margin at top of display panel
    end

    methods
        % Constructor. 
        function this = bdDisplay(fig,sys)
            % Check the contents of sys and fill any missing fields with
            % default values. Rethrow any problems back to the caller.
            try
                sys = bd.syscheck(sys);
            catch ME
                throwAsCaller(MException('bdtoolkit:bdDisplay',ME.message));
            end
            
            % get parent figure geometry
            figw = fig.Position(3);
            figh = fig.Position(4);

            % construct the container uipanel
            x = 0;
            y = this.dpanely;
            w = figw - bdControl.cpanelw - 10;
            h = figh - this.dpanely - this.dpanelm;
            this.dpanel = uipanel(fig,'Units','pixels','Position',[x y w h],'BorderType','none');
            
            % construct the tab group within the container uipanel
            this.tabgroup = uitabgroup(this.dpanel, ...
                'SelectionChangedFcn', @bdPanel.PanelSelectionChangedFcn, ...
                'Interruptible','off');
        end
       
        % Resize the display panel to fit the figure window.
        function SizeChanged(this,fig)
            % get parent figure geometry
            figw = fig.Position(3);
            figh = fig.Position(4);

            % new geometry of the container uipanel
            x = 0;
            y = this.dpanely;
            w = figw - bdControl.cpanelw - 10;
            h = figh - this.dpanely - this.dpanelm;
            this.dpanel.Position = [x y w h];
        end
        
        % load all display panels specified in control.sys.panels
        function LoadPanels(this,control)
            if isfield(control.sys,'panels')
                panelnames = fieldnames(control.sys.panels);
                for indx = 1:numel(panelnames)
                    classname = panelnames{indx};
                    if exist(classname,'class')
                        % construct the panel, keep a handle to it.
                        classhndl = feval(classname,this.tabgroup,control);
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
        
        % Get a list of the currently loaded panels. Returns an array of
        % structs where names(i).panelclass is the name of the panel
        % class and names(i).paneltitle is the title of the panel tab.
        function names = PanelNames(this) 
            names = [];
            
            % Clean the panelmgr of any stale handles to panel classes
            % that have since been destroyed.
            this.CleanPanelMgr();

            % for each class in panelmgr
            classnames = fieldnames(this.panelmgr);
            for cindx = 1:numel(classnames)
                panelclass = classnames{cindx};
                paneltitle = this.panelmgr.(panelclass).title;
                names(cindx).panelclass = panelclass;
                names(cindx).paneltitle = paneltitle;
            end
        end

        % Export a deep copy of the public properties of the named panel class
        function panel = ExportPanel(this,classname)
            % init outgoing data
            panel = [];
            
            % for each instance of the class
            classcount = numel(this.panelmgr.(classname));
            for indx = 1:classcount
                % for each field in the class
                fldnames = fieldnames(this.panelmgr.(classname));
                for findx = 1:numel(fldnames)
                    fname = fldnames{findx};
                    % deep copy of class properties to output
                    panel(indx).(fname) = this.panelmgr.(classname)(indx).(fname);
                end                    
            end
        end
        
        % Export a deep copy of the public properties of all panel classes
        function panels = ExportPanels(this) 
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

        % Construct the Panel menu
        function menuobj = PanelsMenu(this,fig,control)
            % find all panel classes in the bdtoolkit/panels directory
            panelspath = what('panels');
            if isempty(panelspath)
                msg = {'The display panels were not found in the search path.'
                ''
                'Ensure the ''bdtoolkit/panels'' directory is added to the PATH before starting ''bdGUI''.'
                ''
                'See Chapter 1 of the Handbook for the Brain Dynamics Toolbox.'
                ''
                };
                uiwait( errordlg(msg,'Missing Display Panels') );
                throw(MException('bdGUI:badpath','The ''panels'' directory was not found'));
            end

            % construct the New Panels menu
            menuobj = uimenu('Parent',fig, 'Label','New Panel');
            
            % add the found panels to the menu ...
            for indx = 1:numel(panelspath.m)
                % get the classname of the panel
                [~,panelclass] = fileparts(panelspath.m{indx});
                
                % get the title of the panel
                mc = meta.class.fromName(panelclass);
                mp = findobj(mc.PropertyList,'Name','title');
                if ~isempty(mp)
                    uimenu('Parent',menuobj, ...
                        'Label',mp.DefaultValue, ...
                        'Callback', @(~,~) NewPanel(control,panelclass));
                else
                    warning([panelspath.m{indx} ' is not a valid display panel class.']);
                end
            end
            
            return
            
            classnames = {'bdLatexPanel','bdTimePortrait','bdPhasePortrait','bdBifurcation','bdSpaceTime','bdCorrPanel','bdHilbert','bdSurrogate','bdSolverPanel','bdTrapPanel'};
            menuobj = uimenu('Parent',fig, 'Label','New Panel');
            uimenu('Parent',menuobj, ...
                    'Label','Equations', ...
                    'Callback', @(~,~) NewPanel(control,'bdLatexPanel'));
            uimenu('Parent',menuobj, ...
                    'Label','Time Portrait', ...
                    'Callback', @(~,~) NewPanel(control,'bdTimePortrait'));
            uimenu('Parent',menuobj, ...
                    'Label','Phase Portrait', ...
                    'Callback', @(~,~) NewPanel(control,'bdPhasePortrait'));
            uimenu('Parent',menuobj, ...
                    'Label','Bifurcation Diagram', ...
                    'Callback', @(~,~) NewPanel(control,'bdBifurcation'));
            uimenu('Parent',menuobj, ...
                    'Label','Space-Time', ...
                    'Callback', @(~,~) NewPanel(control,'bdSpaceTime'));
            uimenu('Parent',menuobj, ...
                    'Label','Correlations', ...
                    'Callback', @(~,~) NewPanel(control,'bdCorrPanel'));
            uimenu('Parent',menuobj, ...
                    'Label','Hilbert Transform', ...
                    'Callback', @(~,~) NewPanel(control,'bdHilbert'));
            uimenu('Parent',menuobj, ...
                    'Label','Surrogate Signal', ...
                    'Callback', @(~,~) NewPanel(control,'bdSurrogate'));
            uimenu('Parent',menuobj, ...
                    'Label','Solver Panel', ...
                    'Callback', @(~,~) NewPanel(control,'bdSolverPanel'));
            uimenu('Parent',menuobj, ...
                    'Label','Trap Panel', ...
                    'Callback', @(~,~) NewPanel(control,'bdTrapPanel'));
      
            % add any custom gui panels to the menu and also to this.panelclasses
            if isfield(control.sys,'panels')
                panelnames = fieldnames(control.sys.panels);
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
                                       'Callback', @(~,~) NewPanel(control,classname));
                                % Remember the name of the novel panel class
                                classnames{end} = classname;
                        end
                    end
                end
            end 
            
            % Menu Callback function
            function NewPanel(control,classname)
               if exist(classname,'class')
                    % construct the panel, keep a handle to it.
                    classhndl = feval(classname,this.tabgroup,control);
                    if ~isfield(this.panelmgr,classname)
                        this.panelmgr.(classname) = classhndl;
                    else
                        this.panelmgr.(classname)(end+1) = classhndl;
                    end
                    
                    % force a redraw event
                    notify(control,'redraw');
                else
                    dlg = warndlg({['''', classname, '.m'' not found'],'That panel will not be displayed'},'Missing file','modal');
                    uiwait(dlg);
                end          
            end
            
        end
  
    end
    
    methods (Static)
    end
    
end

