function address = randomDeviceAddress()
%RANDOMDEVICEADDRESS Generate a random 6-octet Bluetooth address string.

hexChars = "0123456789ABCDEF";
nibbles = randi([1, strlength(hexChars)], 1, 12);
address = strings(1, 1);
address{1} = char(extractBetween(hexChars, nibbles, nibbles));
address = join(string(address{1}), "");
address = erase(address, " ");

if address == "000000000000"
    address = "000000000001";
end
end

