require_relative './linkedin'
class Map

  def self.make_link(location, postcode)
    @location_string = strip_spaces(location, postcode)
    iframe_html = "<iframe width='100%' height='400' frameborder='0' style='border:0' src='https://www.google.com/maps/embed/v1/place?key=#{ENV['GOOGLEMAPS_KEY']}&q=#{@location_string}' allowfullscreen></iframe>"
    return iframe_html
  end

  def self.strip_spaces(location, postcode)
    str = location + ',' + postcode
    return str.downcase.tr(' ', '+')
  end

end
