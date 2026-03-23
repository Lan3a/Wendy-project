function output = findFilesToProcess(inFileSpec, outFileSpec)
% inFileSpec, outFileSpec: {folderPath, extension} or just folderPath
% Returns a struct array with fields: name, baseName, filePath, ...

% ----- INPUT FILES -----
[inFolder, inExt] = parseSpec(inFileSpec);
if ~isfolder(inFolder), mkdir(inFolder); end
inStruct = listFiles(inFolder, inExt);      % struct array
if isempty(inStruct)
    inBase = {};
else
    inBase   = {inStruct.baseName}.';       % base names (no extension)
end

% ----- OUTPUT FILES -----
[outFolder, outExt] = parseSpec(outFileSpec);
if ~isfolder(outFolder), mkdir(outFolder); end
outStruct = listFiles(outFolder, outExt);  % struct array
if isempty(outStruct)
    outBase = {};
else
    outBase   = {outStruct.baseName}.';
end

% ----- CHOICE: ONLY UNPROCESSED / ALL -----
choice = questdlg('View files', '', 'Only unprocessed', 'All', 'All');
switch choice
    case 'Only unprocessed'
        % Compare only base names. listFiles has already restricted each side
        % to its own extension (if provided), so ext matching is respected.
        mask = ~ismember(inBase, outBase);
        output = inStruct(mask);
        if isempty(output)
            error('findFilesToProcess:NoUnprocessed', 'No unprocessed files.');
        end
    case 'All'
        output = inStruct;
    otherwise
        error('findFilesToProcess:Cancelled', 'Cancelled.');
end

% ----- SELECTION GUI (filtered struct) -----
listStr = {output.baseName}.';   % show base names in dialog
[idx, ok] = listdlg('PromptString', 'Select files:', 'ListString', listStr);
if ~ok, error('findFilesToProcess:Cancelled', 'Cancelled.'); end
output = output(idx);

% ----- FINAL CONFIRMATION -----
if ~strcmp(questdlg(sprintf('Process %d file(s)?', numel(output)), '', 'Yes', 'No', 'No'), 'Yes')
    error('findFilesToProcess:Cancelled', 'Cancelled.');
end

end

function [folder, ext] = parseSpec(spec)
if iscell(spec)
    folder = char(spec{1});
    ext = '';
    if numel(spec) >= 2 && ~isempty(spec{2})
        ext = char(spec{2});
        if ext(1) ~= '.', ext = ['.', ext]; end
    end
else
    folder = char(spec);
    ext = '';
end
end

function f = listFiles(folder, ext)
% Build a struct array of files in folder.
% If ext is non-empty (e.g. '.edf'), only keep files matching that ext.
% Adds:
%   - baseName : filename without extension
%   - filePath : full path
% Reorders fields so: name, baseName, filePath, then the rest.

if ~isfolder(folder)
    f = struct([]);
    return;
end

d = dir(folder);
d = d(~[d.isdir]);   % keep only files

if ~isempty(ext)
    names = {d.name};
    keep  = endsWith(names, ext);
    d     = d(keep);
end

if isempty(d)
    f = struct([]);
    return;
end

for i = 1:numel(d)
    [~, base, ~] = fileparts(d(i).name);
    d(i).baseName = base;
    d(i).filePath = fullfile(d(i).folder, d(i).name);
end

% Reorder fields: name, baseName, filePath, then others
fn = fieldnames(d);
fn(strcmp(fn, 'name'))     = [];
fn(strcmp(fn, 'baseName')) = [];
fn(strcmp(fn, 'filePath')) = [];
order = [{'name'}; {'baseName'}; {'filePath'}; fn];

f = orderfields(d, order);
end
