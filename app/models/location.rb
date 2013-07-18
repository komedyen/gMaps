require 'nokogiri'
require 'geocoder'
require 'open-uri'
require 'mechanize'


class Location < ActiveRecord::Base
  attr_accessible :address, :latitude, :longitude
  geocoded_by :address
  reverse_geocoded_by :latitude, :longitude
  after_validation :geocode, :reverse_geocode

  def air
    loc = Geocoder.search(address).first
    prep = 'https://maps.google.com/maps?q=airport+near+' << loc.address_components[4]['long_name'] << '+' << loc.country
    crawl(prep,"airport")
  end

  def bus
    prep = 'https://maps.google.com/maps?q=bus+stations+near+' << address.tr(' ', '+')
    crawl(prep,"bus station")
  end

  def restaurant
    prep = 'https://maps.google.com/maps?q=restaurants+near+' << address.tr(' ', '+')
    crawl(prep,"restaurant")
  end

  def hosp
    prep = 'https://maps.google.com/maps?q=hospital+near+' << address.tr(' ', '+')
    crawl(prep,"hospital")
  end

  def crawl(url,key)
    @uno = []
    a = Mechanize.new
    page = a.get(url)
    gsForm = page.forms[0]
    gsForm.encoding = 'utf-8'
    gForm = gsForm.submit
    gDoc = gForm.parser
    data = gDoc.css('script').text.to_s[64..-4][0..-14]
    parsed = eval(data)[:overlays][:markers]
    parsed.each do |node|
      prep = node[:latlng][:lat].to_s << ','
      prep << node[:latlng][:lng].to_s
      @uno << validate(prep,key)
    end
    @uno
  end

  def validate(data,key)
      coded = Geocoder.search(data)
      coded.each do |d|
        return d if d.types.include?(key)
      end
  end

end
