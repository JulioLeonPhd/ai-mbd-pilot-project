function state = initializeState(design, channelCount)
%INITIALIZESTATE Initialize explicit continuous DDC state at scan start.
%   STATE = RADARDEMO.DDC.INITIALIZESTATE(DESIGN, CHANNELCOUNT) returns
%   zero-valued FIR delays and zero-based decimation phase counters.

arguments
    design struct
    channelCount (1, 1) double {mustBeInteger, mustBePositive}
end
state = struct();
state.stage1Delay = zeros(design.stage1Order, channelCount);
state.stage2Delay = zeros(design.stage2Order, channelCount);
state.inputSampleCount = uint64(0);
state.stage1Phase = uint8(0);
state.stage2Phase = uint8(0);
state.channelCount = channelCount;
end
