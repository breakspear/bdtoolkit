classdef bdPhasePortrait < bdPanel
    %bdPhasePortrait Display panel for plotting phase potraits in bdGUI.
    %   Detailed explanation goes here
    
    properties
        ax              % handle to the plot axes
        y1              % x-values of the trajectory (1 x t)
        y2              % y-values of the trajectory (1 x t)
        y3              % z-values of the trajectory (1 x t)
    end
    
    properties (Access=private)
        nvar            % the number of system variables (elements in vardef)
        viewmenu        % handle to 3D VIEW menu item
        tranmenu        % handle to TRANSIENTS menu item
        markmenu        % handle to MARKERS menu item
        pointmenu       % handle to DISCRETE POINTS menu item
        vecfmenu        % handle to VECTOR FIELD menu item
        nullmenu        % handle to NULLCLINES menu item
        gridmenu        % handle to GRID menu item
        holdmenu        % handle to HOLD menu item
        xselector       % handle to the selected menu item for the x-axis
        yselector       % handle to the selected menu item for the y-axis
        zselector       % handle to the selected menu item for the z-axis
        vecfplot = []   % handle to the vector field plot object
        nullplot = []   % handle(s) to the nullcline plot object
        listener        % handle to our listener object
    end
    
    methods
        
        function this = bdPhasePortrait(tabgroup,control)
            % initialise the base class (specifically this.menu and this.tab)
            this@bdPanel(tabgroup);
            
            % assign default values to missing options in sys.panels.bdPhasePortrait
            control.sys.panels.bdPhasePortrait = bdPhasePortrait.syscheck(control.sys);
            
            % remember the number of variables in sys.vardef
            this.nvar = numel(control.sys.vardef);
            
            % configure the pull-down menu
            this.menu.Text = control.sys.panels.bdPhasePortrait.title;
            this.InitCalibrateMenu(control);
            this.InitViewMenu(control);
            this.InitTransientsMenu(control);
            this.InitMarkerMenu(control);
            this.InitPointsMenu(control);
            this.InitVectorFieldMenu(control);
            this.InitNullclineMenu(control);
            this.InitGridMenu(control);
            this.InitHoldMenu(control);
            this.InitExportMenu(control);
            this.InitCloseMenu(control);

            % configure the panel graphics
            this.tab.Title = control.sys.panels.bdPhasePortrait.title;
            this.InitSubpanel(control);
            
            % listen to the control panel for redraw events
            this.listener = listener(control,'redraw',@(~,~) this.redraw(control));    
        end
        
    end
    
    methods (Access=private)
        
        % Initialise the CALIBRATE menu item
        function InitCalibrateMenu(this,control)
            % construct the menu item
            uimenu(this.menu, ...
               'Text','Calibrate Axes', ...
                'Callback', @CalibrateMenuCallback );
            
            % Menu callback function
            function CalibrateMenuCallback(~,~)
                % if the TRANSIENT menu is checked then ...
                switch this.tranmenu.Checked
                    case 'on'
                        % adjust the limits to fit all of the data
                        tindx = true(size(control.tindx));
                    case 'off'
                        % adjust the x-limits to fit the non-transient data only
                        tindx = control.tindx;
                end
                
                % adjust the x-limits to fit the visible data
                lo = min(this.y1(tindx));
                hi = max(this.y1(tindx));
                varindx = this.xselector.UserData.xxxindx;
                control.sys.vardef(varindx).lim = bdPanel.RoundLim(lo,hi);

                % adjust the y-limits to fit the visible data
                lo = min(this.y2(tindx));
                hi = max(this.y2(tindx));
                varindx = this.yselector.UserData.xxxindx;
                control.sys.vardef(varindx).lim = bdPanel.RoundLim(lo,hi);
                
                if strcmp(this.viewmenu.Checked,'on')
                    % adjust the z-limits to fit the visible data
                    lo = min(this.y3(tindx));
                    hi = max(this.y3(tindx));
                    varindx = this.zselector.UserData.xxxindx;
                    control.sys.vardef(varindx).lim = bdPanel.RoundLim(lo,hi);
                end

                % refresh the control widgets (becasue their limits have changed)
                notify(control,'refresh');
                 
                % redraw all panels (because the new limits apply to all panels)
                notify(control,'redraw');
            end

        end
        
        % Initialise the 3D VIEW menu item
        function InitViewMenu(this,control)
            % construct the menu item
            this.viewmenu = uimenu(this.menu, ...
                'Text','3D View', ...
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
                        this.ax.View = [45 45];
                end
                % redraw this panel
                this.redraw(control);
            end
        end
        
        % Initiliase the TRANISENTS menu item
        function InitTransientsMenu(this,control)
            % get the default transient menu setting from sys.panels
            if control.sys.panels.bdPhasePortrait.transients
                checkflag = 'on';
            else
                checkflag = 'off';
            end

            % construct the menu item
            this.tranmenu = uimenu(this.menu, ...
                'Text','Transients', ...
                'Checked',checkflag, ...
                'Callback', @TranMenuCallback);

            % Menu callback function
            function TranMenuCallback(menuitem,~)
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
        
        % Initiliase the MARKERS menu item
        function InitMarkerMenu(this,control)
            % get the marker menu setting from sys.panels
            if control.sys.panels.bdPhasePortrait.markers
                checkflag = 'on';
            else
                checkflag = 'off';
            end

            % construct the menu item
            this.markmenu = uimenu(this.menu, ...
                'Text','Markers', ...
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
            if control.sys.panels.bdPhasePortrait.points
                checkflag = 'on';
            else
                checkflag = 'off';
            end

            % construct the menu item
            this.pointmenu = uimenu(this.menu, ...
                'Text','Discrete Points', ...
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
         
        % Initialise the VECTIOR FIELD menu item
        function InitVectorFieldMenu(this,control)
             % get the default menu setting from sys.panels options
            if control.sys.panels.bdPhasePortrait.vecfield
                checkflag = 'on';
            else
                checkflag = 'off';
            end
            
            % Vector fields work for ODEs only
            switch control.solvertype
                case 'odesolver'
                    enableflag = 'on';
                otherwise
                    enableflag = 'off';
            end
            
            % construct the menu item
            this.vecfmenu = uimenu(this.menu, ...
                'Text','Vector Field', ...
                'Checked',checkflag, ...
                'Enable',enableflag, ...
                'Callback', @callback );

            % Menu callback function
            function callback(menuitem,~)
                switch menuitem.Checked
                    case 'on'
                        menuitem.Checked='off';
                    case 'off'
                        menuitem.Checked='on';
                end
                % redraw this panel
                this.redraw(control);
            end
        end

        % Initiliase the NULLCLINE menu item
        function InitNullclineMenu(this,control)
            % get the default grid menu setting from sys.panels
            if control.sys.panels.bdPhasePortrait.nullclines
                nullcheck = 'on';
            else
                nullcheck = 'off';
            end
            
            % Nullclines work for ODEs only
            switch control.solvertype
                case 'odesolver'
                    enableflag = 'on';
                otherwise
                    enableflag = 'off';
            end

            % construct the menu item
            this.nullmenu = uimenu(this.menu, ...
                'Text','Nullclines', ...
                'Checked',nullcheck, ...
                'Enable',enableflag, ...
                'Callback', @NullMenuCallback);

            % Menu callback function
            function NullMenuCallback(menuitem,~)
                switch menuitem.Checked
                    case 'on'
                        menuitem.Checked='off';
                    case 'off'
                        menuitem.Checked='on';
                end
                % redraw this panel
                this.redraw(control);
            end
        end
        
        % Initiliase the GRID menu item
        function InitGridMenu(this,control)
            % get the default grid menu setting from sys.panels
            if control.sys.panels.bdPhasePortrait.grid
                gridcheck = 'on';
            else
                gridcheck = 'off';
            end

            % construct the menu item
            this.gridmenu = uimenu(this.menu, ...
                'Text','Grid', ...
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
        
        % Initialise the HOLD menu item
        function InitHoldMenu(this,control)
             % get the hold menu setting from sys.panels options
            if control.sys.panels.bdPhasePortrait.hold
                holdcheck = 'on';
            else
                holdcheck = 'off';
            end
            
            % construct the menu item
            this.holdmenu = uimenu(this.menu, ...
                'Text','Hold', ...
                'Checked',holdcheck, ...
                'Callback', @HoldMenuCallback );

            % Menu callback function
            function HoldMenuCallback(menuitem,~)
                switch menuitem.Checked
                    case 'on'
                        menuitem.Checked='off';
                    case 'off'
                        menuitem.Checked='on';
                end
                % redraw this panel
                this.redraw(control);
            end
        end
        
        % Initialise the EXPORT menu item
        function InitExportMenu(this,control)
            % construct the menu item
            uimenu(this.menu, ...
               'Text','Export Figure', ...
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
                
                % Allow the user to hit everything in the new figure
                objs = findobj(axnew,'-property', 'HitTest');
                set(objs,'HitTest','on');
                
                % Change mouse cursor to arrow
                set(fig,'Pointer','arrow');
                drawnow;
            end
        end

        % Initialise the CLOSE menu item
        function InitCloseMenu(this,control)
            % construct the menu item
            uimenu(this.menu, ...
                   'Text','Close', ...
                   'Callback',@(~,~) this.close());
        end
        
        % Initialise the subpanel
        function InitSubpanel(this,control)
            % construct the subpanel
            [this.ax,cmenu] = bdPanel.Subpanel(this.tab,[0 0 1 1],[0 0 1 1]);
            xlabel(this.ax,'?');
            ylabel(this.ax,'?');
            
            % construct a selector menu comprising items from sys.vardef
            this.xselector = bdPanel.SelectorMenuFull( ...
                uimenu(cmenu,'Text','x-axis'), ...
                control.sys.vardef, ...
                @xcallback, ...
                'off', 'mb1',1,1);

            % construct a selector menu comprising items from sys.vardef
            this.yselector = bdPanel.SelectorMenuFull( ...
                uimenu(cmenu,'Text','y-axis'), ...
                control.sys.vardef, ...
                @ycallback, ...
                'off', 'mb2',min(this.nvar,2),1);

            % construct a selector menu comprising items from sys.vardef
            this.zselector = bdPanel.SelectorMenuFull(...
                uimenu(cmenu,'Text','z-axis'), ...
                control.sys.vardef, ...
                @zcallback, ...
                'off', 'mb3',min(this.nvar,3),1);
            
            % Callback function for the x-axis selector menu
            function xcallback(menuitem,~)
                % check 'on' the selected menu item and check 'off' all others
                bdPanel.SelectorCheckItem(menuitem);
                % update our handle to the selected menu item
                this.xselector = menuitem;
                % redraw the panel
                this.redraw(control);
            end
            
            % Callback function for the y-axis selector menu
            function ycallback(menuitem,~)
                % check 'on' the selected menu item and check 'off' all others
                bdPanel.SelectorCheckItem(menuitem);
                % update our handle to the selected menu item
                this.yselector = menuitem;
                % redraw the panel
                this.redraw(control);
            end
            
            % Callback function for the z-axis selector menu
            function zcallback(menuitem,~)
                % check 'on' the selected menu item and check 'off' all others
                bdPanel.SelectorCheckItem(menuitem);
                % update our handle to the selected menu item
                this.zselector = menuitem;
                % redraw the panel
                this.redraw(control);
            end
        end
        
        % Redraw the data plots
        function redraw(this,control)
            %disp('bdPhasePortrait.redraw()')
            
            % if the DISCRETE POINTS menu is checked then ...
            switch this.pointmenu.Checked
                case 'on'
                    % set our plot style to discrete points
                    markerstyle = '.';
                    linestyle = 'none';
                case 'off'
                    % set our plot style to continuous lines
                    markerstyle = 'none';
                    linestyle = '-';
            end

            % if 'hold' menu is checked then ...
            switch this.holdmenu.Checked
                case 'on'
                    % Change existing plots to thin grey lines 
                    set( findobj(this.ax,'Type','Line'), 'LineWidth',0.5, 'Color',[0.75 0.75 0.75]);               
                case 'off'
                    % Clear the plot axis
                    cla(this.ax);
            end

            % We need to compute the vector field if either of the
            % VECTOR FIELD or NULLCLINE menu items are checked.
            vecflag = false; 
            if strcmp(this.vecfmenu.Checked,'on')
                vecflag = true;
            end
            if strcmp(this.nullmenu.Checked,'on')
                vecflag = true;
            end

            % get the indices of the non-transient timesteps
            tindx = control.tindx;

            % get the details of the currently selected x-variable
            varname1  = this.xselector.UserData.xxxname;          % generic name of variable
            varlabel1 = this.xselector.UserData.label;            % plot label for selected variable
            varindx1  = this.xselector.UserData.xxxindx;          % index of selected variable in sys.vardef
            valindx1  = this.xselector.UserData.valindx;          % indices of selected entries in sys.vardef.value
            solindx1  = control.sys.vardef(varindx1).solindx;     % indices of selected entries in sol
            solrow1   = solindx1(valindx1);                       % row index of the selected variable in sol
            lim1   = control.sys.vardef(varindx1).lim;            % axis limits of the selected variable
            
            % get the details of the currently selected y-variable
            varname2  = this.yselector.UserData.xxxname;          % generic name of variable
            varlabel2 = this.yselector.UserData.label;            % plot label for selected variable
            varindx2  = this.yselector.UserData.xxxindx;          % index of selected variable in sys.vardef
            valindx2  = this.yselector.UserData.valindx;          % indices of selected entries in sys.vardef.value
            solindx2  = control.sys.vardef(varindx2).solindx;     % indices of selected entries in sol
            solrow2   = solindx2(valindx2);                       % row index of the selected variable in sol
            lim2      = control.sys.vardef(varindx2).lim;         % axis limits of the selected variable

            % get the solution data (including the transient part)
            this.y1 = control.sol.y(solindx1(valindx1),:);
            this.y2 = control.sol.y(solindx2(valindx2),:);
            this.y3 = [];

            % isolate the non-transient part of the solution
            yy1 = this.y1(tindx);
            yy2 = this.y2(tindx);

            % set the axes limits
            this.ax.XLim = lim1 + [-1e-6 +1e-6];
            this.ax.YLim = lim2 + [-1e-6 +1e-6];

            % if the 3D VIEW menu is checked then plot 3D view else plot 2D view
            switch this.viewmenu.Checked
                % 3D plot
                case 'on'                       
                    % get the details of the currently selected z-variable
                    varname3  = this.zselector.UserData.xxxname;          % generic name of variable
                    varlabel3 = this.zselector.UserData.label;            % plot label for selected variable
                    varindx3  = this.zselector.UserData.xxxindx;          % index of selected variable in sys.vardef
                    valindx3  = this.zselector.UserData.valindx;          % indices of selected entries in sys.vardef.value
                    solindx3  = control.sys.vardef(varindx3).solindx;     % indices of selected entries in sol
                    solrow3   = solindx3(valindx3);                       % row index of the selected variable in sol
                    lim3      = control.sys.vardef(varindx3).lim;         % axis limits of the selected variable

                    % get the solution data (including the transient part)
                    this.y3 = control.sol.y(solindx3(valindx3),:);

                    % isolate the non-transient part of the solution
                    yy3 = this.y3(tindx);            

                    % set the axes limits
                    this.ax.ZLim = lim3 + [-1e-6 +1e-6];
                    
                    % compute the 3D vector field (if required)
                    if vecflag
                        % we compute the vector field that passed through point Yval at time tval
                        tval = control.sys.tval;
                        Yval = bdEval(control.sol,tval);
    
                        % compute the 3D vector field
                        [xmesh,ymesh,zmesh,dxmesh,dymesh,dzmesh] = this.VectorField3D(control,tval,Yval,solrow1,solrow2,solrow3,lim1,lim2,lim3);
                    end
                    
                    % if the VECTOR FIELD menu is checked then ...
                    if strcmp(this.vecfmenu.Checked,'on')
                        % plot the 3D vector field (after deleting the existing one)
                        delete(this.vecfplot);
                        this.vecfplot = quiver3(xmesh,ymesh,zmesh,dxmesh,dymesh,dzmesh,'parent',this.ax, 'color',[0.75 0.75 0.75], 'ShowArrowHead','off', 'Marker','none', 'HitTest','off');
                    end
                    
                    % if the NULLCLINE menu is checked then ...
                    if strcmp(this.nullmenu.Checked,'on')
                        % delete existing nullclines (FIX ME)
                        delete(this.nullplot(:));
                        
                        px = patch(isosurface(xmesh,ymesh,zmesh,dxmesh,0), 'FaceAlpha',0.2);
                        isonormals(xmesh,ymesh,zmesh,dxmesh,px);
                        px.FaceColor = 'g';
                        px.EdgeColor = 'none';

                        py = patch(isosurface(xmesh,ymesh,zmesh,dymesh,0), 'FaceAlpha',0.2);
                        isonormals(xmesh,ymesh,zmesh,dymesh,py);
                        py.FaceColor = 'y';
                        py.EdgeColor = 'none';

                        pz = patch(isosurface(xmesh,ymesh,zmesh,dzmesh,0), 'FaceAlpha',0.2);
                        isonormals(xmesh,ymesh,zmesh,dymesh,pz);
                        pz.FaceColor = 'r';
                        pz.EdgeColor = 'none';

                        this.nullplot = [px py pz];
                        
                        camlight 
                        lighting gouraud
                    end

                    % if the TRANSIENT menu is enabled then  ...
                    if strcmp(this.tranmenu.Checked,'on')
                        % plot the transients (actually the whole trajectory) as a thin grey line
                        plot3(this.ax, this.y1, this.y2,  this.y3, 'color',[0.75 0.75 0.75], 'HitTest','off');

                        % if the MARKERS menu is also checked then ...
                        if strcmp(this.markmenu.Checked,'on')
                            % mark the initial conditions with a pentagram
                            plot3(this.ax, this.y1(1), this.y2(1), this.y3(1), 'Marker','p', 'Color',[0.75 0.75 0.75], 'MarkerFaceColor','y', 'MarkerSize',10);
                        end
                    end

                    % plot the non-transient part of the trajectory as a heavy black line
                    plot3(this.ax, yy1, yy2, yy3, 'color','k', 'Marker',markerstyle, 'LineStyle',linestyle, 'Linewidth',1.5);

                    % if the MARKERS menu is checked then ...
                    if strcmp(this.markmenu.Checked,'on')
                        % mark the start of the non-transient trajectory with an open circle
                        plot3(this.ax, yy1(1), yy2(1), yy3(1), 'Marker','o', 'Color','k', 'MarkerFaceColor','y', 'MarkerSize',6);
                    end
                
                    % update the plot title
                    title(this.ax,[varname1 ' versus ' varname2 ' versus ' varname3]);
            
                    % update the plot labels
                    xlabel(this.ax, varlabel1);
                    ylabel(this.ax, varlabel2);
                    zlabel(this.ax, varlabel3);
                  
                % 2D plot
                case 'off'
                    % compute the 2D vector field (if required)
                    if vecflag
                        % we compute the vector field that passed through point Yval at time tval
                        tval = control.sys.tval;
                        Yval = bdEval(control.sol,tval);
    
                        % compute the 2D vector field
                        [xmesh,ymesh,dxmesh,dymesh] = this.VectorField2D(control,tval,Yval,solrow1,solrow2,lim1,lim2);
                    end

                    % if the VECTOR FIELD menu is checked then ...
                    if strcmp(this.vecfmenu.Checked,'on')
                        % plot the 3D vector field (after deleting the existing one)
                        delete(this.vecfplot);
                        this.vecfplot = quiver(xmesh,ymesh,dxmesh,dymesh,'parent',this.ax, 'color',[0.75 0.75 0.75], 'ShowArrowHead','off', 'Marker','.', 'HitTest','off');
                    end
                    
                    % if the NULLCLINE menu is checked then ...
                    if strcmp(this.nullmenu.Checked,'on')
                        % plot the x-nullcline
                        contour(this.ax,xmesh,ymesh,dxmesh, [0 0], 'color', [0 1 0], 'HitTest','off', 'LineStyle','-', 'LineWidth',1);
                        % plot the y-nullcline
                        contour(this.ax,xmesh,ymesh,dymesh, [0 0], 'color', [0 1 0], 'HitTest','off', 'LineStyle','-', 'LineWidth',1);
                    end
                    
                    % if the TRANSIENT menu is enabled then  ...
                    if strcmp(this.tranmenu.Checked,'on')
                        % plot the transients (actually the whole trajectory) as a thin grey line
                        plot(this.ax, this.y1, this.y2, 'color',[0.75 0.75 0.75], 'HitTest','off');

                        % if the MARKERS menu is also checked then ...
                        if strcmp(this.markmenu.Checked,'on')
                            % mark the initial conditions with a pentagram
                            plot(this.ax, this.y1(1), this.y2(1), 'Marker','p', 'Color',[0.75 0.75 0.75], 'MarkerFaceColor','y', 'MarkerSize',10);
                        end
                    end

                    % plot the non-transients as a heavy black line
                    plot(this.ax, yy1, yy2, 'color','k', 'Marker',markerstyle, 'LineStyle',linestyle, 'Linewidth',1.5);

                    % if the MARKERS menu is checked then ...
                    if strcmp(this.markmenu.Checked,'on')
                        % mark the start of the non-transient with an open circle
                        plot(this.ax, yy1(1), yy2(1), 'Marker','o', 'Color','k', 'MarkerFaceColor','y', 'MarkerSize',6);
                    end
                
                    % update the plot title
                    title(this.ax,[varname1 ' versus ' varname2]);

                    % update the plot labels
                    xlabel(this.ax, varlabel1);
                    ylabel(this.ax, varlabel2);
            end            
        end

    end
    
    
    methods (Static)
        
        % Evaluate the 2D vector field
        function [xmesh,ymesh,dxmesh,dymesh] = VectorField2D(control,tval,Yval,xsolrow,ysolrow,xlimit,ylimit)
            %disp('bdPhasePortrait.VectorField@D()');

            % Only compute vector fields for ODEs 
            if ~strcmp(control.solvertype,'odesolver')
                xmesh=[];
                ymesh=[];
                dxmesh=[];
                dymesh=[];
                return
            end
            
            % compute a mesh for the domain
            nx = 21;
            ny = 21;
            xdomain = linspace(xlimit(1),xlimit(2), nx);
            ydomain = linspace(ylimit(1),ylimit(2), ny);
            [xmesh,ymesh] = meshgrid(xdomain,ydomain);
            dxmesh = zeros(size(xmesh));
            dymesh = zeros(size(ymesh));
            
            % curent parameter values
            P0  = {control.sys.pardef.value};
            
            % evaluate vector field
            for xi = 1:nx
                for yi = 1:ny
                    % set initial conditions to current mesh point
                    Yval(xsolrow) = xmesh(xi,yi);
                    Yval(ysolrow) = ymesh(xi,yi);

                    % evaluate the ODE at Yval
                    dY = control.sys.odefun(tval,Yval,P0{:});

                    % save results
                    dxmesh(xi,yi) = dY(xsolrow);
                    dymesh(xi,yi) = dY(ysolrow);
                end
            end
        end
        
        % Evaluate the 3D vector field
        function [xmesh,ymesh,zmesh,dxmesh,dymesh,dzmesh] = VectorField3D(control,tval,Yval,xindx,yindx,zindx,xlimit,ylimit,zlimit)
            %disp('bdPhasePortrait.VectorField3D()');

            % Only compute vector fields for ODEs 
            if ~strcmp(control.solvertype,'odesolver')
                xmesh=[];
                ymesh=[];
                zmesh=[];
                dxmesh=[];
                dymesh=[];
                dzmesh=[];
                return
            end
            
            % compute a mesh for the domain
            nx = 21;
            ny = 21;
            nz = 11;
            xdomain = linspace(xlimit(1),xlimit(2), nx);
            ydomain = linspace(ylimit(1),ylimit(2), ny);
            zdomain = linspace(zlimit(1),zlimit(2), nz);
            [xmesh,ymesh,zmesh] = meshgrid(xdomain,ydomain,zdomain);
            dxmesh = zeros(size(xmesh));
            dymesh = zeros(size(ymesh));
            dzmesh = zeros(size(zmesh));
            
            % curent parameter values
            P0  = {control.sys.pardef.value};
            
            % evaluate vector field
            for xi = 1:nx
                for yi = 1:ny
                    for zi = 1:nz
                        % set initial conditions to current mesh point
                        Yval(xindx) = xmesh(xi,yi,zi);
                        Yval(yindx) = ymesh(xi,yi,zi);
                        Yval(zindx) = zmesh(zi,yi,zi);
                
                        % evaluate the ODE at Yval
                        dY = control.sys.odefun(tval,Yval,P0{:});
                
                        % save results
                        dxmesh(xi,yi,zi) = dY(xindx);
                        dymesh(xi,yi,zi) = dY(yindx);
                        dzmesh(xi,yi,zi) = dY(zindx);
                    end
                end
            end
        end
        
        % Assign default values to missing fields in sys.panels.bdPhasePortrait
        function syspanel = syscheck(sys)
            % Default panel settings
            syspanel.title = 'Phase Portrait';
            syspanel.transients = true;
            syspanel.markers = true;
            syspanel.points = false;
            syspanel.vecfield = false;
            syspanel.nullclines = false;
            syspanel.grid = false;
            syspanel.hold = false;
            
            % Nothing more to do if sys.panels.bdTimePortrait is undefined
            if ~isfield(sys,'panels') || ~isfield(sys.panels,'bdPhasePortrait')
                return;
            end
            
            % sys.panels.bdPhasePortrait.title
            if isfield(sys.panels.bdPhasePortrait,'title')
                syspanel.title = sys.panels.bdPhasePortrait.title;
            end

            % sys.panels.bdPhasePortrait.transients
            if isfield(sys.panels.bdPhasePortrait,'transients')
                syspanel.transients = sys.panels.bdPhasePortrait.transients;
            end
            
            % sys.panels.bdPhasePortrait.markers
            if isfield(sys.panels.bdPhasePortrait,'markers')
                syspanel.markers = sys.panels.bdPhasePortrait.markers;
            end
            
            % sys.panels.bdPhasePortrait.points
            if isfield(sys.panels.bdPhasePortrait,'points')
                syspanel.points = sys.panels.bdPhasePortrait.points;
            end
            
            % sys.panels.bdPhasePortrait.vecfield
            if isfield(sys.panels.bdPhasePortrait,'vecfield')
                syspanel.vecfield = sys.panels.bdPhasePortrait.vecfield;
            end
            
            % sys.panels.bdPhasePortrait.nullclines
            if isfield(sys.panels.bdPhasePortrait,'nullclines')
                syspanel.nullclines = sys.panels.bdPhasePortrait.nullclines;
            end
            
            % sys.panels.bdPhasePortrait.grid
            if isfield(sys.panels.bdPhasePortrait,'grid')
                syspanel.grid = sys.panels.bdPhasePortrait.grid;
            end
            
            % sys.panels.bdPhasePortrait.hold
            if isfield(sys.panels.bdPhasePortrait,'hold')
                syspanel.hold = sys.panels.bdPhasePortrait.hold;
            end
        end
        
    end
    
end
