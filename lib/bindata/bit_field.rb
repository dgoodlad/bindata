require 'bindata/base'

module BinData
  class BitField < Base
    mandatory_parameter :fields

    def initialize(params = {}, env = nil)
      super(params, env)

      bit_offset = 0
      @fields = param(:fields).collect do |name, bit_length, params|
        params = { :bit_length => bit_length,
                   :bit_offset => bit_offset }.merge(params || {})
        bit_offset += bit_length; bit_offset %= 8
        [name, Bit.new(params, create_env)]
      end
    end

    def method_missing(symbol, *args, &block)
      name = symbol.id2name

      is_writer = (name[-1, 1] == "=")
      name.chomp!("=")

      # find the object that is responsible for name
      if (obj = find_obj_for_name(name))
        # pass on the request
        if is_writer
          obj.value = *args
        else
          obj.value
        end
      else
        super
      end

    end

    def find_obj_for_name(name)
      n, o = @fields.assoc(name.to_sym)
      return o
    end

    def clear(name = nil)
      if name.nil?
        bindata_objects.each { |f| f.clear }
      else
        find_obj_for_name(name.to_s).clear
      end
    end

    attr_accessor :leftover_byte

    private

    def _num_bytes(ignored)
      (bindata_objects.inject(0) { |sum, f| sum + f.bit_length } / 8.0).ceil
    end

    def _do_read(io)
      bindata_objects.each { |f| f.do_read(io) }
    end

    def done_read
    end

    def bindata_objects
      @fields.collect { |f| f[1] }
    end
  end
end
