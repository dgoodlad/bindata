require 'bindata/single'

module BinData
  class Bit < Single
    def initialize(params, env)
      super(params, env)

      #if @env.parent_data_object.nil?
      #  raise ArgumentError, "Bit data objects cannot be initialized outside the context of a BitField"
      #end
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

    def bit_length; param(:bit_length); end
    def bit_offset; param(:bit_offset); end

    def leftover_byte; @env.parent_data_object.leftover_byte; end
    def leftover_byte=(b); @env.parent_data_object.leftover_byte = b; end
  end
end
