classdef bdSolverPanel < handle
    %bdSolverPanel - Brain Dynamics GUI panel for solver options.
    %
    %SYS OPTIONS
    %   sys.gui.bdSolverPanel.title      Name of the panel (optional)
    %
    %AUTHORS
    %  Stewart Heitmann (2016a)

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
    properties (Access=private) 
        fig             % handle to parent figure
    end
 
    methods        
        function this = bdSolverPanel(tabgroup,control)
            % default sys.gui settings
            title = 'Solver';
            
            % sys.gui.bdSolverPanel.title
            if isfield(control.sys.gui,'bdSolverPanel') && isfield(control.sys.gui.bdSolverPanel,'title')
                title = control.sys.gui.bdSolverPanel.title;
            end
            
            % get handle to parent figure
            this.fig = ancestor(tabgroup,'figure');

            % construct the uitab
            tab = uitab(tabgroup,'title',title, 'Units','pixels');
            
            % get tab geometry
            parentw = tab.Position(3);
            parenth = tab.Position(4);

            % compute axes geometry
            axesh = (parenth-200)/2;
            axesw = parentw-100;
            
            % construct the dydt axes
            ax1 = axes('Parent',tab, ...
                'Units','pixels', ...
                'Position', [60 150+axesh  axesw axesh]);
            plt1 = stairs(0,0, 'parent',ax1, 'color','k', 'Linewidth',1);
            set(ax1,'TickDir','out');
            %xlabel('time (t)','FontSize',14);
            ylabel('||dY||','FontSize',14);

            % construct the step-size axes
            ax2 = axes('Parent',tab, ...
                'Units','pixels', ...
                'Position', [60 130 axesw axesh]);
            plt2 = stairs(0,0, 'parent',ax2, 'color','k', 'Linewidth',1);
            set(ax2,'TickDir','out');
            xlabel('time (t)','FontSize',14);
            ylabel('step size (dt)','FontSize',14);
            
            % construct panel for odeoptions
            this.odePanel(tab,control);
            
            % construct the Solver menu (if it does not already exist)
            obj = findobj(this.fig,'Tag','bdSolverPanelMenu');
            if isempty(obj)
                bdSolverPanel.constructMenu(this.fig,control);
            end
                        
            % register a callback for resizing the panel
            set(tab,'SizeChangedFcn', @(~,~) this.SizeChanged(tab,ax1,ax2));

            % listen to the control panel for redraw events
            addlistener(control,'redraw',@(~,~) this.render(control,ax1,ax2,plt1,plt2));    
        end
        
    end
    
    methods (Access=private)
        
        function panel = odePanel(this,parent,control)
            % edit box geometry
            boxw = 50;
            boxh = 20;
            boxx = 60;

            % get parent geometry
            parentw = parent.Position(3);
            
            % construct panel
            panel = uipanel('Parent',parent, ...
                'Units','pixels', ...
                'Position',[0 0 parentw 80], ...
                'bordertype','none');

            % Error Control
            uicontrol('Style','text', ...
                'String','Error Control', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontWeight','bold', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', panel, ...
                'Position',[boxx 10+2*boxh 2*boxw+5 boxh]);

            % construct edit box for AbsTol
            fieldname = 'AbsTol';
            AbsTol = uicontrol('Style','edit', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'TooltipString', 'Absolute error tolerance', ...
                'Parent', panel, ...
                'Callback', @(hObj,~) editboxCallback(hObj,fieldname), ...
                'Position',[boxx 10 boxw boxh]);
            uicontrol('Style','text', ...
                'String',fieldname, ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', panel, ...
                'Position',[boxx 10+boxh boxw boxh]);

            % next col
            boxx = boxx + boxw + 5;
            
            % construct edit box for RelTol
            fieldname = 'RelTol';
            RelTol = uicontrol('Style','edit', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'TooltipString', 'Relative error tolerance', ...
                'Parent', panel, ...
                'Callback', @(hObj,~) editboxCallback(hObj,fieldname), ...
                'Position',[boxx 10 boxw boxh]);
            uicontrol('Style','text', ...
                'String',fieldname, ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', panel, ...
                'Position',[boxx 10+boxh boxw boxh]);

            % next col
            boxx = boxx + boxw + 20;

            % Step Size
            uicontrol('Style','text', ...
                'String','Step Size', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontWeight','bold', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', panel, ...
                'Position',[boxx 10+2*boxh 2*boxw+5 boxh]);

            % construct edit box for InitialStep
            fieldname = 'InitialStep';
            InitialStep = uicontrol('Style','edit', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'TooltipString', 'Initial step size', ...
                'Parent', panel, ...
                'Callback', @(hObj,~) editboxCallback(hObj,fieldname), ...
                'Position',[boxx 10 boxw boxh]);
            uicontrol('Style','text', ...
                'String','Initial', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', panel, ...
                'Position',[boxx 10+boxh boxw boxh]);

            % next col
            boxx = boxx + boxw + 5;

            % construct edit box for MaxStep
            fieldname = 'MaxStep';
            MaxStep = uicontrol('Style','edit', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', panel, ...
                'TooltipString', 'Maximum step size', ...
                'Callback', @(hObj,~) editboxCallback(hObj,fieldname), ...
                'Position',[boxx 10 boxw boxh]);
            uicontrol('Style','text', ...
                'String',fieldname, ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', panel, ...
                'Position',[boxx 10+boxh boxw boxh]);

            % next col
            boxx = boxx + boxw + 20;

            % Statistics
            uicontrol('Style','text', ...
                'String','Statistics', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontWeight','bold', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', panel, ...
                'Position',[boxx 10+2*boxh 3*boxw+10 boxh]);

            % nsteps
            nsteps = uicontrol('Style','text', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontWeight','normal', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', panel, ...
                'Position',[boxx 10 boxw boxh]);
            uicontrol('Style','text', ...
                'String','nsteps', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', panel, ...
                'Position',[boxx 10+boxh boxw boxh]);

            % next col
            boxx = boxx + boxw + 5;

            % nfailed
            nfailed = uicontrol('Style','text', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontWeight','normal', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', panel, ...
                'Position',[boxx 10 boxw boxh]);
            uicontrol('Style','text', ...
                'String','nfailed', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', panel, ...
                'Position',[boxx 10+boxh boxw boxh]);

            % next col
            boxx = boxx + boxw + 5;

            % nfevals
            nfevals = uicontrol('Style','text', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontWeight','normal', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', panel, ...
                'Position',[boxx 10 boxw boxh]);
            uicontrol('Style','text', ...
                'String','nfevals', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', panel, ...
                'Position',[boxx 10+boxh boxw boxh]);
            
            % update the edit box contents
            renderboxes;
            
            % listen to the control panel for redraw events
            addlistener(control,'redraw',@(~,~) renderboxes);    

            % Listener function for updating the edit boxes
            function renderboxes
                %disp('bdSolverPanel.odePanel.renderboxes()')
                solvertype = control.solvermap(control.solveridx).solvertype;
                switch solvertype
                    case 'odesolver'
                        AbsTol.String = num2str(odeget(control.sys.odeoption,'AbsTol'),'%g');
                        RelTol.String = num2str(odeget(control.sys.odeoption,'RelTol'),'%g');
                        InitialStep.String = num2str(odeget(control.sys.odeoption,'InitialStep'),'%g');
                        MaxStep.String = num2str(odeget(control.sys.odeoption,'MaxStep'),'%g');
                        AbsTol.Enable = 'on';
                        RelTol.Enable = 'on';
                        InitialStep.Enable = 'on';
                        MaxStep.Enable = 'on';
                    case 'ddesolver'
                        AbsTol.String = num2str(ddeget(control.sys.ddeoption,'AbsTol'),'%g');
                        RelTol.String = num2str(ddeget(control.sys.ddeoption,'RelTol'),'%g');
                        InitialStep.String = num2str(ddeget(control.sys.ddeoption,'InitialStep'),'%g');
                        MaxStep.String = num2str(ddeget(control.sys.ddeoption,'MaxStep'),'%g');
                        AbsTol.Enable = 'on';
                        RelTol.Enable = 'on';
                        InitialStep.Enable = 'on';
                        MaxStep.Enable = 'on';
                    case 'sdesolver'
                        if isfield(control.sys.sdeoption,'InitialStep')
                            InitialStep.String = num2str(control.sys.sdeoption.InitialStep,'%g');
                        end
                        AbsTol.Enable = 'off';
                        RelTol.Enable = 'off';
                        InitialStep.Enable = 'on';
                        MaxStep.Enable = 'off';
                end
                if ~isempty(control.sol)
                    nsteps.String = num2str(control.sol.stats.nsteps,'%d');
                    nfailed.String = num2str(control.sol.stats.nfailed,'%d');
                    nfevals.String = num2str(control.sol.stats.nfevals,'%d');
                end
            end
            
            % Callback for user input to the edit boxes
            function editboxCallback(uibox,fieldname)
                %disp('bdSolverPanel.odePanel.editboxCallback()')
                % convert the edit box string into an odeoption value
                if isempty(uibox.String)
                    val = [];               % use an empty odeoption value for an empty edit box
                else    
                    % get the incoming value from a non-empty edit box
                    val = str2double(uibox.String);
                    if isnan(val)
                        % invalid number
                        dlg = errordlg(['''', uibox.String, ''' is not a valid number'],'Invalid Number','modal');
                        % restore previous edit box value/string
                        val = uibox.Value;    
                        uibox.String = num2str(val,'%0.4g');
                        % wait for dialog box to close
                        uiwait(dlg);
                    end
                end
                
                % remember the new value
                uibox.Value = val;
                
                % update the solver options
                switch control.solvermap(control.solveridx).solvertype
                    case 'odesolver'
                        control.sys.odeoption = setfield(control.sys.odeoption,fieldname,val);
                    case 'ddesolver'
                        control.sys.ddeoption = setfield(control.sys.ddeoption,fieldname,val);
                    case 'sdesolver'
                        control.sys.sdeoption = setfield(control.sys.sdeoption,fieldname,val);
                        control.sys.sdeoption.randn = [];
                end

                % recompute
                notify(control,'recompute');
            end           
        end
        
        function render(this,control,ax1,ax2,plt1,plt2)
            %disp('bdSolverPanel.render()')
            tsteps = control.sol.x;
                        
            % render dy/dt versus time
            dydt = diff(control.sol.y,1,2);
            nrm = sqrt( sum(dydt.^2,1) );
            set(plt1, 'XData',tsteps, 'YData',nrm([1:end,end]));
            
            % render the step size versus time
            stepsize = diff(control.sol.x);
            set(plt2, 'XData',tsteps, 'YData',stepsize([1:end,end]));
            ylim(ax2,[0 max(stepsize)*1.1]); 

            % retrieve the appdata
            appdata = getappdata(this.fig,'bdSolverPanel');
            
            % show gridlines (or not)
            if appdata.gridflag
                grid(ax1,'on');
                grid(ax2,'on');
            else
                grid(ax1,'off')
                grid(ax2,'off')
            end
        end
          
        
        % Callback for tab panel resizing.
        function SizeChanged(this,tab,ax1,ax2)
            %disp('bdSolverPanel.SizeChanged()')
            
            % get new parent geometry
            parentw = tab.Position(3);
            parenth = tab.Position(4);

            % compute axes geometry
            axesh = (parenth-200)/2;
            axesw = parentw-100;

            % resize axes
            ax1.Position(2) = 180 + axesh;
            ax1.Position(3) = axesw;
            ax1.Position(4) = axesh;
            ax2.Position(3) = axesw;
            ax2.Position(4) = axesh;
        end
        
    end
    
    
    methods (Static)
        
        % The menu is static so that one menu can serve many instances of the class
        function menuobj = constructMenu(fig,control)            
            % init the appdata for the menu     
            appdata = struct('gridflag',false);
            setappdata(fig,'bdSolverPanel',appdata);
            
            % construct menu
            menuobj = uimenu('Parent',fig, 'Label','Solver', 'Tag','bdSolverPanelMenu');
            
            % solver menu items
            checkstr='on';
%             for indx = 1:numel(control.sys.solver)
%                 uimenu('Parent',menuobj, ...
%                     'Label',control.sys.solver{indx}, ...
%                     'Tag', 'bdSolverSelector', ...
%                     'Checked',checkstr, ...
%                     'Callback', @(menuitem,~) bdSolverPanel.SolverMenuCallback(menuobj,menuitem,control) );
%                 checkstr='off';                
%             end
             for indx = 1:numel(control.solvermap)
                uimenu('Parent',menuobj, ...
                    'Label',control.solvermap(indx).solvername, ...
                    'Tag', 'bdSolverSelector', ...
                    'UserData', indx, ...
                    'Checked',checkstr, ...
                    'Callback', @(menuitem,~) bdSolverPanel.SolverMenuCallback(menuobj,menuitem,control) );
                checkstr='off';                
            end
            
            % grid menu item
            uimenu('Parent',menuobj, ...
                'Label','Grid', ...
                'Checked','off', ...
                'Separator','on', ...
                'Callback', @(menuitem,~) bdSolverPanel.MenuCallback(fig,menuitem,control) );          
        end        
        
        % Solver Solver Menu Item Callback
        function SolverMenuCallback(menuobj,menuitem,control)
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

        % Menu Item Callback
        function MenuCallback(fig,menuitem,control)
            % retrieve the appdata
            appdata = getappdata(fig,'bdSolverPanel');
            
            switch menuitem.Label
                case 'Grid'
                    switch menuitem.Checked
                        case 'on'
                            appdata.gridflag = false;
                            menuitem.Checked='off';
                        case 'off'
                            appdata.gridflag = true;
                            menuitem.Checked='on';
                    end
            end 
            
            % save the new appdata
            setappdata(fig,'bdSolverPanel',appdata);
            
            % notify all panels to redraw
            notify(control,'redraw');
        end
        
    end    
    
end

