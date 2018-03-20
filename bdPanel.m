classdef (Abstract) bdPanel < handle
    % Base class for display panels in the Brain Dynamics Toolbox GUI.
    % User-defined panels must be drived from this class. Among other
    % things, it manages the construction and destruction of the panel
    % tab as well as the visibility of the panel's menu in the toolbar.
    %
    % AUTHORS
    % Stewart Heitmann (2018a)   
    
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
    
    properties (Access=protected)
        menu                                % Handle to the panel's toolbar uimenu
        tab                                 % Handle to the panel's uitab
    end

    methods
        
        function this = bdPanel(tabgroup)
            % Constructs a new display panel in the given tabgroup.
            
            % handle to the parent figure
            fig = ancestor(tabgroup,'figure');
            
            % construct an empty menu and make it invisible. 
            this.menu = uimenu('Parent',fig, 'Label','noname', 'Visible','off');
            
            % construct an empty tab
            this.tab = uitab(tabgroup,'title','noname','Unit','pixels');
            
            % associated the menu with this tab
            this.tab.UserData.menu = this.menu;
            
            % ensure the menu for the selected tab (possibly this tab) is visible
            tabgroup.SelectedTab.UserData.menu.Visible = 'on';
        end
               
        % Close the panel
        function close(this)
            %disp('bdPanel.close()');
            % Get the tabgroup handle
            tabgroup = this.tab.Parent;
            
            % Delete the toolbar menu and the panel tab
            delete(this.menu);
            delete(this.tab);            
    
            % Reveal the menu of the newly selected tab (if it exists)
            if ~isempty(tabgroup.SelectedTab)
                tabgroup.SelectedTab.UserData.menu.Visible = 'on';
            end
            
            % Delete the panel object itself
            delete(this);
        end    
        
    end
    
    methods (Static)
        function [ax,cmenu,spanel] = Subpanel(parent,panelpos,axespos)
            % Construct a graphical subpanel in the parent tab.
            %
            % [ax,cmenu,spanel] = Subpanel(parent,panelpos,axespos)
            %
            % The position of the subpanel within the parent is dictated
            % by panelpos. The position of the axes within the subpanel
            % is dictated by axespos. Both positions are in normal
            % coordinates.
            %
            % Returns handles to the subpanel's axes (ax), its context
            % menu (cmenu) and its uipanel container (spanel).

            % handle to the parent figure
            fig = ancestor(parent,'figure');

            % Construct the uipanel container
            spanel = uipanel(parent, ...
                        'Units','normal', ...
                        'Position',panelpos, ...
                        'BorderType','beveledout');

            % Construct the axes
            ax = axes('Parent',spanel, ...
                'Units','normal', ...
                'OuterPosition',axespos, ...
                'NextPlot','add', ...
                'FontSize',12, ...
                'Box','on');

            % Define the icon for the menu button
            cdata = ones(10,10,3);
            cdata([1 2 5 6 9 10],:,:) = 0;

            % Construct an empty context menu
            cmenu = uicontextmenu();
            
            % Construct the menu button and attach the context menu to it
            mb = uicontrol(spanel, ...
                'Style','PushButton', ...
                'Position',[5 5 20 20], ...
                'CData',cdata, ...
                'UIContextMenu',cmenu, ...
                'Callback', @ButtonCallback, ...
                'DeleteFcn', @(~,~) DeleteFcn(cmenu), ...
                'ToolTipString', 'Plot menu');

            % Assign the callback function responsible for resizing the subpanel
            spanel.SizeChangedFcn = @SizeChanged;

            % Callback function for resizing the subpanel 
            function SizeChanged(~,~)
                parentpos = getpixelposition(spanel);
                mb.Position(2) = parentpos(4) - mb.Position(4) - 6;
            end
            
            % Callback function for the subpanel menu button
            function ButtonCallback(src,~)
                pos = getpixelposition(src,true);
                mb.UIContextMenu.Position = pos([1 2]);
                mb.UIContextMenu.Visible='on';
            end
            
            % Callback function for cleaning up the context menu
            function DeleteFcn(cmenu)
                % Delete the context menu
                delete(cmenu);
            end
        end

        function menuitem = SelectorMenu(menu,xxxdef,callback,separator,tag,checkindx)
            % Construct a set of selector menu items for each entry in xxxdef.
            %
            % menuitem = SelectorMenu(menu,xxxdef,callback,separator,tag,checkindx)
            %
            % The menu items are assigned to the specified parent menu.
            % Each one of those menu items are assigned the specified tag
            % and callback function. The Check state of all menu items are
            % set to 'off' except for the checkindx'th menu item which is
            % set to 'on'. The separator flag ('on' or 'off') only applies
            % to the first menu item. It is useful when concatenating
            % several selector menus to the same parent menu.
            %
            % Returns a handle to the checked menu item
            
            n = numel(xxxdef);
            for xxxindx=1:n
                UserData.xxxname = xxxdef(xxxindx).name;
                UserData.xxxindx = xxxindx;
                UserData.valindx = 1:numel(xxxdef(xxxindx).value);
                UserData.label = xxxdef(xxxindx).name;
                UserData.rootmenu = menu;
                if xxxindx==checkindx
                    % this menu item is checked 'on'
                    menuitem = uimenu('Parent',menu, ...
                        'Label',UserData.xxxname, ...
                        'Separator',separator, ...
                        'Checked','on', ...
                        'Tag',tag, ...
                        'UserData',UserData, ...
                        'Callback',callback);
                else
                    % this menu item is checked 'off'
                    uimenu('Parent',menu, ...
                        'Label',UserData.xxxname, ...
                        'Separator',separator, ...
                        'Checked','off', ...
                        'Tag',tag, ...
                        'UserData',UserData, ...
                        'Callback',callback);
                end
                separator='off';
            end
        end
        
        function menuitem = SelectorMenuFull(menu,xxxdef,callback,separator,tag,checkindx,checkvalindx)
            % Construct a fully enumerated selector menu for each entry in xxxdef.
            %
            % menuitem = SelectorMenuFull(menu,xxxdef,callback,separator,tag,checkindx,checkvalindx)
            %
            % Similar to SelectorMenu except that the individual elements
            % of vector and matrix values in xxxdef are all enumerated as
            % seperate menu items.
            
            n = numel(xxxdef);
            for xxxindx=1:n
                xxxname = xxxdef(xxxindx).name;
                [nr nc] = size(xxxdef(xxxindx).value);                
                
                % Test whether the xxxdef.value is a scalar, vector or matrix
                if nr*nc==1
                    % The xxxdef value is a scalar.
                    % No nested menu items are required.
                    UserData.xxxname = xxxname;
                    UserData.xxxindx = xxxindx;
                    UserData.valindx = 1;
                    UserData.label = xxxname;
                    UserData.rootmenu = menu;
                    if xxxindx==checkindx
                        % this menu item is checked 'on'
                        menuitem = uimenu('Parent',menu, ...
                            'Label',xxxname, ...
                            'Separator',separator, ...
                            'Tag',tag, ...
                            'Checked','on', ...
                            'UserData',UserData, ...
                            'Callback',callback);
                    else
                        % this menu item is checked 'off'
                        uimenu('Parent',menu, ...
                            'Label',xxxname, ...
                            'Separator',separator, ...
                            'Tag',tag, ...
                            'Checked','off', ...
                            'UserData',UserData, ...
                            'Callback',callback);
                    end
                elseif nr==1 || nc==1
                    % The xxxdef value is a vector (1 x nc) or (nr x 1).
                    % Construct a nested menu with one item per entry in the vector.
                    submenu = uimenu('Parent',menu, ...
                        'Label',xxxname, ...
                        'Separator',separator);
                    for valindx=1:(nr*nc)
                        % break up large menu lists into nested submenus
                        if mod(valindx,26)==0
                            submenu = uimenu('Parent',submenu, 'Label','more');
                        end
                        % gather the menuitem details
                        label = num2str(valindx,[xxxname,'(%d)']);
                        UserData.xxxname = xxxname;
                        UserData.xxxindx = xxxindx;
                        UserData.valindx = valindx;
                        UserData.label = num2str(valindx,[xxxname,'_{%d}']);
                        UserData.rootmenu = menu;
                        if xxxindx==checkindx && valindx==checkvalindx
                            % this menu item is checked 'on'
                            menuitem = uimenu('Parent',submenu,...
                                'Label',label, ...
                                'Tag',tag, ...
                                'Checked','on', ...
                                'UserData',UserData, ...
                                'Callback',callback);
                        else
                            % this menu item is checked 'off'
                            uimenu('Parent',submenu,...
                                'Label',label, ...
                                'Tag',tag, ...
                                'Checked','off', ...
                                'UserData',UserData, ...
                                'Callback',callback);
                        end
                    end
                else
                    % The xxxdef value is a matrix (nr x nc)
                    % Construct a doubly-nested menu with one submenu for each row
                    % and one item per entry in that row.
                    submenu = uimenu('Parent',menu, ...
                        'Label',xxxname, ...
                        'Separator',separator);
                    valindx = 1;
                    for r=1:nr
                        % break up large menu lists into nested submenus
                        if mod(r,26)==0
                            submenu = uimenu('Parent',submenu, 'Label','more');
                        end
                        % construct a subsubmenu for the column values 
                        subsubmenu = uimenu('Parent',submenu, 'Label',num2str(r,[xxxname,'(%d,-)']));
                        for c=1:nc
                            % break up large menu lists into nested submenus
                            if mod(c,26)==0
                                subsubmenu = uimenu('Parent',subsubmenu, 'Label','more');
                            end
                            % gather menuitem details
                            label = num2str([r,c],[xxxname,'(%d,%d)']);
                            UserData.xxxname = xxxname;
                            UserData.xxxindx = xxxindx;
                            UserData.valindx = valindx;
                            UserData.label = num2str([r,c],[xxxname,'_{%d,%d}']);
                            UserData.rootmenu = menu;
                            if xxxindx==checkindx && valindx==checkvalindx
                                % this menu item is checked 'on'
                                menuitem = uimenu('Parent',subsubmenu,...
                                    'Label',label, ...
                                    'Tag',tag, ...
                                    'Checked','on', ...
                                    'UserData',UserData, ...
                                    'Callback',callback);
                            else
                                % this menu item is checked 'off'
                                uimenu('Parent',subsubmenu,...
                                    'Label',label, ...
                                    'Tag',tag, ...
                                    'Checked','off', ...
                                    'UserData',UserData, ...
                                    'Callback',callback);
                            end
                            valindx = valindx + 1;
                        end
                    end
                end

                % The separator only applies to the first menu item
                separator='off';
            end
        end
        
        function SelectorCheckItem(menuitem)
            % Check 'on' the selected menu item and check 'off' the others.
            %
            % SelectorCheckItem(menuitem)
            %
            % The Checked state of the given menu item is set to 'on'
            % while the Checked state of all other menu items with the
            % same tag as that menuitem are set to 'off'.
            
            objs = findobj(menuitem.UserData.rootmenu,'Tag',menuitem.Tag);
            for indx=1:numel(objs)
                objs(indx).Checked='off';
            end            
            % now check 'on' the selected menu item
            menuitem.Checked='on';
        end
        
        function lim = RoundLim(lo,hi)
            % Utility function for rounding limits to 2 significant digits. 
            %
            % lim = RoundLim(lo,hi)
            %
            % Returns a [lo hi] limit that brackets the specified range.
            % As a safety precaution, the span of the returned limit will
            % not be larger than 2.4e100 and no smaller than 2e-4. 
            if lo < -1e100
                lo = -1e100;
            end
            if hi > 1e100
                hi = 1e100;
            end
            d = hi-lo;
            lim = round([lo-0.1*d, hi+0.1*d],2,'significant') + [-1e-4 1e-4];
        end

        function PanelSelectionChangedFcn(~,evnt)
            % Callback executed by the parent tabgroup when the selected tab changes.

            %disp('bdPanel.PanelSelectionChangedFcn');
            % Hide the panel menu associated with the old tab
            evnt.OldValue.UserData.menu.Visible = 'off';
            % Reveal the panel menu associated with the new tab
            evnt.NewValue.UserData.menu.Visible = 'on';
        end

    end
end

