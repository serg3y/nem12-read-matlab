function [T, blocks] = nem12read(file)
% Read NEM12 data files and output data as a table.
% (Tested only on files with only '200' and '300' codes.)
%   T = nem12read(file)
%
% Remarks:
% - NEM12 is a very old CSV format used by SA Power Networks to provide
%   electricity usage data, via their customer portal:
%   https://customer.portal.sapowernetworks.com.au/meterdata
%
% Example:
%   T = nem12read('sample.csv')
%
% NEM12 format description:
% https://www.energyaustralia.com.au/resources/PDFs/User%20Guide_v3.pdf

% Please send your sample files to: s3rg3y at hotmail dot com

% Read file contents
txt = fileread(file);

% Split text into blocks using '200' code
txtblocks = regexp([10 txt], '(?<=\n200,).*?(?=\n200|\n900|$)', 'match');

% Extract block header information
frmt = '(?<nmi>\d+),(?<list>\w+),(?<ch2>\w+),(?<channel>\w+),.*,(?<meter>\d+),(?<unit>\w+),(?<rez>\d+),\n(?<data>.*)';
blocks = regexp(txtblocks, frmt, 'names');

% Parse data for each block
data = cell(size(blocks));
for k = 1:numel(blocks)
    data{k} = parseblock(blocks{k}.data, str2double(blocks{k}.rez), blocks{k}.channel);
end

% Combine parsed data into one table and pivot using 'channel'
T = cat(1, data{:});
T = unstack(T, 'kwh', 'channel');
end

% Helper function to parse each data block
function T = parseblock(txt, rez, channel)
tod = 0 : rez/24/60 : 1 - 0.0001;
frmt = ['300 %{yyyyMMdd}D' repmat('%f', 1, numel(tod)) '%s%*s%*s%{yyyyMMddHHmmss}D'];

data = textscan(txt, frmt, 'Delimiter', ',', 'CollectOutput', true);
kwh = reshape(data{2}', [], 1);
start = reshape((data{1} + tod)', [], 1);
start.Format = 'yyyy-MM-dd HH:mm';

T = table(start, kwh);
T.channel(:) = string(channel);
end
