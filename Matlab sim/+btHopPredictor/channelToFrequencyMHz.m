function freqMHz = channelToFrequencyMHz(channelIndex)
%CHANNELTOFREQUENCYMHZ Convert BR/EDR channel index to center frequency.

freqMHz = 2402 + double(channelIndex);
end

