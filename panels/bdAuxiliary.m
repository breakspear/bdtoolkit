classdef bdAuxiliary < bdPanel
    %bdAuxiliary Display panel for plotting model-specific functions.
    %
    %AUTHORS
    %  Stewart Heitmann (2018a)

    % Copyright (C) 2018 QIMR Berghofer Medical Research Institute
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
        title = 'Auxiliary'
    end
    
    properties
        ax              % Handle to the plot axes
    end
    
    properties (Access=private)
        holdmenu        % handle to HOLD menu item
        submenu         % handle to subpanel selector menu item
        listener        % handle to our listener object
    end
    
    methods
        
        function this = bdAuxiliary(tabgroup,control)
            % Construct a new Auxiliary Panel in the given tabgroup

            % initialise the base class (specifically this.menu and this.tab)
            this@bdPanel(tabgroup);
            
            % assign default values to missing options in sys.panels.bdTimePortrait
            control.sys.panels.bdAuxiliary = bdAuxiliary.syscheck(control.sys);

            % configure the pull-down menu
            this.menu.Text = control.sys.panels.bdAuxiliary.title;
            this.InitHoldMenu(control);
            this.InitExportMenu(control);
            this.InitCloseMenu(control);

            % configure the panel graphics
            this.tab.Title = control.sys.panels.bdAuxiliary.title;
            this.InitSubpanel(control);
            
            % listen to the control panel for redraw events
            this.listener = listener(control,'redraw',@(~,~) this.redraw(control));    
        end
        
    end
    
    methods (Access=private)
        
        % Initialise the HOLD menu item
        function InitHoldMenu(this,control)
             % get the hold menu setting from sys.panels options
            if control.sys.panels.bdTimePortrait.hold
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
        function InitExportMenu(this,~)
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

                % Allow the user to hit everything in ax1new
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
                   'Text','Close', ...
                   'Callback',@(~,~) this.close());
        end
        
        % Initialise the subpanel
        function InitSubpanel(this,control)
            % construct the subpanel
            [this.ax,cmenu] = bdPanel.Subpanel(this.tab,[0 0 1 1],[0 0 1 1]);
            title(this.ax,'Auxiliary Functions');
            
            % construct the selector menu for the auxiliary functions
            naux = numel(control.sys.panels.bdAuxiliary.auxfun);
            for indx=1:naux
                UserData.auxfun = control.sys.panels.bdAuxiliary.auxfun{indx};
                UserData.label = func2str(UserData.auxfun);
                UserData.rootmenu = cmenu;
                menuitem = uimenu('Parent',cmenu, ...
                    'Text',UserData.label, ...
                    'Checked','off', ...
                    'Tag','auxmenu', ...
                    'UserData',UserData, ...
                    'Callback',@callback);                
                if indx==1
                    menuitem.Checked = 'on';
                    this.submenu = menuitem;
                end
            end
            
            
            % Callback function for the subpanel selector menu
            function callback(menuitem,~)
                % check 'on' the selected menu item and check 'off' all others
                bdPanel.SelectorCheckItem(menuitem);
                
                % update our handle to the selected menu item
                this.submenu = menuitem;
                
                % clear the axis, reset to defaults, set hold='on'
                cla(this.ax);
                reset(this.ax);
                hold(this.ax,'on');
                
                % redraw the panel
                this.redraw(control);
            end
        end
        
        % Redraw the data plots
        function redraw(this,control)
            %disp('bdAuxiliary.redraw()')
            
            % if 'hold' menu is checked then ...
            switch this.holdmenu.Checked
                case 'off'
                    % Clear the plot axis
                    cla(this.ax);
            end

            % init the title with thr name of the auxiliary function   
            title(this.ax,this.submenu.UserData.label);

            % get the details of the currently selected plot function
            auxfun  = this.submenu.UserData.auxfun;
            
            % execute the auxiliary plot function
            feval(auxfun,this.ax,control.sys.tval,control.sol,struct2cell(control.par)');
        end

    end
    
    methods (Static)
        function syspanel = syscheck(sys)
            % Assign default values to missing fields in sys.panels.bdAuxiliary

            % Default panel settings
            syspanel.title = bdAuxiliary.title;
            %syspanel.transients = true;
            %syspanel.markers = true;
            %syspanel.points = false;
            %syspanel.grid = false;
            syspanel.hold = false;
            syspanel.auxfun = {@bdAuxiliary.auxdefault};
            
            % Nothing more to do if sys.panels.bdAuxiliary is undefined
            if ~isfield(sys,'panels') || ~isfield(sys.panels,'bdAuxiliary')
                return;
            end
            
            % sys.panels.bdAuxiliary.title
            if isfield(sys.panels.bdAuxiliary,'title')
                syspanel.title = sys.panels.bdAuxiliary.title;
            end
            
            % sys.panels.bdAuxiliary.hold
            if isfield(sys.panels.bdAuxiliary,'hold')
                syspanel.hold = sys.panels.bdAuxiliary.hold;
            end
            
            % sys.panels.bdAuxiliary.auxfun
            if isfield(sys.panels.bdAuxiliary,'auxfun')
                syspanel.auxfun = sys.panels.bdAuxiliary.auxfun;
            end
        end
        
        function auxdefault(ax,vargargin)
            text(ax,0.5,0.5,'No auxiliary plotting functions are defined for this system', ...
                'HorizontalAlignment','center');
        end
    end
    
end

function myfunc(ax,tindx,sol,Kij,a,b,c,d,r,s,x0,Iap,gs,Vs,theta)
    plot(ax,sol.x(tindx),sol.y(:,tindx));
end
