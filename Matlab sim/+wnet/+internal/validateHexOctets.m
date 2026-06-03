function validateHexOctets(value, argumentName, expectedSize)
%VALIDATEHEXOCTETS Compatibility shim for Bluetooth Toolbox address setters.
%
% Some MATLAB installations expose bluetoothFrequencyHop but miss the internal
% wnet validator it calls when DeviceAddress is assigned. This local shim keeps
% the simulation package usable by validating the same simple contract needed
% here: a scalar hexadecimal Bluetooth address string.

arguments
    value
    argumentName (1,:) char = 'value'
    expectedSize (1,2) double {mustBeInteger, mustBePositive} = [1 12]
end

if isstring(value)
    if ~isscalar(value)
        error('wnet:validateHexOctets:InvalidType', ...
            '%s must be a scalar string or character vector.', argumentName);
    end
    value = char(value);
end

if ~(ischar(value) && isrow(value))
    error('wnet:validateHexOctets:InvalidType', ...
        '%s must be a scalar string or character vector.', argumentName);
end

if ~isequal(size(value), expectedSize)
    error('wnet:validateHexOctets:InvalidSize', ...
        '%s must be a 1-by-%d hexadecimal character vector.', argumentName, expectedSize(2));
end

if isempty(regexp(value, '^[0-9A-Fa-f]+$', 'once'))
    error('wnet:validateHexOctets:InvalidValue', ...
        '%s must contain only hexadecimal characters 0-9, A-F, or a-f.', argumentName);
end
end

