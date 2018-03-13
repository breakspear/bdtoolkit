classdef bdBifurcation < bdPanel
    %bdBifurcation Display panel for plotting a bifurcation diagram in bdGUI.
    %  The Bifurcation diagram plots the orbits of two or three dynamic
    %  variables versus a parameter of the user's choosing.
    %
    %AUTHORS
    %Stewart Heitmann (2018a)   
    
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

    properties (Constant)
        title = 'Bifurcation';
    end    

    properties (Access=private)
        ax              % Handle to the plot axes
        nvar            % the number of system variables (elements in vardef)
        viewmenu        % handle to 3D VIEW menu item
        tranmenu        % handle to TRANSIENTS menu item
        markmenu        % handle to MARKERS menu item
        pointmenu       % handle to POINTS menu item
        gridmenu        % handle to GRID menu item
        holdmenu        % handle to HOLD menu item
        xselector       % handle to the selected menu item for the x-axis
        yselector       % handle to the selected menu item for the y-axis
        zselector       % handle to the selected menu item for the z-axis
        listener        % handle to our listener object
        lastplot        % handle to the current trajectory (non-transient part)
        lastfp          % handle to the current trajectory fixed point
        ylo = +Inf      % historical minimum of the y-trajectory
        yhi = -Inf      % historical minimum of the y-trajectory
        zlo = +Inf      % historical minimum of the z-trajectory
        zhi = -Inf      % historical minimum of the z-trajectory
    end
    
    methods
        
        function this = bdBifurcation(tabgroup,control)
            % Construct a new Bifurcation diagram in the given tabgroup

            % initialise the base class (specifically this.menu and this.tab)
            this@bdPanel(tabgroup);
            
            % assign default values to missing options in sys.panels.bdBifurcation
            control.sys.panels.bdBifurcation = bdBifurcation.syscheck(control.sys);

            % remember the number of variables in sys.vardef
            this.nvar = numel(control.sys.vardef);
            
            % configure the pull-down menu
            this.menu.Label = control.sys.panels.bdBifurcation.title;
            this.InitCalibrateMenu(control);
            this.InitClearMenu(control);
            this.InitViewMenu(control);
            this.InitTransientsMenu(control);
            this.InitMarkerMenu(control);
            this.InitPointsMenu(control);
            this.InitGridMenu(control);
            this.InitExportMenu(control);
            this.InitCloseMenu(control);

            % configure the panel graphics
            this.tab.Title = control.sys.panels.bdBifurcation.title;
            this.InitSubpanel(control);
            
            % listen to the control panel for redraw events
            this.listener = addlistener(control,'redraw',@(~,~) this.redraw(control));    
        end
        
        function delete(this)
            % Destructor
            delete(this.listener)
        end
         
    end
    
    methods (Access=private)
        
        % Initialise the CALIBRATE menu item
        function InitCalibrateMenu(this,control)
            % construct the menu item
            uimenu(this.menu, ...
               'Label','Calibrate Axes', ...
                'Callback', @CalibrateMenuCallback );
            
            % Menu callback function
            function CalibrateMenuCallback(~,~)
                % adjust the limits to fit the lows and highs of the data
                %indx1 = this.xselector.UserData.xxxindx;       % index of selected parameter in sys.pardef
                indx2 = this.yselector.UserData.xxxindx;       % index of selected parameter in sys.pardef
                indx3 = this.zselector.UserData.xxxindx;       % index of selected parameter in sys.pardef
                %control.sys.pardef(indx1).lim = bdPanel.RoundLim(this.xlo,this.xhi);
                control.sys.vardef(indx2).lim = bdPanel.RoundLim(this.ylo,this.yhi);
                control.sys.vardef(indx3).lim = bdPanel.RoundLim(this.zlo,this.zhi);
                
                % refresh the vardef control widgets
                notify(control,'vardef');
                
                % redraw all panels (because the new limits apply to all panels)
                notify(control,'redraw');
            end

        end
        
        % Initialise the CLEAR menu item
        function InitClearMenu(this,control)
            % construct the menu item
            uimenu(this.menu, ...
                'Label','Clear Axes', ...
                'Callback', @ClearMenuCallback );

            % Menu callback function
            function ClearMenuCallback(~,~)
                % clear the axis
                cla(this.ax);
                
                %reset the lows and highs
                this.ylo = +Inf;
                this.yhi = -Inf;
                this.zlo = +Inf;
                this.zhi = -Inf;

                % redraw this panel
                this.redraw(control);
            end
        end
        
        % Initialise the 3D VIEW menu item
        function InitViewMenu(this,control)
            % construct the menu item
            this.viewmenu = uimenu(this.menu, ...
                'Label','3D View', ...
                'Checked','off', ...
                'Callback', @ViewMenuCallback);

            % Menu callback function
            function ViewMenuCallback(menuitem,~)
                switch menuitem.Checked
                    case 'on'
                        % 3D menu state goes from 'on' to 'off'
                        menuitem.Checked='off';
                        this.ax.View = [0 90];

                    case 'off'
                        % 3D menu state goes from 'off' to 'on'
                        menuitem.Checked='on';
                        this.ax.View = [-45 45];
                end
                
                % clear the axes
                cla(this.ax);
                
                %reset the lows and highs
                this.ylo = +Inf;
                this.yhi = -Inf;
                this.zlo = +Inf;
                this.zhi = -Inf;

                % redraw this panel
                this.redraw(control);
            end
        end

        % Initiliase the TRANISENTS menu item
        function InitTransientsMenu(this,control)
            % get the default transient menu setting from sys.panels
            if control.sys.panels.bdBifurcation.transients
                checkflag = 'on';
            else
                checkflag = 'off';
            end

            % construct the menu item
            this.tranmenu = uimenu(this.menu, ...
                'Label','Transients', ...
                'Checked',checkflag, ...
                'Callback', @TranMenuCallback);

            % Menu callback function
            function TranMenuCallback(menuitem,~)
                switch menuitem.Checked
                    case 'on'
                        menuitem.Checked='off';
                        % delete all existing plot lines for transients
                        delete( findobj(this.ax,'Tag','transient') );                         
                    case 'off'
                        menuitem.Checked='on';
                end
                % redraw this panel only
                this.redraw(control);
            end
        end
        
        % Initiliase the MARKERS menu item
        function InitMarkerMenu(this,control)
            % get the marker menu setting from sys.panels
            if control.sys.panels.bdBifurcation.markers
                checkflag = 'on';
            else
                checkflag = 'off';
            end

            % construct the menu item
            this.markmenu = uimenu(this.menu, ...
                'Label','Markers', ...
                'Checked',checkflag, ...
                'Callback', @MarkMenuCallback);

            % Menu callback function
            function MarkMenuCallback(menuitem,~)
                switch menuitem.Checked
                    case 'on'
                        menuitem.Checked='off';
                    case 'off'
                        menuitem.Checked='on';
                end
                % redraw this panel only
                this.redraw(control);
            end
        end
        
        % Initiliase the DISCRETE POINTS menu item
        function InitPointsMenu(this,control)
            % get the points menu setting from sys.panels
            if control.sys.panels.bdBifurcation.points
                checkflag = 'on';
            else
                checkflag = 'off';
            end

            % construct the menu item
            this.pointmenu = uimenu(this.menu, ...
                'Label','Discrete Points', ...
                'Checked',checkflag, ...
                'Callback', @PointsMenuCallback);

            % Menu callback function
            function PointsMenuCallback(menuitem,~)
                switch menuitem.Checked
                    case 'on'
                        menuitem.Checked='off';
                    case 'off'
                        menuitem.Checked='on';
                end
                % redraw this panel only
                this.redraw(control);
            end
        end
        
        % Initiliase the GRID menu item
        function InitGridMenu(this,control)
            % get the default grid menu setting from sys.panels
            if control.sys.panels.bdBifurcation.grid
                gridcheck = 'on';
            else
                gridcheck = 'off';
            end

            % construct the menu item
            this.gridmenu = uimenu(this.menu, ...
                'Label','Grid', ...
                'Checked',gridcheck, ...
                'Callback', @GridMenuCallback);

            % Menu callback function
            function GridMenuCallback(menuitem,~)
                switch menuitem.Checked
                    case 'on'
                        menuitem.Checked='off';
                        grid(this.ax,'off');
                    case 'off'
                        menuitem.Checked='on';
                        grid(this.ax,'on');
                end
                grid(this.ax, menuitem.Checked);
            end
        end
        
        % Initialise the EXPORT menu item
        function InitExportMenu(this,~)
            % construct the menu item
            uimenu(this.menu, ...
               'Label','Export Figure', ...
               'Callback',@callback);
           
            function callback(~,~)
                % Construct a new figure
                fig = figure();    
                
                % Change mouse cursor to hourglass
                set(fig,'Pointer','watch');
                drawnow;
                
                % Copy the plot data to the new figure
                axnew = copyobj(this.ax,fig);
                axnew.OuterPosition = [0 0 1 1];

                % Allow the user to hit everything in the new axis
                objs = findobj(axnew,'-property', 'HitTest');
                set(objs,'HitTest','on');
                                
                % Change mouse cursor to arrow
                set(fig,'Pointer','arrow');
                drawnow;
            end
        end

        % Initialise the CLOSE menu item
        function InitCloseMenu(this,~)
            % construct the menu item
            uimenu(this.menu, ...
                   'Label','Close', ...
                   'Callback',@(~,~) this.close());
        end
        
        % Initialise the subpanel
        function InitSubpanel(this,control)
            % construct the subpanel
            [this.ax,cmenu] = bdPanel.Subpanel(this.tab,[0 0 1 1],[0 0 1 1]);
            xlabel(this.ax,'parameter');
            ylabel(this.ax,'variable');
            
            % construct a selector menu comprising items from sys.pardef
            this.xselector = bdPanel.SelectorMenuFull(...
                uimenu(cmenu,'Label','x-axis'), ...
                control.sys.pardef, ...
                @xselectorcallback, ...
                'off', 'xselector',1,1);

            % construct a selector menu comprising items from sys.vardef
            this.yselector = bdPanel.SelectorMenuFull( ...
                uimenu(cmenu,'Label','y-axis'), ...
                control.sys.vardef, ...
                @yselectorcallback, ...
                'off', 'yselector',min(this.nvar,2),1);

            % construct a selector menu comprising items from sys.vardef
            this.zselector = bdPanel.SelectorMenuFull( ...
                uimenu(cmenu,'Label','z-axis'), ...
                control.sys.vardef, ...
                @zselectorcallback, ...
                'off', 'zselector',1,1);

            % Callback function for the x-selector menu
            function xselectorcallback(menuitem,~)
                % check 'on' the selected menu item and check 'off' all others
                bdPanel.SelectorCheckItem(menuitem);
                % update our handle to the selected menu item
                this.xselector = menuitem;
                % clear the axes
                cla(this.ax);
                % redraw the panel
                this.redraw(control);
            end

            % Callback function for the y-selector menu
            function yselectorcallback(menuitem,~)
                % check 'on' the selected menu item and check 'off' all others
                bdPanel.SelectorCheckItem(menuitem);
                % update our handle to the selected menu item
                this.yselector = menuitem;
                % clear the axes
                cla(this.ax);
                % redraw the panel
                this.redraw(control);
            end
            
            % Callback function for the z-selector menu
            function zselectorcallback(menuitem,~)
                % check 'on' the selected menu item and check 'off' all others
                bdPanel.SelectorCheckItem(menuitem);
                % update our handle to the selected menu item
                this.zselector = menuitem;
                % clear the axes
                cla(this.ax);
                % redraw the panel
                this.redraw(control);
            end            
        end
   
        % Redraw the data plots
        function redraw(this,control)
            %disp('bdBirfurcation.redraw()')

            % get the details of the currently selected parameter (x-axis)
            name1    = this.xselector.UserData.xxxname;       % generic name of parameter
            label1   = this.xselector.UserData.label;         % plot label for selected parameter
            varindx1 = this.xselector.UserData.xxxindx;       % index of selected parameter in sys.pardef
            valindx1 = this.xselector.UserData.valindx;       % index of selected parameter in sys.pardef.value
            lim1     = control.sys.pardef(varindx1).lim;      % axis limits of the selected parameter

            % get the details of the currently selected variable (y-axis)
            name2    = this.yselector.UserData.xxxname;       % generic name of y-axis variable
            label2   = this.yselector.UserData.label;         % plot label for selected variable
            varindx2 = this.yselector.UserData.xxxindx;       % index of selected variable in sys.vardef
            valindx2 = this.yselector.UserData.valindx;       % indices of selected entries in sys.vardef.value
            solindx2 = control.sys.vardef(varindx2).solindx;  % indices of selected entries in sol
            lim2     = control.sys.vardef(varindx2).lim;      % axis limits of the selected variable
            
            % get the details of the currently selected variable (z-axis)
            name3    = this.zselector.UserData.xxxname;       % generic name of z-axis variable
            label3   = this.zselector.UserData.label;         % plot label for selected variable
            varindx3 = this.zselector.UserData.xxxindx;       % index of selected variable in sys.vardef
            valindx3 = this.zselector.UserData.valindx;       % indices of selected entries in sys.vardef.value
            solindx3 = control.sys.vardef(varindx3).solindx;  % indices of selected entries in sol
            lim3     = control.sys.vardef(varindx3).lim;      % axis limits of the selected variable

            % get the indices of the non-transient time steps in the solution
            tindx = control.tindx;      % logical indices of the non-transient time steps
            indxt = find(tindx>0,1);    % numerical index of the first non-transient step (may be empty)

            % get the solution data (including the transient part)
            y = control.sol.y(solindx2(valindx2),:);
            z = control.sol.y(solindx3(valindx3),:);
            
            % get the value of the bifurcation parameter (that was used to compute sol)            
            pp = control.par.(name1)(valindx1);
            p = pp*ones(size(y));

            % remember the lows and highs of the (non-transient) trajectories in x and y.
            this.ylo = min(this.ylo, min(y(tindx)));
            this.yhi = max(this.yhi, max(y(tindx)));
            this.zlo = min(this.zlo, min(z(tindx)));
            this.zhi = max(this.zhi, max(z(tindx)));
            
            % test for fixed point at tend of solution.
            tend = control.sol.x(end);
            [~,dYval] = bdEval(control.sol,tend);
            fixedpoint = (norm(dYval) < 1e-3);
            
            % set the axes limits
            this.ax.XLim = lim1 + [-1e-6 +1e-6];
            this.ax.YLim = lim2 + [-1e-6 +1e-6];
            this.ax.ZLim = lim3 + [-1e-6 +1e-6];
            
            % if the DISCRETE POINTS menu is checked then ...
            switch this.pointmenu.Checked
                case 'on'
                    % set our plot style to discrete points
                    markerstyle = '.';
                    linestyle = 'none';
                    % no need to highlight fixed points in discrete mode
                    fixedpoint = false;
                case 'off'
                    % set our plot style to continuous lines
                    markerstyle = 'none';
                    linestyle = '-';
            end
            
            % if the TRANSIENT menu is enabled then  ...
            switch this.tranmenu.Checked
                case 'on'
                    % set the visibility of our transient plots
                    transflag = true;
                    
                    % if the MARKER menu is enabled then  ...
                    switch this.markmenu.Checked
                        case 'on'
                            mark1flag = true;
                            mark2flag = true;
                        case 'off'
                            mark1flag = false;
                            mark2flag = false;
                    end
                    
                case 'off'
                    % set the visibility of our transient plots
                    transflag = false;
                    
                    % if the MARKER menu is enabled then  ...
                    switch this.markmenu.Checked
                        case 'on'
                            mark1flag = false;
                            mark2flag = true;
                        case 'off'
                            mark1flag = false;
                            mark2flag = false;
                    end
            end
            
            % remove all existing markers from the axes
            delete( findobj(this.ax,'Tag','marker') );
            
            % change the last plot line to a thin line
            if ~isempty(this.lastplot) && isvalid(this.lastplot)
                set(this.lastplot, 'LineWidth',1, 'Color',[0.75 0.75 0.75]);
            end
            
            % change the last fixed point to a gray dot
            if ~isempty(this.lastfp) && isvalid(this.lastfp)
                set(this.lastfp, 'MarkerSize',2, 'Color',[0.75 0.75 0.75], 'MarkerFaceColor',[0.75 0.75 0.75]);
            end
            
            % if the 3D VIEW menu is checked then plot 3D view else plot 2D view
            switch this.viewmenu.Checked
                % 3D plot
                case 'on'                       
                    % get the solution data for thr z-axis (including the transient part)
                    z = control.sol.y(solindx3(valindx3),:);

                    % plot the entire trajectory as a thin grey line (if transients are required)
                    if transflag
                        plot3(this.ax, p, y, z, ...
                            'color',[0.75 0.75 0.75], ...
                            'Tag','transient', ...
                            'HitTest','off');
                    end

                    % plot the non-transient part as a heavy black line
                    this.lastplot = plot3(this.ax, p(tindx), y(tindx), z(tindx), ...
                        'color','k', ...
                        'Marker',markerstyle, ...
                        'LineStyle',linestyle, ...
                        'Linewidth',1.5);
                    
                    % Fixed points need highlighting 
                    if fixedpoint
                        this.lastfp = plot3(this.ax, p(end), y(end), z(end), 'color','k', 'Marker','o', 'MarkerFaceColor','k','MarkerSize',4);
                    end

                    % mark the initial conditions with a pentagram (if required)
                    if mark1flag
                        plot3(this.ax, p(1), y(1), z(1), ...
                            'Marker','p', ...
                            'Color','k', ...
                            'Tag','marker', ...
                            'MarkerFaceColor','y', ...
                            'MarkerSize',10);
                    end

                    % mark the start of the non-transient trajectory with an open circle (if reuired)
                    if mark2flag && ~isempty(indxt)
                        plot3(this.ax, p(indxt), y(indxt), z(indxt), ...
                            'Marker','o', ...
                            'Color','k', ...
                            'Tag','marker', ...
                            'MarkerFaceColor','y', ...
                            'MarkerSize',6);
                    end
                    
                    % update the titles
                    title(this.ax,['(' name2 ',' name3 ') versus ' name1]);

                % 2D plot
                case 'off'
                    % plot the entire trajectory as a thin grey line (if transients are required)
                    if transflag
                        plot(this.ax, p, y, ...
                            'color',[0.75 0.75 0.75], ...
                            'Tag','transient', ...
                            'HitTest','off');
                    end
                            
                    % plot the non-transient part as a black line
                    this.lastplot = plot(this.ax, p(tindx), y(tindx), ...
                        'color','k', ...
                        'Marker',markerstyle, ...
                        'LineStyle',linestyle, ...
                        'Linewidth',1);

                    % Fixed points need highlighting 
                    if fixedpoint
                        this.lastfp = plot(this.ax, p(end), y(end), 'color','k', 'Marker','o', 'MarkerFaceColor','k', 'MarkerSize',4);
                    end

                    % mark the initial conditions with a pentagram (if required)
                    if mark1flag
                        plot(this.ax, p(1), y(1), ...
                            'Marker','p', ...
                            'Color','k', ...
                            'Tag','marker', ...
                            'MarkerFaceColor','y', ...
                            'MarkerSize',10);
                    end
                    
                    % mark the start of the non-transient trajectory with an open circle (if reuired)
                    if mark2flag && ~isempty(indxt)
                        plot(this.ax, p(indxt), y(indxt), ...
                            'Marker','o', ...
                            'Color','k', ...
                            'Tag','marker', ...
                            'MarkerFaceColor','y', ...
                            'MarkerSize',6);
                    end
                    
                    % update the titles
                    title(this.ax,[name2 ' versus ' name1]);
            end
                        
            % update the labels
            xlabel(this.ax, label1);
            ylabel(this.ax, label2);
            zlabel(this.ax, label3);
        end

    end
    
    methods (Static)
        
        function syspanel = syscheck(sys)
            % Assign default values to missing fields in sys.panels.bdBifurcation

            % Default panel settings
            syspanel.title = bdBifurcation.title;
            syspanel.transients = true;
            syspanel.markers = true;
            syspanel.points = false;
            syspanel.grid = false;
            
            % Nothing more to do if sys.panels.bdBifurcation is undefined
            if ~isfield(sys,'panels') || ~isfield(sys.panels,'bdBifurcation')
                return;
            end
            
            % sys.panels.bdBifurcation.title
            if isfield(sys.panels.bdBifurcation,'title')
                syspanel.title = sys.panels.bdBifurcation.title;
            end
            
            % sys.panels.bdBifurcation.transients
            if isfield(sys.panels.bdBifurcation,'transients')
                syspanel.transients = sys.panels.bdBifurcation.transients;
            end
            
            % sys.panels.bdBifurcation.markers
            if isfield(sys.panels.bdBifurcation,'markers')
                syspanel.markers = sys.panels.bdBifurcation.markers;
            end
            
            % sys.panels.bdBifurcation.points
            if isfield(sys.panels.bdBifurcation,'points')
                syspanel.points = sys.panels.bdBifurcation.points;
            end
            
            % sys.panels.bdBifurcation.grid
            if isfield(sys.panels.bdBifurcation,'grid')
                syspanel.grid = sys.panels.bdBifurcation.grid;
            end
            
        end
        
    end
    
end
