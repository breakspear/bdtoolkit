%bdEditScalars  Dialog box for editing scalar values.
%Usage:
%    outdata = bdEditScalars(pardef,name,descr)
%where
%    'pardeg' is a cell array of {value,'text'} pairs
%    'name' is the title of the dialog box (text)
%    'descr' is the description of the content (text)
%Returns the edited data in 'outdata'. If the user cancels the operation
%then the returned as empty.
%
%EXAMPLE
%    outdata = bdEditScalars({1,'a'; 2,'b'; 3,'c'}, ...
%       'My Title', 'My Descrition Text')
%
%AUTHORS
%  Stewart Heitmann (2016a)

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
function outdata = bdEditScalars(pardef,name,descr)
    outdata = [];

    % number of rows in pardef
    npardef = size(pardef,1);
    
    % array of edit box widgets
    editbox = gobjects(npardef);

    % row geometry
    rowh = 22;
    boxh = 20;
    boxw = 50;
    
    % open dialog box
    height = npardef*rowh + 100; 
    dlg = dialog('Position',[300 300 250 height],'Name',name);

    % first line
    ypos = height - 1.5*rowh;
    
    % heading
    uicontrol('Parent',dlg,...
        'Style','text',...
        'Position',[20 ypos 210 rowh],...
        'String',descr, ...
        'FontSize',12, ...
        'HorizontalAlignment','left', ...
    ... 'BackgroundColor','r', ...
        'FontWeight','bold');

    % for each pardef extry
    for indx=1:npardef
        % next line
        ypos = ypos - rowh;

        % edit box
        editbox(indx) = uicontrol('Parent',dlg,...
            'Style','edit',...
            'Position',[20 ypos boxw boxh],...
            'String',num2str(pardef{indx,1}),...
            'FontSize',12, ...
            'HorizontalAlignment','center', ...
        ... 'BackgroundColor','r', ...           
            'Callback',@editbox_callback);

        % number of neurons (text label)
        uicontrol('Parent',dlg,...
            'Style','text',...
            'Position',[75 ypos 155 boxh],...
            'String',pardef{indx,2}, ...
            'FontSize',12, ...
            'HorizontalAlignment','left', ...
        ... 'BackgroundColor','r', ...
            'FontWeight','normal');
    end

    % next line
    ypos = ypos - 1.5*rowh;
    
    % syntax error (text)    
    err = uicontrol('Parent',dlg,...
        'Style','text',...
        'Position',[20 ypos 200 25],...
        'String','Syntax Error', ...
        'FontSize',12, ...
        'HorizontalAlignment','left', ...
        'ForegroundColor','r', ...
        'Visible','off', ...
        'FontWeight','normal');
    
    % next line
    ypos = ypos - rowh;

    % CANCEL button
    uicontrol('Parent',dlg,...
        'Position',[20 ypos 75 25],...
        'String','Cancel',...
        'Callback',@(~,~) cancel_callback );

    % CONTINUE button
    btn = uicontrol('Parent',dlg,...
        'Position',[250-95 ypos 75 25],...
        'String','Continue',...
        'Callback',@(~,~) delete(dlg) );
    
    % force the editbox values into outdata
    editbox_callback([],[]);
    
    % Wait for dialog to close
    uiwait(dlg);
   
    function editbox_callback(~,~)
        for indx = 1:npardef
            val = str2num(editbox(indx).String);
            if isempty(val)
                % invalid number
                btn.Enable = 'off';      % disable the CONTINUE button
                err.Visible = 'on';      % show the syntax error text
                return
            else
                outdata(indx) = val;
            end
        end
        btn.Enable = 'on';              % enable the CONTINUE button
        err.Visible = 'off';            % hide the syntax error text
    end

    function cancel_callback(~,~)
        outdata = [];
        delete(dlg);
    end
    
end
