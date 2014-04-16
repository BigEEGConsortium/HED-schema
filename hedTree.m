% Copyright (C) 2013 Nima Bigdely-Shamlo and Matthew Burns, Swartz Center for Computational
% Neuroscience.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice, this
%    list of conditions and the following disclaimer.
% 2. Redistributions in binary form must reproduce the above copyright notice,
%    this list of conditions and the following disclaimer in the documentation
%    and/or other materials provided with the distribution.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
% ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
% WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
% ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
% (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
% LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
% ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
% (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%
% The views and conclusions contained in the software and documentation are those
% of the authors and should not be interpreted as representing official policies,
% either expressed or implied, of the FreeBSD Project.

classdef hedTree
    % this class represents an input cell array containing HED strings (each HED string is composed
    % of several HED tags) as a jungle (multiple node trees). Each tree shows the hierarchical
    % structure of HEd tags. Number of occurance and indices of the original HED strings that match
    % each tag are calculated and plaved in class properties.
    
    properties
        uniqueTag               % a cell array with unique HED tags in the input HED string cell array (derived from all input HED strings)
        uniqueTagCount          % a numrival array containing the number of occurances of each unique tag across all input HED string cell array.
        
        hedVersion=[];           % version of HED specification used to create this hedTree
        originalHedStringId=[];     % a cell array where each cell contains indices in the input HED string cell array where each uniqueTag
        originalHedStrings=[];      % a cell array of hed strings that were used to form this hedTree
        adjacencyMatrix             % Adjacency matrix (could be sparse) defined as follows:
        %   element i,j = 1 if node_i is connected with node_j,
        %   therwise the entry is 0. With i,j = 1: number of nodes.
    end;
    
    methods
        %hedManager is optional second argument: issues an error if the hed
        %specification is violated. 
        function obj = hedTree(hedStrings, hedmanager)
            
            if nargin > 1
                assert(isa(hedmanager,'hedManager'));
                hm=hedmanager;
            else
                hm={};
            end
            
            obj.originalHedStrings=hedStrings;
            
            %Setting these to zero indicates we are not using hedManager
            %class.
            requireChild=0;
            nodeSequence=0;
            
            %Verify the hed tags are in compliance with a given hed specification, extract requireChild
            %information
            if ~isempty(hm)
                nodeSequence = cell(size(obj.originalHedStrings));
                requireChild = cell(size(obj.originalHedStrings));
                
                for i=1:length(obj.originalHedStrings)
                    [val, nodeSequence{i}, requireChild{i}] = hm.isValidHedString(obj.originalHedStrings{i});
                    if val~=1
                        error('hedTree: "%s" not located in hed specification - replacing with "time-locked event"', obj.originalHedStrings{i});
                        obj.originalHedStrings{i} = 'time-locked event';
                    end
                    
                    if mod(i,1000)==1
                        prog=i/length(obj.originalHedStrings)*100;
                        fprintf('hedTree: progress %d percent\n',prog);
                    end
                end
                
                obj.hedVersion=hm.hedVersion;
            end
            
            [obj.uniqueTag, obj.uniqueTagCount, obj.originalHedStringId] = hedTree.hed_tag_count(obj.originalHedStrings, nodeSequence, requireChild);
            obj = makeAdjacencyMatrix(obj);
        end;
        
        function obj = makeAdjacencyMatrix(obj)
            isParentyMatrix = false(length(obj.uniqueTag)+1, length(obj.uniqueTag)+1);
            
            hedTree.progress('init');
            for i=1:length(obj.uniqueTag)
                
                if mod(i, 200) == 0
                    hedTree.progress(i/length(obj.uniqueTag), 'Step 4/4');
                end;
                
                isParentyMatrix(i+1,2:end) = strncmpi(obj.uniqueTag{i}, obj.uniqueTag, length(obj.uniqueTag{i}));
            end;
            
            
            % find top-level nodes to be connected to the 'root' node, they are recognized as having no parents
            isParentyMatrix = logical(isParentyMatrix - diag(diag(isParentyMatrix)));
            isTopLevel = ~any(isParentyMatrix);
            
            obj.adjacencyMatrix = isParentyMatrix;
            
            obj.adjacencyMatrix(1,isTopLevel) = true;
            obj.adjacencyMatrix(1,1) = false; % the root node is not considered a child of itself.
            obj.adjacencyMatrix = obj.adjacencyMatrix | obj.adjacencyMatrix';
            
            pause(.1);
            hedTree.progress('close'); % duo to some bug need a pause() before
            fprintf('\n');
        end;
        
        
        function plot(obj, varargin)
            uniqueTagLabel = cell(length(obj.uniqueTag),1);
            for i=1:length(obj.uniqueTag)
                locationOfSlash = find(obj.uniqueTag{i} == '/', 1, 'last');
                
                if isempty(locationOfSlash)
                    uniqueTagLabel{i} = obj.uniqueTag{i};
                else
                    uniqueTagLabel{i} = obj.uniqueTag{i}(locationOfSlash+1:end);
                end;
                
                uniqueTagLabel{i}(1) = upper(uniqueTagLabel{i}(1));
                
                uniqueTagLabel{i} = [uniqueTagLabel{i} ' (' num2str(obj.uniqueTagCount(i)) ')'];
            end;
            
            jtreeGraph(obj.adjacencyMatrix, uniqueTagLabel, 'Hed Tag');
        end;
    end
    
    methods (Static = true)
        
        function n = progress(rate, title)
            %PROGRESS   Text progress bar
            %   Similar to waitbar but without the figure display.
            %
            %   Start:
            %   PROGRESS('init'); initializes the progress bar with title 'Please wait...'
            %   PROGRESS('init',TITLE); initializes the progress bar with title TITLE
            %   PROGRESS(RATE); sets the length of the bar to RATE (between 0 and 1)
            %   PROGRESS(RATE,TITLE); sets the RATE and the TITLE
            %   PROGRESS('close'); (optionnal) closes the bar
            %
            %   Faster version for high number of loops:
            %   The function returns a integer indicating the length of the bar.
            %   This can be use to speed up the computation by avoiding unnecessary
            %   refresh of the display
            %   N = PROGRESS('init'); or N = PROGRESS('init',TITLE);
            %   N = PROGRESS(RATE,N); changes the length of the bar only if different
            %   from the previous one
            %   N = PROGRESS(RATE,TITLE); changes the RATE and the TITLE
            %   PROGRESS('close'); (optionnal) closes the bar
            %
            %   The previous state could be kept in a global variable, but it is a bit
            %   slower and doesn't allows nested waitbars (see examples)
            %
            %   Known bug: Calling progress('close') shortly afer another call of the
            %   function may cause strange errors. I guess it is because of the
            %   backspace char. You can add a pause(0.01) before to avoid this.
            %
            %   Examples:
            %       progress('init');
            %       for i=1:100
            %           progress(i/100, sprintf('loop %d/100',i));
            %
            %           % computing something ...
            %           pause(.1)
            %       end
            %       progress('close'); % optionnal
            %
            %
            %       % Inside a script you may use:
            %       n = progress('init','wait for ... whatever');
            %       for i=1:100
            %           n = progress(i/100,n);
            %
            %           % computing something ...
            %           pause(.1)
            %       end
            %       progress('close');
            %
            %
            %       % Add a time estimation:
            %       progress('init','Processing...');
            % 		tic       % only if not already called
            % 		t0 = toc; % or toc if tic has already been called
            % 		tm = t0;
            % 		L  = 100;
            % 		for i=1:L
            % 			tt = ceil((toc-t0)*(L-i)/i);
            % 			progress(i/L,sprintf('Processing... (estimated time: %ds)',tt));
            %
            % 			% computing something ...
            % 			pause(.1)
            % 		end
            % 		progress('close');
            %
            %
            %       % Add a faster time estimation:
            % 		n  = progress('init','Processing...');
            % 		tic       % only if not already called
            % 		t0 = toc; % or toc if tic has already been called
            % 		tm = t0;
            % 		L  = 100;
            % 		for i=1:L
            % 			if tm+1 < toc % refresh time every 1s only
            % 				tm = toc;
            % 				tt = ceil((toc-t0)*(L-i)/i);
            % 				n  = progress(i/L,sprintf('Processing... (estimated time: %ds)',tt));
            % 			else
            % 				n  = progress(i/L,n);
            % 			end
            %
            % 			% computing something ...
            % 			pause(.1)
            % 		end
            % 		progress('close');
            %
            %       % Nested loops:
            %       % One loop...
            % 		n1 = progress('init','Main loop');
            % 		for i=0:7
            % 			n1 = progress(i/7,n1);
            %
            % 			% ... and another, inside the first one.
            % 			n2 = progress('init','Inside loop');
            % 			for j=0:50
            % 				n2 = progress(j/50,n2);
            %
            % 				% computing something ...
            % 				pause(.01)
            % 			end
            % 			progress('close');
            % 		end
            % 		pause(.01)
            % 		progress('close');
            
            %   31-08-2007
            %   By Joseph martinot-Lagarde
            %   joseph.martinot-lagarde@m4x.org
            
            %   Adapted from:
            %   MMA 31-8-2005, martinho@fis.ua.pt
            %   Department of Physics
            %   University of Aveiro, Portugal
            
            %% The simplest way to bypass it...
            % n = 0; return
            
            %% Width of the bar
            %If changes are made here, change also the default title
            lmax=70;  % TM: changed from lmax=50;
            
            %% Erasing the bar if necessary
            % not needed, but one could find it prettier
            if isequal(rate,'close')
                % there were 3 '\n' added plus the title and the bar itself
                fprintf(rep('\b',2*lmax+3))
                return
            end
            
            %% The init
            if isequal(rate,'init') % If in init stage
                cont = 0;           % we don't continue a previous bar
                back = '\n';        % add a blank line at the begining
                rate = 0;           % start from 0
            else
                cont = 1;           % we continue a previous bar
            end
            
            %% No need to update the view if not necessary
            % optional, but saves a LOT of time
            
            % length of the displayer bar in number of char
            % double([0,1]) to int([0,lmax-1])
            n = min(max( ceil(rate*(lmax-2)) ,0),lmax-2);
            
            % If the 2nd arg is numeric, assumed to be the previous bar length
            if nargin >=2 && isnumeric(title)
                if n == title % If no change, do nothing
                    return
                else          % otherwise continue
                    n_ = title;
                    clear title
                end
            else % draw the whole bar
                n_ = -1;
            end
            
            %% The title
            % If a new title is given, display it
            if exist('title','var')
                Ltitle = length(title);
                if Ltitle > lmax % If too long, cut it
                    title = [title(1:lmax) '\n']
                else             % otherwise center it
                    title = [rep(' ',floor((lmax-Ltitle)/2)) title rep(' ',ceil((lmax-Ltitle)/2)) '\n'];
                end
                if cont % If not in init stage, erase the '\n' and the previous title
                    back = rep('\b',lmax+1);
                end
            else
                if cont % If not in init stage, give a void title
                    title = '';
                    back  = ''; % has to be set
                else    % else set a default title
                    title = '                  Please wait...                  \n';
                end
            end
            
            %% The bar
            % '\f' should draw a small square (at least in Windows XP, Matlab 7.3.0 R2006b)
            % If not, change to any desired single character, like '*' or '#'
            if ~cont || n_ == -1 % at the begining disp the whole bar
                str = ['[' rep('*',n) rep(' ',lmax-n-2) ']\n'];
                if cont % If not in init stage, erase the previous bar
                    back = [back, rep('\b',lmax+1)];
                end
            else % draw only the part that changed
                str  = [rep('*',n-n_) rep(' ',lmax-n-2) ']\n'];
                back = [back, rep('\b',lmax-n_)];
            end
            
            %% The print
            % Actually make the change
            fprintf([back title str]);
            return
            
            %% Function to repeat a char n times
            function cout = rep(cin,n)
                if n==0
                    cout = [];
                    return
                elseif length(cin)==1
                    cout = cin(ones(1,n));
                    return
                else
                    d    = [1; 2];
                    d    = d(:,ones(1,n));
                    cout = cin(reshape(d,1,2*n));
                    return
                end
            end
        end
        
        function [uniqueTag, uniqueTagCount, originalHedStringId] = hed_tag_count(hedStringArray, nodeSequence, requireChild)
            % separate HED string in the array into indivudal tags and removing the ones with ".
            hedTree.progress('init');
            
            %rc designates whether the requireChild feature is being used.
            %This will lump any tag with attribute requireChild="true" with
            %its child. If the name of the child tag is # (to designate a number), it will be
            %lumped with its value, the next proceeding tag.
            if ~iscell(requireChild)
                rc = boolean(0);
            else
                rc = boolean(1);
            end
            
            trimmed = strtrim(hedStringArray);
            hasDoublequote = ~cellfun(@isempty, strfind(hedStringArray, '"'));
            separated =  strtrim(regexp(trimmed, '[;,]', 'split'));
            
            allTags = cell(length(hedStringArray) * 3,1);
            allTagId = zeros(length(hedStringArray) * 3,1);
            counter = 1;
            
            %If we are specifying the requireChild parameter, make sure we
            %have the required number of sequences (one per hedtag)
            if rc
                msg = 'hed_tag_count: did not specify nodeSequence and requireChild args correctly';
                assert((length(nodeSequence)==length(separated))&&(length(nodeSequence)==length(requireChild)), msg);
                allreqChild = cell(length(hedStringArray) * 3,1);
                allNodeSeq = cell(length(hedStringArray) * 3,1);
            end
            
            for i=1:length(separated)
                if rc
                    this_seq = nodeSequence{i};
                    this_req_child = requireChild{i};
                end
                
                this_hed_string = separated{i};
                
                % This class does not recognize the "Time-Locked Event tag,
                % but it may be present in this_hed_string.
                for j=1:length(this_hed_string)
                    if rc
                        if strcmpi(this_seq{j}{1}, 'Time-Locked Event')
                            this_seq{j} = this_seq{j}(2:end);
                            this_req_child{j} = this_req_child{j}(2:end);
                        end
                    end
                    
                    this_hed_string{j} = regexprep(this_hed_string{j}, 'Time-Locked Event/', '', 'ignorecase');
                    this_hed_string{j} = regexprep(this_hed_string{j}, 'Time-Locked Event', '', 'ignorecase');
                end
                
                if mod(i, 200) == 0
                    hedTree.progress(i/length(separated), 'Step 1/4');
                end;
                
                if ~hasDoublequote(i)
                    allTags(counter:(counter+length(this_hed_string) -1)) = this_hed_string;
                    allTagId(counter:(counter + length(this_hed_string) - 1)) = i;
                    
                    %If our node sequence from hedManager matched up
                    if rc
                        msg = 'hed_tag_count: this_seq did not match up with the hed string provided';
                        assert(length(this_seq)==length(this_hed_string), msg);
                        allreqChild(counter:(counter + length(this_hed_string) - 1)) = this_req_child;
                        allNodeSeq(counter:(counter + length(this_hed_string) - 1)) = this_seq;
                    end;
                    
                    counter = counter  + length(this_hed_string);
                end;
            end;
            
            if counter < (length(allTags)+1)
                allTags(counter:end) = [];
                allTagId(counter:end) = [];
            end
            
            % remove numbers, for some reason some tags are just numbers
            isaNumber =  ~isnan(str2double(allTags));
            allTags(isaNumber) = [];
            allTagId(isaNumber) = [];
            
            
            %% unroll the tags so the hierarchy is turned into multiple nodes. For example /Stimulus/Visual/Red becomes three tags: /Stimulus/, Stimulus/Visual and /Stimulus/Visual/Red. This lets us count the higher hierarchy levels.
            
            combinedTag = cell(length(allTags) * 5, 1);
            combinedId = zeros(length(allTags) * 5, 1);
            counter = 1;
            
            hedTree.progress(10, '10 percent');
            
            for i = 1:length(allTags)
                
                if mod(i, 200) == 0
                    hedTree.progress(i/length(allTags), 'Step 2/4');
                end;
                
                this_nodeSequence = regexp(allTags{i}, '[/]', 'split');
                
                if rc
                    this_reqChild = allreqChild{i};
                end
                
                % remove / from start and end
                this_nodeSequence(cellfun(@isempty, this_nodeSequence)) = [];
                
                newTags = {};
                j=0;
                k=1;
                while j < length(this_nodeSequence)
                    j=j+1;
                    
                    if rc
                        %Check if node requires child
                        if this_reqChild(j)==1
                            %Check if child is a number, if soo, keep as part
                            %of this tag.
                            if strcmp(this_nodeSequence(j+1),'#')
                                j=j+1;
                            end
                            continue;
                        end
                    end
                    
                    newTags{k} = strjoin(this_nodeSequence(1:j),'/');
                    k=k+1;
                end;
                
                combinedTag(counter:(counter + length(newTags) - 1)) = newTags;
                
                newTagsId = ones(length(newTags),1) * i;
                %combinedId = cat(1, combinedId, newTagsId);
                combinedId(counter:(counter + length(newTags) - 1)) = newTagsId;
                
                counter = counter + length(newTags);
            end;
            
            if counter < (length(combinedTag)+1)
                combinedTag(counter:end) = [];
                combinedId(counter:end) = [];
            end
            
            %% find unique tags and count them. Use sorting to speed this up.
            
            [sortedCombinedTag ord]= sort(combinedTag);
            sortedCombinedId = combinedId(ord);
            
            [uniqueTag firstIndexUnique]= unique(sortedCombinedTag, 'first');
            [uniqueTag lastIndexUnique]= unique(sortedCombinedTag, 'last');
            
            uniqueTagCount = lastIndexUnique-firstIndexUnique+1;
            
            uniqueTagId = cell(length(lastIndexUnique),1);
            originalHedStringId = cell(length(lastIndexUnique),1);
            for i=1:length(lastIndexUnique)
                
                if mod(i, 200) == 0
                    hedTree.progress(i/length(lastIndexUnique), 'Step 3/4');
                end;
                
                uniqueTagId{i} = unique(sortedCombinedId(firstIndexUnique(i):lastIndexUnique(i))); % these are IDs of allTags.
                originalHedStringId{i} = allTagId(uniqueTagId{i}); % these are IDs of input HED string.
            end;
            
            pause(.1);
            hedTree.progress('close'); % duo to some bug need a pause() before
            fprintf('\n');
        end;
    end;  
end


