require 'bindata/single'

module BinData
  # An unsigned big-endian integer of arbirary bit length. It may be offset to
  # begin at a non-zero position in the data.
  #
  # For example, a Bit with offset 2 and length 10 would look like this in a
  # pair of bytes:
  #
  #  0000100000001100
  #      |--------|
  #
  # In this case, its value would be 0b1000000011 = 0x203.
  #
  # *NOTE*: this data type is untested outside of the scope of a BitField. Its
  # behavior is unspecified when not used as a member of a BitField.
  #
  # == Parameters
  #
  # <tt>:bit_offset</tt>:: The offset from the actual least-significant bit of
  #                        the data at which this value's least-significant
  #                        bit resides.
  # <tt>:bit_length</tt>:: The number of bits used to represent this value.
  #
  class Bit < Single
    def initialize(params, env)
      super(params, env)
    end

    mandatory_parameters :bit_offset, :bit_length

    # Return a sensible default for this data.
    def sensible_default
      0
    end

    # Returns the number of bits this value uses
    def bit_length; param(:bit_length); end

    # Returns the bit offset at which this value begins
    def bit_offset; param(:bit_offset); end

    private

    def read_val(io)
      bytes = if bit_offset > 0 && leftover_byte
                [leftover_byte] + readbytes(io, num_bytes - 1).unpack("C*")
              else
                readbytes(io, num_bytes).unpack("C*")
              end

      value, self.leftover_byte = read_value_from_bytes(bytes)
      value
    end

    def read_value_from_bytes(bytes)
      value = 0
      bytes.each_with_index do |b, index|
        value |= b << (index * 8) >> bit_offset
      end
      value &= 2 ** bit_length - 1
      leftover = bytes.last & 0xFF - (2 ** bit_offset - 1)
      return value, leftover
    end

    def _num_bytes(ignored)
      ((bit_length + bit_offset) / 8.0).ceil
    end

    def _write(io)
      raise "can't write whilst reading" if @in_read

      # Build an array of bytes, with byte[0] being least-significant
      shifted_value = value << bit_offset
      bytes = []
      num_bytes.times do |i|
        bytes << (shifted_value & 0xFF)
        shifted_value >>= 8
      end

      # Bring in any data left over from another Bit's write method
      if bit_offset != 0
        bytes[0] |= leftover_byte
      end

      # If we don't consume the most-significant bit of the last byte, assume
      # that there will be more fields adding to that byte, so store it off
      # for later
      if (bit_offset + bit_length) % 8 != 0
        self.leftover_byte = bytes.pop
      end

      # If there are full bytes to write, write them to the io stream in
      # reverse order (big-endian)
      if bytes.size > 0
        io.write bytes.reverse.pack("C*")
      end
    end

    # Returns any value from the parent object which was left over by another
    # Bit's read/write operation
    def leftover_byte
      @env.parent_data_object.leftover_byte
    end

    # Informs the parent object of an incomplete byte which we have left over
    # from a read/write operation
    def leftover_byte=(b)
      @env.parent_data_object.leftover_byte = b
    end
  end
end
