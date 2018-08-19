classdef bdBoldHRF < bdPanel
    %bdBoldHRF Display panel for simulating the BOLD signal of neural activity.
    %The BOLD HRF panel computes the Blood Oxygenation Level Dependent (BOLD)
    %signal for simulated neuronal activity as it would be observed in fMRI.
    %The neuronal activity is taken from the selected state variable after 
    %mapping it from the interval [z0, z1] onto [0, 1]. The panel uses the
    %haemodynamic model by Glaser, Friston, Mechelli, Turner & Price (2003)
    %as described in Chapter 5 of the Handbook for the Brain Dynamics Toolbox.
    %The same equations are also implemented in the 'BOLDHRF' example model.
    %Use it to validate your choice of haemodynamic parameters (V0, E0, tau0,
    %tau1, alpha, kappa, gamma).
    %
    %SEE ALSO
    %  BOLDHRF
    %
    %AUTHORs
    %  Stewart Heitmann (2018b)

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
        title = 'BOLD HRF';
    end    

    properties
        t               % Time steps of the solution (1 x t)
        v               % Normalised volume of blood (n x t)
        q               % Normalised deoxyhaemoglobin content (n x t)
        f               % Blood inflow (n x t)
        s               % Vasodilatory signal (n x t)
        u               % Neuronal activity (n x t)
        z               % Selected driving variable (n x t)
        bold            % BOLD signal (n x t)
        V0              % Resting blood volume
        E0              % Resting next oxygen extraction fraction
        tau0            % mean transit time of blood
        tau1            % time constant of blood inflow
        alpha           % Balloon stifness parameter
        kappa           % decay parameter of the vasodilatory signal
        gamma           % autoregulatory parameter of the vasodilatory signal 
        z0              % z(t)=z0 of the selected variable maps onto u(t)=0
        z1              % z(t)=z1 of teh selected variable maps onto u(t)=1
    end
    
    properties (Access=private)
        ax2             % Handle to the BOLD plot axes
        V0_editbox      % Handle to V0 editbox widget
        E0_editbox      % Handle to E0 editbox widget
        tau0_editbox    % Handle to tau0 editbox widget
        tau1_editbox    % Handle to tau1 editbox widget
        alpha_editbox   % Handle to alpha editbox widget
        kappa_editbox   % Handle to kappa editbox widget
        gamma_editbox   % Handle to gamma editbox widget
        z0_editbox      % Handle to z0 editbox widget
        z1_editbox      % Handle to z editbox widget
        warn_box        % Handle to Warning text widget
        tranmenu        % handle to TRANSIENTS menu item
        markmenu        % handle to MARKERS menu item
        gridmenu        % handle to GRID menu item
        holdmenu        % handle to HOLD menu item
        submenu1        % handle to upper subpanel selector menu item
        submenu2        % handle to lower subpanel selector menu item
        listener        % handle to our listener object
    end
    
    methods
        
        function this = bdBoldHRF(tabgroup,control)
            % Construct a new Time Portrait in the given tabgroup

            % initialise the base class (specifically this.menu and this.tab)
            this@bdPanel(tabgroup);
            
            % assign default values to missing options in sys.panels.bdBoldHRF
            control.sys.panels.bdBoldHRF = bdBoldHRF.syscheck(control.sys);

            % configure the pull-down menu
            this.menu.Label = control.sys.panels.bdBoldHRF.title;
            this.InitAboutMenu(control);
            this.InitTransientsMenu(control);
            this.InitMarkerMenu(control);
            this.InitGridMenu(control);
            this.InitHoldMenu(control);
            this.InitExportMenu(control);
            this.InitCloseMenu(control);

            % configure the panel graphics
            this.tab.Title = control.sys.panels.bdBoldHRF.title;
            this.InitSubpanel2(control);
            
            % listen to the control panel for redraw events
            this.listener = addlistener(control,'redraw',@(~,~) this.redraw(control));    
        end
        
        function delete(this)
            % Destructor
            delete(this.listener)
        end
         
    end
    
    methods (Access=private)
        
        % Initialise the ABOUT menu item
        function InitAboutMenu(this,control)
            % construct the menu item
            uimenu(this.menu, ...
                'Label','About', ...
                'Callback', @AboutMenuCallback );
            
            % Menu callback function
            function AboutMenuCallback(menuitem,~)
                msg = ['The BOLD HRF panel computes the Blood Oxygenation Level Dependent ' ...
                      'signal for simulated neuronal activity as it would be observed in fMRI. ' ...
                      'The neuronal activity is defined by the selected state variable after ' ...
                      'mapping it from the interval [z0, z1] onto [0, 1]. ' ...
                      'The panel uses the haemodynamic model by Glaser, Friston, Mechelli, Turner & Price (2003) ' ...
                      'as described in the Handbook for the Brain Dynamics Toolbox (2018b). ' ... 
                      'The same equations are also implemented in the ''BOLDHRF'' example model. ' ...
                      'Use it to validate your choice of haemodynamic parameters. ' ...
                      'Warning: This panel can be very slow to respond because it is essentially a solver within a solver.'];
                uiwait( msgbox(msg,'About the BOLD HRF panel','modal') );
            end
        end
        
        % Initialise the TRANSIENTS menu item
        function InitTransientsMenu(this,control)
            % get the default transient menu setting from sys.panels
            if control.sys.panels.bdBoldHRF.transients
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
            if control.sys.panels.bdBoldHRF.markers
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
        
        % Initiliase the GRID menu item
        function InitGridMenu(this,control)
            % get the default grid menu setting from sys.panels
            if control.sys.panels.bdBoldHRF.grid
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
                        grid(this.ax2,'off');
                    case 'off'
                        menuitem.Checked='on';
                        grid(this.ax2,'on');
                end
                grid(this.ax2, menuitem.Checked);
            end
        end
        
        % Initialise the HOLD menu item
        function InitHoldMenu(this,control)
             % get the hold menu setting from sys.panels options
            if control.sys.panels.bdBoldHRF.hold
                holdcheck = 'on';
            else
                holdcheck = 'off';
            end
            
            % construct the menu item
            this.holdmenu = uimenu(this.menu, ...
                'Label','Hold', ...
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
                ax2new = copyobj(this.ax2,fig);
                ax2new.OuterPosition = [0 0 1 1];

                % Allow the user to hit everything in ax2new
                objs = findobj(ax2new,'-property', 'HitTest');
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

        % Initialise the lower subpanel
        function InitSubpanel2(this,control)
            % construct the BOLD subpanel
            [this.ax2,cmenu] = bdPanel.Subpanel(this.tab,[0 0 1 1],[0 0.2 1 0.75]);
            xlabel(this.ax2,'time');
            ylabel(this.ax2,'BOLD (%)');
            
            % get the subpanel container
            subpanel2 = this.ax2.Parent;

             % construct a selector menu comprising items from sys.vardef
             this.submenu2 = bdPanel.SelectorMenuFull(cmenu, ...
                 control.sys.vardef, ...
                 @selectorCallback, ...
                 'off', 'mb1',1,1);            
            
            % edit box geometry
            boxw = 50;
            boxh = 20;
            boxx = 5;

            % construct edit box for V0
            fieldname = 'V0';
            this.V0_editbox = uicontrol('Style','edit', ...
                'Value', control.sys.panels.bdBoldHRF.V0, ...
                'String', num2str(control.sys.panels.bdBoldHRF.V0,'%0.4g'), ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'TooltipString', 'Resting blood volume', ...
                'Parent', subpanel2, ...
                'Callback', @(hObj,~) editboxCallback(control,hObj,fieldname), ...
                'Position',[boxx 10 boxw boxh]);
            uicontrol('Style','text', ...
                'String',fieldname, ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', subpanel2, ...
                'Position',[boxx 10+boxh boxw boxh]);
            
            % next col
            boxx = boxx + boxw + 5;
            
            % construct edit box for E0
            fieldname = 'E0';
            this.E0_editbox = uicontrol('Style','edit', ...
                'Value', control.sys.panels.bdBoldHRF.E0, ...
                'String', num2str(control.sys.panels.bdBoldHRF.E0,'%0.4g'), ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'TooltipString', 'Resting net oxygen extraction fraction', ...
                'Parent', subpanel2, ...
                'Callback', @(hObj,~) editboxCallback(control,hObj,fieldname), ...
                'Position',[boxx 10 boxw boxh]);
            uicontrol('Style','text', ...
                'String',fieldname, ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', subpanel2, ...
                'Position',[boxx 10+boxh boxw boxh]);
                       
            % next col
            boxx = boxx + boxw + 5;
            
            % construct edit box for tau0
            fieldname = 'tau0';
            this.tau0_editbox = uicontrol('Style','edit', ...
                'Value', control.sys.panels.bdBoldHRF.tau0, ...
                'String', num2str(control.sys.panels.bdBoldHRF.tau0,'%0.4g'), ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'TooltipString', 'Transit time of blood', ...
                'Parent', subpanel2, ...
                'Callback', @(hObj,~) editboxCallback(control,hObj,fieldname), ...
                'Position',[boxx 10 boxw boxh]);
            uicontrol('Style','text', ...
                'String',fieldname, ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', subpanel2, ...
                'Position',[boxx 10+boxh boxw boxh]);
            
            % next col
            boxx = boxx + boxw + 5;
            
            % construct edit box for tau1
            fieldname = 'tau1';
            this.tau1_editbox = uicontrol('Style','edit', ...
                'Value', control.sys.panels.bdBoldHRF.tau1, ...
                'String', num2str(control.sys.panels.bdBoldHRF.tau1,'%0.4g'), ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'TooltipString', 'Time constant of blood inflow', ...
                'Parent', subpanel2, ...
                'Callback', @(hObj,~) editboxCallback(control,hObj,fieldname), ...
                'Position',[boxx 10 boxw boxh]);
            uicontrol('Style','text', ...
                'String',fieldname, ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', subpanel2, ...
                'Position',[boxx 10+boxh boxw boxh]);
            
            % next col
            boxx = boxx + boxw + 5;

            % construct edit box for alpha
            fieldname = 'alpha';
            this.alpha_editbox = uicontrol('Style','edit', ...
                'Value', control.sys.panels.bdBoldHRF.alpha, ...
                'String', num2str(control.sys.panels.bdBoldHRF.alpha,'%0.4g'), ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'TooltipString', 'Grubb''s Exponent', ...
                'Parent', subpanel2, ...
                'Callback', @(hObj,~) editboxCallback(control,hObj,fieldname), ...
                'Position',[boxx 10 boxw boxh]);
            uicontrol('Style','text', ...
                'String',fieldname, ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', subpanel2, ...
                'Position',[boxx 10+boxh boxw boxh]);
            
            % next col
            boxx = boxx + boxw + 5;
            
            % construct edit box for kappa
            fieldname = 'kappa';
            this.kappa_editbox = uicontrol('Style','edit', ...
                'Value', control.sys.panels.bdBoldHRF.kappa, ...
                'String', num2str(control.sys.panels.bdBoldHRF.kappa,'%0.4g'), ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'TooltipString', 'Vasodilatory constant', ...
                'Parent', subpanel2, ...
                'Callback', @(hObj,~) editboxCallback(control,hObj,fieldname), ...
                'Position',[boxx 10 boxw boxh]);
            uicontrol('Style','text', ...
                'String',fieldname, ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', subpanel2, ...
                'Position',[boxx 10+boxh boxw boxh]);
            
            % next col
            boxx = boxx + boxw + 5;
            
            % construct edit box for gamma
            fieldname = 'gamma';
            this.gamma_editbox = uicontrol('Style','edit', ...
                'Value', control.sys.panels.bdBoldHRF.gamma, ...
                'String', num2str(control.sys.panels.bdBoldHRF.gamma,'%0.4g'), ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'TooltipString', 'Vasodilatory constant', ...
                'Parent', subpanel2, ...
                'Callback', @(hObj,~) editboxCallback(control,hObj,fieldname), ...
                'Position',[boxx 10 boxw boxh]);
            uicontrol('Style','text', ...
                'String',fieldname, ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', subpanel2, ...
                'Position',[boxx 10+boxh boxw boxh]);

            % next col
            boxx = boxx + boxw + 5;
            
            % construct edit box for z0
            fieldname = 'z0';
            this.z0_editbox = uicontrol('Style','edit', ...
                'Value', control.sys.panels.bdBoldHRF.z0, ...
                'String', num2str(control.sys.panels.bdBoldHRF.z0,'%0.4g'), ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'TooltipString', 'z(t)=z0 maps onto u(t)=0', ...
                'Parent', subpanel2, ...
                'Callback', @(hObj,~) editboxCallback(control,hObj,fieldname), ...
                'Position',[boxx 10 boxw boxh]);
            uicontrol('Style','text', ...
                'String',fieldname, ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', subpanel2, ...
                'Position',[boxx 10+boxh boxw boxh]);
            
            % next col
            boxx = boxx + boxw + 5;
            
            % construct edit box for z1
            fieldname = 'z1';
            this.z1_editbox = uicontrol('Style','edit', ...
                'Value', control.sys.panels.bdBoldHRF.z1, ...
                'String', num2str(control.sys.panels.bdBoldHRF.z1,'%0.4g'), ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'TooltipString', 'z(t)=z1 maps onto u(t)=1', ...
                'Parent', subpanel2, ...
                'Callback', @(hObj,~) editboxCallback(control,hObj,fieldname), ...
                'Position',[boxx 10 boxw boxh]);
            uicontrol('Style','text', ...
                'String',fieldname, ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', subpanel2, ...
                'Position',[boxx 10+boxh boxw boxh]);           
            
            % next col
            boxx = boxx + boxw + 10;
                                 
            % construct text box for WARNING 
            fieldname = 'Warning';
            this.warn_box = uicontrol('Style','text', ...
                'String','none', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'TooltipString', 'BOLD warning message', ...
                'Parent', subpanel2, ...
                'Position',[boxx 10 3*boxw boxh]);
            uicontrol('Style','text', ...
                'String',fieldname, ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
            ... 'BackgroundColor', 'w', ...
                'Parent', subpanel2, ...
                'Position',[boxx 10+boxh 3*boxw boxh]);
            
            % Callback function for the subpanel selector menu
            function selectorCallback(menuitem,~)
                % check 'on' the selected menu item and check 'off' all others
                bdPanel.SelectorCheckItem(menuitem);
                % update our handle to the selected menu item
                this.submenu2 = menuitem;
                % redraw the panel
                this.redraw(control);
            end
                        
            % Callback for user input to the edit boxes
            function editboxCallback(control,uibox,fieldname)
                % get the incoming value from the edit box
                val = str2double(uibox.String);
                if isnan(val)
                    % invalid number
                    dlg = errordlg(['''', uibox.String, ''' is not a valid number'],'Invalid Number','modal');
                    % restore previous edit box value/string
                    val = uibox.Value;    
                    uibox.String = num2str(val,'%0.4g');
                    % wait for dialog box to close
                    uiwait(dlg);
                    return
                end

                % remember the new value
                uibox.Value = val;

                % recompute the BOLD by redrawing this panel
                this.redraw(control);
            end           
            
        end    
   
        % Redraw the data plots
        function redraw(this,control)
            %disp('bdBoldHRF.redraw()')
            
            % get the details of the variable currently selected in the panel menu
            varname  = this.submenu2.UserData.xxxname;          % generic name of variable
            varlabel = this.submenu2.UserData.label;            % plot label for selected variable
            varindx  = this.submenu2.UserData.xxxindx;          % index of selected variable in sys.vardef
            valindx  = this.submenu2.UserData.valindx;          % indices of selected entries in sys.vardef.value
            solindx  = control.sys.vardef(varindx).solindx;    % indices of selected entries in sol
                        
            % compute the BOLD signal
            this.t = control.sol.x;
            this.z = control.sol.y(solindx,:);
            this.V0 = this.V0_editbox.Value;
            this.E0 = this.E0_editbox.Value;
            this.tau0 = this.tau0_editbox.Value;
            this.tau1 = this.tau1_editbox.Value;
            this.alpha = this.alpha_editbox.Value;
            this.kappa = this.kappa_editbox.Value;
            this.gamma = this.gamma_editbox.Value;
            this.z0 = this.z0_editbox.Value;
            this.z1 = this.z1_editbox.Value;
            v0 = 1;
            q0 = 1;
            f0 = 1;
            s0 = 0;
          
            % set default options for the BOLD solver (which is ode23s)
            options = odeset();
            
            % now override the default options with those used by the GUI solver
            switch control.solvertype
                case 'odesolver'
                    options.AbsTol = odeget(control.sys.odeoption,'AbsTol');
                    options.RelTol = odeget(control.sys.odeoption,'RelTol');
                    options.InitialStep = odeget(control.sys.odeoption,'InitialStep');
                    options.MaxStep = odeget(control.sys.odeoption,'MaxStep');
                case 'ddesolver'
                    options.AbsTol = ddeget(control.sys.ddeoption,'AbsTol');
                    options.RelTol = ddeget(control.sys.ddeoption,'RelTol');
                    options.InitialStep = ddeget(control.sys.ddeoption,'InitialStep');
                    options.MaxStep = ddeget(control.sys.ddeoption,'MaxStep');
                case 'sdesolver'
                    if isfield(control.sys.sdeoption,'InitialStep')
                        options.InitialStep = control.sys.sdeoption.InitialStep;
                        options.RelTol = 1e-6;
                        options.MaxStep = options.InitialStep;
                    end
            end
            
            % clear the last warning message
            lastwarn('');            
            oldwarn = warning('off','backtrace');                

            % map the selected variable to u(t)
            this.u = (this.z - this.z0)./(this.z1 - this.z0);
            
            % Solve the haemodynamic model
            [this.bold,this.v,this.q,this.f,this.s] = this.compute(this.t,this.u,this.V0,this.E0,this.tau0,this.tau1,this.alpha,this.gamma,this.kappa,v0,q0,f0,s0,options);

            % Sanity check
            if ~isreal(this.bold)
                warning('bdBoldHRF:invalidComplex', 'Computed BOLD is invalid because it is complex');
            end
            
            % restore the old warning state
            warning(oldwarn.state,'backtrace'); 

            % Display any warnings from the BOLD solver
            [msg,msgid] = lastwarn();
            ix = find(msgid==':',1,'last');
            if ~isempty(ix)
                this.warn_box.String = msgid((ix+1):end);
                this.warn_box.TooltipString = msg;
                this.warn_box.ForegroundColor = 'r';
                linecolor = 'r';
            else
                this.warn_box.String = 'none';
                this.warn_box.TooltipString = 'Solver Warning Message';
                this.warn_box.ForegroundColor = 'k';
                linecolor = 'k';
            end
            
            % if 'hold' menu is checked then ...
            switch this.holdmenu.Checked
                case 'on'
                    % Remove the foreground lines and markers only
                    delete( findobj(this.ax2,'Tag','Fgnd') );
                case 'off'
                    % Clear everything from the axes
                    cla(this.ax2);
            end
            
            % if the TRANSIENT menu is enabled then  ...
            switch this.tranmenu.Checked
                case 'on'
                    % set the x-axes limits to the full time span
                    this.ax2.XLim = control.sys.tspan + [-1e-4 0];
                case 'off'
                    % limit the x-axes to the non-transient part of the time domain
                    this.ax2.XLim = [control.sys.tval control.sys.tspan(2)] + [-1e-4 0];
            end
            
            % plot the background traces as thin grey lines
            plot(this.ax2, this.t, 100*this.bold, 'color',[0.75 0.75 0.75], 'HitTest','off');

%             % plot the neural actiity
%             axx = axes('Parent',this.ax2.Parent, ...
%                 'Position',this.ax2.Position, ...
%                 'Color','none', ... 
%                 'NextPlot','add');
%             plot(axx,this.t, this.u, 'color','b');
            
            % get the indices of the non-transient time steps in this.t
            tindx = control.tindx;      % logical indices of the non-transient time steps
            indxt = find(tindx>0,1);    % numerical index of the first non-transient step (may be empty)

            % (re)plot the non-transient part of the variable of interest as a heavy black line
            plot(this.ax2, this.t(tindx), 100*this.bold(valindx,tindx), 'color',linecolor, 'Marker','none', 'LineStyle','-', 'Linewidth',1.5);
            
            % plot the pentagram marker (upper plot)
            plot(this.ax2, this.t(1), 100*this.bold(valindx,1), ...
                 'Marker','p', 'Color','k', 'MarkerFaceColor','y', 'MarkerSize',10 , ...
                 'Visible',this.markmenu.Checked, 'Tag','Fgnd');
                    
            % plot the circle marker (upper plot)
            plot(this.ax2, this.t(indxt), 100*this.bold(valindx,indxt), ...
                  'Marker','o', 'Color','k', 'MarkerFaceColor','y', 'MarkerSize',6, ...
                  'Visible',this.markmenu.Checked, 'Tag','Fgnd');

            % update the title
            title(['BOLD response derived from ' varname], 'Parent',this.ax2);
        end
    end
    
    methods (Static)

        function [bold,V,Q,F,S] = compute(T,Z,V0,E0,tau0,tau1,alpha,gamma,kappa,v0,q0,f0,s0,options)
            % Compute the BOLD haemodynamic response to neural activity
            % in Z (nxt) at time steps t (1xt) using initial values q0,v0,f0,s0.
            % Returns the BOLD signal in Y (nxt) and the haemodynamic variables
            % in V,Q,F,S (each nxt). The integration is performed using ode23s.
            % Solver options can be specified in the 'options' struct using 
            % odeset.
            
            % number of rows in Z
            n = size(Z,1);

            % initial conditions
            Y0 = [ v0 * ones(n,1); 
                   q0 * ones(n,1); 
                   f0 * ones(n,1); 
                   s0 * ones(n,1) ];
               
            % integrate the haemodynamics
            sol = ode23s(@odefun,T([1,end]),Y0,options);

            % interpolate the solution using the original time points T
            V = deval(sol,T,1:n);  
            Q = deval(sol,T,[1:n]+n);  
            F = deval(sol,T,[1:n]+2*n);  
            S = deval(sol,T,[1:n]+3*n);  
                       
            % compute the BOLD signal
            k1 = 7*E0;
            k2 = 2;
            k3 = 2*E0 - 0.2;            
            bold = V0*(k1.*(1-Q) + k2*(1-Q./V) + k3*(1-V));

            % The ODE function for the Haemodynamic model of BOLD response
            function dY = odefun(t,Y)  
                % extract incoming variables from Y
                v = Y([1:n]);             % blood volume 
                q = Y([1:n]+n);           % deoxyhaemoglobin
                f = Y([1:n]+2*n);         % blood inflow
                s = Y([1:n]+3*n);         % vasodilatory signal

                % interpolate Z at time t
                z = interp1(T,Z',t)';
                
                % differential equations
                dv = (f - v.^(1/alpha)) ./ tau0;
                dq = (f.*(1-(1-E0).^(1./f))/E0 - v.^((1-alpha)/alpha).*q ) ./ tau0;
                df = s ./ tau1;
                ds = (z - kappa*s - gamma*(f-1)) ./ tau1;

                % return result
                dY = [dv; dq; df; ds];            
            end
        
        end

        
        function syspanel = syscheck(sys)
            % Assign default values to missing fields in sys.panels.bdBoldHRF

            % Default panel settings
            syspanel.title = bdBoldHRF.title;
            syspanel.transients = true;
            syspanel.markers = true;
            syspanel.grid = false;
            syspanel.hold = false;
            syspanel.V0 = 0.02;
            syspanel.E0 = 0.34;
            syspanel.tau0 = 0.98;
            syspanel.tau1 = 1;
            syspanel.alpha = 0.32;
            syspanel.kappa = 0.65;
            syspanel.gamma = 0.41;
            syspanel.z0 = 0;
            syspanel.z1 = 1;
            
            % Nothing more to do if sys.panels.bdBoldHRF is undefined
            if ~isfield(sys,'panels') || ~isfield(sys.panels,'bdBoldHRF')
                return;
            end
            
            % sys.panels.bdBoldHRF.title
            if isfield(sys.panels.bdBoldHRF,'title')
                syspanel.title = sys.panels.bdBoldHRF.title;
            end
            
            % sys.panels.bdBoldHRF.transients
            if isfield(sys.panels.bdBoldHRF,'transients')
                syspanel.transients = sys.panels.bdBoldHRF.transients;
            end
            
            % sys.panels.bdBoldHRF.markers
            if isfield(sys.panels.bdBoldHRF,'markers')
                syspanel.markers = sys.panels.bdBoldHRF.markers;
            end
            
            % sys.panels.bdBoldHRF.grid
            if isfield(sys.panels.bdBoldHRF,'grid')
                syspanel.grid = sys.panels.bdBoldHRF.grid;
            end
            
            % sys.panels.bdBoldHRF.hold
            if isfield(sys.panels.bdBoldHRF,'hold')
                syspanel.hold = sys.panels.bdBoldHRF.hold;
            end
            
            % sys.panels.bdBoldHRF.V0
            if isfield(sys.panels.bdBoldHRF,'V0')
                syspanel.V0 = sys.panels.bdBoldHRF.V0;
            end
            
            % sys.panels.bdBoldHRF.E0
            if isfield(sys.panels.bdBoldHRF,'E0')
                syspanel.E0 = sys.panels.bdBoldHRF.E0;
            end
            
            % sys.panels.bdBoldHRF.tau0
            if isfield(sys.panels.bdBoldHRF,'tau0')
                syspanel.tau0 = sys.panels.bdBoldHRF.tau0;
            end
            
            % sys.panels.bdBoldHRF.tau1
            if isfield(sys.panels.bdBoldHRF,'tau1')
                syspanel.tau1 = sys.panels.bdBoldHRF.tau1;
            end
            
            % sys.panels.bdBoldHRF.alpha
            if isfield(sys.panels.bdBoldHRF,'alpha')
                syspanel.alpha = sys.panels.bdBoldHRF.alpha;
            end
            
            % sys.panels.bdBoldHRF.kappa
            if isfield(sys.panels.bdBoldHRF,'kappa')
                syspanel.kappa = sys.panels.bdBoldHRF.kappa;
            end
            
            % sys.panels.bdBoldHRF.gamma
            if isfield(sys.panels.bdBoldHRF,'gamma')
                syspanel.gamma = sys.panels.bdBoldHRF.gamma;
            end
            
            % sys.panels.bdBoldHRF.z0
            if isfield(sys.panels.bdBoldHRF,'z0')
                syspanel.z0 = sys.panels.bdBoldHRF.z0;
            end            
            
            % sys.panels.bdBoldHRF.z1
            if isfield(sys.panels.bdBoldHRF,'z1')
                syspanel.z1 = sys.panels.bdBoldHRF.z1;
            end            
        end
        
    end
    
end


