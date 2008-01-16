require 'bindata/single'

module BinData
  class Bit < Single
    def initialize(params, env)
      super(params, env)
    end

    mandatory_parameters :bit_offset, :bit_length

    # Return a sensible default for this data.
    def sensible_default
      0
    end

    def read_val(io)
      bytes = if bit_offset > 0 && leftover_byte
                [leftover_byte] + readbytes(io, num_bytes.ceil - 1).unpack("C*")
              else
                readbytes(io, num_bytes.ceil).unpack("C*")
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
      ((bit_length + bit_offset) / 8.0)
    end

    def _write(io)
      raise "can't write whilst reading" if @in_read

      # Build an array of bytes, with byte[0] being least-significant
      shifted_value = value << bit_offset
      bytes = []
      num_bytes.ceil.times do |i|
        bytes << (shifted_value & 0xFF)
        shifted_value >>= 8
      end

      if bit_offset != 0
        bytes[0] |= leftover_byte
      end

      if (bit_offset + bit_length) % 8 != 0
        self.leftover_byte = bytes.pop
      end

      if bytes.size > 0
        io.write bytes.reverse.pack("C*")
      end
    end

    def bit_length; param(:bit_length); end
    def bit_offset; param(:bit_offset); end

    def leftover_byte
      if @env.parent_data_object.respond_to?(:leftover_byte)
        @env.parent_data_object.leftover_byte
      else
        0
      end
    end
    def leftover_byte=(b)
      if @env.parent_data_object.respond_to?(:leftover_byte=)
        @env.parent_data_object.leftover_byte = b
      end
    end
  end
end
