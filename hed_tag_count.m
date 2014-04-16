function [uniqueTag, uniqueTagCount, originalHedStringId] = hed_tag_count(hedStringArray)
% separate HED string in the array into indivudal tags and removing the ones with " or numbers.

trimmed = strtrim(hedStringArray);
hasDoublequote = ~cellfun(@isempty, strfind(hedStringArray, '"'));
separatd =  strtrim(regexp(trimmed, '[;,]', 'split'));

allTags = cell(length(hedStringArray) * 3,1);
allTagId = zeros(length(hedStringArray) * 3,1);
counter = 1;
for i=1:length(separatd)
    if ~hasDoublequote(i)
    inside = separatd{i};
    allTags(counter:(counter+length(inside) -1)) = inside;
    allTagId(counter:(counter + length(inside) - 1)) = i;
    counter = counter  + length(inside);
    end;
end;

allTags(counter:end) = [];
allTagId(counter:end) = [];


% remove numbers, for some reason some tags are just numbers
isaNumber =  ~isnan(str2double(allTags));
allTags(isaNumber) = [];
allTagId(isaNumber) = [];

%% unroll the tags so the hierarchy is turned into multiple nodes. For example /Stimulus/Visual/Red becomes three tags: /Stimulus/, Stimulus/Visual and /Stimulus/Visual/Red. This lets us count the higher hierarchy levels.

combinedTag = cell(length(allTags) * 5, 1);
combinedId = zeros(length(allTags) * 5, 1);
counter = 1;

for i = 1:length(allTags)   
    nodeSequence = regexp(allTags{i}, '[/]', 'split');
    
    % remove / from start and end
    nodeSequence(cellfun(@isempty, nodeSequence)) = [];
    
    newTags = {};    
    for j=1:length(nodeSequence)
        if j==1
            newTags{j} = nodeSequence{1};
        else
            newTags{j} = strjoin('/', nodeSequence(1:j));
        end;
    end;
    
     combinedTag(counter:(counter + length(newTags) - 1)) = newTags;
     
     newTagsId = ones(length(newTags),1) * i;
     %combinedId = cat(1, combinedId, newTagsId);    
     combinedId(counter:(counter + length(newTags) - 1)) = newTagsId;
     
     counter = counter + length(newTags);     
end;

if counter < length(combinedTag)
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
    uniqueTagId{i} = unique(sortedCombinedId(firstIndexUnique(i):lastIndexUnique(i))); % these are IDs of allTags.    
    originalHedStringId{i} = allTagId(uniqueTagId{i}); % these are IDs of input HED string.
end;

