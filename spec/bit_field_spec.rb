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
end
