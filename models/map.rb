require_relative './linkedin'
class Map
  API_KEY = LinkedInAuth.get(3).client_id

  def self.make_link(location, postcode)
    @location_string = strip_spaces(location, postcode)
    iframe_html = "<iframe width='80%' height='300' frameborder='0' style='border:0' src='https://www.google.com/maps/embed/v1/place?key=#{API_KEY}&q=#{@location_string}' allowfullscreen></iframe>"
    return iframe_html
  end

  def self.strip_spaces(location, postcode)
    str = location + ',' + postcode
    return str.downcase.tr(' ', '+')
  end

end
