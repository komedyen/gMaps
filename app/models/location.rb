#!/bin/env ruby
# encoding: utf-8

require 'nokogiri'
require 'geocoder'
require 'open-uri'
require 'mechanize'
require 'json'

class Location < ActiveRecord::Base
  attr_accessible :address, :latitude, :longitude
  geocoded_by :address
  reverse_geocoded_by :latitude, :longitude
  after_validation :geocode, :reverse_geocode

  def air
    loc = Geocoder.search(address).first
    prep = 'https://maps.google.com/maps?q=airport+near+' << loc.address_components[4]['long_name'] << '+' << loc.country
    crawl(prep)
  end

  def bus
    prep = 'https://maps.google.com/maps?q=otobus+duraklari+near+' << address.tr(' ', '+')
    crawl(prep)
  end

  def restaurant
    prep = 'https://maps.google.com/maps?q=restaurants+near+' << address.tr(' ', '+')
    crawl(prep)
  end

  def hosp
    prep = 'https://maps.google.com/maps?q=hospital+near+' << address.tr(' ', '+')
    crawl(prep)
  end

  def crawl(url)
    @uno = []
    a = Mechanize.new
    page = a.get(url)
    page.encoding = 'ISO-8859-1'
    gForm = page.forms[0].submit
    gDoc = gForm.parser
    data = gDoc.css('script').text.to_s[64..-4][0..-14]
    f = Mechanize.new
    formatter = f.get('http://jsonformat.com/')
    fForm = formatter.forms.first
    fForm.jsondata = data
    s = fForm.submit
    jData = s.forms[1].jsondata
    parsed = JSON.parse(jData)['overlays']['markers']
    parsed.each do |node|
      duo = node['id'].to_s << ' '
      duo << node['latlng']['lat'].to_s << ' '
      duo << node['latlng']['lng'].to_s
      @uno << duo
    end
    @uno
  end

end
