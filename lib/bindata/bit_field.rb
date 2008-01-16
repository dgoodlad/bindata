require 'bindata/base'

module BinData
  # A container for Bit values. It assumes that its contents will consume an
  # even multiple of 8 bits.
  #
  #  bf = BitField.new(:fields => [ [:a, 4, { :initial_value => 1 }],
  #                                 [:b, 10],
  #                                 [:c, 2] ])
  #  bf.a # => 4
  #  bf.b = 0x200
  #  io = StringIO.new
  #  bf.write(io)
  #  io.rewind
  #  io.read # => "\x20\x01"
  #
  # A graphical representation of the bits after all that work could look
  # like:
  #
  #  00100000 00000001
  #  **
  #    ****** ****
  #               ****
  #  c b          a
  #
  #
  # == Assumptions
  #
  # The entire bit field is represented in 'big endian' form, with the
  # most-significant byte of the entire field transmitted first. Its fields
  # are also big-endian, as described in the description of the Bit class.
  #
  # == Parameters
  #
  # <tt>:fields</tt>:: An array of fields which make up this BitField. Each
  #                    element of the array is of the form [name, bit length,
  #                    params].
  class BitField < Base
    register(self.name, self)

    mandatory_parameter :fields

    # Used by fields to store incomplete bytes left over from their read/write
    # operations, which can subsequently be used by the following field.
    attr_accessor :leftover_byte

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

    # Allows direct access to fields' values like:
    #
    #  bitfield.a = 0
    #
    # instead of
    #
    #  bitfield.a.value = 0
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

    # Returns the bindata object for the given field name
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

    def snapshot
      hash = {}
      @fields.each do |name, obj|
        hash[name] = obj.snapshot
      end
      hash
    end

    def field_names
      @fields.map { |n, o| n }
    end

    private

    def _num_bytes(ignored)
      (bindata_objects.inject(0) { |sum, f| sum + f.bit_length } / 8.0).ceil
    end

    def _do_read(io)
      # XXX Ugly way to reverse the order of the bytes read from the io stream
      io = StringIO.new(io.read(num_bytes).unpack("C*").reverse.pack("C*"))
      bindata_objects.each { |f| f.do_read(io) }
    end

    def done_read
      bindata_objects.each { |f| f.done_read }
    end

    def _write(io)
      # XXX Ugly way to reverse the order in which bytes are written to the
      #     given io stream
      sio = StringIO.new
      bindata_objects.each { |f| f.write(sio) }
      sio.rewind
      io.write sio.read(num_bytes).unpack("C*").reverse.pack("C*")
    end

    def bindata_objects
      @fields.collect { |f| f[1] }
    end
  end
end
