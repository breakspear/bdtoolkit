classdef bdGUI
    %bdGUI - The Brain Dynamics Toolbox graphic User Interface.
    %   Opens a dynamical system model (sys) which the user can
    %   interactively explore in a graphical user interface.
    %   
    %   Example:
    %      sys = ODEdemo1();
    %      bdGUI(sys);
    
    % Copyright (c) 2016, Stewart Heitmann <heitmann@ego.id.au>
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
        control         % handle to the bdControl object
    end
    
    properties (Access=private)
        fig             % handle to application figure
        panel1          % handle to uipanel 1
        panel2          % handle to uipanel 2
        tabgroup        % handle to tabgroup in panel1
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
            
            % construct System menu (without any menu items)
            systemMenu = uimenu('Parent',this.fig, 'Label','System');

            % construct Panels menu (without any menu items)
            %panelsMenu = uimenu('Parent',this.fig, 'Label','Panels');

            % construct the LHS panel (using an approximate position)
            this.panel1 = uipanel(this.fig,'Units','pixels','Position',[5 5 600 600],'BorderType','none');
            this.tabgroup = uitabgroup(this.panel1);
            
            % construct the RHS panel (using an approximate position)
            this.panel2 = uipanel(this.fig,'Units','pixels','Position',[5 5 300 600],'BorderType','none');

            % construct the control panel
            this.control = bdControl(this.panel2,sys);

            % resize the panels (putting them in their exact position)
            this.SizeChanged();

            % load each gui panel listed in sys.gui
            if isfield(sys,'gui')
                guifields = fieldnames(sys.gui);
                for indx = 1:numel(guifields)
                    classname = guifields{indx};
                    if exist(classname,'class')
                        % construct the panel
                        obj = feval(classname,this.tabgroup,this.control);
                        % add it to the panel menu
                        %uimenu('Parent',panelsMenu, 'Label',classname);
                    else
                        dlg = warndlg({['''', classname, '.m'' not found'],'That panel will not be displayed'},'Missing file','modal');
                        uiwait(dlg);
                    end
                end
            end
            
            % construct menu items
            if isfield(sys,'self')
                uimenu('Parent',systemMenu, ...
                       'Label','Reconfigure', ...
                       'Callback', @(~,~) this.SystemNew() );
            else
                uimenu('Parent',systemMenu, ...
                       'Label','Reconfigure', ...
                       'Enable', 'off');
            end
            uimenu('Parent',systemMenu, ...
                   'Label','Load', ...
                   'Callback', @(~,~) this.SystemLoad() );
            uimenu('Parent',systemMenu, ...
                   'Label','Save', ...
                   'Callback', @(~,~) this.SystemSave() );

            % register a callback for resizing the figure
            set(this.fig,'SizeChangedFcn', @(~,~) this.SizeChanged());

            % force a recompute
            notify(this.control,'recompute');
            
        end
    end
    
    methods (Access=private)

       % Callback for System-New menu
        function SystemNew(this)
            if isfield(this.control.sys,'self')
                newsys = feval(this.control.sys.self);
                if ~isempty(newsys)
                    bdGUI(newsys);
                end
            end
        end
         
        % Callback for System-Load menu
        function gui = SystemLoad(~)
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
        function SystemSave(this)
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
        
        % Callback for Panel menu item
        function PanelMenu(this, menuobj, classname, panelname)
            switch menuobj.Enable
                case 'on'
                    % Hide all objects
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
            this.panel1.Position = [5 5 w1 h1];
            
            % resize the RHS panel
            w2 = panel2w;
            h2 = figh - 10;
            this.panel2.Position = [8+w1 5 w2 h2];            
        end
    end
    
end


