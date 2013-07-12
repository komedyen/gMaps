require 'nokogiri'
require 'geocoder'
require 'open-uri'

class Location < ActiveRecord::Base
  attr_accessible :address, :latitude, :longitude
  geocoded_by :address
  reverse_geocoded_by :latitude, :longitude
  after_validation :geocode, :reverse_geocode

  def air
    loc = Geocoder.search(address).first
    doc = Nokogiri::HTML(open(URI.encode("https://maps.google.com/maps?q=airport+" << address.tr(' ', '+'))))
    link = doc.css('#link_A_2')[0]
    addr = link.content
    airport = Geocoder.search(addr)
    if airport.first.country.eql?(loc.country)
      airport.first
    else
      link = doc.css('#link_B_2')[0]
      addr = link.content
      airport = Geocoder.search(addr)
    end

    airport.first
  end

  def bus
    doc = Nokogiri::HTML(open(URI.encode("https://maps.google.com/maps?q=otobus+duraklari+" << address.tr(' ', '+'))))
    link = doc.css('span span')[8]
    addr = link.content
    busstop = Geocoder.search(addr).first
  end

  def hosp
    doc = Nokogiri::HTML(open(URI.encode("https://maps.google.com/maps?q=hospital+" << address.tr(' ', '+'))))
    link = doc.css('#link_A_2')[0]
    addr = link.content
    hospital = Geocoder.search(addr).first
  end

end
