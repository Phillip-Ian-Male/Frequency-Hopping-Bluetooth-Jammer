function address = randomDeviceAddress()
%RANDOMDEVICEADDRESS Generate a random 6-octet Bluetooth address string.

hexChars = '0123456789ABCDEF';
address = string(hexChars(randi(numel(hexChars), 1, 12)));

if address == "000000000000"
    address = "000000000001";
end
end
