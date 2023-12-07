function CreateValueWhen()
    local vw = {};
    vw._stream = instance:addInternalStream(0, 0); 
    vw._count = 0;
    function vw:set(period, condition, value, occurrence)
        if self._count > 0 and self._stream:getBookmark(self._count) == period then
            self._stream:setBookmark(self._count, -1);
        end
        if condition then
            if self._count == 0 or self._stream:getBookmark(self._count) ~= -1 then
                self._count = self._count + 1;
            end
            self._stream:setBookmark(self._count, period);
            if value == nil then
                self._stream:setNoData(period);
            else
                self._stream[period] = value;
            end
        end
        if self._count <= occurrence then
            return nil;
        end
        return self._stream[self._stream:getBookmark(self._count - occurrence)];
    end
    return vw;
end