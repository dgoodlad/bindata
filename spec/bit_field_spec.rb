#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__)) + '/spec_common'
require 'bindata'

describe "A bit field with 8 bits of fields" do
  before(:each) do
    @bf = BinData::BitField.new(:fields =>
                                  [ [:a, 4, {:initial_value => 0xC}],
                                    [:b, 3, {:initial_value => 0x5}],
                                    [:c, 1] ])
  end

  it "should be 1 byte long" do
    @bf.num_bytes.should == 1
  end

  it "should get fields' values directly" do
    @bf.a.should == 0xC
    @bf.b.should == 0x5
    @bf.c.should == 0
  end

  it "should set fields' values directly" do
    @bf.a = 0xB
    @bf.a.should == 0xB
  end

  it "should clear its fields when cleared" do
    @bf.a = 0xB
    @bf.clear
    @bf.a.should == 0xC
  end

  it "should read from an io stream" do
    io = StringIO.new("\xA3")
    @bf.read(io)
    @bf.a.should == 3
    @bf.b.should == 2
    @bf.c.should == 1
  end

  it "should write to an io stream" do
    io = StringIO.new
    @bf.write(io)
    io.rewind
    io.read.should == "\x5C"
  end
end

describe "A bit field with 16 bits of fields" do
  before(:each) do
    @bf = BinData::BitField.new(:fields =>
                                  [ [:a, 2,  {:initial_value => 0x3}],
                                    [:b, 10, {:initial_value => 0x2BB}],
                                    [:c, 4,  {:initial_value => 0xA}] ])
  end

  it "should be 2 bytes long" do
    @bf.num_bytes.should == 2
  end

  it "should get fields' values directly" do
    @bf.a.should == 0x3
    @bf.b.should == 0x2BB
    @bf.c.should == 0xA
  end

  it "should set fields' values directly" do
    @bf.a = 0x9
    @bf.a.should == 0x9
  end

  it "should clear its fields when cleared" do
    @bf.a = 0x9
    @bf.clear
    @bf.a.should == 0x3
  end

  it "should read from an io stream" do
    io = StringIO.new("\x84\x21")
    @bf.read(io)
    @bf.a.should == 0x1
    @bf.b.should == 0x108
    @bf.c.should == 0x8
  end

  it "should write to an io stream" do
    io = StringIO.new
    @bf.write(io)
    io.rewind
    io.read.should == "\xAA\xEF"
  end
end
